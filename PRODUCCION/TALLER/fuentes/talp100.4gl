-------------------------------------------------------------------------------
-- Titulo               : talp100.4gl -- Mantenimiento Configuración parametros
--					 por Compañia
-- Elaboración          : 11-sep-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun  talp100.4gl base TA 1 
-- Ultima Correción     : 11-sep-2001
-- Motivo Corrección    : 1
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_pcia   RECORD LIKE talt000.*
DEFINE rm_pcia2  RECORD LIKE talt000.*
DEFINE rm_cli    RECORD LIKE cxct001.*
DEFINE rm_cia    RECORD LIKE gent001.*
DEFINE rm_conf   RECORD LIKE gent000.*
DEFINE rm_cmon   RECORD LIKE gent014.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)

MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp100.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'talp100'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_pcia AT 3,2 WITH 18 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_pcia FROM '../forms/talf100_1'
DISPLAY FORM f_pcia
INITIALIZE rm_pcia.* TO NULL
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
                IF vm_num_rows > 0 THEN
                        CALL control_modificacion()
                ELSE
			CALL fl_mensaje_consultar_primero()
		END IF
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
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		IF vm_row_current < vm_num_rows THEN
			LET vm_row_current = vm_row_current + 1 
		END IF	
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		IF vm_row_current > 1 THEN
			LET vm_row_current = vm_row_current - 1 
		END IF
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
        COMMAND KEY('E') 'Bloquear/Activar' 'Bloquear o activar registro. '
                CALL control_bloqueo_activacion()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON t00_compania, t00_cia_vehic, t00_codcli_int,
		 t00_cliente_final,
		 t00_factor_mb, t00_factor_ma, t00_seudo_tarea, t00_req_tal,
		 t00_dias_dev, t00_dev_mes
	ON KEY(F2)
		IF INFIELD(t00_compania) THEN
		     CALL fl_ayuda_compania()
			RETURNING rm_cia.g01_compania
		     IF rm_cia.g01_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_cia.g01_compania)
				RETURNING rm_cia.*
			LET rm_pcia.t00_compania = rm_cia.g01_compania
			DISPLAY BY NAME rm_pcia.t00_compania
			DISPLAY rm_cia.g01_razonsocial TO nom_cia
		     END IF
		END IF
		IF INFIELD(t00_cia_vehic) THEN
		     CALL fl_ayuda_compania()
			RETURNING rm_cia.g01_compania
		     IF rm_cia.g01_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_cia.g01_compania)
				RETURNING rm_cia.*
			LET rm_pcia.t00_cia_vehic = rm_cia.g01_compania
			DISPLAY BY NAME rm_pcia.t00_cia_vehic
			DISPLAY rm_cia.g01_razonsocial TO nom_cia_veh
		     END IF
		END IF
		IF INFIELD(t00_codcli_int) THEN
                     CALL fl_ayuda_cliente_general()
                     RETURNING rm_cli.z01_codcli, rm_cli.z01_nomcli
                     IF rm_cli.z01_codcli IS NOT NULL THEN
			LET rm_pcia.t00_codcli_int = rm_cli.z01_codcli
                        DISPLAY BY NAME rm_pcia.t00_codcli_int
			DISPLAY  rm_cli.z01_nomcli TO nom_cli
                     END IF
                END IF
                LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM talt000 WHERE ', expr_sql CLIPPED,
		' ORDER BY 1'
PREPARE cons FROM query
DECLARE q_pcia CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_pcia INTO rm_pcia.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_ingreso()

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_pcia.* TO NULL
LET vm_flag_mant          = 'I'
LET rm_pcia.t00_valor_tarea= 'O'
LET rm_pcia.t00_estado     = 'A'
LET rm_pcia.t00_dev_mes    = 'S'
LET rm_pcia.t00_req_tal    = 'S'
DISPLAY BY NAME rm_pcia.t00_estado
DISPLAY 'ACTIVO' TO tit_estado
CALL lee_datos()
IF NOT int_flag THEN
	INSERT INTO talt000 VALUES (rm_pcia.*)
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current = vm_num_rows
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_modificacion()

LET vm_flag_mant      = 'M'
IF rm_pcia.t00_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM talt000 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_pcia.*
IF status < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE talt000 SET * = rm_pcia.*
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE 
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CLOSE q_up

END FUNCTION



FUNCTION control_bloqueo_activacion()
DEFINE resp     CHAR(6)
DEFINE i        SMALLINT
DEFINE mensaje  VARCHAR(20)
DEFINE estado   CHAR(1)
                                                                                
LET int_flag = 0

IF rm_pcia.t00_compania IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
        RETURN
END IF

LET mensaje = 'Seguro de bloquear'
IF rm_pcia.t00_estado <> 'A' THEN
        LET mensaje = 'Seguro de activar'
END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
        RETURNING resp
IF resp = 'Yes' THEN
WHENEVER ERROR CONTINUE
        BEGIN WORK
        DECLARE q_del CURSOR FOR SELECT * FROM talt000
                WHERE ROWID = vm_r_rows[vm_row_current]
                FOR UPDATE
        OPEN q_del
        FETCH q_del INTO rm_pcia.*
        IF status < 0 THEN
                COMMIT WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
                WHENEVER ERROR STOP
                RETURN
        END IF
        LET estado = 'B'
        IF rm_pcia.t00_estado <> 'A' THEN
                LET estado = 'A'
        END IF
        UPDATE talt000 SET t00_estado = estado WHERE CURRENT OF q_del
        COMMIT WORK
        LET int_flag = 1
	CALL fl_mensaje_registro_modificado()
        CLEAR FORM
        CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
                                                                                
END FUNCTION



FUNCTION lee_datos()
DEFINE           resp      CHAR(6)
DEFINE 	r_z01			RECORD LIKE cxct001.*
                                                                                
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME rm_pcia.t00_compania,rm_pcia.t00_cia_vehic,rm_pcia.t00_codcli_int, 	      rm_pcia.t00_factor_mb, rm_pcia.t00_factor_ma,
		  rm_pcia.t00_cliente_final,
	      rm_pcia.t00_seudo_tarea, rm_pcia.t00_req_tal,
	      rm_pcia.t00_dias_dev, rm_pcia.t00_dev_mes,
              rm_pcia.t00_valor_tarea
              WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	 IF field_touched(rm_pcia.t00_compania, rm_pcia.t00_cia_vehic,
rm_pcia.t00_codcli_int, rm_pcia.t00_factor_mb, rm_pcia.t00_factor_ma, rm_pcia.t00_seudo_tarea, rm_pcia.t00_req_tal, rm_pcia.t00_dev_mes, rm_pcia.t00_dias_dev)
                 THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                             LET int_flag = 1
			    IF vm_flag_mant = 'I' THEN
                                	CLEAR FORM
			    END IF
                            RETURN
                        END IF
                ELSE
			IF vm_flag_mant = 'I' THEN
                	        CLEAR FORM
			END IF
                        RETURN
                END IF       	
	ON KEY(F2)
		IF INFIELD(t00_compania) THEN
		     CALL fl_ayuda_compania()
			RETURNING rm_cia.g01_compania
		     IF rm_cia.g01_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_cia.g01_compania)
				RETURNING rm_cia.*
			LET rm_pcia.t00_compania = rm_cia.g01_compania
			DISPLAY BY NAME rm_pcia.t00_compania
			DISPLAY rm_cia.g01_razonsocial TO nom_cia
		     END IF
		END IF
		IF INFIELD(t00_cia_vehic) THEN
		     CALL fl_ayuda_compania()
			RETURNING rm_cia.g01_compania
		     IF rm_cia.g01_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_cia.g01_compania)
				RETURNING rm_cia.*
			LET rm_pcia.t00_cia_vehic = rm_cia.g01_compania
			DISPLAY BY NAME rm_pcia.t00_cia_vehic
			DISPLAY rm_cia.g01_razonsocial TO nom_cia_veh
		     END IF
		END IF
		IF INFIELD(t00_codcli_int) THEN
        	CALL fl_ayuda_cliente_general()
                     RETURNING rm_cli.z01_codcli, rm_cli.z01_nomcli
            IF rm_cli.z01_codcli IS NOT NULL THEN
				LET rm_pcia.t00_codcli_int = rm_cli.z01_codcli
                DISPLAY BY NAME rm_pcia.t00_codcli_int
				DISPLAY  rm_cli.z01_nomcli TO nom_cli
            END IF
        END IF
		IF INFIELD(t00_cliente_final) THEN
        	CALL fl_ayuda_cliente_general()
                     RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
            IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_pcia.t00_cliente_final = r_z01.z01_codcli
                DISPLAY BY NAME rm_pcia.t00_cliente_final
				DISPLAY  r_z01.z01_nomcli TO nom_cli_final
            END IF
        END IF
        LET int_flag = 0
	BEFORE  FIELD t00_compania
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD t00_compania
		IF rm_pcia.t00_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_pcia.t00_compania)
				RETURNING rm_cia.*
			IF rm_cia.g01_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la compañía ','exclamation')
				NEXT FIELD t00_compania
			END IF
			DISPLAY rm_cia.g01_razonsocial TO nom_cia
			CALL fl_lee_configuracion_taller(rm_pcia.t00_compania)
				RETURNING rm_pcia2.*
			IF rm_pcia2.t00_compania IS NOT NULL THEN
				CALL fgl_winmessage(vg_producto, 'Ya existe configuración para esta compañía ','exclamation')
				NEXT FIELD t00_compania
			END IF
		ELSE
			CLEAR nom_cia
		END IF
	AFTER FIELD t00_cia_vehic
		IF rm_pcia.t00_cia_vehic IS NOT NULL THEN
			CALL fl_lee_compania(rm_pcia.t00_cia_vehic)
				RETURNING rm_cia.*
			IF rm_cia.g01_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la compañía ','exclamation')
				NEXT FIELD t00_cia_veh
			END IF
			DISPLAY rm_cia.g01_razonsocial TO nom_cia_veh
		ELSE
			CLEAR nom_cia_veh
		END IF
	AFTER FIELD t00_codcli_int
		IF rm_pcia.t00_codcli_int IS NOT NULL THEN
                     CALL fl_lee_cliente_general(rm_pcia.t00_codcli_int)
                     RETURNING rm_cli.*
                     IF rm_cli.z01_nomcli IS NULL THEN
                           CALL fgl_winmessage(vg_producto, 'No existe el client
e ','exclamation')
                           NEXT FIELD t00_codcli_int
                     END IF
                     DISPLAY rm_cli.z01_nomcli TO nom_cli
                ELSE
                        CLEAR nom_cli
		END IF
	AFTER FIELD t00_cliente_final
		IF rm_pcia.t00_cliente_final IS NOT NULL THEN
                     CALL fl_lee_cliente_general(rm_pcia.t00_cliente_final)
                     RETURNING r_z01.*
                     IF r_z01.z01_nomcli IS NULL THEN
                           CALL fgl_winmessage(vg_producto, 'No existe el client
e ','exclamation')
                           NEXT FIELD t00_cliente_final
                     END IF
                     DISPLAY r_z01.z01_nomcli TO nom_cli_final
                ELSE
                        CLEAR nom_cli_final
		END IF
	AFTER FIELD t00_factor_mb
		IF rm_pcia.t00_factor_mb IS NOT NULL THEN
			CALL fl_lee_configuracion_facturacion()
                     		RETURNING rm_conf.*
                     	IF rm_conf.g00_serial IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe la configuración para la facturación ', 'stop')
				NEXT FIELD t00_factor_mb
                     	END IF
			IF rm_conf.g00_moneda_alt IS NULL
			OR rm_conf.g00_moneda_alt = ''
			THEN
				LET rm_pcia.t00_factor_ma = 0
				DISPLAY BY NAME rm_pcia.t00_factor_ma
				NEXT FIELD NEXT
			END IF
			CALL fl_lee_factor_moneda(rm_conf.g00_moneda_base,
						  rm_conf.g00_moneda_alt)
				RETURNING rm_cmon.*
			IF rm_cmon.g14_serial IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe la conversion entre monedas ', 'stop')
				NEXT FIELD t00_factor_mb
			END IF
			LET rm_pcia.t00_factor_ma = rm_pcia.t00_factor_mb *
						    rm_cmon.g14_tasa
			DISPLAY BY NAME rm_pcia.t00_factor_ma
		END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_z01		RECORD LIKE cxct001.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_pcia.* FROM talt000 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_pcia.t00_compania, 	rm_pcia.t00_cia_vehic, 
		rm_pcia.t00_codcli_int, rm_pcia.t00_cliente_final,	
		rm_pcia.t00_factor_mb, 
		rm_pcia.t00_factor_ma, 	rm_pcia.t00_seudo_tarea, 
		rm_pcia.t00_req_tal, 	rm_pcia.t00_dias_dev, 
		rm_pcia.t00_dev_mes, 	rm_pcia.t00_valor_tarea, 
		rm_pcia.t00_estado

CALL fl_lee_cliente_general(rm_pcia.t00_codcli_int)
	RETURNING rm_cli.*
CALL fl_lee_cliente_general(rm_pcia.t00_cliente_final)
	RETURNING r_z01.*
CALL fl_lee_compania(rm_pcia.t00_compania)
	RETURNING rm_cia.*
DISPLAY rm_cia.g01_razonsocial TO nom_cia
CALL fl_lee_compania(rm_pcia.t00_cia_vehic)
	RETURNING rm_cia.*
DISPLAY rm_cia.g01_razonsocial TO nom_cia_veh
IF rm_pcia.t00_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF
DISPLAY rm_cli.z01_nomcli TO nom_cli

END FUNCTION


                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION

                                                                                
                                                                                
FUNCTION validar_parametros()
                                                                                
CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'sto
p')
        EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'st
op')
        EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
     CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 			 'stop')
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
      CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 			  'stop')
      EXIT PROGRAM
END IF
                                                                                
END FUNCTION

