------------------------------------------------------------------------------
-- Titulo           : talp200.4gl - Mantenimiento Vehículos de Clientes
-- Elaboracion      : 08-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp200 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_tal		RECORD LIKE talt010.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp200.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'talp200'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
OPEN WINDOW wf AT 3,2 WITH 21 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_tal FROM "../forms/talf200_1"
DISPLAY FORM f_tal
INITIALIZE rm_tal.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
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
       	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
		CALL control_Modificacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
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
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o activar registro. '
                CALL bloquear_activar()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

CALL fl_retorna_usuario()
INITIALIZE rm_tal.* TO NULL
CLEAR tit_compania, tit_localidad, tit_nombre_cli, tit_est, tit_estado_tal
LET rm_tal.t10_compania = vg_codcia
LET rm_tal.t10_estado   = 'A'
LET rm_tal.t10_usuario  = vg_usuario
LET rm_tal.t10_fecing   = CURRENT
CALL muestra_estado()
CALL leer_datos()
IF NOT int_flag THEN
	LET rm_tal.t10_fecing  = CURRENT
	INSERT INTO talt010 VALUES (rm_tal.*)
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current = vm_num_rows
	DISPLAY BY NAME rm_tal.t10_fecing
	LET vm_r_rows[vm_row_current] = SQLCA.SQLERRD[6] 
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_tal.t10_estado = 'B' THEN
        CALL fl_mensaje_estado_bloqueado()
        RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM talt010
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_tal.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
CALL leer_datos_modificacion()
IF NOT int_flag THEN
	UPDATE talt010 SET t10_color       = rm_tal.t10_color,
			   t10_motor       = rm_tal.t10_motor, 
			   t10_placa       = rm_tal.t10_placa, 
			   t10_ano         = rm_tal.t10_ano
			WHERE CURRENT OF q_up
	CALL fl_mensaje_registro_modificado()
ELSE
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF
COMMIT WORK
WHENEVER ERROR STOP
 
END FUNCTION



FUNCTION control_consulta()
DEFINE codc_aux         LIKE talt000.t00_compania
DEFINE nomc_aux         LIKE gent001.g01_razonsocial
DEFINE codl_aux         LIKE gent002.g02_localidad
DEFINE noml_aux         LIKE gent002.g02_nombre
DEFINE codi_aux         LIKE cxct001.z01_codcli
DEFINE nomi_aux         LIKE cxct001.z01_nomcli
DEFINE codm_aux         LIKE talt004.t04_modelo
DEFINE nomm_aux         LIKE talt004.t04_linea
DEFINE codv_aux         LIKE veht022.v22_codigo_veh
DEFINE cliente		LIKE cxct001.z01_codcli
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE modelo           LIKE veht022.v22_modelo
DEFINE r_veh            RECORD LIKE veht022.*
DEFINE r_col            RECORD LIKE veht005.*
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER

LET int_flag = 0
INITIALIZE codc_aux TO NULL
INITIALIZE codl_aux TO NULL
INITIALIZE codi_aux TO NULL
INITIALIZE codv_aux TO NULL
INITIALIZE codm_aux TO NULL
INITIALIZE r_veh.* TO NULL
INITIALIZE r_col.* TO NULL
CLEAR FORM
CONSTRUCT BY NAME expr_sql ON t10_codcia_vta, t10_codloc_vta, t10_codveh_vta,
	t10_codcli, t10_modelo, t10_chasis, t10_color, t10_motor, t10_placa,
	t10_ano
	ON KEY(F2)
		IF infield(t10_codcia_vta) THEN
                        CALL fl_ayuda_companias_taller()
                                RETURNING codc_aux, nomc_aux
                        LET int_flag = 0
                        IF codc_aux IS NOT NULL THEN
                                DISPLAY codc_aux TO t10_codcia_vta
                                DISPLAY nomc_aux TO tit_compania
                        END IF
                END IF
		IF infield(t10_codloc_vta) THEN
                        CALL fl_ayuda_localidad(codc_aux)
                                RETURNING codl_aux, noml_aux
                        LET int_flag = 0
                        IF codl_aux IS NOT NULL THEN
                                DISPLAY codl_aux TO t10_codloc_vta
                                DISPLAY noml_aux TO tit_localidad
                        END IF
                END IF
		IF infield(t10_codveh_vta) THEN
		  IF codc_aux IS NOT NULL AND codl_aux IS NOT NULL THEN
                        CALL fl_ayuda_serie_veh_facturados(codc_aux,codl_aux)
                                RETURNING cliente, nomcli, codv_aux, modelo
                        LET int_flag = 0
                        IF codv_aux IS NOT NULL THEN
				CALL fl_lee_cod_vehiculo_veh(codc_aux,codl_aux,
								codv_aux)
					RETURNING r_veh.*
				CALL fl_lee_color_veh(codc_aux,
							r_veh.v22_cod_color)
					RETURNING r_col.*
				DISPLAY codv_aux TO t10_codveh_vta
				DISPLAY cliente TO t10_codcli
                                DISPLAY nomcli TO tit_nombre_cli
				DISPLAY modelo TO t10_modelo
				DISPLAY r_veh.v22_chasis TO t10_chasis
				DISPLAY r_col.v05_descri_base TO t10_color
				DISPLAY r_veh.v22_motor TO t10_motor
				DISPLAY r_veh.v22_ano TO t10_ano
                        END IF
		  ELSE
			CALL blanquear()
		  END IF
                END IF
		IF infield(t10_codcli) THEN
                        CALL fl_ayuda_cliente_general()
                                RETURNING codi_aux, nomi_aux
                        LET int_flag = 0
                        IF codi_aux IS NOT NULL THEN
                                DISPLAY codi_aux TO t10_codcli
                                DISPLAY nomi_aux TO tit_nombre_cli
                        END IF
                END IF
		IF infield(t10_modelo) THEN
                        CALL fl_ayuda_tipos_vehiculos(vg_codcia)
                                RETURNING codm_aux, nomm_aux
                        LET int_flag = 0
                        IF codm_aux IS NOT NULL THEN
                                DISPLAY codm_aux TO t10_modelo
                        END IF
                END IF
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM talt010 WHERE t10_compania = ' ||
		vg_codcia || ' AND ' || expr_sql CLIPPED || ' ORDER BY 2'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_tal.*, num_reg
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
	LET vm_r_rows[vm_num_rows] = num_reg
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
ELSE  
	LET vm_row_current = 1
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION leer_datos ()
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_cli            RECORD LIKE cxct001.*
DEFINE r_cia            RECORD LIKE gent001.*
DEFINE r_loc            RECORD LIKE gent002.*
DEFINE r_veh            RECORD LIKE veht022.*
DEFINE r_col            RECORD LIKE veht005.*
DEFINE codc_aux         LIKE talt000.t00_compania
DEFINE nomc_aux         LIKE gent001.g01_razonsocial
DEFINE codl_aux         LIKE gent002.g02_localidad
DEFINE noml_aux         LIKE gent002.g02_nombre
DEFINE codi_aux         LIKE cxct001.z01_codcli
DEFINE nomi_aux         LIKE cxct001.z01_nomcli
DEFINE codv_aux         LIKE veht022.v22_codigo_veh
DEFINE cliente		LIKE cxct001.z01_codcli
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE modelo           LIKE talt004.t04_modelo
DEFINE chasis           LIKE veht022.v22_chasis
DEFINE motor            LIKE veht022.v22_motor
DEFINE codcolor         LIKE veht022.v22_cod_color
DEFINE anio             LIKE veht022.v22_ano
DEFINE codm_aux         LIKE talt004.t04_modelo
DEFINE nomm_aux         LIKE talt004.t04_linea
DEFINE r_mod		RECORD LIKE talt004.*

LET int_flag = 0
INITIALIZE r_cli.* TO NULL
INITIALIZE r_cia.* TO NULL
INITIALIZE r_loc.* TO NULL
INITIALIZE r_veh.* TO NULL
INITIALIZE r_col.* TO NULL
INITIALIZE codc_aux TO NULL
INITIALIZE codl_aux TO NULL
INITIALIZE codi_aux TO NULL
INITIALIZE codv_aux TO NULL
INITIALIZE codm_aux TO NULL
INITIALIZE r_mod.* TO NULL
DISPLAY BY NAME rm_tal.t10_usuario, rm_tal.t10_fecing
INPUT BY NAME rm_tal.t10_codcia_vta, rm_tal.t10_codloc_vta,
	rm_tal.t10_codveh_vta, rm_tal.t10_codcli, rm_tal.t10_modelo,
	rm_tal.t10_chasis, rm_tal.t10_color, rm_tal.t10_motor, rm_tal.t10_placa,
	rm_tal.t10_ano
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_tal.t10_codcia_vta, rm_tal.t10_codloc_vta,
			rm_tal.t10_codveh_vta, rm_tal.t10_codcli,
			rm_tal.t10_modelo, rm_tal.t10_chasis,
			rm_tal.t10_color, rm_tal.t10_motor, rm_tal.t10_placa,
			rm_tal.t10_ano)
        	THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                		RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
                       		CLEAR FORM
                       		RETURN
                	END IF
		ELSE
			RETURN
		END IF
	ON KEY(F2)
		IF infield(t10_codcia_vta) THEN
                        CALL fl_ayuda_companias_taller()
                                RETURNING codc_aux, nomc_aux
                        LET int_flag = 0
                        IF codc_aux IS NOT NULL THEN
				LET rm_tal.t10_codcia_vta = codc_aux
                                DISPLAY BY NAME rm_tal.t10_codcia_vta
                                DISPLAY nomc_aux TO tit_compania
                        END IF
                END IF
		IF infield(t10_codloc_vta) THEN
                        CALL fl_ayuda_localidad(rm_tal.t10_codcia_vta)
                                RETURNING codl_aux, noml_aux
                        LET int_flag = 0
                        IF codl_aux IS NOT NULL THEN
				LET rm_tal.t10_codloc_vta = codl_aux
                                DISPLAY BY NAME rm_tal.t10_codloc_vta
                                DISPLAY noml_aux TO tit_localidad
                        END IF
                END IF
		IF infield(t10_codveh_vta) THEN
		  IF rm_tal.t10_codcia_vta IS NOT NULL
		  AND rm_tal.t10_codloc_vta IS NOT NULL THEN
                       CALL fl_ayuda_serie_veh_facturados(rm_tal.t10_codcia_vta,
							rm_tal.t10_codloc_vta)
                                RETURNING cliente, nomcli, codv_aux, modelo
                        LET int_flag = 0
                        IF codv_aux IS NOT NULL THEN
			     CALL fl_lee_cod_vehiculo_veh(rm_tal.t10_codcia_vta,
							rm_tal.t10_codloc_vta,
							codv_aux)
					RETURNING r_veh.*
				CALL fl_lee_color_veh(rm_tal.t10_codcia_vta,
							r_veh.v22_cod_color)
					RETURNING r_col.*
				LET rm_tal.t10_codveh_vta = codv_aux
				LET rm_tal.t10_codcli   = cliente
				LET rm_tal.t10_modelo   = modelo
				LET rm_tal.t10_chasis   = r_veh.v22_chasis
				LET rm_tal.t10_color    = r_col.v05_descri_base 
				LET rm_tal.t10_motor    = r_veh.v22_motor
				LET rm_tal.t10_ano      = r_veh.v22_ano
                                DISPLAY nomcli TO tit_nombre_cli
				DISPLAY BY NAME rm_tal.t10_codcli,
					rm_tal.t10_codveh_vta,rm_tal.t10_modelo,
					rm_tal.t10_chasis,rm_tal.t10_color,
					rm_tal.t10_motor,rm_tal.t10_ano
                        END IF
		  ELSE
			CALL blanquear()
		  END IF
                END IF
		IF infield(t10_codcli) THEN
                        CALL fl_ayuda_cliente_general()
                                RETURNING codi_aux, nomi_aux
                        LET int_flag = 0
                        IF codi_aux IS NOT NULL THEN
				LET rm_tal.t10_codcli = codi_aux
                                DISPLAY BY NAME rm_tal.t10_codcli
                                DISPLAY nomi_aux TO tit_nombre_cli
                        END IF
                END IF
		IF infield(t10_modelo) THEN
                        CALL fl_ayuda_tipos_vehiculos(vg_codcia)
                                RETURNING codm_aux, nomm_aux
                        LET int_flag = 0
                        IF codm_aux IS NOT NULL THEN
				LET rm_tal.t10_modelo = codm_aux 
                                DISPLAY BY NAME rm_tal.t10_modelo
                        END IF
                END IF
	BEFORE FIELD t10_chasis
		IF rm_tal.t10_codcli IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Ingrese el cliente primero','info')
			NEXT FIELD t10_codcli
		END IF
		IF rm_tal.t10_modelo IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Ingrese el modelo primero','info')
			NEXT FIELD t10_modelo
		END IF
	BEFORE FIELD t10_color
		IF rm_tal.t10_codcli IS NOT NULL
		AND rm_tal.t10_modelo IS NOT NULL
		AND rm_tal.t10_chasis IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Ingrese el chasis','info')
			NEXT FIELD t10_chasis
		END IF
	AFTER FIELD t10_codcia_vta
		IF rm_tal.t10_codcia_vta IS NOT NULL THEN
			CALL fl_lee_compania(rm_tal.t10_codcia_vta)
				RETURNING r_cia.*
			IF r_cia.g01_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Compañía no existe','exclamation')
				NEXT FIELD t10_codcia_vta
			END IF
			DISPLAY r_cia.g01_razonsocial TO tit_compania
			IF r_cia.g01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD t10_codcia_vta
			END IF
			IF rm_tal.t10_codloc_vta IS NOT NULL
			AND rm_tal.t10_codveh_vta IS NOT NULL THEN
				CALL validar_codigos_venta()
					RETURNING resul, r_veh.*
				IF resul = 1 THEN
					NEXT FIELD t10_codveh_vta
				END IF
			END IF 
		ELSE
			CLEAR tit_compania
		END IF
	AFTER FIELD t10_codloc_vta
		IF rm_tal.t10_codloc_vta IS NOT NULL THEN
			IF rm_tal.t10_codcia_vta IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Ingrese la compañía primero','exclamation')
				LET rm_tal.t10_codloc_vta = NULL
				CLEAR t10_codloc_vta, tit_localidad
				NEXT FIELD t10_codcia_vta
			END IF
			CALL fl_lee_localidad(rm_tal.t10_codcia_vta,
						rm_tal.t10_codloc_vta)
				RETURNING r_loc.*
			IF r_loc.g02_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Localidad no existe','exclamation')
				NEXT FIELD t10_codloc_vta
			END IF
			DISPLAY r_loc.g02_nombre TO tit_localidad
			IF r_loc.g02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD t10_codloc_vta
			END IF
			IF rm_tal.t10_codveh_vta IS NOT NULL THEN
				CALL validar_codigos_venta()
					RETURNING resul, r_veh.*
				IF resul = 1 THEN
					NEXT FIELD t10_codveh_vta
				END IF
			END IF 
		ELSE
			CLEAR tit_localidad
		END IF
	AFTER FIELD t10_codveh_vta	
		IF rm_tal.t10_codcia_vta IS NOT NULL
		AND rm_tal.t10_codloc_vta IS NOT NULL
		AND rm_tal.t10_codveh_vta IS NOT NULL THEN
			CALL validar_codigos_venta()
				RETURNING resul, r_veh.*
			IF resul = 1 THEN
				NEXT FIELD t10_codveh_vta
			END IF
		END IF 
	AFTER FIELD t10_codcli
                IF rm_tal.t10_codcli IS NOT NULL THEN
                        CALL fl_lee_cliente_general(rm_tal.t10_codcli)
                                RETURNING r_cli.*
                        IF r_cli.z01_codcli IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Cliente no existe','exclamation')
                                NEXT FIELD t10_codcli
                        END IF
                        DISPLAY r_cli.z01_nomcli TO tit_nombre_cli
                        IF r_cli.z01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD t10_codcli
                        END IF
                END IF
	AFTER FIELD t10_modelo
		IF rm_tal.t10_modelo IS NOT NULL THEN
			CALL fl_lee_tipo_vehiculo(vg_codcia,rm_tal.t10_modelo)
				RETURNING r_mod.*
			IF r_mod.t04_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Modelo no existe','exclamation')
				NEXT FIELD t10_modelo
			END IF
		END IF
	AFTER FIELD t10_chasis
                IF rm_tal.t10_chasis IS NOT NULL THEN
			CALL validar_clave() RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD t10_codcli
			END IF
                END IF
	AFTER FIELD t10_ano
		IF rm_tal.t10_ano IS NOT NULL THEN
			IF rm_tal.t10_ano > YEAR(TODAY) + 1 THEN
				CALL fgl_winmessage(vg_producto,'Año del vehículo es incorrecto','exclamation')
				NEXT FIELD t10_ano
			END IF
		END IF
	AFTER INPUT
		CALL validar_clave() RETURNING resul
		IF resul = 1 THEN
			NEXT FIELD t10_codcli
		END IF
		IF rm_tal.t10_codcia_vta IS NULL
		OR rm_tal.t10_codloc_vta IS NULL
		OR rm_tal.t10_codveh_vta IS NULL THEN
			CALL blanquear()
		END IF
		IF rm_tal.t10_modelo <> r_veh.v22_modelo
		OR rm_tal.t10_chasis <> r_veh.v22_chasis THEN
			CALL blanquear()
		END IF
END INPUT

END FUNCTION



FUNCTION blanquear()
LET rm_tal.t10_codcia_vta = NULL
LET rm_tal.t10_codloc_vta = NULL
LET rm_tal.t10_codveh_vta = NULL
CLEAR t10_codcia_vta, t10_codloc_vta,t10_codveh_vta,
	tit_compania,tit_localidad

END FUNCTION



FUNCTION validar_clave()
DEFINE r_tal_aux	RECORD LIKE talt010.*

INITIALIZE r_tal_aux.* TO NULL
CALL fl_lee_vehiculo_cliente_taller(vg_codcia,rm_tal.t10_codcli,
					rm_tal.t10_modelo,rm_tal.t10_chasis)
	RETURNING r_tal_aux.*
IF r_tal_aux.t10_compania IS NOT NULL THEN
	CALL fgl_winmessage(vg_producto,'Este vehículo con su cliente ya existe','exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION leer_datos_modificacion()
DEFINE resp		CHAR(6)

LET int_flag = 0
INPUT BY NAME rm_tal.t10_color, rm_tal.t10_motor, rm_tal.t10_placa,
	rm_tal.t10_ano
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_tal.t10_color, rm_tal.t10_motor,
			rm_tal.t10_placa, rm_tal.t10_ano)
        	THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                		RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
                       		CLEAR FORM
                       		RETURN
                	END IF
		ELSE
			RETURN
		END IF
	AFTER FIELD t10_ano
		IF rm_tal.t10_ano IS NOT NULL THEN
			IF rm_tal.t10_ano > YEAR(TODAY) + 1 THEN
				CALL fgl_winmessage(vg_producto,'Año del vehículo es incorrecto','exclamation')
				NEXT FIELD t10_ano
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION validar_codigos_venta()
DEFINE r_veh            RECORD LIKE veht022.*
DEFINE r_veh_fac        RECORD LIKE veht030.*
DEFINE r_cli            RECORD LIKE cxct001.*
DEFINE r_col            RECORD LIKE veht005.*
DEFINE r_cia            RECORD LIKE gent001.*
DEFINE r_loc            RECORD LIKE gent002.*

INITIALIZE r_veh.* TO NULL
INITIALIZE r_veh_fac.* TO NULL
INITIALIZE r_cli.* TO NULL
INITIALIZE r_col.* TO NULL
INITIALIZE r_cia.* TO NULL
INITIALIZE r_loc.* TO NULL
CALL fl_lee_cod_vehiculo_veh(rm_tal.t10_codcia_vta,rm_tal.t10_codloc_vta,
				rm_tal.t10_codveh_vta)
	RETURNING r_veh.*
IF r_veh.v22_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Este vehículo no existe','exclamation')
	RETURN 1, r_veh.*
END IF 
IF r_veh.v22_estado <> 'F' THEN
	CALL fgl_winmessage(vg_producto,'Este vehículo no ha sido facturado','exclamation')
	RETURN 1, r_veh.*
END IF
CALL fl_lee_cabecera_transaccion_veh(rm_tal.t10_codcia_vta,
				rm_tal.t10_codloc_vta, r_veh.v22_cod_tran,
				r_veh.v22_num_tran)
	RETURNING r_veh_fac.*
CALL fl_lee_cliente_general(r_veh_fac.v30_codcli)
	RETURNING r_cli.*
CALL fl_lee_color_veh(rm_tal.t10_codcia_vta,r_veh.v22_cod_color)
	RETURNING r_col.*
LET rm_tal.t10_codcli = r_veh_fac.v30_codcli
DISPLAY r_cli.z01_nomcli TO tit_nombre_cli
LET rm_tal.t10_modelo = r_veh.v22_modelo
LET rm_tal.t10_chasis = r_veh.v22_chasis
LET rm_tal.t10_color  = r_col.v05_descri_base
LET rm_tal.t10_motor  = r_veh.v22_motor
LET rm_tal.t10_ano    = r_veh.v22_ano
DISPLAY BY NAME rm_tal.t10_codcli, rm_tal.t10_modelo, rm_tal.t10_chasis,
		rm_tal.t10_color, rm_tal.t10_motor, rm_tal.t10_ano
RETURN 0, r_veh.*

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL mostrar_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL mostrar_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 68
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_cli_gen        RECORD LIKE cxct001.*
DEFINE r_cia            RECORD LIKE gent001.*
DEFINE r_loc            RECORD LIKE gent002.*

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_tal.* FROM talt010 WHERE ROWID = num_registro	
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_tal.t10_codcia_vta, rm_tal.t10_codloc_vta,
			rm_tal.t10_codveh_vta, rm_tal.t10_codcli,
			rm_tal.t10_modelo, rm_tal.t10_chasis,
			rm_tal.t10_color, rm_tal.t10_motor, rm_tal.t10_placa,
			rm_tal.t10_ano,	rm_tal.t10_usuario, rm_tal.t10_fecing
	CALL fl_lee_compania(rm_tal.t10_codcia_vta) RETURNING r_cia.*
	DISPLAY r_cia.g01_razonsocial TO tit_compania
	CALL fl_lee_localidad(rm_tal.t10_codcia_vta,rm_tal.t10_codloc_vta)
		RETURNING r_loc.*
	DISPLAY r_loc.g02_nombre TO tit_localidad
	CALL fl_lee_cliente_general(rm_tal.t10_codcli) RETURNING r_cli_gen.*
        DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
	CALL muestra_estado()
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir   CHAR(6)
                                                                                
IF vm_num_rows = 0 THEN
        CALL fl_mensaje_consultar_primero()
        RETURN
END IF
LET int_flag = 0
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_ba CURSOR FOR SELECT * FROM talt010
        WHERE ROWID = vm_r_rows[vm_row_current]
        FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_tal.*
IF STATUS < 0 THEN
        COMMIT WORK
        CALL fl_mensaje_bloqueo_otro_usuario()
        WHENEVER ERROR STOP
        RETURN
END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING confir
IF confir = 'Yes' THEN
        LET int_flag = 1
        CALL bloquea_activa_registro()
END IF
COMMIT WORK
WHENEVER ERROR STOP
                                                                                
END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado   CHAR(1)
                                                                                
IF rm_tal.t10_estado = 'A' THEN
        DISPLAY 'BLOQUEADO' TO tit_estado_tal
        LET estado = 'B'
ELSE
        DISPLAY 'ACTIVO' TO tit_estado_tal
        LET estado = 'A'
END IF
DISPLAY estado TO tit_est
UPDATE talt010 SET t10_estado = estado WHERE CURRENT OF q_ba
LET rm_tal.t10_estado = estado
                                                                                
END FUNCTION



FUNCTION muestra_estado()
IF rm_tal.t10_estado = 'A' THEN
        DISPLAY 'ACTIVO' TO tit_estado_tal
ELSE
        DISPLAY 'BLOQUEADO' TO tit_estado_tal
END IF
DISPLAY rm_tal.t10_estado TO tit_est
                                                                                
END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
