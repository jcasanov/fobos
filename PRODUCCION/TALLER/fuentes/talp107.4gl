-------------------------------------------------------------------------------
-- Titulo               : talp107.4gl -- Mantenimiento Tareas
-- Elaboración          : 10-sep-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun talp107 base TA 1 
-- Ultima Correción     : 21-ene-2002
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_t00		RECORD LIKE talt000.*
DEFINE rm_t07		RECORD LIKE talt007.*
DEFINE rm_t07_2		RECORD LIKE talt007.*
DEFINE rm_conf		RECORD LIKE gent000.*
DEFINE rm_cmon		RECORD LIKE gent014.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp107.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'talp107'
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
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*
IF rm_t00.t00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurada compania en el modulo del TALLER.', 'stop')
	EXIT PROGRAM
END IF
LET vm_max_rows = 1000
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 19
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_talf107_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_talf107_1 FROM '../forms/talf107_1'
ELSE
	OPEN FORM f_talf107_1 FROM '../forms/talf107_1c'
END IF
DISPLAY FORM f_talf107_1
INITIALIZE rm_t07.* TO NULL
LET vm_num_rows    = 0
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
        COMMAND KEY('E') 'Bloquear/Activar' 'Bloquear o activar registro. '
                CALL control_bloqueo_activacion()
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
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU
CLOSE WINDOW w_talf107_1
EXIT PROGRAM

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(700)
DEFINE query		CHAR(1500)

INITIALIZE rm_t07.* TO NULL
CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON t07_codtarea, t07_nombre, t07_pto_default,
	t07_val_defa_mb, t07_val_defa_ma, t07_tipo, t07_modif_desc,
	t07_dscmax_ger, t07_dscmax_jef, t07_dscmax_ven, t07_usuario, t07_fecing
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
	ON KEY(F1, CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t07_codtarea) THEN
			CALL fl_ayuda_tempario(vg_codcia, 'T')
				RETURNING rm_t07.t07_codtarea, rm_t07.t07_nombre
			IF rm_t07.t07_codtarea IS NOT NULL THEN
				DISPLAY BY NAME rm_t07.t07_codtarea,
						rm_t07.t07_nombre
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
LET query = 'SELECT *, ROWID ',
		' FROM talt007 ',
		' WHERE t07_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 1, 2, 3'
PREPARE cons FROM query
DECLARE q_tar CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_tar INTO rm_t07.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
        CLEAR FORM
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_ingreso()

CLEAR FORM
INITIALIZE rm_t07.* TO NULL
LET vm_flag_mant           = 'I'
LET rm_t07.t07_compania    = vg_codcia
LET rm_t07.t07_fecing      = CURRENT
LET rm_t07.t07_usuario     = vg_usuario
LET rm_t07.t07_tipo        = 'P'
LET rm_t07.t07_estado      = 'A'
LET rm_t07.t07_modif_desc  = 'N'
LET rm_t07.t07_pto_default = 0
LET rm_t07.t07_val_defa_mb = 0
LET rm_t07.t07_val_defa_ma = 0
LET rm_t07.t07_dscmax_ger  = 0
LET rm_t07.t07_dscmax_jef  = 0
LET rm_t07.t07_dscmax_ven  = 0
DISPLAY BY NAME rm_t07.t07_estado, rm_t07.t07_fecing, rm_t07.t07_usuario
DISPLAY 'ACTIVO' TO tit_estado
CALL lee_datos()
IF NOT int_flag THEN
	INSERT INTO talt007 VALUES (rm_t07.*)
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
IF rm_t07.t07_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM talt007
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_t07.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET rm_t07_2.t07_nombre = rm_t07.t07_nombre
CALL lee_datos()
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	RETURN
END IF
UPDATE talt007
	SET * = rm_t07.*
	WHERE CURRENT OF q_up
COMMIT WORK
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_bloqueo_activacion()
DEFINE resp		CHAR(6)
DEFINE i		SMALLINT
DEFINE mensaje		VARCHAR(20)
DEFINE estado		CHAR(1)

LET int_flag = 0
IF rm_t07.t07_codtarea IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
        RETURN
END IF
IF rm_t00.t00_seudo_tarea = rm_t07.t07_codtarea THEN
	CALL fl_mostrar_mensaje('No puede Bloquear/Activar la tarea por defecto del modulo TALLER.', 'exclamation')
        RETURN
END IF
LET mensaje = 'Seguro de bloquear'
IF rm_t07.t07_estado <> 'A' THEN
        LET mensaje = 'Seguro de activar'
END IF
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_del CURSOR FOR
	SELECT * FROM talt007
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_del
FETCH q_del INTO rm_t07.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET estado = 'B'
IF rm_t07.t07_estado <> 'A' THEN
	LET estado = 'A'
END IF
UPDATE talt007
	SET t07_estado = estado
	WHERE CURRENT OF q_del
COMMIT WORK
CLEAR FORM
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mensaje_registro_modificado()
                                                                                
END FUNCTION



FUNCTION lee_datos()
DEFINE cod_tarea	LIKE talt007.t07_codtarea
DEFINE resp		CHAR(6)
                                                                                
LET int_flag = 0 
INPUT BY NAME rm_t07.t07_codtarea, rm_t07.t07_nombre, rm_t07.t07_pto_default,
	rm_t07.t07_val_defa_mb, rm_t07.t07_val_defa_ma, rm_t07.t07_tipo,
	rm_t07.t07_modif_desc, rm_t07.t07_dscmax_ger, rm_t07.t07_dscmax_jef,
	rm_t07.t07_dscmax_ven
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_t07.t07_codtarea, rm_t07.t07_nombre,
				 rm_t07.t07_pto_default, rm_t07.t07_val_defa_mb,
				 rm_t07.t07_val_defa_ma, rm_t07.t07_tipo,
				 rm_t07.t07_modif_desc, rm_t07.t07_dscmax_ger,
				 rm_t07.t07_dscmax_jef, rm_t07.t07_dscmax_ven)
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
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD t07_codtarea
		IF vm_flag_mant = 'M' THEN
			LET cod_tarea = rm_t07.t07_codtarea
		END IF
	AFTER FIELD t07_codtarea
		IF vm_flag_mant = 'M' THEN
			LET rm_t07.t07_codtarea = cod_tarea
			DISPLAY BY NAME rm_t07.t07_codtarea
		END IF
	AFTER FIELD t07_pto_default
		IF rm_t07.t07_pto_default IS NOT NULL THEN
			IF rm_t07.t07_tipo = 'V' AND
			   rm_t07.t07_pto_default <> 0
			THEN
				CALL fl_mostrar_mensaje('El tipo de tarea es por valor por lo tanto solo requiere el Valor Default de la Moneda Base.','exclamation')
				LET rm_t07.t07_pto_default = 0
				DISPLAY BY NAME rm_t07.t07_pto_default
				CONTINUE INPUT
			END IF
		END IF
	AFTER FIELD t07_val_defa_mb
		IF rm_t07.t07_val_defa_mb IS NOT NULL THEN
			IF rm_t07.t07_tipo = 'V' THEN
				CALL fl_lee_configuracion_facturacion()
					RETURNING rm_conf.*
				IF rm_conf.g00_serial IS NULL THEN
					CALL fl_mostrar_mensaje('No existe la configuración para la facturación.', 'stop')
					NEXT FIELD t07_val_defa_mb
				END IF
				IF rm_conf.g00_moneda_alt IS NULL OR
				   rm_conf.g00_moneda_alt = ''
				THEN
					LET rm_t07.t07_val_defa_ma = 0
					DISPLAY BY NAME rm_t07.t07_val_defa_ma
					CONTINUE INPUT
				END IF
				CALL fl_lee_factor_moneda(
						rm_conf.g00_moneda_base,
						rm_conf.g00_moneda_alt)
					RETURNING rm_cmon.*
				IF rm_cmon.g14_serial IS NULL THEN
					CALL fl_mostrar_mensaje('No existe la conversion entre monedas.', 'stop')
					NEXT FIELD t07_val_defa_mb
				END IF
				LET rm_t07.t07_val_defa_ma =
						rm_t07.t07_val_defa_mb *
						rm_cmon.g14_tasa
				DISPLAY BY NAME rm_t07.t07_val_defa_ma
			ELSE
				IF rm_t07.t07_val_defa_mb <> 0 THEN
					CALL fl_mostrar_mensaje('El tipo de tarea es Puntuable por lo tanto solo requiere el Tiempo Optimo.','exclamation')
					LET rm_t07.t07_val_defa_mb = 0
					LET rm_t07.t07_val_defa_ma = 0
					DISPLAY BY NAME rm_t07.t07_val_defa_mb,
							rm_t07.t07_val_defa_ma
					NEXT FIELD PREVIOUS
				END IF
			END IF
		END IF
	AFTER INPUT
		IF vm_flag_mant = 'I' THEN
			CALL fl_lee_tarea(vg_codcia, rm_t07.t07_codtarea)
				RETURNING rm_t07_2.*
			IF rm_t07_2.t07_codtarea IS NOT NULL THEN
				CALL fl_mostrar_mensaje('La Tarea ya existe en la compañía.','exclamation')
				NEXT FIELD t07_codtarea
			END IF
		END IF
		IF rm_t07.t07_pto_default <= 0 AND rm_t07.t07_tipo = 'P' THEN
			CALL fl_mostrar_mensaje('El tipo de tarea es puntuable por lo tanto debe ingresar un Tiempo Optimo mayor a cero.','exclamation')
			LET rm_t07.t07_val_defa_mb = 0
			LET rm_t07.t07_val_defa_ma = 0
			DISPLAY BY NAME rm_t07.t07_val_defa_mb,
					rm_t07.t07_val_defa_ma
			NEXT FIELD t07_pto_default
             	END IF
		IF rm_t07.t07_val_defa_mb <= 0 AND rm_t07.t07_tipo = 'V' THEN
			CALL fl_mostrar_mensaje('El tipo de tarea es por valor por lo tanto debe ingresar un Valor Default en la Moneda Base mayor a cero.','exclamation')
			LET rm_t07.t07_pto_default = 0
			DISPLAY BY NAME rm_t07.t07_pto_default
			NEXT FIELD t07_val_defa_mb
		END IF
END INPUT
IF int_flag THEN
	RETURN
END IF
IF rm_t07.t07_modif_desc IS NULL THEN
	LET rm_t07.t07_modif_desc = 'N'
	DISPLAY BY NAME rm_t07.t07_modif_desc
END IF

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_t07.* FROM talt007 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_t07.t07_codtarea, rm_t07.t07_nombre, rm_t07.t07_val_defa_mb,
		rm_t07.t07_pto_default, rm_t07.t07_val_defa_ma,	rm_t07.t07_tipo,
		rm_t07.t07_modif_desc, rm_t07.t07_estado, rm_t07.t07_dscmax_ger,
		rm_t07.t07_dscmax_jef, rm_t07.t07_dscmax_ven,rm_t07.t07_usuario,
		rm_t07.t07_fecing
IF rm_t07.t07_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF

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
