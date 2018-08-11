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
                                                                                
DEFINE rm_t00		RECORD LIKE talt000.*
DEFINE rm_t00_2		RECORD LIKE talt000.*
DEFINE rm_z01		RECORD LIKE cxct001.*
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g00		RECORD LIKE gent000.*
DEFINE rm_g14		RECORD LIKE gent014.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp100.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'talp100'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 21
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_pcia AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu, BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_pcia FROM '../forms/talf100_1'
ELSE
	OPEN FORM f_pcia FROM '../forms/talf100_1c'
END IF
DISPLAY FORM f_pcia
INITIALIZE rm_t00.* TO NULL
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
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1500)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON t00_compania, t00_cia_vehic, t00_codcli_int,
	t00_factor_mb, t00_factor_ma, t00_seudo_tarea, t00_valor_tarea,
	t00_req_tal, t00_dias_dev, t00_dev_mes, t00_dias_pres, t00_dias_elim,
	t00_elim_mes, t00_anopro, t00_mespro
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t00_compania) THEN
		     CALL fl_ayuda_compania()
			RETURNING rm_g01.g01_compania
		     IF rm_g01.g01_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_g01.g01_compania)
				RETURNING rm_g01.*
			LET rm_t00.t00_compania = rm_g01.g01_compania
			DISPLAY BY NAME rm_t00.t00_compania
			DISPLAY rm_g01.g01_razonsocial TO nom_cia
		     END IF
		END IF
		IF INFIELD(t00_cia_vehic) THEN
		     CALL fl_ayuda_compania()
			RETURNING rm_g01.g01_compania
		     IF rm_g01.g01_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_g01.g01_compania)
				RETURNING rm_g01.*
			LET rm_t00.t00_cia_vehic = rm_g01.g01_compania
			DISPLAY BY NAME rm_t00.t00_cia_vehic
			DISPLAY rm_g01.g01_razonsocial TO nom_cia_veh
		     END IF
		END IF
		IF INFIELD(t00_codcli_int) THEN
                     CALL fl_ayuda_cliente_general()
                     RETURNING rm_z01.z01_codcli, rm_z01.z01_nomcli
                     IF rm_z01.z01_codcli IS NOT NULL THEN
			LET rm_t00.t00_codcli_int = rm_z01.z01_codcli
                        DISPLAY BY NAME rm_t00.t00_codcli_int
			DISPLAY  rm_z01.z01_nomcli TO nom_cli
                     END IF
                END IF
                LET int_flag = 0
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
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
FOREACH q_pcia INTO rm_t00.*, vm_r_rows[vm_num_rows]
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
INITIALIZE rm_t00.* TO NULL
LET vm_flag_mant            = 'I'
LET rm_t00.t00_valor_tarea = 'O'
LET rm_t00.t00_estado      = 'A'
LET rm_t00.t00_dev_mes     = 'S'
LET rm_t00.t00_req_tal     = 'S'
LET rm_t00.t00_elim_mes    = 'N'
LET rm_t00.t00_anopro      = YEAR(vg_fecha)
LET rm_t00.t00_mespro      = MONTH(vg_fecha)
DISPLAY BY NAME rm_t00.t00_estado, rm_t00.t00_anopro, rm_t00.t00_mespro
DISPLAY 'ACTIVO' TO tit_estado
CALL lee_datos()
IF NOT int_flag THEN
	INSERT INTO talt000 VALUES (rm_t00.*)
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
IF rm_t00.t00_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM talt000
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_t00.*
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos()
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	RETURN
END IF
UPDATE talt000 SET * = rm_t00.* WHERE CURRENT OF q_up
COMMIT WORK
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_bloqueo_activacion()
DEFINE resp     CHAR(6)
DEFINE i        SMALLINT
DEFINE mensaje  VARCHAR(100)
DEFINE estado   CHAR(1)
                                                                                

IF rm_t00.t00_compania IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
        RETURN
END IF

LET mensaje = 'Seguro de bloquear'
IF rm_t00.t00_estado <> 'A' THEN
        LET mensaje = 'Seguro de activar'
END IF
LET mensaje = mensaje CLIPPED, ' este registro ?'
LET int_flag = 0
CALL fl_hacer_pregunta(mensaje, 'No') RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_del CURSOR FOR
	SELECT * FROM talt000
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_del
FETCH q_del INTO rm_t00.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET estado = 'B'
IF rm_t00.t00_estado <> 'A' THEN
	LET estado = 'A'
END IF
UPDATE talt000 SET t00_estado = estado WHERE CURRENT OF q_del
COMMIT WORK
CALL fl_mensaje_registro_modificado()
CLEAR FORM
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION lee_datos()
DEFINE resp		CHAR(6)

OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME rm_t00.t00_compania, rm_t00.t00_cia_vehic, rm_t00.t00_codcli_int,
	rm_t00.t00_factor_mb, rm_t00.t00_factor_ma, rm_t00.t00_seudo_tarea,
	rm_t00.t00_valor_tarea, rm_t00.t00_req_tal, rm_t00.t00_dias_dev,
	rm_t00.t00_dev_mes, rm_t00.t00_dias_pres, rm_t00.t00_dias_elim,
	rm_t00.t00_elim_mes
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_t00.t00_compania, rm_t00.t00_cia_vehic,
				 rm_t00.t00_codcli_int, rm_t00.t00_factor_mb,
				 rm_t00.t00_factor_ma, rm_t00.t00_seudo_tarea,
				 rm_t00.t00_valor_tarea, rm_t00.t00_req_tal,
				 rm_t00.t00_dias_dev, rm_t00.t00_dev_mes,
				 rm_t00.t00_dias_pres, rm_t00.t00_dias_elim,
				 rm_t00.t00_elim_mes)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				IF vm_flag_mant = 'I' THEN
					CLEAR FORM
				END IF
				EXIT INPUT
			END IF
		ELSE
			IF vm_flag_mant = 'I' THEN
				CLEAR FORM
			END IF
			EXIT INPUT
		END IF       	
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t00_compania) THEN
		     CALL fl_ayuda_compania()
			RETURNING rm_g01.g01_compania
		     IF rm_g01.g01_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_g01.g01_compania)
				RETURNING rm_g01.*
			LET rm_t00.t00_compania = rm_g01.g01_compania
			DISPLAY BY NAME rm_t00.t00_compania
			DISPLAY rm_g01.g01_razonsocial TO nom_cia
		     END IF
		END IF
		IF INFIELD(t00_cia_vehic) THEN
		     CALL fl_ayuda_compania()
			RETURNING rm_g01.g01_compania
		     IF rm_g01.g01_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_g01.g01_compania)
				RETURNING rm_g01.*
			LET rm_t00.t00_cia_vehic = rm_g01.g01_compania
			DISPLAY BY NAME rm_t00.t00_cia_vehic
			DISPLAY rm_g01.g01_razonsocial TO nom_cia_veh
		     END IF
		END IF
		IF INFIELD(t00_codcli_int) THEN
                     CALL fl_ayuda_cliente_general()
                     RETURNING rm_z01.z01_codcli, rm_z01.z01_nomcli
                     IF rm_z01.z01_codcli IS NOT NULL THEN
			LET rm_t00.t00_codcli_int = rm_z01.z01_codcli
                        DISPLAY BY NAME rm_t00.t00_codcli_int
			DISPLAY  rm_z01.z01_nomcli TO nom_cli
                     END IF
                END IF
                LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD t00_compania
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD t00_compania
		IF rm_t00.t00_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_t00.t00_compania)
				RETURNING rm_g01.*
			IF rm_g01.g01_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe la compañía.','exclamation')
				NEXT FIELD t00_compania
			END IF
			DISPLAY rm_g01.g01_razonsocial TO nom_cia
			CALL fl_lee_configuracion_taller(rm_t00.t00_compania)
				RETURNING rm_t00_2.*
			IF rm_t00_2.t00_compania IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Ya existe configuración para esta compañía.','exclamation')
				NEXT FIELD t00_compania
			END IF
		ELSE
			CLEAR nom_cia
		END IF
	AFTER FIELD t00_cia_vehic
		IF rm_t00.t00_cia_vehic IS NOT NULL THEN
			CALL fl_lee_compania(rm_t00.t00_cia_vehic)
				RETURNING rm_g01.*
			IF rm_g01.g01_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe la compañía.','exclamation')
				NEXT FIELD t00_cia_veh
			END IF
			DISPLAY rm_g01.g01_razonsocial TO nom_cia_veh
		ELSE
			CLEAR nom_cia_veh
		END IF
	AFTER FIELD t00_codcli_int
		IF rm_t00.t00_codcli_int IS NOT NULL THEN
                     CALL fl_lee_cliente_general(rm_t00.t00_codcli_int)
                     RETURNING rm_z01.*
                     IF rm_z01.z01_nomcli IS NULL THEN
			CALL fl_mostrar_mensaje('No existe el cliente.','exclamation')
                        NEXT FIELD t00_codcli_int
                     END IF
                     DISPLAY rm_z01.z01_nomcli TO nom_cli
                ELSE
                        CLEAR nom_cli
		END IF
	AFTER FIELD t00_factor_mb
		IF rm_t00.t00_factor_mb IS NOT NULL THEN
			CALL fl_lee_configuracion_facturacion()
                     		RETURNING rm_g00.*
                     	IF rm_g00.g00_serial IS NULL THEN
				CALL fl_mostrar_mensaje('No existe la configuración para la facturación.','stop')
				NEXT FIELD t00_factor_mb
                     	END IF
			IF rm_g00.g00_moneda_alt IS NULL
			OR rm_g00.g00_moneda_alt = ''
			THEN
				LET rm_t00.t00_factor_ma = 0
				DISPLAY BY NAME rm_t00.t00_factor_ma
				NEXT FIELD NEXT
			END IF
			CALL fl_lee_factor_moneda(rm_g00.g00_moneda_base,
						  rm_g00.g00_moneda_alt)
				RETURNING rm_g14.*
			IF rm_g14.g14_serial IS NULL THEN
				CALL fl_mostrar_mensaje('No existe la conversion entre monedas.','stop')
				NEXT FIELD t00_factor_mb
			END IF
			LET rm_t00.t00_factor_ma = rm_t00.t00_factor_mb *
						    rm_g14.g14_tasa
			DISPLAY BY NAME rm_t00.t00_factor_ma
		END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_t00.* FROM talt000 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_t00.t00_compania, rm_t00.t00_cia_vehic,
		rm_t00.t00_codcli_int, rm_t00.t00_factor_mb,
		rm_t00.t00_factor_ma, rm_t00.t00_seudo_tarea,
		rm_t00.t00_req_tal, rm_t00.t00_dias_dev, rm_t00.t00_dev_mes,
		rm_t00.t00_valor_tarea, rm_t00.t00_estado, rm_t00.t00_dias_pres,
		rm_t00.t00_dias_elim, rm_t00.t00_elim_mes, rm_t00.t00_anopro,
		rm_t00.t00_mespro
CALL fl_lee_cliente_general(rm_t00.t00_codcli_int) RETURNING rm_z01.*
CALL fl_lee_compania(rm_t00.t00_compania) RETURNING rm_g01.*
DISPLAY rm_g01.g01_razonsocial TO nom_cia
CALL fl_lee_compania(rm_t00.t00_cia_vehic) RETURNING rm_g01.*
DISPLAY rm_g01.g01_razonsocial TO nom_cia_veh
IF rm_t00.t00_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF
DISPLAY rm_z01.z01_nomcli TO nom_cli

END FUNCTION


                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
DEFINE nrow                     SMALLINT
                                                                                
LET nrow = 17
IF vg_gui = 1 THEN
	LET nrow = 1
END IF
DISPLAY "" AT nrow, 1
DISPLAY row_current, " de ", num_rows AT nrow, 67

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
