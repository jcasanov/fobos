------------------------------------------------------------------------------
-- Titulo           : vehp211.4gl - Recepcion de Pedidos
-- Elaboracion      : 02-oct-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp211 base modulo compania localidad [num_ped]
--		Si (num_ped <> 0) el programa se esta ejcutando en modo de
--			solo consulta
--		Si (num_ped = 0) el programa se esta ejecutando en forma 
--			independiente
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_num_ped	LIKE veht034.v34_pedido
DEFINE vm_nivel_cta	LIKE ctbt001.b01_nivel

DEFINE vm_ind_arr   	SMALLINT	-- Indica el numero de elementos del
					-- detalle
DEFINE vm_ini_arr	SMALLINT	-- Indica la posicion inicial desde
					-- que se empezo a mostrar la ultima vez
DEFINE vm_curr_arr	SMALLINT	-- Indica la posición actual en el
					-- detalle (ultimo elemento mostrado)

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_v34		RECORD LIKE veht034.*
DEFINE rm_v35		RECORD LIKE veht035.*
DEFINE rm_pedido ARRAY[100] OF RECORD 
	check		CHAR(1),                
	secuencia	LIKE veht035.v35_secuencia,
	modelo		LIKE veht035.v35_modelo,
	color		LIKE veht035.v35_cod_color,
	serie      	LIKE veht022.v22_chasis,
	precio_unit	LIKE veht035.v35_precio_unit,
	v35_estado	LIKE veht035.v35_estado
END RECORD
DEFINE rm_v22	 ARRAY[100] OF RECORD
	v22_chasis	LIKE veht022.v22_chasis,
	v22_estado	LIKE veht022.v22_estado,
	v22_bodega	LIKE veht022.v22_bodega,
	v22_modelo	LIKE veht022.v22_modelo,
	v22_comentarios	LIKE veht022.v22_comentarios,
	v22_motor	LIKE veht022.v22_motor,
	v22_ano		LIKE veht022.v22_ano,
	v22_cod_color	LIKE veht022.v22_cod_color,
	v22_moneda_prec	LIKE veht022.v22_moneda_prec,
	v22_precio	LIKE veht022.v22_precio
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN	-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'vehp211'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

INITIALIZE vm_num_ped TO NULL
IF num_args() = 5 THEN
	LET vm_num_ped  = arg_val(5)
END IF

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12,
	INSERT KEY F20,
	DELETE KEY F21
OPEN WINDOW w_211 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_211 FROM '../forms/vehf211_1'
DISPLAY FORM f_211

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v34.* TO NULL
INITIALIZE rm_v35.* TO NULL
CALL muestra_contadores()

LET vm_max_rows = 1000

CALL setea_botones_f1()

IF vm_num_ped IS NOT NULL THEN
	CALL execute_query()
END IF

SELECT MAX(b01_nivel) INTO vm_nivel_cta FROM ctbt001
IF vm_nivel_cta IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No se ha configurado el plan de cuentas.',
		'stop')
	EXIT PROGRAM
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Avanzar Detalle'
		HIDE OPTION 'Retroceder Detalle'
		IF vm_num_ped IS NOT NULL THEN  -- Se ejecuta en modo de solo
			HIDE OPTION 'Ingresar'  -- consulta
			HIDE OPTION 'Consultar'
			IF (vm_ind_arr - vm_curr_arr) > 0 THEN
				SHOW OPTION 'Avanzar Detalle'
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar modificar registros.'
		HIDE OPTION 'Avanzar Detalle'
		HIDE OPTION 'Retroceder Detalle'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 AND (vm_ind_arr - vm_curr_arr) > 0 THEN
			SHOW OPTION 'Avanzar Detalle'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
			IF (vm_ind_arr - vm_curr_arr) > 0 THEN
				SHOW OPTION 'Avanzar Detalle'
			END IF
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			IF (vm_ind_arr - vm_curr_arr) > 0 THEN
				SHOW OPTION 'Avanzar Detalle'
			END IF
		END IF
		CALL setea_botones_f1()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		HIDE OPTION 'Avanzar Detalle'
		HIDE OPTION 'Retroceder Detalle'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			IF (vm_ind_arr - vm_curr_arr) > 0 THEN
				SHOW OPTION 'Avanzar Detalle'
			END IF
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Avanzar Detalle'
				HIDE OPTION 'Retroceder Detalle'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			IF (vm_ind_arr - vm_curr_arr) > 0 THEN
				SHOW OPTION 'Avanzar Detalle'
			END IF
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		CALL setea_botones_f1()
	COMMAND KEY('V') 'Avanzar Detalle'	'Muestra sigientes detalles.'
		CALL control_mostrar_sig_det()
		IF (vm_ind_arr - vm_curr_arr) <= 0 THEN
			HIDE OPTION 'Avanzar Detalle'
		END IF
		SHOW OPTION 'Retroceder Detalle'
	COMMAND KEY('T') 'Retroceder Detalle'	'Muestra anteriores detalles.'
		CALL control_mostrar_ant_det()
		SHOW OPTION 'Avanzar Detalle'
		IF vm_ini_arr <= 1 THEN
			HIDE OPTION 'Retroceder Detalle'
		END IF
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		HIDE OPTION 'Avanzar Detalle'
		HIDE OPTION 'Retroceder Detalle'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF (vm_ind_arr - vm_curr_arr) > 0 THEN
			SHOW OPTION 'Avanzar Detalle'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		HIDE OPTION 'Avanzar Detalle'
		HIDE OPTION 'Retroceder Detalle'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF (vm_ind_arr - vm_curr_arr) > 0 THEN
			SHOW OPTION 'Avanzar Detalle'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE num_elm		SMALLINT
DEFINE intentar		SMALLINT
DEFINE done   		SMALLINT
DEFINE i      		SMALLINT
DEFINE contador 	SMALLINT
DEFINE resp 		CHAR(6)

DEFINE num_rows			SMALLINT

DEFINE r_v22		RECORD LIKE veht022.*
DEFINE r_v34		RECORD LIKE veht034.*

CLEAR FORM

INITIALIZE r_v22.* TO NULL

LET r_v22.v22_fecing      = CURRENT
LET r_v22.v22_usuario     = vg_usuario
LET r_v22.v22_compania    = vg_codcia
LET r_v22.v22_localidad   = vg_codloc

-- THESE FIELDS ARE NOT NULL SO IN AN INPUT I CAN'T PUT NULL'S IN THEM -- 

LET r_v22.v22_kilometraje = 0    
LET r_v22.v22_nuevo       = 'S'  
LET r_v22.v22_costo_liq   = 0.00 
LET r_v22.v22_cargo_liq   = 0.00 
LET r_v22.v22_costo_ing   = 0.00 
LET r_v22.v22_cargo_ing   = 0.00 
LET r_v22.v22_costo_adi   = 0.00 
LET r_v22.v22_moneda_liq  = rg_gen.g00_moneda_base 
LET r_v22.v22_moneda_ing  = rg_gen.g00_moneda_base
LET r_v22.v22_moneda_prec = rg_gen.g00_moneda_base

---------------------------------------------------------------------------- 

LET INT_FLAG = 0
INPUT BY NAME rm_v34.v34_pedido  
	ON KEY(F2)
		IF INFIELD(v34_pedido) THEN
			CALL fl_ayuda_pedidos_vehiculos(vg_codcia, vg_codloc,
							'R')
				RETURNING r_v34.v34_pedido, r_v34.v34_estado,
					  r_v34.v34_fec_envio, 
					  r_v34.v34_fec_llegada
			IF r_v34.v34_pedido IS NOT NULL THEN
				LET rm_v34.v34_pedido      = r_v34.v34_pedido
				DISPLAY BY NAME rm_v34.v34_pedido
			END IF		
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL setea_botones_f1()
	AFTER FIELD v34_pedido
		IF rm_v34.v34_pedido IS NOT NULL THEN
			CALL fl_lee_pedido_veh(vg_codcia, vg_codloc,
 					       rm_v34.v34_pedido)
							RETURNING r_v34.*
			IF r_v34.v34_pedido IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
						    'Pedido no existe',
        					    'exclamation')
				NEXT FIELD v34_pedido
			END IF
		END IF
END INPUT
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET num_rows = vm_num_rows
-- EXISTE EL PEDIDO?
LET vm_num_rows = 1
SELECT *, ROWID INTO rm_v34.*, vm_rows[vm_num_rows] 
	FROM veht034 
	WHERE v34_compania  = vg_codcia 
	  AND v34_localidad = vg_codloc
	  AND v34_pedido    = rm_v34.v34_pedido 
-- NO: REGRESO TODO A SU ESTADO ANTERIOR
IF STATUS = NOTFOUND THEN
	LET vm_num_rows = num_rows 
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF
-- SI: ACTUALIZO ROW_CURRENT Y CONTINUO
CASE (rm_v34.v34_estado)
	WHEN 'P' 
		CALL fgl_winmessage(vg_producto, 
				    'Este pedido ya ha sido procesado',
				    'exclamation')
		LET vm_num_rows = num_rows
		CLEAR FORM
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		RETURN
	WHEN 'L'
		CALL fgl_winmessage(vg_producto, 
				    'Este pedido esta en proceso de ' ||
				    'liquidación',
				    'exclamation')
		LET vm_num_rows = num_rows 
		CLEAR FORM
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		RETURN
END CASE

LET vm_row_current = vm_num_rows
CALL lee_muestra_registro(vm_rows[vm_row_current])

BEGIN WORK

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
	DECLARE q_cab CURSOR FOR 
		SELECT * FROM veht034 
			WHERE ROWID = vm_rows[vm_row_current] 
	FOR UPDATE
	WHENEVER ERROR STOP
	OPEN q_cab
	FETCH q_cab INTO rm_v34.*
	IF STATUS < 0 THEN
		CALL fgl_winquestion(vg_producto, 
				     'Registro bloqueado por ' ||
			      	     'otro usuario, desea ' ||
                                     'intentarlo nuevamente', 'No',
         			     'Yes|No', 'question', 1)
						RETURNING resp
		IF resp = 'No' THEN
			CALL fl_mensaje_abandonar_proceso()
				 RETURNING resp
			IF resp = 'Yes' THEN
				LET intentar = 0
				LET done = 0
			END IF	
		END IF
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
IF intentar = 0 AND done = 0 THEN
	ROLLBACK WORK
	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN 
END IF

LET num_elm = ingresa_detalles()
IF INT_FLAG THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET intentar = 1
LET done = 0
WHILE (intentar)
	DECLARE q_det CURSOR FOR 
		SELECT * FROM veht035 
			WHERE v35_compania  = vg_codcia
		  	  AND v35_localidad = vg_codloc
		  	  AND v35_pedido    = rm_v34.v34_pedido
			ORDER BY v35_secuencia
	OPEN  q_det
	FETCH q_det
	IF STATUS < 0 THEN
		CALL fgl_winquestion(vg_producto, 
				     'Registro bloqueado por ' ||
			      	     'otro usuario, desea ' ||
                                     'intentarlo nuevamente', 'No',
         			     'Yes|No', 'question', 1)
						RETURNING resp
		IF resp = 'No' THEN
			CALL fl_mensaje_abandonar_proceso()
				 RETURNING resp
			IF resp = 'Yes' THEN
				LET intentar = 0
				LET done = 0
			END IF	
		END IF
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
	CLOSE q_det
END WHILE
IF intentar = 0 AND done = 0 THEN
	ROLLBACK WORK
	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN 
END IF

LET i = 1
FOREACH q_det INTO rm_v35.*
	IF rm_v35.v35_estado <> 'A' AND rm_v35.v35_estado <> 'R' THEN
		LET i = i + 1
		CONTINUE FOREACH
	END IF	
	IF rm_pedido[i].check = 'S' AND rm_v35.v35_estado = 'A' THEN
--	HAY QUE INSERTAR EL REGISTRO EN LA TABLA VEHT022
		SELECT MAX(v22_codigo_veh) INTO r_v22.v22_codigo_veh
			FROM veht022 
			WHERE v22_compania  = vg_codcia
	  	  	  AND v22_localidad = vg_codloc
		IF r_v22.v22_codigo_veh IS NULL THEN
			LET r_v22.v22_codigo_veh = 1
		ELSE
			LET r_v22.v22_codigo_veh = r_v22.v22_codigo_veh + 1
		END IF

		LET r_v22.v22_chasis      = rm_v22[i].v22_chasis
		LET r_v22.v22_estado      = rm_v22[i].v22_estado
		LET r_v22.v22_bodega      = rm_v22[i].v22_bodega
		LET r_v22.v22_modelo      = rm_v22[i].v22_modelo
		LET r_v22.v22_comentarios = rm_v22[i].v22_comentarios
		LET r_v22.v22_motor       = rm_v22[i].v22_motor
		LET r_v22.v22_ano	  = rm_v22[i].v22_ano
		LET r_v22.v22_cod_color   = rm_v22[i].v22_cod_color
		LET r_v22.v22_precio      = 0
		LET r_v22.v22_moneda_prec = rm_v22[i].v22_moneda_prec

		LET r_v22.v22_pedido      = rm_v34.v34_pedido

		INSERT INTO veht022 VALUES(r_v22.*)
--	CONTINUAMOS CON EL PROCESO DE ACTUALIZACION
		LET rm_v35.v35_estado      = 'R'                  
		LET rm_v35.v35_bodega_alm  = r_v22.v22_bodega                  
		LET rm_v35.v35_codigo_veh  = r_v22.v22_codigo_veh
		LET rm_v35.v35_fecha_lleg  = rm_v34.v34_fec_llegada
		LET rm_v35.v35_precio_unit = rm_pedido[i].precio_unit
		UPDATE veht035 SET * = rm_v35.* 
			WHERE v35_compania  = vg_codcia
		  	  AND v35_localidad = vg_codloc
		  	  AND v35_pedido    = rm_v34.v34_pedido
			  AND v35_secuencia = rm_pedido[i].secuencia 
		LET i = i + 1
		CONTINUE FOREACH
	END IF
	IF rm_v35.v35_estado = 'R' THEN
		LET intentar = 1
		LET done     = 0
		WHILE (intentar)
		WHENEVER ERROR CONTINUE
		DECLARE q_upd CURSOR FOR
			SELECT * FROM veht022 
				WHERE v22_compania   = vg_codcia
				  AND v22_localidad  = vg_codloc
				  AND v22_codigo_veh = rm_v35.v35_codigo_veh
			FOR UPDATE
		WHENEVER ERROR STOP
		IF STATUS < 0 THEN
			CALL fgl_winquestion(vg_producto, 
				     	     'Registro bloqueado por ' ||
			      	             'otro usuario, desea ' ||
                                             'intentarlo nuevamente', 'No',
         			             'Yes|No', 'question', 1)
							RETURNING resp
			IF resp = 'No' THEN
				CALL fl_mensaje_abandonar_proceso()
				 	RETURNING resp
				IF resp = 'Yes' THEN
					ROLLBACK WORK
					LET intentar = 0
					LET done = 0
				END IF	
			END IF
		ELSE
			LET intentar = 0
			LET done = 1
		END IF
		IF NOT intentar AND NOT done THEN
			EXIT WHILE
		END IF
		END WHILE
		IF done THEN
			IF rm_pedido[i].check = 'S' THEN
				OPEN q_upd
				FETCH q_upd INTO r_v22.*
				LET r_v22.v22_chasis = rm_v22[i].v22_chasis
				LET r_v22.v22_estado = rm_v22[i].v22_estado
				LET r_v22.v22_bodega = rm_v22[i].v22_bodega
				LET r_v22.v22_modelo = rm_v22[i].v22_modelo
				LET r_v22.v22_comentarios = 
					rm_v22[i].v22_comentarios
				LET r_v22.v22_motor = rm_v22[i].v22_motor
				LET r_v22.v22_ano = rm_v22[i].v22_ano
				LET r_v22.v22_cod_color = 
					rm_v22[i].v22_cod_color
				LET r_v22.v22_precio = 0 
				LET r_v22.v22_moneda_prec = 
					rm_v22[i].v22_moneda_prec
				UPDATE veht022 SET * = r_v22.* 
					WHERE CURRENT OF q_upd 
				LET rm_v35.v35_precio_unit = 
					rm_pedido[i].precio_unit
				LET rm_v35.v35_fecha_lleg = 
					rm_v34.v34_fec_llegada
				UPDATE veht035 SET * = rm_v35.*
					WHERE v35_compania  = vg_codcia
		  			  AND v35_localidad = vg_codloc
		  			  AND v35_pedido    = rm_v34.v34_pedido
					  AND v35_secuencia = rm_pedido[i].secuencia 
				CLOSE q_upd
			END IF 
			IF rm_pedido[i].check = 'N' THEN 
				CALL fgl_winquestion(vg_producto,
					'La secuencia ' ||
				        rm_pedido[i].secuencia CLIPPED ||
					' estaba marcada como recibida, ' ||
 					'al desmarcarla perderá toda la ' ||
					'información sobre la serie ' ||
					rm_pedido[i].serie CLIPPED || '.' ||
					' Confirma que desea eliminar el ' ||
					'registro?',
					'No', 'Yes|No|Cancel', 'question', 1)
						RETURNING resp
				IF resp = 'Yes' THEN		    
					OPEN q_upd
					FETCH q_upd INTO r_v22.*
					LET rm_v35.v35_estado = 'A'
					INITIALIZE rm_v35.v35_codigo_veh TO NULL
					UPDATE veht035 set * = rm_v35.*
						WHERE v35_compania  = vg_codcia
		  				  AND v35_localidad = vg_codloc
		  				  AND v35_pedido    = rm_v34.v34_pedido
						  AND v35_secuencia = rm_pedido[i].secuencia 
					DELETE FROM veht022 
						WHERE CURRENT OF q_upd
					CLOSE q_upd
				END IF
			END IF
		END IF
	END IF
	LET i = i + 1
END FOREACH
LET i = i - 1

SELECT SUM(v35_precio_unit) INTO rm_v34.v34_tot_valor
	FROM veht035
	WHERE v35_compania  = vg_codcia
	  AND v35_localidad = vg_codloc
	  AND v35_pedido    = rm_v34.v34_pedido
SELECT COUNT(v35_estado) INTO contador
	FROM veht035
	WHERE v35_compania  = vg_codcia
	  AND v35_localidad = vg_codloc
	  AND v35_pedido    = rm_v34.v34_pedido
	  AND v35_estado IN ('R', 'P')
IF contador > 0 THEN
	LET rm_v34.v34_estado = 'R'
ELSE
	LET rm_v34.v34_estado = 'A'
END IF
UPDATE veht034 SET * = rm_v34.* WHERE CURRENT OF q_cab
CLOSE q_cab

COMMIT WORK

CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION ingresa_detalles()

DEFINE i 		SMALLINT
DEFINE j 		SMALLINT
DEFINE salir		SMALLINT
DEFINE resp		CHAR(6)
DEFINE mensaje		CHAR(40)
DEFINE check		CHAR(1)	

LET i = lee_detalle()

IF i = 0 THEN
	CALL fgl_winmessage(vg_producto, 
			    'Pedido no tiene detalle para mostrar.',
			    'exclamation')
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

OPTIONS
	INSERT KEY F20,
	DELETE KEY F21

LET salir = 0
WHILE NOT salir
LET j = 1
LET INT_FLAG = 0	
CALL set_count(i)
INPUT ARRAY rm_pedido WITHOUT DEFAULTS FROM ra_pedido.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
               		RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT 
		END IF
	BEFORE INPUT
		CALL dialog.keysetlabel('INSERT', '')
		CALL dialog.keysetlabel('DELETE', '')
	BEFORE INSERT
		IF i = arr_count() THEN
			LET i = arr_count() - 1
		ELSE
			LET i = arr_count()
		END IF
		EXIT INPUT
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	BEFORE FIELD check
		LET check = rm_pedido[i].check
	AFTER FIELD check 
		IF rm_pedido[i].check = 'S' THEN
			IF rm_pedido[i].v35_estado = 'A' THEN
				LET INT_FLAG = 0
				CALL lee_datos(i)
				IF INT_FLAG THEN
					LET INT_FLAG = 0
					LET rm_pedido[i].check = 'N'
					DISPLAY rm_pedido[i].check 
						TO ra_pedido[j].check
					CONTINUE INPUT
				END IF
				LET rm_pedido[i].serie = rm_v22[i].v22_chasis
				LET rm_pedido[i].precio_unit = 
					rm_v22[i].v22_precio
				DISPLAY rm_pedido[i].serie 
					TO ra_pedido[j].serie
				DISPLAY rm_pedido[i].precio_unit
					TO ra_pedido[j].v35_precio_unit
			END IF
			IF rm_pedido[i].v35_estado = 'R' AND 
			   check = 'N' THEN
				LET INT_FLAG = 0
				CALL lee_datos(i)
				IF INT_FLAG THEN
					LET INT_FLAG = 0
					CONTINUE INPUT
				END IF
				LET rm_pedido[i].serie = rm_v22[i].v22_chasis
				LET rm_pedido[i].precio_unit = 
					rm_v22[i].v22_precio
				DISPLAY rm_pedido[i].serie 
					TO ra_pedido[j].serie
				DISPLAY rm_pedido[i].precio_unit
					TO ra_pedido[j].v35_precio_unit
			END IF
		ELSE
			IF rm_pedido[i].v35_estado = 'A' OR 
			   rm_pedido[i].v35_estado = 'R' THEN
--				INITIALIZE rm_pedido[i].serie TO NULL
--				CLEAR ra_pedido[j].serie
				CONTINUE INPUT
			END IF
			CASE rm_pedido[i].v35_estado
				WHEN 'L' LET mensaje = 'El vehículo ya ha ' ||
						       'sido liquidado.'	
				WHEN 'P' LET mensaje = 'El vehículo ya ha ' ||
						       'sido procesado.'	
			END CASE
			CALL fgl_winmessage(vg_producto, mensaje, 'exclamation')
			LET rm_pedido[i].check = 'S'
			DISPLAY rm_pedido[i].check TO ra_pedido[j].check
		END IF
	AFTER INPUT
		LET i = arr_count()
		LET vm_ind_arr = arr_count()
		LET salir = 1
END INPUT
IF INT_FLAG THEN
	RETURN 0
END IF

END WHILE

RETURN i

END FUNCTION



FUNCTION lee_datos(i)

DEFINE i 		SMALLINT

DEFINE resp		CHAR(6)

DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_v02		RECORD LIKE veht002.*
DEFINE r_v05		RECORD LIKE veht005.*
DEFINE r_v20		RECORD LIKE veht020.*

DEFINE r_v22 RECORD
	v22_chasis	LIKE veht022.v22_chasis,
	v22_estado	LIKE veht022.v22_estado,
	v22_bodega	LIKE veht022.v22_bodega,
	v22_modelo	LIKE veht022.v22_modelo,
	v22_comentarios	LIKE veht022.v22_comentarios,
	v22_motor	LIKE veht022.v22_motor,
	v22_ano		LIKE veht022.v22_ano,
	v22_cod_color	LIKE veht022.v22_cod_color,
	v22_moneda_prec	LIKE veht022.v22_moneda_prec,
	v22_precio	LIKE veht022.v22_precio
END RECORD


OPEN WINDOW w_211_2 AT 8,4 WITH 13 ROWS, 74 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, MESSAGE LINE LAST) 
OPEN FORM f_211_2 FROM '../forms/vehf211_2'
DISPLAY FORM f_211_2


LET r_v22.* = rm_v22[i].*

CALL muestra_etiquetas_w2(i)

LET INT_FLAG = 0
INPUT BY NAME r_v22.* WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(v22_bodega) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia) 
				RETURNING r_v02.v02_bodega, r_v02.v02_nombre 
			IF r_v02.v02_bodega IS NOT NULL THEN
				LET r_v22.v22_bodega = r_v02.v02_bodega
				DISPLAY BY NAME r_v22.v22_bodega
				DISPLAY r_v02.v02_nombre TO n_bodega
			END IF
		END IF
		IF INFIELD(v22_modelo) THEN
			CALL fl_ayuda_modelos_veh(vg_codcia)
				RETURNING r_v20.v20_modelo, r_v20.v20_linea
			IF r_v20.v20_modelo IS NOT NULL THEN
				CALL fl_lee_modelo_veh(vg_codcia,
						      r_v20.v20_modelo)
							RETURNING r_v20.*
				LET r_v22.v22_modelo = r_v20.v20_modelo
				DISPLAY BY NAME r_v22.v22_modelo
				DISPLAY r_v20.v20_modelo_ext TO n_modelo
			END IF
		END IF
		IF INFIELD(v22_moneda_prec) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET r_v22.v22_moneda_prec = r_mon.g13_moneda
				DISPLAY BY NAME r_v22.v22_moneda_prec
				DISPLAY r_mon.g13_nombre TO n_moneda_prec
			END IF	
		END IF
		IF INFIELD(v22_cod_color) THEN
			CALL fl_ayuda_colores(vg_codcia) 
				RETURNING r_v05.v05_cod_color, 
					  r_v05.v05_descri_base
			IF r_v05.v05_cod_color IS NOT NULL THEN
				LET r_v22.v22_cod_color = r_v05.v05_cod_color
				DISPLAY BY NAME r_v22.v22_cod_color
				DISPLAY r_v05.v05_descri_base TO n_color
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD v22_moneda_prec
		IF r_v22.v22_moneda_prec IS NULL THEN
			CLEAR n_moneda_prec
		ELSE
			CALL fl_lee_moneda(r_v22.v22_moneda_prec) 
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                             		            'Moneda no existe',        
                                        	    'exclamation')
				CLEAR n_moneda_prec
				NEXT FIELD v22_moneda_prec
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Moneda está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					CLEAR n_moneda_prec
					NEXT FIELD v22_moneda_prec
				ELSE
					DISPLAY r_mon.g13_nombre 								TO n_moneda_prec
				END IF
			END IF 
		END IF
	AFTER  FIELD v22_modelo
		IF r_v22.v22_modelo IS NULL THEN
			CLEAR n_modelo
		ELSE
			CALL fl_lee_modelo_veh(vg_codcia, r_v22.v22_modelo)
				RETURNING r_v20.*
			IF r_v20.v20_modelo IS NULL THEN	
				CLEAR n_modelo
				CALL fgl_winmessage(vg_producto,
					            'Modelo no existe',
						    'exclamation')
				NEXT FIELD v22_modelo
			ELSE
				DISPLAY r_v20.v20_modelo_ext TO n_modelo
			END IF 
		END IF
	AFTER  FIELD v22_cod_color
		IF r_v22.v22_cod_color IS NULL THEN
			CLEAR n_color
		ELSE
			CALL fl_lee_color_veh(vg_codcia, r_v22.v22_cod_color)
				RETURNING r_v05.*
			IF r_v05.v05_cod_color IS NULL THEN	
				CLEAR n_color
				CALL fgl_winmessage(vg_producto,
					            'No existe color',
						    'exclamation')
				NEXT FIELD v22_cod_color
			ELSE
				DISPLAY r_v05.v05_descri_base TO n_color
			END IF 
		END IF
	AFTER  FIELD v22_bodega
		IF r_v22.v22_bodega IS NULL THEN
			CLEAR n_bodega
		ELSE
			CALL fl_lee_bodega_veh(vg_codcia, r_v22.v22_bodega)
				RETURNING r_v02.*
			IF r_v02.v02_bodega IS NULL THEN	
				CLEAR n_bodega
				CALL fgl_winmessage(vg_producto,
					            'Bodega no existe para' ||
                                                    ' esta compañía',
						    'exclamation')
				NEXT FIELD v22_bodega
			ELSE
				IF r_v02.v02_estado = 'B' THEN
					CLEAR n_bodega
					CALL fgl_winmessage(vg_producto,
						           'Bodega está' ||
                                                           ' bloqueada',
						    	   'exclamation')
					NEXT FIELD v22_bodega
				ELSE
					DISPLAY r_v02.v02_nombre TO n_bodega
				END IF
			END IF 
		END IF
	AFTER FIELD v22_precio
		IF r_v22.v22_precio IS NULL OR r_v22.v22_precio <= 0 THEN
			CALL fgl_winmessage(vg_producto,
				'Debe ingresar un valor mayor a cero.',
				'exclamation')
			NEXT FIELD v22_precio
		END IF
		LET r_v22.v22_precio =
			fl_retorna_precision_valor(r_v22.v22_moneda_prec,
						   r_v22.v22_precio)
		DISPLAY BY NAME r_v22.v22_precio
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w_211_2
	RETURN
END IF

LET rm_v22[i].*      = r_v22.*

CLOSE WINDOW w_211_2 

END FUNCTION



FUNCTION muestra_etiquetas_w2(i)

DEFINE i 			SMALLINT

DEFINE nom_estado		CHAR(9)

DEFINE r_v02			RECORD LIKE veht002.*
DEFINE r_v20			RECORD LIKE veht020.*
DEFINE r_v05			RECORD LIKE veht005.*
DEFINE r_g13			RECORD LIKE gent013.*
DEFINE r_g21			RECORD LIKE gent021.*

CALL fl_lee_bodega_veh(vg_codcia, rm_v22[i].v22_bodega) RETURNING r_v02.*
DISPLAY r_v02.v02_nombre TO n_bodega

CALL fl_lee_modelo_veh(vg_codcia, rm_v22[i].v22_modelo) RETURNING r_v20.*
DISPLAY r_v20.v20_modelo_ext TO n_modelo

CALL fl_lee_color_veh(vg_codcia, rm_v22[i].v22_cod_color) RETURNING r_v05.*
DISPLAY r_v05.v05_descri_base TO n_color

CALL fl_lee_moneda(rm_v22[i].v22_moneda_prec) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda_prec

CASE rm_v22[i].v22_estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'B' LET nom_estado = 'BLOQUEADO'
	WHEN 'F' LET nom_estado = 'FACTURADO'
	WHEN 'P' LET nom_estado = 'EN PEDIDO'
	WHEN 'R' LET nom_estado = 'RESERVADO'
	WHEN 'M' LET nom_estado = 'MANUAL'
END CASE
DISPLAY nom_estado   TO n_estado

END FUNCTION



FUNCTION lee_detalle()

DEFINE i		SMALLINT
DEFINE query		CHAR(300)
DEFINE codigo_veh       LIKE veht022.v22_codigo_veh

DEFINE r_v22		RECORD LIKE veht022.*

INITIALIZE r_v22.* TO NULL

LET query = 'SELECT v35_estado, v35_secuencia, v35_modelo, v35_cod_color, ',
	    '       v35_codigo_veh, v35_precio_unit',
	    '	FROM veht035 ',
	    '	WHERE v35_compania = ', vg_codcia,
	    '     AND v35_localidad = ', vg_codloc,
	    '     AND v35_pedido = "', rm_v34.v34_pedido, '"',
	    ' 	ORDER BY v35_secuencia '

PREPARE ing2 FROM query
DECLARE q_ing2 CURSOR FOR ing2

INITIALIZE codigo_veh TO NULL
LET i = 1
FOREACH q_ing2 INTO rm_pedido[i].v35_estado, rm_pedido[i].secuencia, 
		    rm_pedido[i].modelo, rm_pedido[i].color,
		    codigo_veh, rm_pedido[i].precio_unit
	IF codigo_veh IS NOT NULL THEN
		CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, codigo_veh)
			RETURNING r_v22.*
		LET rm_pedido[i].serie        = r_v22.v22_chasis	
		LET rm_v22[i].v22_chasis      = r_v22.v22_chasis
		LET rm_v22[i].v22_estado      = r_v22.v22_estado
		LET rm_v22[i].v22_bodega      = r_v22.v22_bodega
		LET rm_v22[i].v22_modelo      = r_v22.v22_modelo
		LET rm_v22[i].v22_comentarios = r_v22.v22_comentarios
		LET rm_v22[i].v22_motor	      = r_v22.v22_motor
		LET rm_v22[i].v22_ano	      = r_v22.v22_ano	
		LET rm_v22[i].v22_cod_color   = r_v22.v22_cod_color
		LET rm_v22[i].v22_precio      = r_v22.v22_precio
		LET rm_v22[i].v22_moneda_prec = r_v22.v22_moneda_prec
	ELSE
		INITIALIZE rm_pedido[i].serie TO NULL	
		INITIALIZE rm_v22[i].*        TO NULL
		LET rm_v22[i].v22_estado      = 'P'             
		LET rm_v22[i].v22_modelo      = rm_pedido[i].modelo
		LET rm_v22[i].v22_cod_color   = rm_pedido[i].color
		LET rm_v22[i].v22_moneda_prec = rg_gen.g00_moneda_base
		LET rm_v22[i].v22_precio      = rm_pedido[i].precio_unit
	END IF
	LET rm_pedido[i].check = 'N'
	IF rm_pedido[i].v35_estado <> 'A' THEN
		LET rm_pedido[i].check = 'S'
	END IF
	LET i = i + 1
	INITIALIZE codigo_veh TO NULL
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1 

RETURN i

END FUNCTION



FUNCTION muestra_detalle()

DEFINE i 		SMALLINT
DEFINE query 		CHAR(250)

LET i = lee_detalle()
IF i = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	RETURN
END IF

LET vm_ind_arr  = i
LET vm_curr_arr = 0
LET vm_ini_arr  = 0

CALL control_mostrar_sig_det()

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE proveedor		LIKE cxpt001.p01_codprov,
       nom_proveedor		LIKE cxpt001.p01_nomprov

DEFINE r_mon			RECORD LIKE gent013.*
DEFINE r_p01			RECORD LIKE cxpt001.*
DEFINE r_b10			RECORD LIKE ctbt010.*
DEFINE r_v34			RECORD LIKE veht034.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON v34_pedido, v34_estado, v34_proveedor, v34_moneda, v34_aux_cont,  
	   v34_referencia, v34.v34_tipo, v34_fec_envio, v34_fec_llegada, 
	   v34_usuario 
	ON KEY(F2)
		IF INFIELD(v34_pedido) THEN
			CALL fl_ayuda_pedidos_vehiculos(vg_codcia, vg_codloc,
							'R')
				RETURNING r_v34.v34_pedido, r_v34.v34_estado,
					  r_v34.v34_fec_envio, 
					  r_v34.v34_fec_llegada
			IF r_v34.v34_pedido IS NOT NULL THEN
				LET rm_v34.v34_pedido      = r_v34.v34_pedido
				DISPLAY BY NAME rm_v34.v34_pedido
			END IF		
		END IF
		IF INFIELD(v34_proveedor) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,
						            vg_codloc) 
				RETURNING proveedor, nom_proveedor
			IF proveedor IS NOT NULL THEN
				LET rm_v34.v34_proveedor = proveedor
				DISPLAY BY NAME rm_v34.v34_proveedor
				DISPLAY nom_proveedor TO n_proveedor
			END IF
		END IF
		IF INFIELD(v34_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_v34.v34_moneda = r_mon.g13_moneda
				DISPLAY r_mon.g13_moneda TO v34_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF	
		END IF
		IF INFIELD(v34_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel_cta) 
				RETURNING r_b10.b10_cuenta, 
        				  r_b10.b10_descripcion 
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_v34.v34_aux_cont = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta TO v34_aux_cont
				DISPLAY r_b10.b10_descripcion TO n_cuenta
			END IF	
		END IF
		LET INT_FLAG = 0	
	BEFORE CONSTRUCT
		CALL setea_botones_f1()
	AFTER FIELD v34_aux_cont
		LET rm_v34.v34_aux_cont = GET_FLDBUF(v34_aux_cont)
		IF rm_v34.v34_aux_cont IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, rm_v34.v34_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NOT NULL THEN
				IF r_b10.b10_estado = 'B' THEN
					CLEAR n_cuenta
				END IF
				IF r_b10.b10_nivel <> vm_nivel_cta THEN
					CLEAR n_cuenta
				END IF
				DISPLAY r_b10.b10_descripcion TO n_cuenta
			ELSE
					CLEAR n_cuenta
			END IF
		ELSE
			CLEAR n_cuenta
		END IF
	AFTER FIELD v34_proveedor
		LET rm_v34.v34_proveedor = GET_FLDBUF(v34_proveedor)
		IF rm_v34.v34_proveedor IS NULL THEN
			CLEAR n_proveedor
		ELSE
			CALL fl_lee_proveedor(rm_v34.v34_proveedor) 
				RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN	
				CLEAR n_proveedor
			ELSE
				IF r_p01.p01_estado = 'B' THEN
					CLEAR n_proveedor
				ELSE
					DISPLAY r_p01.p01_nomprov TO n_proveedor
				END IF
			END IF 
		END IF
	AFTER FIELD v34_moneda
		LET rm_v34.v34_moneda = GET_FLDBUF(v34_moneda)
		IF rm_v34.v34_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_v34.v34_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR n_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CLEAR n_moneda
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda
				END IF
			END IF 
		END IF
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM veht034 ',  
            '	WHERE v34_compania  = ', vg_codcia, 
	    '	  AND v34_localidad = ', vg_codloc,
	    '     AND ', expr_sql,	 	
	    '     AND v34_estado IN ("R", "L")',
	    ' 	ORDER BY 1, 2, 3' 

PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v34.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows = 0
	LET vm_row_current = 0
	CALL muestra_contadores()
	CLEAR FORM
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_v34.* FROM veht034 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_v34.v34_pedido,
		rm_v34.v34_estado,
		rm_v34.v34_tipo,       
		rm_v34.v34_referencia,
		rm_v34.v34_proveedor,
		rm_v34.v34_fec_envio,
		rm_v34.v34_fec_llegada,
		rm_v34.v34_moneda,
		rm_v34.v34_aux_cont,
		rm_v34.v34_usuario,
		rm_v34.v34_fecing
CALL muestra_contadores()
CALL muestra_etiquetas()
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_contadores()

--DISPLAY '   ' TO n_estado
--CLEAR n_estado

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 68 

END FUNCTION



FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_etiquetas()

DEFINE nom_estado		CHAR(9)
DEFINE r_p01			RECORD LIKE cxpt001.*
DEFINE r_g13			RECORD LIKE gent013.*
DEFINE r_b10			RECORD LIKE ctbt010.*

CASE rm_v34.v34_estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'R' LET nom_estado = 'RECIBIDO'
	WHEN 'L' LET nom_estado = 'LIQUIDADO'
	WHEN 'P' LET nom_estado = 'PROCESADO'
END CASE
DISPLAY nom_estado   TO n_estado

CALL fl_lee_proveedor(rm_v34.v34_proveedor) RETURNING r_p01.*
DISPLAY r_p01.p01_nomprov TO n_proveedor

CALL fl_lee_moneda(rm_v34.v34_moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda

CALL fl_lee_cuenta(vg_codcia, rm_v34.v34_aux_cont) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO n_cuenta

END FUNCTION



FUNCTION control_mostrar_sig_det()

DEFINE i 		SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE filas_mostrar	SMALLINT

IF (vm_ind_arr - vm_curr_arr) <= 0 THEN
	RETURN
END IF

LET filas_pant = fgl_scr_size('ra_pedido')
LET filas_mostrar = vm_ind_arr - vm_curr_arr

FOR i = 1 TO filas_pant 
	CLEAR ra_pedido[i].*
END FOR

IF filas_mostrar < filas_pant THEN
	LET filas_pant = filas_mostrar
END IF

LET vm_ini_arr = vm_curr_arr + 1

FOR i = 1 TO filas_pant   
	LET vm_curr_arr = vm_curr_arr + 1
	DISPLAY rm_pedido[vm_curr_arr].* TO ra_pedido[i].*
END FOR

END FUNCTION



FUNCTION control_mostrar_ant_det()

DEFINE i 		SMALLINT
DEFINE filas_pant	SMALLINT

IF vm_ini_arr <= 1 THEN
	RETURN
END IF

LET filas_pant = fgl_scr_size('ra_pedido')
LET vm_ini_arr = vm_ini_arr - filas_pant
FOR i = 1 TO filas_pant 
	CLEAR ra_pedido[i].*
END FOR

LET vm_curr_arr = vm_ini_arr - 1
FOR i = 1 TO filas_pant   
	LET vm_curr_arr = vm_curr_arr + 1
	DISPLAY rm_pedido[vm_curr_arr].* TO ra_pedido[i].*
END FOR

END FUNCTION



FUNCTION setea_botones_f1()

DISPLAY 'Sec'  TO bt_sec
DISPLAY 'Modelo' TO bt_modelo
DISPLAY 'Color' TO bt_color
DISPLAY 'Serie' TO bt_serie
DISPLAY 'Precio Fab.' TO bt_fob
DISPLAY 'E' TO bt_estado

END FUNCTION



FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM veht034
	WHERE v34_compania  = vg_codcia
	  AND v34_localidad = vg_codloc
	  AND v34_pedido    = vm_num_ped
	  AND v34_estado IN ('R', 'L')
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 
		'No se ha recibido ningún vehículo en este pedido.', 
		'exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
                            vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
