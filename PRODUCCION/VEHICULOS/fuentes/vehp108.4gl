------------------------------------------------------------------------------
-- Titulo           : vehp108.4gl - Mantenimiento de Series     
-- Elaboracion      : 18-sep-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp108 base modulo compania localidad [cod_veh]
--		Si (cod_veh <> 0) el programa se esta ejcutando en modo de
--			solo consulta
--		Si (cod_veh = 0) el programa se esta ejecutando en forma 
--			independiente
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios		VARCHAR(12)
DEFINE vm_cod_veh		LIKE veht022.v22_codigo_veh

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_v22			RECORD LIKE veht022.*



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
LET vg_proceso = 'vehp108'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

LET vm_cod_veh = 0
IF num_args() = 5 THEN
	LET vm_cod_veh = arg_val(5)
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
OPEN WINDOW w_v22 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_v22 FROM '../forms/vehf108_1'
DISPLAY FORM f_v22

DISPLAY '' TO n_estado

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v22.* TO NULL
CALL muestra_contadores()
CALL muestra_etiquetas()

LET vm_max_rows = 1000

IF vm_cod_veh <> 0 THEN
	CALL execute_query()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Ver Reservación'
		IF vm_cod_veh <> 0 THEN         -- Se ejecuta en modo de solo
			HIDE OPTION 'Ingresar'  -- consulta
			HIDE OPTION 'Consultar'
			IF rm_v22.v22_estado = 'R' THEN
				SHOW OPTION 'Ver Reservación'
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		HIDE OPTION 'Ver Reservación'
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
		IF rm_v22.v22_estado = 'R' THEN
			SHOW OPTION 'Ver Reservación'
		END IF
	COMMAND KEY('V') 'Ver Reservación' 	'Ver Reservación.'
		CALL ver_reservacion()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		HIDE OPTION 'Ver Reservación'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_v22.v22_estado = 'R' THEN
			SHOW OPTION 'Ver Reservación'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		HIDE OPTION 'Ver Reservación'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_v22.v22_estado = 'R' THEN
			SHOW OPTION 'Ver Reservación'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE total 		LIKE veht022.v22_costo_ing

CLEAR FORM
INITIALIZE rm_v22.* TO NULL


LET rm_v22.v22_fecing      = CURRENT
LET rm_v22.v22_usuario     = vg_usuario
LET rm_v22.v22_compania    = vg_codcia
LET rm_v22.v22_localidad   = vg_codloc
LET rm_v22.v22_estado      = 'A'
LET rm_v22.v22_nuevo       = 'N'
DISPLAY 'ACTIVO' TO n_estado

-- THESE FIELDS ARE NOT NULL BUT IN AN INPUT I CAN'T PUT ANYTHING IN THEM -- 

LET rm_v22.v22_costo_liq   = 0.00 
LET rm_v22.v22_cargo_liq   = 0.00 
LET rm_v22.v22_costo_ing   = 0.00 
LET rm_v22.v22_cargo_ing   = 0.00 
LET rm_v22.v22_costo_adi   = 0.00 
LET rm_v22.v22_moneda_liq  = rg_gen.g00_moneda_base 
LET rm_v22.v22_moneda_ing  = rg_gen.g00_moneda_base
LET rm_v22.v22_moneda_prec = rg_gen.g00_moneda_base

---------------------------------------------------------------------------- 

LET total = rm_v22.v22_costo_ing + rm_v22.v22_cargo_ing + rm_v22.v22_costo_adi
DISPLAY total TO costo_tot

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

SELECT MAX(v22_codigo_veh) INTO rm_v22.v22_codigo_veh
	FROM veht022 
	WHERE v22_compania  = vg_codcia
	  AND v22_localidad = vg_codloc
IF rm_v22.v22_codigo_veh IS NULL THEN
	LET rm_v22.v22_codigo_veh = 1
ELSE
	LET rm_v22.v22_codigo_veh = rm_v22.v22_codigo_veh + 1
END IF
INSERT INTO veht022 VALUES (rm_v22.*)

DISPLAY BY NAME rm_v22.v22_codigo_veh

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
CALL muestra_contadores()
CALL muestra_etiquetas()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_v22.v22_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
IF rm_v22.v22_estado = 'F' THEN
	CALL fgl_winmessage(vg_producto, 'Serie ya ha sido facturada',
			    'exclamation')
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM veht022 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_v22.*
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

UPDATE veht022 SET * = rm_v22.* WHERE CURRENT OF q_upd
COMMIT WORK
CLOSE q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



fUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE bodega		LIKE veht002.v02_bodega,
       nom_bodega	LIKE veht002.v02_nombre

DEFINE color		LIKE veht005.v05_cod_color,
       nom_color 	LIKE veht005.v05_descri_base

DEFINE g13_moneda       LIKE gent013.g13_moneda,
       nombre		LIKE gent013.g13_nombre,
       decimales 	LIKE gent013.g13_decimales

DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_v20		RECORD LIKE veht020.*
DEFINE r_v05		RECORD LIKE veht005.*
DEFINE r_v02		RECORD LIKE veht002.*

LET INT_FLAG = 0
INPUT BY NAME rm_v22.v22_chasis, rm_v22.v22_estado, rm_v22.v22_nuevo,
	      rm_v22.v22_bodega, rm_v22.v22_modelo, rm_v22.v22_codigo_veh,
              rm_v22.v22_comentarios, rm_v22.v22_motor, rm_v22.v22_ano,
              rm_v22.v22_cod_color, rm_v22.v22_dueno, rm_v22.v22_kilometraje,
              rm_v22.v22_placa, rm_v22.v22_moneda_prec, rm_v22.v22_precio,
              rm_v22.v22_moneda_liq, rm_v22.v22_costo_liq,
	      rm_v22.v22_cargo_liq, rm_v22.v22_numero_liq, 
              rm_v22.v22_fec_ing_bod, rm_v22.v22_pedido, rm_v22.v22_moneda_ing,
              rm_v22.v22_costo_ing, rm_v22.v22_cargo_ing, rm_v22.v22_costo_adi,
              rm_v22.v22_cod_tran, rm_v22.v22_num_tran,               
              rm_v22.v22_usuario, rm_v22.v22_fecing WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_v22.v22_chasis, rm_v22.v22_nuevo,
	                             rm_v22.v22_bodega, rm_v22.v22_modelo, 
                                     rm_v22.v22_codigo_veh, 
                                     rm_v22.v22_comentarios, rm_v22.v22_motor,
                                     rm_v22.v22_ano, rm_v22.v22_cod_color, 
                                     rm_v22.v22_dueno, rm_v22.v22_kilometraje,
                                     rm_v22.v22_placa
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
		IF INFIELD(v22_bodega) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia) 
				RETURNING bodega, nom_bodega 
			IF bodega IS NOT NULL THEN
				LET rm_v22.v22_bodega = bodega
				DISPLAY BY NAME rm_v22.v22_bodega
				DISPLAY nom_bodega TO n_bodega
			END IF
		END IF
		IF INFIELD(v22_modelo) THEN
			CALL fl_ayuda_modelos_veh(vg_codcia)
				RETURNING r_v20.v20_modelo, r_v20.v20_linea
			IF r_v20.v20_modelo IS NOT NULL THEN
				CALL fl_lee_modelo_veh(vg_codcia,
						      r_v20.v20_modelo)
							RETURNING r_v20.*
				LET rm_v22.v22_modelo = r_v20.v20_modelo
				DISPLAY BY NAME rm_v22.v22_modelo
				DISPLAY r_v20.v20_modelo_ext TO n_modelo
			END IF
		END IF
		IF INFIELD(v22_moneda_prec) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_v22.v22_moneda_prec = g13_moneda
				DISPLAY BY NAME rm_v22.v22_moneda_prec
				DISPLAY nombre TO n_moneda_prec
			END IF	
		END IF
		IF INFIELD(v22_cod_color) THEN
			CALL fl_ayuda_colores(vg_codcia) 
				RETURNING color, nom_color
			IF color IS NOT NULL THEN
				LET rm_v22.v22_cod_color = color
				DISPLAY BY NAME rm_v22.v22_cod_color
				DISPLAY nom_color TO n_color
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE FIELD v22_chasis
		IF flag = 'M' THEN
			NEXT FIELD v22_bodega
		END IF
	BEFORE FIELD v22_nuevo
		IF flag = 'M' THEN
			NEXT FIELD v22_bodega
		END IF
	AFTER FIELD v22_nuevo
		IF FLAG = 'I' AND  rm_v22.v22_nuevo = 'S' THEN
			LET rm_v22.v22_estado = 'M'		
			DISPLAY BY NAME rm_v22.v22_estado
			DISPLAY 'MANUAL' TO n_estado
		ELSE
			LET rm_v22.v22_estado = 'A'		
			DISPLAY BY NAME rm_v22.v22_estado
			DISPLAY 'ACTIVO' TO n_estado
		END IF
	AFTER FIELD v22_moneda_prec
		IF rm_v22.v22_moneda_prec IS NULL THEN
			CLEAR n_moneda_prec
		ELSE
			CALL fl_lee_moneda(rm_v22.v22_moneda_prec) 
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
					DISPLAY r_mon.g13_nombre TO n_moneda_prec
				END IF
			END IF 
		END IF
	AFTER  FIELD v22_modelo
		IF rm_v22.v22_modelo IS NULL THEN
			CLEAR n_modelo
		ELSE
			CALL fl_lee_modelo_veh(rm_v22.v22_compania, 
                                             rm_v22.v22_modelo)
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
		IF rm_v22.v22_cod_color IS NULL THEN
			CLEAR n_color
		ELSE
			CALL fl_lee_color_veh(rm_v22.v22_compania, 
                                              rm_v22.v22_cod_color)
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
		IF rm_v22.v22_bodega IS NULL THEN
			CLEAR n_bodega
		ELSE
			CALL fl_lee_bodega_veh(rm_v22.v22_compania, 
                                               rm_v22.v22_bodega)
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
		LET rm_v22.v22_precio =
			fl_retorna_precision_valor(rm_v22.v22_moneda_prec,
						   rm_v22.v22_precio)
		DISPLAY BY NAME rm_v22.v22_precio
	AFTER INPUT 
		LET rm_v22.v22_precio =
			fl_retorna_precision_valor(rm_v22.v22_moneda_prec,
						   rm_v22.v22_precio)
		DISPLAY BY NAME rm_v22.v22_precio
		IF flag = 'I' AND rm_v22.v22_estado = 'M' THEN
			CALL fgl_winmessage(vg_producto,
					    'Para vender este vehículo debe ' ||
                                            'realizar primero una compra local',
					    'info')
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE bodega			LIKE veht002.v02_bodega,
       nom_bodega		LIKE veht002.v02_nombre

DEFINE modelo			LIKE veht020.v20_modelo,
       linea			LIKE veht020.v20_linea,     -- DUMMY VARIABLE
       modelo_ext       	LIKE veht020.v20_modelo_ext

DEFINE color			LIKE veht005.v05_cod_color,
       nom_color 		LIKE veht005.v05_descri_base

DEFINE g13_moneda		LIKE gent013.g13_moneda,
       nombre			LIKE gent013.g13_nombre,
       decimales 		LIKE gent013.g13_decimales

DEFINE tran 			LIKE gent021.g21_cod_tran,
       nom_tran			LIKE gent021.g21_nombre

DEFINE r_mon			RECORD LIKE gent013.*
DEFINE r_v20			RECORD LIKE veht020.*
DEFINE r_v05			RECORD LIKE veht005.*
DEFINE r_v02			RECORD LIKE veht002.*
DEFINE r_g21			RECORD LIKE gent021.*

DEFINE r_serveh RECORD
        codigo_veh	LIKE veht022.v22_codigo_veh,
        chasis		LIKE veht022.v22_chasis,
        modelo		LIKE veht022.v22_modelo,
        cod_color	LIKE veht022.v22_cod_color,
        bodega		LIKE veht022.v22_bodega
END RECORD

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON v22_chasis, v22_estado, v22_nuevo, v22_bodega, v22_modelo, 
           v22_codigo_veh, v22_comentarios, v22_motor, v22_ano,
           v22_cod_color, v22_dueno, v22_kilometraje, v22_placa, 
           v22_moneda_prec, v22_precio, v22_moneda_liq, v22_costo_liq, 
           v22_cargo_liq, 
           v22_numero_liq, v22_fec_ing_bod, v22_pedido, v22_moneda_ing,
           v22_costo_ing, v22_cargo_ing, v22_costo_adi, v22_cod_tran, 
           v22_num_tran, v22_usuario 
	ON KEY(F2)
		IF INFIELD(v22_chasis) THEN
			CALL fl_ayuda_serie_veh_todos(vg_codcia, vg_codloc, 
				'00') RETURNING r_serveh.*
			IF r_serveh.codigo_veh IS NOT NULL THEN
				LET rm_v22.v22_chasis     = r_serveh.chasis	
				LET rm_v22.v22_codigo_veh = r_serveh.codigo_veh
				LET rm_v22.v22_modelo     = r_serveh.modelo
				DISPLAY BY NAME rm_v22.v22_chasis,       
						rm_v22.v22_codigo_veh,
						rm_v22.v22_modelo
			END IF
		END IF
		IF INFIELD(v22_bodega) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia) 
				RETURNING bodega, nom_bodega 
			IF bodega IS NOT NULL THEN
				LET rm_v22.v22_bodega = bodega
				DISPLAY BY NAME rm_v22.v22_bodega
				DISPLAY nom_bodega TO n_bodega
			END IF
		END IF
		IF INFIELD(v22_modelo) THEN
			CALL fl_ayuda_modelos_veh(vg_codcia)
				RETURNING modelo, linea
			IF modelo IS NOT NULL THEN
				SELECT v20_modelo_ext INTO modelo_ext
					FROM veht020
					WHERE v20_compania = vg_codcia
					  AND v20_modelo   = modelo
				LET rm_v22.v22_modelo = modelo
				DISPLAY BY NAME rm_v22.v22_modelo
				DISPLAY modelo_ext TO n_modelo
			END IF
		END IF
		IF INFIELD(v22_cod_color) THEN
			CALL fl_ayuda_colores(vg_codcia) 
				RETURNING color, nom_color
			IF color IS NOT NULL THEN
				LET rm_v22.v22_cod_color = color
				DISPLAY BY NAME rm_v22.v22_cod_color
				DISPLAY nom_color TO n_color
			END IF
		END IF
		IF INFIELD(v22_moneda_liq) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_v22.v22_moneda_liq = g13_moneda
				DISPLAY BY NAME rm_v22.v22_moneda_liq
				DISPLAY nombre TO n_moneda_liq
			END IF	
		END IF
		IF INFIELD(v22_moneda_ing) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_v22.v22_moneda_ing = g13_moneda
				DISPLAY BY NAME rm_v22.v22_moneda_ing
				DISPLAY nombre TO n_moneda_ing
			END IF	
		END IF
		IF INFIELD(v22_moneda_prec) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_v22.v22_moneda_prec = g13_moneda
				DISPLAY BY NAME rm_v22.v22_moneda_prec
				DISPLAY nombre TO n_moneda_prec
			END IF	
		END IF
		IF INFIELD(v22_cod_tran) THEN
			CALL fl_ayuda_tipo_tran('N') RETURNING tran, nom_tran
			IF tran IS NOT NULL THEN
				LET rm_v22.v22_cod_tran = tran
				DISPLAY BY NAME rm_v22.v22_cod_tran
				DISPLAY nom_tran TO n_transaccion
			END IF
		END IF 
		LET INT_FLAG = 0
	AFTER  FIELD v22_modelo
		LET rm_v22.v22_modelo = GET_FLDBUF(v22_modelo)
		IF rm_v22.v22_modelo IS NULL THEN
			CLEAR n_modelo
		ELSE
			CALL fl_lee_modelo_veh(rm_v22.v22_compania, 
                                               rm_v22.v22_modelo)
							RETURNING r_v20.*
			IF r_v20.v20_modelo IS NULL THEN	
				CLEAR n_modelo
			ELSE
				DISPLAY r_v20.v20_modelo_ext TO n_modelo
			END IF 
		END IF
	AFTER  FIELD v22_cod_color
		LET rm_v22.v22_cod_color = GET_FLDBUF(v22_cod_color)
		IF rm_v22.v22_cod_color IS NULL THEN
			CLEAR n_color
		ELSE
			CALL fl_lee_color_veh(rm_v22.v22_compania, 
                                              rm_v22.v22_cod_color)
							RETURNING r_v05.*
			IF r_v05.v05_cod_color IS NULL THEN	
				CLEAR n_bodega
			ELSE
				DISPLAY r_v05.v05_descri_base TO n_color
			END IF 
		END IF
	AFTER  FIELD v22_bodega
		LET rm_v22.v22_bodega = GET_FLDBUF(v22_bodega)
		IF rm_v22.v22_bodega IS NULL THEN
			CLEAR n_bodega
		ELSE
			CALL fl_lee_bodega_veh(vg_codcia, 
                                               rm_v22.v22_bodega)
							RETURNING r_v02.*
			IF r_v02.v02_bodega IS NULL THEN	
				CLEAR n_bodega
			ELSE
				IF r_v02.v02_estado = 'B' THEN
					CLEAR n_bodega
				ELSE
					DISPLAY r_v02.v02_nombre TO n_bodega
				END IF
			END IF 
		END IF
	AFTER  FIELD v22_cod_tran
		LET rm_v22.v22_cod_tran = GET_FLDBUF(v22_cod_tran)
		IF rm_v22.v22_cod_tran IS NULL THEN
			CLEAR n_transaccion
		ELSE
			CALL fl_lee_cod_transaccion(rm_v22.v22_cod_tran)
				RETURNING r_g21.*
			IF r_g21.g21_cod_tran IS NULL THEN	
				CLEAR n_transaccion
			ELSE
				IF r_g21.g21_estado = 'B' THEN
					CLEAR n_transaccion
				ELSE
					DISPLAY r_g21.g21_nombre TO n_transaccion
				END IF
			END IF 
		END IF
	AFTER FIELD v22_moneda_liq
		LET rm_v22.v22_moneda_liq = GET_FLDBUF(v22_moneda_liq)
		IF rm_v22.v22_moneda_liq IS NULL THEN
			CLEAR n_moneda_liq
		ELSE
			CALL fl_lee_moneda(rm_v22.v22_moneda_liq) 
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR n_moneda_liq
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CLEAR n_moneda_liq
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda_liq
				END IF
			END IF 
		END IF
	AFTER FIELD v22_moneda_ing
		LET rm_v22.v22_moneda_ing = GET_FLDBUF(v22_moneda_ing)
		IF rm_v22.v22_moneda_ing IS NULL THEN
			CLEAR n_moneda_ing
		ELSE
			CALL fl_lee_moneda(rm_v22.v22_moneda_ing) 
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR n_moneda_ing
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CLEAR n_moneda_ing
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda_ing
				END IF
			END IF 
		END IF
	AFTER FIELD v22_moneda_prec
		LET rm_v22.v22_moneda_prec = GET_FLDBUF(v22_moneda_prec)
		IF rm_v22.v22_moneda_prec IS NULL THEN
			CLEAR n_moneda_prec
		ELSE
			CALL fl_lee_moneda(rm_v22.v22_moneda_prec) 
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR n_moneda_prec
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CLEAR n_moneda_prec
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda_prec
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

LET query = 'SELECT *, ROWID FROM veht022 ',
            '	WHERE v22_compania  = ', vg_codcia, 
	    '     AND v22_localidad = ', vg_codloc,
            '  	  AND ', expr_sql, ' ORDER BY 1, 2, 3' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v22.*, vm_rows[vm_num_rows]
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
DEFINE total		LIKE veht022.v22_costo_ing

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_v22.* FROM veht022 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_v22.v22_bodega,
                rm_v22.v22_modelo,
		rm_v22.v22_estado,
		rm_v22.v22_chasis,
		rm_v22.v22_nuevo,
		rm_v22.v22_codigo_veh,
		rm_v22.v22_comentarios,
		rm_v22.v22_motor,
		rm_v22.v22_ano,
		rm_v22.v22_cod_color,
		rm_v22.v22_dueno,
		rm_v22.v22_kilometraje,
		rm_v22.v22_placa,
		rm_v22.v22_moneda_liq,
		rm_v22.v22_costo_liq,
		rm_v22.v22_cargo_liq,
		rm_v22.v22_numero_liq,
		rm_v22.v22_fec_ing_bod,
		rm_v22.v22_pedido,
		rm_v22.v22_moneda_ing,
		rm_v22.v22_costo_ing,
		rm_v22.v22_cargo_ing,
		rm_v22.v22_costo_adi,
		rm_v22.v22_moneda_prec,
		rm_v22.v22_precio,
		rm_v22.v22_cod_tran,
		rm_v22.v22_num_tran,
		rm_v22.v22_usuario,
		rm_v22.v22_fecing

LET total = rm_v22.v22_costo_ing + rm_v22.v22_cargo_ing + rm_v22.v22_costo_adi
DISPLAY total TO costo_tot

CALL muestra_contadores()
CALL muestra_etiquetas()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY vm_row_current, vm_num_rows TO vm_row_current2, vm_num_rows2 
DISPLAY vm_row_current, vm_num_rows TO vm_row_current1, vm_num_rows1 

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

DEFINE r_v02			RECORD LIKE veht002.*
DEFINE r_v20			RECORD LIKE veht020.*
DEFINE r_v05			RECORD LIKE veht005.*
DEFINE r_g13			RECORD LIKE gent013.*
DEFINE r_g21			RECORD LIKE gent021.*

CALL fl_lee_bodega_veh(vg_codcia, rm_v22.v22_bodega) RETURNING r_v02.*
DISPLAY r_v02.v02_nombre TO n_bodega

CALL fl_lee_modelo_veh(vg_codcia, rm_v22.v22_modelo) RETURNING r_v20.*
DISPLAY r_v20.v20_modelo_ext TO n_modelo

CALL fl_lee_color_veh(vg_codcia, rm_v22.v22_cod_color) RETURNING r_v05.*
DISPLAY r_v05.v05_descri_base TO n_color

CALL fl_lee_moneda(rm_v22.v22_moneda_liq) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda_liq

CALL fl_lee_moneda(rm_v22.v22_moneda_ing) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda_ing

CALL fl_lee_moneda(rm_v22.v22_moneda_prec) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda_prec

CALL fl_lee_cod_transaccion(rm_v22.v22_cod_tran) RETURNING r_g21.*
DISPLAY r_g21.g21_nombre TO n_transaccion

CASE rm_v22.v22_estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'B' LET nom_estado = 'BLOQUEADO'
	WHEN 'F' LET nom_estado = 'FACTURADO'
	WHEN 'P' LET nom_estado = 'EN PEDIDO'
	WHEN 'R' LET nom_estado = 'RESERVADO'
	WHEN 'M' LET nom_estado = 'MANUAL'
	WHEN 'C' LET nom_estado = 'EN CHEQUEO'
END CASE
DISPLAY nom_estado   TO n_estado

END FUNCTION



FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM veht022
	WHERE v22_compania  = vg_codcia
	  AND v22_localidad = vg_codloc
	  AND v22_codigo_veh = vm_cod_veh
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe vehículo.', 
		'exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION ver_reservacion()

DEFINE command_line	CHAR(100)

IF rm_v22.v22_estado <> 'R' THEN
	CALL fgl_winmessage(vg_producto,
		'Este vehículo no ha sido reservado.',
		'exclamation')
	RETURN
END IF

LET command_line = 'fglrun vehp209 ', vg_base,   ' ', vg_modulo,
		                 ' ', vg_codcia, ' ', vg_codloc,
				 ' ', rm_v22.v22_codigo_veh
RUN command_line

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
