------------------------------------------------------------------------------
-- Titulo           : vehp204.4gl - Ingreso de Transferencias
-- Elaboracion      : 19-sep-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp201 base modulo compania localidad [numtran]
--              Si (numtran <> 0) el programa se esta ejcutando en modo de
--                      solo consulta
--              Si (numtran = 0) el programa se esta ejecutando en forma
--                      independiente
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_numtran	LIKE veht030.v30_num_tran                      

DEFINE vm_transaccion	VARCHAR(12)

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS A LEER

--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_cfg			RECORD LIKE veht000.*

DEFINE rm_v30			RECORD LIKE veht030.*
DEFINE rm_v31		 	RECORD LIKE veht031.*

DEFINE rm_transf ARRAY[250] OF RECORD
	codigo_veh		LIKE veht022.v22_codigo_veh,
	serie			LIKE veht022.v22_chasis,
	modelo			LIKE veht022.v22_modelo,
	color			LIKE veht005.v05_cod_color
END RECORD
DEFINE vm_ind_arr	SMALLINT
DEFINE vm_filas_pant	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'vehp204'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

LET vm_numtran = 0
IF num_args() = 5 THEN
        LET vm_numtran  = arg_val(5)
END IF

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_veh(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
LET vm_max_rows = 1000

OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_204 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_204 FROM '../forms/vehf204_1'
DISPLAY FORM f_204


LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v30.* TO NULL
INITIALIZE rm_v31.* TO NULL
CALL muestra_contadores()

SELECT g21_cod_tran INTO vm_transaccion
	FROM gent021
	WHERE g21_nombre LIKE '%TRANSFERENCIA%'

SELECT * INTO rm_cfg.* FROM veht000 WHERE v00_compania = vg_codcia
IF rm_cfg.v00_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe registro de configuración para esta compañía',
		'exclamation')
	EXIT PROGRAM
END IF

LET vm_max_rows = 1000
CALL setea_botones_f1()

IF vm_numtran <> 0 THEN
	CALL execute_query()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
                IF vm_numtran <> 0 THEN         -- Se ejecuta en modo de solo
                        HIDE OPTION 'Ingresar'  -- consulta
                        HIDE OPTION 'Consultar'
                        SHOW OPTION 'Detalle'
                END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Detalle'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
			SHOW OPTION 'Detalle'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		CALL setea_botones_f1()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Detalle'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Detalle'
			END IF
		ELSE
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		CALL setea_botones_f1()
	COMMAND KEY('D') 'Detalle'		'Ver detalle de transferencia'
		CALL control_mostrar_det()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
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



FUNCTION control_ingreso()

DEFINE row_curr		SMALLINT
DEFINE i 		SMALLINT
DEFINE num_elm 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT

DEFINE r_v22		RECORD LIKE veht022.* 

CLEAR FORM
INITIALIZE rm_v30.* TO NULL
INITIALIZE rm_v31.* TO NULL

-- INITIAL VALUES FOR rm_v30 FIELDS
LET rm_v30.v30_fecing     = CURRENT
LET rm_v30.v30_usuario    = vg_usuario
LET rm_v30.v30_compania   = vg_codcia
LET rm_v30.v30_localidad  = vg_codloc
LET rm_v30.v30_cod_tran   = vm_transaccion

-- INITIAL VALUES FOR rm_v31 FIELDS
LET rm_v31.v31_compania   = vg_codcia
LET rm_v31.v31_localidad  = vg_codloc
LET rm_v31.v31_cod_tran   = vm_transaccion

-- THESE FIELDS ARE NOT NULL BUT THERE ARE NOTHING TO PUT IN THEM --
LET rm_v30.v30_cont_cred  = 'C'
LET rm_v30.v30_nomcli     = ' '
LET rm_v30.v30_dircli     = ' '
LET rm_v30.v30_cedruc     = ' '
LET rm_v30.v30_descuento  = 0.0
LET rm_v30.v30_porc_impto = 0.0
LET rm_v30.v30_moneda     = 'DO'
LET rm_v30.v30_paridad    = 0.0
LET rm_v30.v30_precision  = 0
LET rm_v30.v30_tot_costo  = 0.0
LET rm_v30.v30_tot_bruto  = 0.0
LET rm_v30.v30_tot_dscto  = 0.0
LET rm_v30.v30_tot_neto   = 0.0
LET rm_v30.v30_flete      = 0.0

LET rm_v31.v31_descuento  = 0.0
LET rm_v31.v31_val_descto = 0.0
LET rm_v31.v31_precio     = 0.0
LET rm_v31.v31_costo      = 0.0
LET rm_v31.v31_fob        = 0.0
LET rm_v31.v31_costant_mb = 0.0
LET rm_v31.v31_costant_ma = 0.0
LET rm_v31.v31_costnue_mb = 0.0
LET rm_v31.v31_costnue_ma = 0.0
--------------------------------------------------------------------

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET INT_FLAG = 0
LET num_elm = ingresa_detalles() 
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
	
BEGIN WORK

LET rm_v30.v30_tot_neto = rm_v30.v30_tot_costo

LET rm_v30.v30_num_tran = nextValInSequence()
IF rm_v30.v30_num_tran = -1 THEN
	ROLLBACK WORK
	CLEAR FORM
	RETURN
END IF

INSERT INTO veht030 VALUES (rm_v30.*)
DISPLAY BY NAME rm_v30.v30_num_tran

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET row_curr = vm_row_current
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
LET rm_v31.v31_num_tran = rm_v30.v30_num_tran
FOR i = 1 TO num_elm
	LET rm_v31.v31_codigo_veh = rm_transf[i].codigo_veh
	CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, 
				     rm_v31.v31_codigo_veh)
					RETURNING r_v22.*
	LET rm_v31.v31_nuevo = r_v22.v22_nuevo
	LET rm_v31.v31_moneda_cost = r_v22.v22_moneda_ing
	LET rm_v31.v31_costo = r_v22.v22_costo_ing + r_v22.v22_cargo_ing +
                               r_v22.v22_costo_adi
	INSERT INTO veht031 VALUES(rm_v31.*)
-- REPITE HASTA QUE PUEDE ACTUALIZAR LA TABLA DE SERIES DE VEHICULOS
-- O HASTA QUE EL USUARIO DECIDA NO VOLVERLO A INTENTAR
	LET intentar = 1
	LET done = 0
	WHILE (intentar)
		WHENEVER ERROR CONTINUE
			UPDATE veht022 
				SET v22_bodega = rm_v30.v30_bodega_dest
				WHERE v22_compania   = vg_codcia
				  AND v22_localidad  = vg_codloc
			  	  AND v22_codigo_veh = rm_v31.v31_codigo_veh
			  	  AND v22_chasis     = rm_transf[i].serie
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
					LET vm_num_rows = vm_num_rows - 1
					LET vm_row_current = row_curr
					LET intentar = 0
					LET done = 0
				END IF	
			END IF
		ELSE
			LET intentar = 0
			LET done = 1
		END IF
	END WHILE
END FOR 
IF intentar = 0 AND done = 0 THEN
	CLEAR FORM       
	RETURN
END IF

COMMIT WORK

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE vendedor 	LIKE veht001.v01_vendedor,
       nom_vendedor	LIKE veht001.v01_nombres

DEFINE bodega		LIKE veht002.v02_bodega,
       nom_bodega	LIKE veht002.v02_nombre

DEFINE r_v01		RECORD LIKE veht001.*
DEFINE r_v02		RECORD LIKE veht002.*

LET INT_FLAG = 0
INPUT BY NAME rm_v30.v30_cod_tran,    rm_v30.v30_vendedor, 
	      rm_v30.v30_bodega_ori,  rm_v30.v30_bodega_dest, 
	      rm_v30.v30_referencia,  rm_v30.v30_usuario, 
	      rm_v30.v30_fecing WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(v30_vendedor, v30_bodega_ori,
                                     v30_bodega_dest, v30_referencia
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
		IF INFIELD(v30_vendedor) THEN
			CALL fl_ayuda_vendedores_veh(vg_codcia) 
				RETURNING vendedor, nom_vendedor
			IF vendedor IS NOT NULL THEN
				LET rm_v30.v30_vendedor = vendedor
				DISPLAY BY NAME rm_v30.v30_vendedor
				DISPLAY nom_vendedor TO n_vendedor
			END IF
		END IF
		IF INFIELD(v30_bodega_ori) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia) 
				RETURNING bodega, nom_bodega 
			IF bodega IS NOT NULL THEN
				LET rm_v30.v30_bodega_ori = bodega
				DISPLAY bodega TO v30_bodega_ori
				DISPLAY nom_bodega TO n_bodega_ori
			END IF
		END IF
		IF INFIELD(v30_bodega_dest) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia) 
				RETURNING bodega, nom_bodega 
			IF bodega IS NOT NULL THEN
				LET rm_v30.v30_bodega_dest = bodega
				DISPLAY bodega TO v30_bodega_dest
				DISPLAY nom_bodega TO n_bodega_dest
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL setea_botones_f1()
	AFTER FIELD v30_vendedor
		IF rm_v30.v30_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_veh(vg_codcia, rm_v30.v30_vendedor)
				RETURNING r_v01.*
			IF r_v01.v01_vendedor IS NOT NULL THEN
				IF r_v01.v01_estado <> 'B' THEN
					DISPLAY r_v01.v01_nombres TO n_vendedor
				ELSE
					CALL fgl_winmessage(vg_producto,
						            'Vendedor está ' ||
                                                            'bloqueado',
							    'exclamation')
					CLEAR n_vendedor
					NEXT FIELD v30_vendedor
				END IF
			ELSE
				CALL fgl_winmessage(vg_producto,
					            'Vendedor no existe',
						    'exclamation')
				CLEAR n_vendedor
				NEXT FIELD v30_vendedor
			END IF
		ELSE
			CLEAR n_vendedor
		END IF		 
	AFTER FIELD v30_bodega_ori
		IF rm_v30.v30_bodega_ori IS NOT NULL THEN
			CALL fl_lee_bodega_veh(vg_codcia, rm_v30.v30_bodega_ori)
				RETURNING r_v02.*
			IF r_v02.v02_bodega IS NOT NULL THEN
				IF r_v02.v02_estado <> 'B' THEN
					DISPLAY r_v02.v02_nombre TO n_bodega_ori
				ELSE
					CALL fgl_winmessage(vg_producto,
						            'Bodega está ' ||
                                                            'bloqueada',
							    'exclamation')
					CLEAR n_bodega_ori  
					NEXT FIELD v30_bodega_ori
				END IF
			ELSE
				CALL fgl_winmessage(vg_producto,
					            'Bodega no existe',
						    'exclamation')
				CLEAR n_bodega_ori
				NEXT FIELD v30_bodega_ori
			END IF
		ELSE
			CLEAR n_bodega_ori
		END IF		 
	AFTER FIELD v30_bodega_dest
		IF rm_v30.v30_bodega_dest IS NOT NULL THEN
			IF rm_v30.v30_bodega_ori = rm_v30.v30_bodega_dest THEN
				CALL fgl_winmessage(vg_producto,
						    'La bodega de destino ' ||
						    'debe ser distinta a la ' ||
 						    ' bodega de origen',
						    'exclamation')
				CLEAR n_bodega_dest
				NEXT FIELD v30_bodega_dest
			END IF
			CALL fl_lee_bodega_veh(vg_codcia, 
                                               rm_v30.v30_bodega_dest)
							RETURNING r_v02.*
			IF r_v02.v02_bodega IS NOT NULL THEN
				IF r_v02.v02_estado <> 'B' THEN
					DISPLAY r_v02.v02_nombre 
						TO n_bodega_dest  
				ELSE
					CALL fgl_winmessage(vg_producto,
						            'Bodega está ' ||
                                                            'bloqueada',
							    'exclamation')
					CLEAR n_bodega_dest  
					NEXT FIELD v30_bodega_dest
				END IF
			ELSE
				CALL fgl_winmessage(vg_producto,
					            'Bodega no existe',
						    'exclamation')
				CLEAR n_bodega_dest
				NEXT FIELD v30_bodega_dest
			END IF
		ELSE
			CLEAR n_bodega_dest
		END IF		 
END INPUT

END FUNCTION



FUNCTION ingresa_detalles()

DEFINE i 		SMALLINT
DEFINE j 		SMALLINT
DEFINE resp		CHAR(6)

DEFINE ind		SMALLINT

DEFINE r_v22		RECORD LIKE veht022.*
DEFINE r_serveh RECORD
        v22_codigo_veh          LIKE veht022.v22_codigo_veh,
        v22_chasis              LIKE veht022.v22_chasis,
        v22_modelo              LIKE veht022.v22_modelo,
        v22_cod_color           LIKE veht022.v22_cod_color,
        v22_bodega              LIKE veht022.v22_bodega
        END RECORD
DEFINE continuar 	SMALLINT

INITIALIZE r_v22.* TO NULL
INITIALIZE r_serveh.* TO NULL

LET i = 1
LET j = 1

CALL set_count(i)
INPUT ARRAY rm_transf FROM ra_transf.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
               		RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN 0
		END IF
	ON KEY(F2)
		IF INFIELD(v31_codigo_veh) THEN
			CALL fl_ayuda_serie_veh(vg_codcia, vg_codloc, 
                                                rm_v30.v30_bodega_ori) 
							RETURNING r_serveh.*
			IF r_serveh.v22_codigo_veh IS NOT NULL THEN
				LET rm_transf[i].serie = r_serveh.v22_chasis	
				LET rm_transf[i].color = r_serveh.v22_cod_color	
				LET rm_transf[i].codigo_veh = r_serveh.v22_codigo_veh
				LET rm_transf[i].modelo = r_serveh.v22_modelo
				DISPLAY rm_transf[i].* TO ra_transf[j].*
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL setea_botones_f1()
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	AFTER FIELD v31_codigo_veh
		IF rm_transf[i].codigo_veh IS NULL THEN
			CLEAR ra_transf[j].*	
			CONTINUE INPUT            
		ELSE
			LET ind = 1
			WHILE (ind <> (arr_count()))
			IF rm_transf[i].codigo_veh = rm_transf[ind].codigo_veh 
			AND ind <> i THEN 
				CALL fgl_winmessage(vg_producto,
                                                    'No puede transferir la' ||
                                                    ' misma serie dos veces',
                                                    'exclamation')
				CLEAR ra_transf[j].modelo
				CLEAR ra_transf[j].serie
				CLEAR ra_transf[j].color
				NEXT FIELD v31_codigo_veh 
			ELSE
				LET ind = ind + 1
			END IF
			END WHILE
			CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc,
			               rm_transf[i].codigo_veh)
						RETURNING r_v22.*
			IF r_v22.v22_chasis IS NULL THEN
				CALL fgl_winmessage(vg_producto,
                                                    'Serie no existe',
                                                    'exclamation')
				CLEAR ra_transf[j].serie
				CLEAR ra_transf[j].modelo
				CLEAR ra_transf[j].color
				INITIALIZE rm_transf[i].* TO NULL
				NEXT FIELD v31_codigo_veh 
			ELSE
				LET continuar = 1
				IF r_v22.v22_estado = 'F' THEN
					CALL fgl_winmessage(vg_producto,
							    'Esta serie ya ' ||
							    'ha sido facturada',
 		                                            'exclamation')
					LET continuar = 0
				END IF 
				IF r_v22.v22_estado = 'P' THEN
					CALL fgl_winmessage(vg_producto,
							    'No puede '||
							    ' transferir ' ||
                                                            ' esta serie',
 		                                            'exclamation')
					LET continuar = 0
				END IF 
				IF r_v22.v22_estado = 'B' THEN
					CALL fgl_winmessage(vg_producto,
							    'Serie bloqueada',
 		                                            'exclamation')
					LET continuar = 0
				END IF 
				IF rm_v30.v30_bodega_ori <> r_v22.v22_bodega 
					THEN
					CALL fgl_winmessage(vg_producto,
							    'Serie no existe' ||
							    ' en esta bodega',
							    'exclamation')
					LET continuar = 0
				END IF 
				IF continuar = 0 THEN
					CLEAR ra_transf[j].serie, 
       					      ra_transf[j].modelo, 
					      ra_transf[j].color 
					NEXT FIELD v31_codigo_veh
				END IF
				LET rm_transf[i].serie  = r_v22.v22_chasis
				LET rm_transf[i].modelo = r_v22.v22_modelo
				LET rm_transf[i].color  = r_v22.v22_cod_color
				DISPLAY rm_transf[i].* TO ra_transf[j].*
			END IF
		END IF
	AFTER INPUT
		LET ind = arr_count()
		FOR i = 1 TO ind
			IF i < ind AND rm_transf[i].codigo_veh IS NULL THEN
				CALL fgl_winmessage(vg_producto,
                                            	'Debe borrar las lineas que ' ||
                                            	'deje en blanco',
					    	'exclamation')
				CONTINUE INPUT 
			END IF
		END FOR
		FOR i = 1 TO ind
			CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, 
						     rm_transf[i].codigo_veh)
							RETURNING r_v22.*
			LET rm_v30.v30_tot_costo = rm_v30.v30_tot_costo +
						   r_v22.v22_costo_ing
		END FOR
		LET vm_ind_arr = arr_count()
END INPUT

RETURN ind

END FUNCTION




FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE vendedor 	LIKE veht001.v01_vendedor,
       nom_vendedor	LIKE veht001.v01_nombres

DEFINE bodega		LIKE veht002.v02_bodega,
       nom_bodega	LIKE veht002.v02_nombre

DEFINE r_v01		RECORD LIKE veht001.*
DEFINE r_v02		RECORD LIKE veht002.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
  	ON v30_num_tran, v30_vendedor, v30_bodega_ori, v30_bodega_dest, 
           v30_referencia, v30_usuario
	ON KEY(F2)
		IF INFIELD(v30_vendedor) THEN
			CALL fl_ayuda_vendedores_veh(vg_codcia) 
				RETURNING vendedor, nom_vendedor
			IF vendedor IS NOT NULL THEN
				LET rm_v30.v30_vendedor = vendedor
				DISPLAY BY NAME rm_v30.v30_vendedor
				DISPLAY nom_vendedor TO n_vendedor
			END IF
		END IF
		IF INFIELD(v30_bodega_ori) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia) 
				RETURNING bodega, nom_bodega 
			IF bodega IS NOT NULL THEN
				LET rm_v30.v30_bodega_ori = bodega
				DISPLAY bodega TO v30_bodega_ori
				DISPLAY nom_bodega TO n_bodega_ori
			END IF
		END IF
		IF INFIELD(v30_bodega_dest) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia) 
				RETURNING bodega, nom_bodega 
			IF bodega IS NOT NULL THEN
				LET rm_v30.v30_bodega_dest = bodega
				DISPLAY bodega TO v30_bodega_dest
				DISPLAY nom_bodega TO n_bodega_dest
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE CONSTRUCT
		CALL setea_botones_f1()
	AFTER FIELD v30_vendedor
		LET rm_v30.v30_vendedor = GET_FLDBUF(v30_vendedor)
		IF rm_v30.v30_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_veh(vg_codcia, rm_v30.v30_vendedor)
				RETURNING r_v01.*
			IF r_v01.v01_vendedor IS NOT NULL THEN
				IF r_v01.v01_estado <> 'B' THEN
					DISPLAY r_v01.v01_nombres TO n_vendedor
				ELSE
					CLEAR n_vendedor
				END IF
			ELSE
				CLEAR n_vendedor
			END IF
		ELSE
			CLEAR n_vendedor
		END IF		 
	AFTER FIELD v30_bodega_ori
		LET rm_v30.v30_bodega_ori = GET_FLDBUF(v30_bodega_ori)
		IF rm_v30.v30_bodega_ori IS NOT NULL THEN
			CALL fl_lee_bodega_veh(vg_codcia, rm_v30.v30_bodega_ori)
				RETURNING r_v02.*
			IF r_v02.v02_bodega IS NOT NULL THEN
				IF r_v02.v02_estado <> 'B' THEN
					DISPLAY r_v02.v02_nombre TO n_bodega_ori
				ELSE
					CLEAR n_bodega_ori  
				END IF
			ELSE
				CLEAR n_bodega_ori
			END IF
		ELSE
			CLEAR n_bodega_ori
		END IF		 
	AFTER FIELD v30_bodega_dest
		LET rm_v30.v30_bodega_dest = GET_FLDBUF(v30_bodega_dest)
		IF rm_v30.v30_bodega_dest IS NOT NULL THEN
			CALL fl_lee_bodega_veh(vg_codcia, 
                                               rm_v30.v30_bodega_dest)
							RETURNING r_v02.*
			IF r_v02.v02_bodega IS NOT NULL THEN
				IF r_v02.v02_estado <> 'B' THEN
					DISPLAY r_v02.v02_nombre TO n_bodega_dest  
				ELSE
					CLEAR n_bodega_dest  
				END IF
			ELSE
				CLEAR n_bodega_dest
			END IF
		ELSE
			CLEAR n_bodega_dest
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

LET query = 'SELECT *, ROWID FROM veht030 ', 
            ' WHERE v30_compania = ', vg_codcia,
	    '   AND v30_localidad = ', vg_codloc,
	    '   AND v30_cod_tran = "', vm_transaccion, '"', 
	    '   AND ', expr_sql,
            ' ORDER BY 1, 2, 3, 4' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v30.*, vm_rows[vm_num_rows]
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

SELECT * INTO rm_v30.* FROM veht030 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_v30.v30_cod_tran,
		rm_v30.v30_num_tran,
		rm_v30.v30_vendedor,
                rm_v30.v30_bodega_ori,
		rm_v30.v30_bodega_dest,
		rm_v30.v30_referencia,
		rm_v30.v30_usuario,
		rm_v30.v30_fecing

CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()
CALL setea_botones_f1()

END FUNCTION



FUNCTION muestra_detalle()

DEFINE i 		SMALLINT
DEFINE query 		CHAR(250)

DEFINE r_v22		RECORD LIKE veht022.*

LET vm_filas_pant = fgl_scr_size('ra_transf')

FOR i = 1 TO vm_filas_pant 
	INITIALIZE rm_transf[i].* TO NULL
	CLEAR ra_transf[i].*
END FOR

LET query = 'SELECT v31_codigo_veh FROM veht031 ',
            'WHERE v31_compania  =  ', vg_codcia, 
	    '  AND v31_localidad =  ', vg_codloc,
	    '  AND v31_cod_tran  = "', vm_transaccion, '"',
            '  AND v31_num_tran  =  ', rm_v30.v30_num_tran,
	    ' ORDER BY 1'
PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
LET i = 1
FOREACH q_cons2 INTO rm_transf[i].codigo_veh
	CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, 
				     rm_transf[i].codigo_veh)
						RETURNING r_v22.*
	IF rm_transf[i].codigo_veh IS NOT NULL THEN
		LET rm_transf[i].serie  = r_v22.v22_chasis 
		LET rm_transf[i].modelo = r_v22.v22_modelo 
		LET rm_transf[i].color  = r_v22.v22_cod_color
	END IF
	LET i = i + 1
        IF i > 1000 THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET i = i - 1
IF i = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET i = 0
	LET i = 0
	CLEAR FORM
	RETURN
END IF

LET vm_ind_arr = i

IF vm_ind_arr < vm_filas_pant THEN
	LET vm_filas_pant = vm_ind_arr
END IF

FOR i = 1 TO vm_filas_pant   
	DISPLAY rm_transf[i].* TO ra_transf[i].*
END FOR

END FUNCTION



FUNCTION muestra_contadores()

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

DEFINE r_v01			RECORD LIKE veht001.*
DEFINE r_v02			RECORD LIKE veht002.*

CALL fl_lee_vendedor_veh(vg_codcia, rm_v30.v30_vendedor) RETURNING r_v01.*
DISPLAY r_v01.v01_nombres TO n_vendedor

CALL fl_lee_bodega_veh(vg_codcia, rm_v30.v30_bodega_ori) RETURNING r_v02.*
DISPLAY r_v02.v02_nombre TO n_bodega_ori

CALL fl_lee_bodega_veh(vg_codcia, rm_v30.v30_bodega_dest) RETURNING r_v02.*
DISPLAY r_v02.v02_nombre TO n_bodega_dest

END FUNCTION



FUNCTION nextValInSequence()

DEFINE resp		CHAR(6)
DEFINE retVal 		INTEGER

LET retVal = -1
WHILE retVal = -1

LET retVal = fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
					 'AA', vm_transaccion)
IF retVal = 0 THEN
	EXIT PROGRAM
END IF
IF retVal <> -1 THEN
	 EXIT WHILE
END IF

CALL fgl_winquestion(vg_producto, 'La tabla de secuencias de transacciones ' ||
                     'está siendo accesada por otro usuario, espere unos  ' ||
                     'segundos y vuelva a intentar', 'No', 'Yes|No|Cancel',
                     'question', 1) RETURNING resp 
IF resp <> 'Yes' THEN
	EXIT WHILE	
END IF

END WHILE

RETURN retVal

END FUNCTION



FUNCTION control_mostrar_det()

CALL set_count(vm_ind_arr)
DISPLAY ARRAY rm_transf TO ra_transf.*
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT', '')
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION setea_botones_f1()

DISPLAY 'Código Veh.' TO bt_codigo_veh
DISPLAY 'Serie' TO bt_serie     
DISPLAY 'Modelo' TO bt_modelo    
DISPLAY 'Color' TO bt_color      

END FUNCTION



FUNCTION execute_query()
                                                                                
LET vm_num_rows = 1
LET vm_row_current = 1
                                                                                
SELECT ROWID INTO vm_rows[vm_num_rows]
        FROM veht030
        WHERE v30_compania  = vg_codcia
          AND v30_localidad = vg_codloc
	  AND v30_cod_tran  = vm_transaccion
          AND v30_num_tran  = vm_numtran
IF STATUS = NOTFOUND THEN
        CALL fgl_winmessage(vg_producto, 
		'No existe número de transferencia.',
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
