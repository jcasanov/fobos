------------------------------------------------------------------------------
-- Titulo           : vehp107.4gl - Mantenimiento de Modelos    
-- Elaboracion      : 15-sep-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp107 base modulo compania [modelo]
--		Si (modelo IS NOT NULL) el programa se esta ejcutando en modo 
-- 			de solo consulta
--		Si (modelo IS NULL) el programa se esta ejecutando en forma 
--			independiente
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_nuevoprog	VARCHAR(400)
DEFINE vm_modelo	LIKE veht020.v20_modelo

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA vm_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS

DEFINE vm_rows2 ARRAY[1000] OF INTEGER 	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current2	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows2	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows2     SMALLINT        -- MAXIMO DE FILAS LEIDAS
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_v20		RECORD LIKE veht020.*
DEFINE rm_v21		RECORD LIKE veht021.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 THEN	-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'vehp107'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc

INITIALIZE vm_modelo TO NULL
IF num_args() = 4 THEN
	LET vm_modelo  = arg_val(4)
END IF

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_v20 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_v20 FROM '../forms/vehf107_1'
DISPLAY FORM f_v20

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v20.* TO NULL
CALL muestra_contadores()

DISPLAY 'disponible.bmp' TO f1 ATTRIBUTE(BLINK,REVERSE)

IF vm_modelo IS NOT NULL THEN
	CALL execute_query()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Componentes'
		HIDE OPTION 'Existencias'
		HIDE OPTION 'Pedidos'
		IF vm_modelo IS NOT NULL THEN   -- Se ejecuta en modo de solo
			HIDE OPTION 'Ingresar'  -- consulta
			HIDE OPTION 'Consultar'
			IF vm_num_rows2 > 0 THEN
				SHOW OPTION 'Componentes'
			END IF
			IF rm_v20.v20_stock > 0 THEN
				SHOW OPTION 'Existencias'
			END IF
			IF rm_v20.v20_pedidos > 0 THEN
				SHOW OPTION 'Pedidos'
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_row_current >= 1 THEN
			IF vm_row_current > 1 THEN
				SHOW OPTION 'Retroceder'
			END IF
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Componentes'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
	COMMAND KEY('O') 'Componentes'          'Mantenimiento de componentes.'
		CALL partes_modelo()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		HIDE OPTION 'Componentes'
		HIDE OPTION 'Existencias'
		HIDE OPTION 'Pedidos'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
                IF vm_num_rows2 > 0 THEN
                	SHOW OPTION 'Componentes'
                END IF
		IF rm_v20.v20_stock > 0 THEN
			SHOW OPTION 'Existencias'
		END IF
		IF rm_v20.v20_pedidos > 0 THEN
			SHOW OPTION 'Pedidos'
		END IF
	COMMAND KEY('E') 'Existencias' 		'Ver detalle de existencias.'
		CALL ver_existencias()
	COMMAND KEY('P') 'Pedidos' 		'Ver detalle de este pedido.'
		CALL ver_pedidos()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		HIDE OPTION 'Componentes'
		HIDE OPTION 'Existencias'
		HIDE OPTION 'Pedidos'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
                IF vm_num_rows2 > 0 THEN
                	SHOW OPTION 'Componentes'
                END IF
		IF rm_v20.v20_stock > 0 THEN
			SHOW OPTION 'Existencias'
		END IF
		IF rm_v20.v20_pedidos > 0 THEN
			SHOW OPTION 'Pedidos'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		HIDE OPTION 'Componentes'
		HIDE OPTION 'Existencias'
		HIDE OPTION 'Pedidos'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
                IF vm_num_rows2 > 0 THEN
                	SHOW OPTION 'Componentes'
                END IF
		IF rm_v20.v20_stock > 0 THEN
			SHOW OPTION 'Existencias'
		END IF
		IF rm_v20.v20_pedidos > 0 THEN
			SHOW OPTION 'Pedidos'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU


END FUNCTION



FUNCTION control_ingreso()

DEFINE done		SMALLINT

DEFINE r_t04		RECORD LIKE talt004.*

CLEAR FORM
DISPLAY 'disponible.bmp' TO f1 ATTRIBUTE(BLINK,REVERSE)
INITIALIZE rm_v20.* TO NULL

LET rm_v20.v20_fecing   = CURRENT
LET rm_v20.v20_usuario  = vg_usuario
LET rm_v20.v20_compania = vg_codcia
LET rm_v20.v20_stock    = 0
LET rm_v20.v20_pedidos  = 0
LET rm_v20.v20_origen   = 'N' 

LET rm_v20.v20_moneda   = rg_gen.g00_moneda_base
LET rm_v20.v20_mon_prov = rg_gen.g00_moneda_base

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		DISPLAY 'disponible.bmp' TO f1 ATTRIBUTE(BLINK,REVERSE)
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

BEGIN WORK

INSERT INTO veht020 VALUES (rm_v20.*)

LET vm_num_rows = vm_num_rows + 1
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
LET done = actualiza_modelo_taller()
IF NOT done THEN
	LET vm_num_rows = vm_num_rows - 1
	LET vm_row_current = vm_num_rows
	ROLLBACK WORK
	RETURN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		DISPLAY 'disponible.bmp' TO f1 ATTRIBUTE(BLINK,REVERSE)
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
END IF

COMMIT WORK

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

DEFINE done 		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd CURSOR FOR 
	SELECT * FROM veht020 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_v20.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

CALL lee_datos('M')

IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

UPDATE veht020 SET * = rm_v20.* WHERE CURRENT OF q_upd

LET done = actualiza_modelo_taller()
IF NOT done THEN
	ROLLBACK WORK
	RETURN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		DISPLAY 'disponible.bmp' TO f1 ATTRIBUTE(BLINK,REVERSE)
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
END IF

COMMIT WORK
CLOSE q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION actualiza_modelo_taller()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE resp		CHAR(6)

DEFINE r_t04		RECORD LIKE talt004.*

-- OjO
LET done = 1

{
CALL fl_lee_tipo_vehiculo(vg_codcia, rm_v20.v20_modelo) RETURNING r_t04.*
IF r_t04.t04_compania IS NULL THEN
	INITIALIZE r_t04.* TO NULL
	LET r_t04.t04_compania    = vg_codcia
	LET r_t04.t04_modelo      = rm_v20.v20_modelo
	LET r_t04.t04_linea       = rm_v20.v20_linea
	LET r_t04.t04_dificultad  = 1
	LET r_t04.t04_cod_mod_veh = 'S'
	LET r_t04.t04_usuario     = rm_v20.v20_usuario
	LET r_t04.t04_fecing      = rm_v20.v20_fecing
	INSERT INTO talt004 VALUES (r_t04.*)
	LET done = 1
ELSE
	LET intentar = 1
	LET done = 0
	WHILE (intentar)
		WHENEVER ERROR CONTINUE
			DECLARE q_t04 CURSOR FOR
				SELECT * FROM talt004
					WHERE t04_compania  = vg_codcia
					  AND t04_modelo    = rm_v20.v20_modelo
				FOR UPDATE
		WHENEVER ERROR STOP
		IF STATUS < 0 THEN
			LET intentar = mensaje_intentar()
		ELSE
			LET intentar = 0
			LET done = 1
		END IF
	END WHILE

	IF NOT intentar AND NOT done THEN
		RETURN done
	END IF

	OPEN q_t04
	FETCH q_t04 INTO r_t04.*
		LET r_t04.t04_linea       = rm_v20.v20_linea
	
		UPDATE talt004 SET * = r_t04.* WHERE CURRENT OF q_t04 
	CLOSE q_t04
END IF
}

RETURN done

END FUNCTION



FUNCTION mensaje_intentar()

DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
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
	END IF	
END IF

RETURN intentar

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE g13_moneda 	LIKE gent013.g13_moneda
DEFINE nombre		LIKE gent013.g13_nombre
DEFINE decimales 	LIKE gent013.g13_decimales

DEFINE tipo_veh		LIKE veht004.v04_tipo_veh
DEFINE nom_tipo_veh	LIKE veht004.v04_nombre

DEFINE linea		LIKE veht003.v03_linea
DEFINE nom_linea	LIKE veht003.v03_nombre
DEFINE est_linea	LIKE veht003.v03_estado

DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_v03		RECORD LIKE veht003.*		
DEFINE r_v04		RECORD LIKE veht004.*
DEFINE r_v20 		RECORD LIKE veht020.*

INITIALIZE r_mon.* TO NULL 
INITIALIZE r_v03.* TO NULL 
INITIALIZE r_v04.* TO NULL 
INITIALIZE r_v20.* TO NULL 

CALL muestra_etiquetas()

LET INT_FLAG = 0
INPUT BY NAME rm_v20.v20_modelo, rm_v20.v20_modelo_ext, rm_v20.v20_tipo_veh, 
              rm_v20.v20_linea, rm_v20.v20_observacion, rm_v20.v20_origen,
              rm_v20.v20_moneda, rm_v20.v20_precio, rm_v20.v20_mon_prov, 
	      rm_v20.v20_prec_exfab, rm_v20.v20_cilindraje, rm_v20.v20_stock,
              rm_v20.v20_pedidos, rm_v20.v20_usuario, rm_v20.v20_fecing 
              WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_v20.v20_modelo, rm_v20.v20_modelo_ext, 
                                     rm_v20.v20_tipo_veh, rm_v20.v20_linea, 
                                     rm_v20.v20_observacion, rm_v20.v20_origen,
                                     rm_v20.v20_precio, rm_v20.v20_moneda, 
                                     rm_v20.v20_prec_exfab, rm_v20.v20_mon_prov,
                                     rm_v20.v20_cilindraje 
				    ) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(v20_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_v20.v20_moneda = g13_moneda
				DISPLAY g13_moneda TO v20_moneda
				DISPLAY nombre TO n_moneda
			END IF	
		END IF
		IF INFIELD(v20_mon_prov) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_v20.v20_mon_prov = g13_moneda
				DISPLAY g13_moneda TO v20_mon_prov
				DISPLAY nombre TO n_mon_prov
			END IF	
		END IF
		IF INFIELD(v20_tipo_veh) THEN
			CALL fl_ayuda_tipos_veh(vg_codcia) 
				RETURNING tipo_veh, nom_tipo_veh
			IF tipo_veh IS NOT NULL THEN
				LET rm_v20.v20_tipo_veh = tipo_veh
				DISPLAY BY NAME rm_v20.v20_tipo_veh
				DISPLAY nom_tipo_veh TO n_tipo_veh
			END IF
		END IF
		IF INFIELD(v20_linea) THEN
			CALL fl_ayuda_lineas_veh(vg_codcia)
				RETURNING linea, nom_linea
			IF linea IS NOT NULL THEN
				LET rm_v20.v20_linea = linea
				DISPLAY BY NAME rm_v20.v20_linea
				DISPLAY nom_linea TO n_linea
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE FIELD v20_modelo
		IF flag = 'M' THEN
			NEXT FIELD v20_modelo_ext
		END IF
	AFTER FIELD v20_modelo  
		IF rm_v20.v20_modelo IS NOT NULL THEN
			CALL fl_lee_modelo_veh(vg_codcia, 
                                               rm_v20.v20_modelo) 
						   RETURNING r_v20.*
			IF r_v20.v20_modelo IS NOT NULL THEN	
				CALL fgl_winmessage(vg_producto,
						    'Modelo ya existe',
						    'exclamation')
				NEXT FIELD v20_modelo
			END IF 
		END IF
	AFTER  FIELD v20_linea
		IF rm_v20.v20_linea IS NULL THEN
			CLEAR n_linea
		ELSE
			CALL fl_lee_linea_veh(vg_codcia, rm_v20.v20_linea)
				RETURNING r_v03.*
			IF r_v03.v03_linea IS NOT NULL THEN 
				IF r_v03.v03_estado = 'B' THEN
					CALL fgl_winmessage(vg_producto,
							    'Linea está ' ||
                  					    'bloqueada',
							    'exclamation')
					CLEAR n_linea
					NEXT FIELD v20_linea 
				ELSE
					DISPLAY r_v03.v03_nombre TO n_linea
				END IF
			ELSE
				CALL fgl_winmessage(vg_producto,
						    'Linea no ' ||
                  				    'existe',
						    'exclamation')
				CLEAR n_linea
				NEXT FIELD v20_linea 
			END IF
		END IF
	AFTER FIELD v20_tipo_veh
		IF rm_v20.v20_tipo_veh IS NULL THEN
			CLEAR n_tipo_veh
		ELSE
			CALL fl_lee_tipo_vehiculo_veh(vg_codcia, 
                                                      rm_v20.v20_tipo_veh) 
							   RETURNING r_v04.*
			IF r_v04.v04_tipo_veh IS NULL THEN	
				CALL fgl_winmessage(vg_producto,
						    'Tipo de vehículo no ' ||
                                                    'existe',
						    'exclamation')
				CLEAR  n_tipo_veh
				NEXT FIELD v20_tipo_veh
			ELSE
				DISPLAY r_v04.v04_nombre TO n_tipo_veh
			END IF 
		END IF
	AFTER FIELD v20_moneda
		IF rm_v20.v20_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_v20.v20_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                             		            'Moneda no existe',        
                                        	    'exclamation')
				CLEAR n_moneda
				NEXT FIELD v20_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Moneda está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					CLEAR n_moneda
					NEXT FIELD v20_moneda
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda
				END IF
			END IF 
		END IF
	AFTER FIELD v20_mon_prov
		IF rm_v20.v20_mon_prov IS NULL THEN
			CLEAR n_mon_prov
		ELSE
			CALL fl_lee_moneda(rm_v20.v20_mon_prov) 
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                             		            'Moneda no existe',        
                                        	    'exclamation')
				CLEAR n_mon_prov
				NEXT FIELD v20_mon_prov
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Moneda está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					CLEAR n_mon_prov
					NEXT FIELD v20_mon_prov
				ELSE
					DISPLAY r_mon.g13_nombre TO n_mon_prov
				END IF
			END IF 
		END IF
	AFTER FIELD v20_precio
		LET rm_v20.v20_precio = 
			fl_retorna_precision_valor(rm_v20.v20_moneda,
				                    rm_v20.v20_precio)
		DISPLAY BY NAME rm_v20.v20_precio
	AFTER FIELD v20_prec_exfab
		LET rm_v20.v20_prec_exfab = 
			fl_retorna_precision_valor(rm_v20.v20_mon_prov,
				                    rm_v20.v20_prec_exfab)
		DISPLAY BY NAME rm_v20.v20_prec_exfab
	AFTER INPUT
		LET rm_v20.v20_precio = 
			fl_retorna_precision_valor(rm_v20.v20_moneda,
				                    rm_v20.v20_precio)
		DISPLAY BY NAME rm_v20.v20_precio
		LET rm_v20.v20_prec_exfab = 
			fl_retorna_precision_valor(rm_v20.v20_mon_prov,
				                    rm_v20.v20_prec_exfab)
		DISPLAY BY NAME rm_v20.v20_prec_exfab
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE modelo 		LIKE veht020.v20_modelo

DEFINE g13_moneda 	LIKE gent013.g13_moneda
DEFINE nombre		LIKE gent013.g13_nombre
DEFINE decimales 	LIKE gent013.g13_decimales

DEFINE tipo_veh		LIKE veht004.v04_tipo_veh
DEFINE nom_tipo_veh	LIKE veht004.v04_nombre

DEFINE linea		LIKE veht003.v03_linea
DEFINE nom_linea	LIKE veht003.v03_nombre
DEFINE est_linea	LIKE veht003.v03_estado

DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_v03		RECORD LIKE veht003.*		
DEFINE r_v04		RECORD LIKE veht004.*
DEFINE r_v20 		RECORD LIKE veht020.*

INITIALIZE r_mon.* TO NULL 
INITIALIZE r_v03.* TO NULL 
INITIALIZE r_v04.* TO NULL 
INITIALIZE r_v20.* TO NULL 

CLEAR FORM
DISPLAY 'disponible.bmp' TO f1 ATTRIBUTE(BLINK,REVERSE)

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON v20_modelo, v20_modelo_ext, v20_tipo_veh, v20_linea, v20_observacion,
	   v20_origen, v20_moneda, v20_precio, v20_mon_prov, v20_prec_exfab,
           v20_cilindraje, v20_stock, v20_pedidos, v20_usuario
	ON KEY(F2)
		IF INFIELD(v20_modelo) THEN
			CALL fl_ayuda_modelos_veh(vg_codcia)
				RETURNING modelo, linea
			IF modelo IS NOT NULL THEN
				LET rm_v20.v20_modelo = modelo
				LET rm_v20.v20_linea  = linea
				DISPLAY BY NAME rm_v20.v20_modelo,
						rm_v20.v20_linea	
			END IF
		END IF
		IF INFIELD(v20_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_v20.v20_moneda = g13_moneda
				DISPLAY g13_moneda TO v20_moneda
				DISPLAY nombre TO n_moneda
			END IF	
		END IF
		IF INFIELD(v20_mon_prov) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_v20.v20_mon_prov = g13_moneda
				DISPLAY g13_moneda TO v20_mon_prov
				DISPLAY nombre TO n_mon_prov
			END IF	
		END IF
		IF INFIELD(v20_tipo_veh) THEN
			CALL fl_ayuda_tipos_veh(vg_codcia) 
				RETURNING tipo_veh, nom_tipo_veh
			IF tipo_veh IS NOT NULL THEN
				LET rm_v20.v20_tipo_veh = tipo_veh
				DISPLAY BY NAME rm_v20.v20_tipo_veh
				DISPLAY nom_tipo_veh TO n_tipo_veh
			END IF
		END IF
		IF INFIELD(v20_linea) THEN
			CALL fl_ayuda_lineas_veh(vg_codcia)
				RETURNING linea, nom_linea
			IF linea IS NOT NULL THEN
				LET rm_v20.v20_linea = linea
				DISPLAY BY NAME rm_v20.v20_linea
				DISPLAY nom_linea TO n_linea
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER  FIELD v20_modelo
		LET rm_v20.v20_modelo = GET_FLDBUF(v20_modelo)
		IF rm_v20.v20_modelo IS NOT NULL THEN
			CALL fl_lee_modelo_veh(vg_codcia, 
					       rm_v20.v20_modelo)
							RETURNING r_v20.*
			IF r_v20.v20_modelo IS NOT NULL THEN
				DISPLAY r_v20.v20_linea TO v20_linea
			ELSE
				DISPLAY  '' TO v20_linea
			END IF
		END IF
	AFTER  FIELD v20_linea
		LET rm_v20.v20_linea = GET_FLDBUF(v20_linea)
		IF rm_v20.v20_linea IS NULL THEN
			CLEAR n_linea
		ELSE
			CALL fl_lee_linea_veh(vg_codcia, rm_v20.v20_linea)
				RETURNING r_v03.*
			IF r_v03.v03_linea IS NOT NULL THEN 
				IF r_v03.v03_estado = 'B' THEN
					CLEAR n_linea
				ELSE
					DISPLAY r_v03.v03_nombre TO n_linea
				END IF
			ELSE
				CLEAR n_linea
			END IF
		END IF
	AFTER FIELD v20_tipo_veh
		LET rm_v20.v20_tipo_veh = GET_FLDBUF(v20_tipo_veh)
		IF rm_v20.v20_tipo_veh IS NULL THEN
			CLEAR n_tipo_veh
		ELSE
			CALL fl_lee_tipo_vehiculo_veh(vg_codcia, 
                                                      rm_v20.v20_tipo_veh) 
							    RETURNING r_v04.*
			IF r_v04.v04_tipo_veh IS NULL THEN	
				CLEAR  n_tipo_veh
			ELSE
				DISPLAY r_v04.v04_nombre TO n_tipo_veh
			END IF 
		END IF
	AFTER FIELD v20_moneda
		LET rm_v20.v20_moneda = GET_FLDBUF(v20_moneda)
		IF rm_v20.v20_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_v20.v20_moneda) RETURNING r_mon.*
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
	AFTER FIELD v20_mon_prov
		LET rm_v20.v20_mon_prov = GET_FLDBUF(v20_mon_prov)
		IF rm_v20.v20_mon_prov IS NULL THEN
			CLEAR n_mon_prov
		ELSE
			CALL fl_lee_moneda(rm_v20.v20_mon_prov) 
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR n_mon_prov
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CLEAR n_mon_prov
				ELSE
					DISPLAY r_mon.g13_nombre TO n_mon_prov
				END IF
			END IF 
		END IF
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		DISPLAY 'disponible.bmp' TO f1 ATTRIBUTE(BLINK,REVERSE)
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM veht020 WHERE ', expr_sql, 
            ' AND v20_compania = ', vg_codcia, ' ORDER BY 2' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v20.*, vm_rows[vm_num_rows]
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
	DISPLAY 'disponible.bmp' TO f1 ATTRIBUTE(BLINK,REVERSE)
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER
DEFINE r_v42		RECORD LIKE veht042.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_v20.* FROM veht020 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_v20.v20_modelo,
                rm_v20.v20_modelo_ext,
		rm_v20.v20_tipo_veh,
		rm_v20.v20_linea,
		rm_v20.v20_observacion,
		rm_v20.v20_origen,
		rm_v20.v20_moneda,
		rm_v20.v20_precio,
		rm_v20.v20_mon_prov,
		rm_v20.v20_prec_exfab,
		rm_v20.v20_cilindraje,
		rm_v20.v20_stock,
		rm_v20.v20_pedidos,
		rm_v20.v20_usuario,
		rm_v20.v20_fecing
		
SELECT COUNT(*) INTO vm_num_rows2 
	FROM veht021
        WHERE v21_compania = rm_v20.v20_compania
          AND v21_modelo   = rm_v20.v20_modelo
          
CALL muestra_etiquetas()
CALL muestra_contadores()

-- PARA AÑADIR UNA IMAGEN
SELECT * INTO r_v42.* FROM veht042 
	WHERE v42_compania = vg_codcia
	  AND v42_modelo   = rm_v20.v20_modelo
	  AND v42_linea    = rm_v20.v20_linea

DISPLAY r_v42.v42_bmp TO f1 ATTRIBUTE(BLINK,REVERSE)
--&&
{
IF r_v42.v42_bmp <> ' ' THEN
     	DISPLAY r_v42.v42_bmp TO f1 ATTRIBUTE(BLINK,REVERSE)
ELSE
	CLEAR f1
END IF
OPEN WINDOW lwin AT 02,50 WITH 6 ROWS, 28 COLUMNS
     ATTRIBUTE(BLINK,BOLD,FORM LINE 1)
     OPEN FORM modelo FROM "../forms/modelo"
     DISPLAY FORM modelo ATTRIBUTE(BLINK,BOLD)
     DISPLAY r_v42.v42_bmp TO f1 ATTRIBUTE(BLINK,REVERSE)
     CURRENT WINDOW IS w_v20
}

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 67 

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

DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_v03		RECORD LIKE veht003.*
DEFINE r_v04		RECORD LIKE veht004.*


CALL fl_lee_moneda(rm_v20.v20_moneda)   RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda

CALL fl_lee_moneda(rm_v20.v20_mon_prov) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_mon_prov

CALL fl_lee_linea_veh(rm_v20.v20_compania, rm_v20.v20_linea) RETURNING r_v03.*
DISPLAY r_v03.v03_nombre TO n_linea

CALL fl_lee_tipo_vehiculo_veh(rm_v20.v20_compania, rm_v20.v20_tipo_veh) 
	RETURNING r_v04.*
DISPLAY r_v04.v04_nombre TO n_tipo_veh


END FUNCTION



FUNCTION partes_modelo()

DEFINE query 		CHAR(250)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_v21 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_v21 FROM '../forms/vehf107_2'
DISPLAY FORM f_v21

LET rm_v21.v21_compania = vg_codcia
LET rm_v21.v21_modelo   = rm_v20.v20_modelo
DISPLAY BY NAME rm_v21.v21_modelo
DISPLAY rm_v20.v20_modelo_ext TO n_modelo

LET query = 'SELECT *, ROWID FROM veht021 ',  
            ' WHERE v21_compania = ', rm_v20.v20_compania,  
            '   AND v21_modelo   = "', rm_v20.v20_modelo CLIPPED, 
            '" ORDER BY 3' 
PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
LET vm_num_rows2 = 1
FOREACH q_cons2 INTO rm_v21.*, vm_rows2[vm_num_rows2]
	LET vm_num_rows2 = vm_num_rows2 + 1
        IF vm_num_rows2 > 1000 THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows2 = vm_num_rows2 - 1
IF vm_num_rows2 = 0 THEN   
	CALL fgl_winmessage(vg_producto, 'No hay componentes que mostrar',
                            'exclamation')
	LET vm_num_rows2 = 0
	LET vm_row_current2 = 0
	CALL muestra_contadores_comp()
	CALL clear_form_comp()
ELSE
	LET vm_row_current2 = 1
	CALL lee_muestra_registro_COMP(vm_rows2[vm_row_current2])
END IF

LET vm_max_rows2 = 1000

MENU 'OPCIONES'
	BEFORE MENU
		IF vm_num_rows2 > 0 THEN
			IF vm_num_rows2 = 1 THEN
				HIDE OPTION 'Avanzar'
			ELSE
				SHOW OPTION 'Avanzar'
			END IF
			SHOW OPTION 'Modificar'
		ELSE
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Avanzar'
		END IF
		HIDE OPTION 'Retroceder'
		IF vm_modelo IS NOT NULL THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Modificar'
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows2 = vm_max_rows2 THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso_comp()
		END IF
		IF vm_num_rows2 = 1 THEN
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current2 > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current2 = vm_num_rows2 THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion_comp()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro_comp()
		IF vm_row_current2 = vm_num_rows2 THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro_comp()
		IF vm_row_current2 = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU
	

END FUNCTION



FUNCTION control_ingreso_comp()

CALL clear_form_comp()

INITIALIZE rm_v21.* TO NULL

LET rm_v21.v21_fecing   = CURRENT
LET rm_v21.v21_usuario  = vg_usuario
LET rm_v21.v21_compania = vg_codcia
LET rm_v21.v21_modelo   = rm_v20.v20_modelo
LET rm_v21.v21_tipo     = 'I'

SELECT MAX(v21_secuencia) INTO rm_v21.v21_secuencia
	FROM veht021
	WHERE v21_compania = vg_codcia
	  AND v21_modelo   = rm_v20.v20_modelo
IF rm_v21.v21_secuencia IS NULL THEN
	LET rm_v21.v21_secuencia = 1
ELSE
	LET rm_v21.v21_secuencia = rm_v21.v21_secuencia + 1
END IF
CALL lee_datos_comp('I')
IF INT_FLAG THEN
	IF vm_num_rows2 = 0 THEN
		CALL clear_form_comp()
	ELSE	
		CALL lee_muestra_registro_comp(vm_rows2[vm_row_current2])
	END IF
	RETURN
END IF


INSERT INTO veht021 VALUES (rm_v21.*)
 
DISPLAY BY NAME rm_v21.v21_secuencia

LET vm_num_rows2 = vm_num_rows2 + 1
LET vm_row_current2 = vm_num_rows2
LET vm_rows2[vm_num_rows2] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
CALL muestra_contadores_comp()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion_comp()

IF vm_num_rows2 = 0 THEN   
	CALL fgl_winmessage(vg_producto, 'No hay componentes que modificar',
                            'exclamation')
	RETURN
END IF

CALL lee_muestra_registro_comp(vm_rows2[vm_row_current2])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd2 CURSOR FOR 
	SELECT * FROM veht021 WHERE ROWID = vm_rows2[vm_row_current2]
	FOR UPDATE
OPEN q_upd2
FETCH q_upd2 INTO rm_v21.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

CALL lee_datos_comp('M')

IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro_comp(vm_rows2[vm_row_current2])
	CLOSE q_upd2
	RETURN
END IF 

UPDATE veht021 SET * = rm_v21.* WHERE CURRENT OF q_upd2
COMMIT WORK
CLOSE q_upd2
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos_comp(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE g13_moneda 	LIKE gent013.g13_moneda
DEFINE nombre		LIKE gent013.g13_nombre
DEFINE decimales 	LIKE gent013.g13_decimales

DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_p01		RECORD LIKE cxpt001.*

DEFINE proveedor	LIKE cxpt001.p01_codprov,
       nom_proveedor    LIKE cxpt001.p01_nomprov

INITIALIZE r_mon.* TO NULL 

LET INT_FLAG = 0
INPUT BY NAME rm_v21.v21_secuencia, rm_v21.v21_descripcion, rm_v21.v21_tipo, 
              rm_v21.v21_cod_prov, rm_v21.v21_val_costo, rm_v21.v21_mon_costo, 
              rm_v21.v21_precio, rm_v21.v21_usuario, rm_v21.v21_fecing
              WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_v21.v21_descripcion, rm_v21.v21_tipo, 
                                     rm_v21.v21_cod_prov, rm_v21.v21_val_costo,
                                     rm_v21.v21_mon_costo, rm_v21.v21_precio
				    ) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(v21_mon_costo) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_v21.v21_mon_costo = g13_moneda
				DISPLAY g13_moneda TO v21_mon_costo
				DISPLAY nombre TO n_moneda
			END IF	
		END IF
		IF INFIELD(v21_cod_prov) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia, 
							    vg_codloc) 
				RETURNING proveedor, nom_proveedor
			IF proveedor IS NOT NULL THEN
				LET rm_v21.v21_cod_prov = proveedor
				DISPLAY BY NAME rm_v21.v21_cod_prov
				DISPLAY nom_proveedor TO n_proveedor
			END IF
		END IF
	AFTER FIELD v21_mon_costo
		IF rm_v21.v21_mon_costo IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_v21.v21_mon_costo) 
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                             		            'Moneda no existe',        
                                        	    'exclamation')
				CLEAR n_moneda
				NEXT FIELD v21_mon_costo
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Moneda está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					CLEAR n_moneda
					NEXT FIELD v21_mon_costo
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda
				END IF
			END IF 
		END IF
	AFTER FIELD v21_cod_prov
		IF rm_v21.v21_cod_prov IS NULL THEN
			CLEAR n_proveedor
		ELSE
			CALL fl_lee_proveedor(rm_v21.v21_cod_prov) 
				RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                             		            'Proveedor no existe',      
                                        	    'exclamation')
				CLEAR n_proveedor
				NEXT FIELD v21_cod_prov
			ELSE
				IF r_p01.p01_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Proveedor está ' ||
                               	                            'bloqueado',        
                                       	                    'exclamation')
					CLEAR n_proveedor
					NEXT FIELD v21_cod_prov
				ELSE
					DISPLAY r_p01.p01_nomprov TO n_proveedor
				END IF
			END IF 
		END IF
	AFTER FIELD v21_val_costo
		LET rm_v21.v21_val_costo = 
			fl_retorna_precision_valor(rm_v21.v21_mon_costo,
						    rm_v21.v21_val_costo) 
		DISPLAY BY NAME rm_v21.v21_val_costo
	AFTER FIELD v21_precio
		LET rm_v21.v21_precio = 
			fl_retorna_precision_valor(rm_v21.v21_mon_costo,
						    rm_v21.v21_precio) 
		DISPLAY BY NAME rm_v21.v21_precio   
	AFTER INPUT 
		LET rm_v21.v21_val_costo = 
			fl_retorna_precision_valor(rm_v21.v21_mon_costo,
						    rm_v21.v21_val_costo) 
		DISPLAY BY NAME rm_v21.v21_val_costo
		LET rm_v21.v21_precio = 
			fl_retorna_precision_valor(rm_v21.v21_mon_costo,
						    rm_v21.v21_precio) 
		DISPLAY BY NAME rm_v21.v21_precio   
END INPUT

END FUNCTION



FUNCTION muestra_contadores_comp()

DISPLAY "" AT 1,1
DISPLAY vm_row_current2, " de ", vm_num_rows2 AT 1, 70 

END FUNCTION



FUNCTION siguiente_registro_comp()

IF vm_num_rows2 = 0 THEN
	RETURN
END IF

IF vm_row_current2 < vm_num_rows2 THEN
	LET vm_row_current2 = vm_row_current2 + 1
END IF
CALL lee_muestra_registro_comp(vm_rows2[vm_row_current2])

END FUNCTION



FUNCTION anterior_registro_comp()

IF vm_num_rows2 = 0 THEN
	RETURN
END IF

IF vm_row_current2 > 1 THEN
	LET vm_row_current2 = vm_row_current2 - 1
END IF
CALL lee_muestra_registro_comp(vm_rows2[vm_row_current2])

END FUNCTION



FUNCTION lee_muestra_registro_comp(row)
DEFINE row 		INTEGER

IF vm_num_rows2 <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_v21.* FROM veht021 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_v21.v21_secuencia,
		rm_v21.v21_descripcion,
		rm_v21.v21_tipo,
		rm_v21.v21_cod_prov,
		rm_v21.v21_mon_costo,
		rm_v21.v21_val_costo,
		rm_v21.v21_precio,
		rm_v21.v21_usuario,
		rm_v21.v21_fecing

CALL muestra_etiquetas_comp()
CALL muestra_contadores_comp()

END FUNCTION



FUNCTION clear_form_comp()

CLEAR FORM

LET rm_v21.v21_compania = vg_codcia
LET rm_v21.v21_modelo   = rm_v20.v20_modelo
DISPLAY BY NAME rm_v21.v21_modelo
DISPLAY rm_v20.v20_modelo_ext TO n_modelo

END FUNCTION



FUNCTION muestra_etiquetas_comp()

DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_p01		RECORD LIKE cxpt001.*

CALL fl_lee_moneda(rm_v21.v21_mon_costo) RETURNING r_g13.*
CALL fl_lee_proveedor(rm_v21.v21_cod_prov) RETURNING r_p01.*

DISPLAY r_g13.g13_nombre  TO n_moneda
DISPLAY r_p01.p01_nomprov TO n_proveedor

END FUNCTION



FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM veht020
	WHERE v20_compania  = vg_codcia
	  AND v20_modelo    = vm_modelo
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe modelo.', 
		'exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION ver_existencias()

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS',
	vg_separador, 'fuentes', vg_separador, ' ; fglrun vehp306 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	'"', rm_v20.v20_modelo, '"'
RUN vm_nuevoprog

END FUNCTION



FUNCTION ver_pedidos()

LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'VEHICULOS',
	vg_separador, 'fuentes', vg_separador, ' ; fglrun vehp305 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	'"', rm_v20.v20_modelo, '"', ' ', 'P'
RUN vm_nuevoprog

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
