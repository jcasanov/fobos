------------------------------------------------------------------------------
-- Titulo           : vehp214.4gl - Mantenimiento orden de chequeo de vehiculos
-- Elaboracion      : 11-oct-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp214 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_v38			RECORD LIKE veht038.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'vehp214'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_214 AT 3,2 WITH 17 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_214 FROM '../forms/vehf214_1'
DISPLAY FORM f_214

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v38.* TO NULL
CALL muestra_contadores()

LET vm_max_rows = 1000

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
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
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
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
	COMMAND KEY('B') 'Bloquear/Activar'     'Bloquea o activa registro.'
		CALL control_bloquea_activa()
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

CLEAR FORM
INITIALIZE rm_v38.* TO NULL

LET rm_v38.v38_fecing    = CURRENT
LET rm_v38.v38_usuario   = vg_usuario
LET rm_v38.v38_compania  = vg_codcia
LET rm_v38.v38_localidad = vg_codloc
LET rm_v38.v38_estado    = 'A'

CALL muestra_etiquetas()

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

SELECT MAX(v38_orden_cheq) INTO rm_v38.v38_orden_cheq
	FROM veht038
	WHERE v38_compania  = vg_codcia
	  AND v38_localidad = vg_codloc
IF rm_v38.v38_orden_cheq IS NULL THEN
	LET rm_v38.v38_orden_cheq = 1
ELSE
	LET rm_v38.v38_orden_cheq = rm_v38.v38_orden_cheq + 1
END IF

INSERT INTO veht038 VALUES (rm_v38.*)

DISPLAY BY NAME rm_v38.v38_orden_cheq

LET vm_num_rows = vm_num_rows + 1
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_v38.v38_estado = 'B' THEN
	CALL fgl_winmessage(vg_producto, 'Orden bloqueada', 'exclamation')
	RETURN          
END IF 

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM veht038 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_v38.*
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

UPDATE veht038 SET * = rm_v38.* WHERE CURRENT OF q_upd
COMMIT WORK
CLOSE q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)
DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE r_serveh RECORD
        codigo_veh          LIKE veht022.v22_codigo_veh,
        chasis              LIKE veht022.v22_chasis,
        modelo              LIKE veht022.v22_modelo,
        cod_color           LIKE veht022.v22_cod_color,
        estado              LIKE veht022.v22_estado
END RECORD

DEFINE r_v22		RECORD LIKE veht022.*
DEFINE continuar        SMALLINT

LET INT_FLAG = 0
INPUT BY NAME rm_v38.v38_orden_cheq, rm_v38.v38_estado, rm_v38.v38_codigo_veh,
	      rm_v38.v38_referencia, rm_v38.v38_num_ot, 
              rm_v38.v38_usuario, rm_v38.v38_fecing WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(v38_codigo_veh, v38_referencia, 
                 		     v38_num_ot 
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
		IF INFIELD(v38_codigo_veh) THEN
			CALL fl_ayuda_serie_veh(vg_codcia, vg_codloc, '00') 
							RETURNING r_serveh.*
			IF r_serveh.codigo_veh IS NOT NULL THEN
				LET rm_v38.v38_codigo_veh = r_serveh.codigo_veh
				DISPLAY BY NAME rm_v38.v38_codigo_veh
				DISPLAY r_serveh.chasis TO serie_veh	
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD v38_codigo_veh
		IF rm_v38.v38_codigo_veh IS NULL THEN
			CLEAR serie_veh
		ELSE
			CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, 
					             rm_v38.v38_codigo_veh)
							RETURNING r_v22.*
			IF r_v22.v22_chasis IS NULL THEN
				CALL fgl_winmessage(vg_producto,
                                                    'Vehículo no existe',
                                                    'exclamation')
				CLEAR serie_veh 
				NEXT FIELD v38_codigo_veh
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
							    'Esta serie no ha'||
							    ' sido recibida',
 		                                            'exclamation')
					LET continuar = 0
				END IF 
				IF r_v22.v22_estado = 'B' THEN
					CALL fgl_winmessage(vg_producto,
							    'Serie bloqueada',
 		                                            'exclamation')
					LET continuar = 0
				END IF 
				IF continuar = 0 THEN
					CLEAR serie_veh 
					NEXT FIELD v38_codigo_veh
				END IF
				DISPLAY r_v22.v22_chasis TO serie_veh	
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE r_serveh RECORD
        codigo_veh          LIKE veht022.v22_codigo_veh,
        chasis              LIKE veht022.v22_chasis,
        modelo              LIKE veht022.v22_modelo,
        cod_color           LIKE veht022.v22_cod_color,
        estado              LIKE veht022.v22_estado
END RECORD

DEFINE r_v38		RECORD LIKE veht038.*
DEFINE r_v22		RECORD LIKE veht022.*
DEFINE continuar        SMALLINT

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
        ON v38_orden_cheq, v38_estado, v38_codigo_veh, v38_referencia, 
	   v38_usuario 
	ON KEY(F2)
		IF INFIELD(v38_codigo_veh) THEN
			CALL fl_ayuda_serie_veh(vg_codcia, vg_codloc, '00') 
							RETURNING r_serveh.*
			IF r_serveh.codigo_veh IS NOT NULL THEN
				LET rm_v38.v38_codigo_veh = r_serveh.codigo_veh
				DISPLAY BY NAME rm_v38.v38_codigo_veh
				DISPLAY r_serveh.chasis TO serie_veh	
			END IF
		END IF
		IF INFIELD(v38_orden_cheq) THEN
			CALL fl_ayuda_orden_chequeo(vg_codcia, vg_codloc, 'T') 
				RETURNING r_v38.v38_orden_cheq, r_v38.v38_estado
			IF r_v38.v38_orden_cheq IS NOT NULL THEN
				LET rm_v38.v38_orden_cheq = r_v38.v38_orden_cheq
                          	DISPLAY BY NAME rm_v38.v38_orden_cheq
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD v38_codigo_veh
		LET rm_v38.v38_codigo_veh = GET_FLDBUF(v38_codigo_veh)
		IF rm_v38.v38_codigo_veh IS NULL THEN
			CLEAR serie_veh
		ELSE
			CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, 
					             rm_v38.v38_codigo_veh)
							RETURNING r_v22.*
			IF r_v22.v22_chasis IS NULL THEN
				CLEAR serie_veh 
			ELSE
				LET continuar = 1
				IF r_v22.v22_estado = 'F' THEN
					LET continuar = 0
				END IF 
				IF r_v22.v22_estado = 'P' THEN
					LET continuar = 0
				END IF 
				IF r_v22.v22_estado = 'B' THEN
					LET continuar = 0
				END IF 
				IF continuar = 0 THEN
					CLEAR serie_veh 
				END IF
				DISPLAY r_v22.v22_chasis TO serie_veh	
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

LET query = 'SELECT *, ROWID FROM veht038 ', 
            '	WHERE v38_compania  = ', vg_codcia,
	    '	  AND v38_localidad = ', vg_codloc,
	    '     AND ', expr_sql CLIPPED,	    
	    ' ORDER BY 1, 2, 3' 

PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v38.*, vm_rows[vm_num_rows]
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



FUNCTION control_bloquea_activa()

DEFINE resp    	CHAR(6)
DEFINE estado	CHAR(1)

LET int_flag = 0
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'Yes' THEN
	WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_del CURSOR FOR SELECT * FROM veht038 
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_v38.*
	IF status < 0 THEN
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN
	END IF

	LET estado = 'B'
	IF rm_v38.v38_estado <> 'A' THEN
		LET estado = 'A'
	END IF

	UPDATE veht038 SET v38_estado = estado WHERE CURRENT OF q_del
	COMMIT WORK
	CLOSE q_del
	WHENEVER ERROR STOP
	LET int_flag = 0 
	
	CALL fl_mensaje_registro_modificado()

	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_v38.* FROM veht038 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_v38.v38_orden_cheq, 
		rm_v38.v38_estado, 
		rm_v38.v38_codigo_veh,
	      	rm_v38.v38_referencia, 
		rm_v38.v38_num_ot, 
              	rm_v38.v38_usuario, 
		rm_v38.v38_fecing 

CALL muestra_etiquetas()
CALL muestra_contadores()

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
DEFINE r_v22			RECORD LIKE veht022.*

CASE rm_v38.v38_estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'B' LET nom_estado = 'BLOQUEADO'
	WHEN 'P' LET nom_estado = 'PROCESADO'
END CASE
DISPLAY nom_estado   TO n_estado

CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, rm_v38.v38_codigo_veh)
	RETURNING r_v22.*
DISPLAY r_v22.v22_chasis TO serie_veh 

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
