--------------------------------------------------------------------------------
-- Titulo           : srip204.4gl - Mantenimiento Configuracion Codigos SRI
-- Elaboracion      : 08-jun-2009
-- Autor            : NPC
-- Formato Ejecucion: fglrun srip204 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_c02		RECORD LIKE ordt002.*
DEFINE rm_c03		RECORD LIKE ordt003.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE rm_retsri	ARRAY[10000] OF RECORD
			c03_codigo_sri		LIKE ordt003.c03_codigo_sri,
			c03_concepto_ret	LIKE ordt003.c03_concepto_ret,
			c03_fecha_ini_porc	LIKE ordt003.c03_fecha_ini_porc,
			c03_fecha_fin_porc	LIKE ordt003.c03_fecha_fin_porc,
			c03_ingresa_proc	LIKE ordt003.c03_ingresa_proc,
			c03_estado		LIKE ordt003.c03_estado
			END RECORD
DEFINE rm_audi		ARRAY[10000] OF RECORD
			     c03_usuario_modifi LIKE ordt003.c03_usuario_modifi,
			     c03_fecha_modifi   LIKE ordt003.c03_fecha_modifi,
			     c03_usuario_elimin LIKE ordt003.c03_usuario_elimin,
			     c03_fecha_elimin   LIKE ordt003.c03_fecha_elimin
			END RECORD
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_det	INTEGER
DEFINE vm_max_det	INTEGER
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/srip204.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de paráametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'srip204'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
LET vm_max_det  = 10000
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_srif204_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_ord FROM "../forms/srif204_1"
ELSE
	OPEN FORM f_ord FROM "../forms/srif204_1c"
END IF
DISPLAY FORM f_ord
CALL muestra_botones()
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_num_det     = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0, vm_num_det)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
     	COMMAND KEY('I') 'Codigos SRI' 'Permite ingresar/modificar tipos de impuestos.'
		CALL control_codigos_sri()
		IF vm_row_current >= 1 THEN
			SHOW OPTION 'Detalle'
                END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Detalle'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Detalle'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Detalle'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('D') 'Detalle' 'Ubicarse en el detalle. '
		CALL ubicarse_detalle()
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
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION cargar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_det
	INITIALIZE rm_retsri[i].*, rm_audi[i].* TO NULL
END FOR
DECLARE q_c03 CURSOR WITH HOLD FOR
	SELECT * FROM ordt003
		WHERE c03_compania   = vg_codcia
		  AND c03_tipo_ret   = rm_c02.c02_tipo_ret
		  AND c03_porcentaje = rm_c02.c02_porcentaje
		ORDER BY 2, 3, 4, 5
LET vm_num_det = 1
FOREACH q_c03 INTO rm_c03.*
	LET rm_retsri[vm_num_det].c03_codigo_sri     = rm_c03.c03_codigo_sri
	LET rm_retsri[vm_num_det].c03_concepto_ret   = rm_c03.c03_concepto_ret
	LET rm_retsri[vm_num_det].c03_fecha_ini_porc = rm_c03.c03_fecha_ini_porc
	LET rm_retsri[vm_num_det].c03_fecha_fin_porc = rm_c03.c03_fecha_fin_porc
	LET rm_retsri[vm_num_det].c03_ingresa_proc   = rm_c03.c03_ingresa_proc
	LET rm_retsri[vm_num_det].c03_estado         = rm_c03.c03_estado
	LET rm_audi[vm_num_det].c03_usuario_modifi   = rm_c03.c03_usuario_modifi
	LET rm_audi[vm_num_det].c03_fecha_modifi     = rm_c03.c03_fecha_modifi
	LET rm_audi[vm_num_det].c03_usuario_elimin   = rm_c03.c03_usuario_elimin
	LET rm_audi[vm_num_det].c03_fecha_elimin     = rm_c03.c03_fecha_elimin
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
IF vm_num_det = 0 THEN
	LET vm_num_det = 1
END IF

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE r_c02		RECORD LIKE ordt002.*

LET int_flag = 0
INPUT BY NAME rm_c02.c02_tipo_ret, rm_c02.c02_porcentaje
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_c02.c02_tipo_ret, rm_c02.c02_porcentaje)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				CLEAR FORM
				EXIT INPUT
			END IF
		ELSE
			EXIT INPUT
		END IF
	AFTER FIELD c02_tipo_ret, c02_porcentaje
		IF rm_c02.c02_tipo_ret IS NULL OR rm_c02.c02_porcentaje IS NULL
		THEN
			CONTINUE INPUT
		END IF
		CALL fl_lee_tipo_retencion(vg_codcia, rm_c02.c02_tipo_ret,
						rm_c02.c02_porcentaje)
			RETURNING r_c02.*
		LET rm_c02.c02_nombre = r_c02.c02_nombre
		DISPLAY BY NAME rm_c02.c02_nombre
		IF NOT (rm_c02.c02_tipo_ret   = r_c02.c02_tipo_ret OR
			rm_c02.c02_porcentaje = r_c02.c02_porcentaje)
		THEN
			CALL fl_mostrar_mensaje('Porcentaje de retención yno existe.','exclamation')
			NEXT FIELD c02_tipo_ret
		END IF
	AFTER INPUT
		CALL fl_lee_tipo_retencion(vg_codcia, rm_c02.c02_tipo_ret,
						rm_c02.c02_porcentaje)
			RETURNING r_c02.*
		IF r_c02.c02_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe tipo de retencion.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION control_codigos_sri()
DEFINE r_c03		RECORD LIKE ordt003.*
DEFINE codigo		LIKE ordt003.c03_codigo_sri
DEFINE nombre		LIKE ordt003.c03_concepto_ret
DEFINE fec_ini		LIKE ordt003.c03_fecha_ini_porc
DEFINE ini_rows 	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE i, j, k, l 	SMALLINT
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(250)

CLEAR FORM
CALL muestra_botones()
INITIALIZE rm_c02.*, rm_c03.* TO NULL
CALL leer_datos()
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
		CALL muestra_botones()
	END IF
	RETURN
END IF
LET rm_c03.c03_compania   = vg_codcia
LET rm_c03.c03_tipo_ret   = rm_c02.c02_tipo_ret
LET rm_c03.c03_porcentaje = rm_c02.c02_porcentaje
LET rm_c03.c03_usuario    = vg_usuario
LET rm_c03.c03_fecing     = CURRENT
FOR i = 1 TO fgl_scr_size('rm_retsri')
	CLEAR rm_retsri[i].*
END FOR
LET vm_num_rows    = 1
LET vm_row_current = 1
SELECT ROWID INTO vm_r_rows[vm_num_rows]
	FROM ordt002
	WHERE c02_compania   = vg_codcia
	  AND c02_tipo_ret   = rm_c02.c02_tipo_ret
	  AND c02_porcentaje = rm_c02.c02_porcentaje
CALL muestra_contadores(vm_row_current, vm_num_rows)
BEGIN WORK
CALL cargar_detalle()
LET int_flag = 0
CALL set_count(vm_num_det)
INPUT ARRAY rm_retsri WITHOUT DEFAULTS FROM rm_retsri.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		LET i = arr_curr()
		LET j = scr_line()
		IF INFIELD(rm_retsri[i].c03_codigo_sri) THEN
			CALL fl_ayuda_codigos_sri_gen(vg_codcia, 'A')
				RETURNING r_c03.c03_codigo_sri,
					  r_c03.c03_concepto_ret
			IF r_c03.c03_codigo_sri IS NOT NULL THEN
				LET rm_retsri[i].c03_codigo_sri =
							r_c03.c03_codigo_sri
				LET rm_retsri[i].c03_concepto_ret =
							r_c03.c03_concepto_ret
				DISPLAY rm_retsri[i].* TO rm_retsri[j].*
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		LET i = arr_curr()
		LET j = scr_line()
		IF rm_retsri[i].c03_estado = 'A' THEN
			LET rm_retsri[i].c03_estado = 'E'
			DISPLAY rm_retsri[i].c03_estado TO
				rm_retsri[j].c03_estado
			LET rm_audi[i].c03_usuario_elimin = vg_usuario
			LET rm_audi[i].c03_fecha_elimin   = CURRENT
			DISPLAY BY NAME rm_audi[i].*
		END IF
	BEFORE DELETE
		LET i = arr_curr()
		LET j = scr_line()
		WHENEVER ERROR CONTINUE
		DELETE FROM ordt003
			WHERE c03_compania      = rm_c03.c03_compania
			  AND c03_tipo_ret      = rm_c03.c03_tipo_ret
			  AND c03_porcentaje    = rm_c03.c03_porcentaje
			  AND c03_codigo_sri    = rm_retsri[i].c03_codigo_sri
			  AND c03_fecha_ini_porc=rm_retsri[i].c03_fecha_ini_porc
		IF STATUS <> 0 THEN
			--#CANCEL DELETE
		END IF
		WHENEVER ERROR STOP
	BEFORE ROW
		LET i          = arr_curr()
		LET j          = scr_line()
		LET vm_num_det = arr_count()
		IF i > vm_num_det THEN
			LET vm_num_det = vm_num_det + 1
		END IF
		CALL muestra_contadores_det(i, vm_num_det)
		CALL muestra_adi(i)
		LET codigo = rm_retsri[i].c03_codigo_sri
		LET nombre = rm_retsri[i].c03_concepto_ret
		IF rm_retsri[i].c03_ingresa_proc IS NULL THEN
			LET rm_retsri[i].c03_ingresa_proc = 'N'
			DISPLAY rm_retsri[i].c03_ingresa_proc TO
				rm_retsri[j].c03_ingresa_proc
		END IF
		IF rm_retsri[i].c03_estado = 'A' THEN
			--#CALL dialog.keysetlabel("F5","Eliminar")
		ELSE
			--#CALL dialog.keysetlabel("F5","")
		END IF
	AFTER FIELD c03_codigo_sri, c03_concepto_ret
		IF rm_retsri[i].c03_estado IS NULL THEN
			LET rm_retsri[i].c03_estado = 'A'
			DISPLAY rm_retsri[i].c03_estado TO
				rm_retsri[j].c03_estado
		END IF
		IF nombre <> rm_retsri[i].c03_concepto_ret THEN
			LET rm_audi[i].c03_usuario_modifi = vg_usuario
			LET rm_audi[i].c03_fecha_modifi   = CURRENT
			DISPLAY BY NAME rm_audi[i].*
		END IF
		IF codigo <> rm_retsri[i].c03_codigo_sri THEN
			LET rm_retsri[i].c03_codigo_sri = codigo
			DISPLAY rm_retsri[i].c03_codigo_sri TO
				rm_retsri[j].c03_codigo_sri
		END IF
		CALL fl_lee_codigos_sri(vg_codcia, rm_c03.c03_tipo_ret,
					rm_c03.c03_porcentaje,
					rm_retsri[i].c03_codigo_sri,
					rm_retsri[i].c03_fecha_ini_porc)
			RETURNING r_c03.*
		IF r_c03.c03_compania IS NOT NULL THEN
			LET rm_retsri[i].c03_concepto_ret=r_c03.c03_concepto_ret
			DISPLAY rm_retsri[i].c03_concepto_ret TO
				rm_retsri[j].c03_concepto_ret
		END IF
	BEFORE FIELD c03_fecha_ini_porc
		LET fec_ini = rm_retsri[i].c03_fecha_ini_porc
	AFTER FIELD c03_fecha_ini_porc
		IF rm_retsri[i].c03_fecha_ini_porc IS NULL THEN
			LET rm_retsri[i].c03_fecha_ini_porc = fec_ini
			DISPLAY rm_retsri[i].c03_fecha_ini_porc TO
				rm_retsri[j].c03_fecha_ini_porc
		END IF
		CALL fl_lee_codigos_sri(vg_codcia, rm_c03.c03_tipo_ret,
					rm_c03.c03_porcentaje,
					rm_retsri[i].c03_codigo_sri,
					rm_retsri[i].c03_fecha_ini_porc)
			RETURNING r_c03.*
		IF r_c03.c03_compania IS NOT NULL THEN
			LET rm_retsri[i].c03_concepto_ret=r_c03.c03_concepto_ret
			DISPLAY rm_retsri[i].c03_concepto_ret TO
				rm_retsri[j].c03_concepto_ret
		END IF
		{--
		IF rm_retsri[i].c03_fecha_ini_porc > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la fecha de hoy.', 'exclamation')
			NEXT FIELD c03_fecha_ini_porc
		END IF
		--}
	AFTER INPUT
		LET vm_num_det = arr_count()
		IF rm_retsri[vm_num_det].c03_fecha_ini_porc IS NULL THEN
			NEXT FIELD c03_fecha_ini_porc
		END IF
		FOR i = 1 TO vm_num_det
			IF rm_retsri[i].c03_codigo_sri IS NULL THEN
				CALL fl_mostrar_mensaje('Digite el código del SRI.', 'exclamation')
				CONTINUE INPUT
			END IF
			IF rm_retsri[i].c03_concepto_ret IS NULL THEN
				CALL fl_mostrar_mensaje('Digite la descripción para el código del SRI.', 'exclamation')
				CONTINUE INPUT
			END IF
		END FOR
		FOR k = 1 TO vm_num_det - 1
			FOR l = k + 1 TO vm_num_det
				IF (rm_retsri[k].c03_codigo_sri =
				    rm_retsri[l].c03_codigo_sri) AND
				   (rm_retsri[k].c03_fecha_ini_porc =
				    rm_retsri[l].c03_fecha_ini_porc)
				THEN
					LET mensaje = 'El código esta repetido en la fila ', l USING "<<<<&", '. Favor de corregirlo.'
					CALL fl_mostrar_mensaje(mensaje, 'exclamation')
					CONTINUE INPUT
				END IF
				IF (rm_retsri[k].c03_concepto_ret =
				    rm_retsri[l].c03_concepto_ret) AND
				   (rm_retsri[k].c03_fecha_ini_porc =
				    rm_retsri[l].c03_fecha_ini_porc)
				THEN
					LET mensaje = 'La descripción esta repetida en la fila ', l USING "<<<<&", '. Favor de corregirla.'
					CALL fl_mostrar_mensaje(mensaje, 'exclamation')
					CONTINUE INPUT
				END IF
			END FOR
		END FOR
END INPUT
IF int_flag THEN
	ROLLBACK WORK
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
		CALL muestra_botones()
	END IF
	RETURN
END IF
FOR i = 1 TO vm_num_det
	INITIALIZE r_c03.* TO NULL
	WHENEVER ERROR CONTINUE
	DECLARE q_c03_2 CURSOR FOR
		SELECT * FROM ordt003
			WHERE c03_compania       = rm_c03.c03_compania
			  AND c03_tipo_ret       = rm_c03.c03_tipo_ret
			  AND c03_porcentaje     = rm_c03.c03_porcentaje
			  AND c03_codigo_sri     = rm_retsri[i].c03_codigo_sri
			  AND c03_fecha_ini_porc =
					rm_retsri[i].c03_fecha_ini_porc
		FOR UPDATE
	OPEN q_c03_2
	FETCH q_c03_2 INTO r_c03.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('El código ' || rm_retsri[i].c03_codigo_sri CLIPPED || ' esta siendo modificado por otro usuario.', 'stop')
		WHENEVER ERROR STOP
		LET int_flag = 1
		EXIT FOR
	END IF
	IF STATUS = NOTFOUND THEN
		INSERT INTO ordt003
			VALUES(rm_c03.c03_compania, rm_c03.c03_tipo_ret,
				rm_c03.c03_porcentaje,
				rm_retsri[i].c03_codigo_sri,
				rm_retsri[i].c03_fecha_ini_porc,
				rm_retsri[i].c03_estado,
				rm_retsri[i].c03_concepto_ret,
				rm_retsri[i].c03_fecha_fin_porc,
				rm_retsri[i].c03_ingresa_proc, NULL, NULL, NULL,
				NULL, rm_c03.c03_usuario, rm_c03.c03_fecing)
		CLOSE q_c03_2
		IF NOT dar_de_baja_cod_sri_anter(i) THEN
			EXIT FOR
		END IF
		CONTINUE FOR
	END IF
	UPDATE ordt003
		SET c03_estado         = rm_retsri[i].c03_estado,
		    c03_concepto_ret   = rm_retsri[i].c03_concepto_ret,
		    c03_fecha_fin_porc = rm_retsri[i].c03_fecha_fin_porc,
		    c03_ingresa_proc   = rm_retsri[i].c03_ingresa_proc
		WHERE CURRENT OF q_c03_2
	IF NOT dar_de_baja_cod_sri_anter(i) THEN
		EXIT FOR
	END IF
	IF rm_audi[i].c03_usuario_modifi IS NOT NULL THEN
		UPDATE ordt003
			SET c03_usuario_modifi = rm_audi[i].c03_usuario_modifi,
			    c03_fecha_modifi   = rm_audi[i].c03_fecha_modifi
			WHERE CURRENT OF q_c03_2
	END IF
	IF rm_audi[i].c03_usuario_elimin IS NOT NULL THEN
		UPDATE ordt003
			SET c03_usuario_elimin = rm_audi[i].c03_usuario_elimin,
			    c03_fecha_elimin   = rm_audi[i].c03_fecha_elimin
			WHERE CURRENT OF q_c03_2
	END IF
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('El código ' || rm_retsri[i].c03_codigo_sri CLIPPED || ' no se pudo actualizar. Por favor llame al ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		LET int_flag = 1
		EXIT FOR
	END IF
	WHENEVER ERROR STOP
END FOR
IF NOT int_flag THEN
	COMMIT WORK
	CALL fl_mostrar_mensaje('Procesados Codigos del SRI.', 'info')
END IF
IF vm_row_current > 0 THEN
	CALL mostrar_registro(vm_r_rows[vm_row_current])
ELSE
	CLEAR FORM
	CALL muestra_botones()
END IF
RETURN

END FUNCTION



FUNCTION dar_de_baja_cod_sri_anter(i)
DEFINE i		SMALLINT
DEFINE fec_fin		LIKE ordt003.c03_fecha_ini_porc

LET fec_fin = rm_retsri[i].c03_fecha_ini_porc - 1 UNITS DAY
WHENEVER ERROR CONTINUE
SELECT a.c03_tipo_ret tip_r, a.c03_porcentaje porc_r, a.c03_codigo_sri cod_sri
	FROM ordt003 a
	WHERE a.c03_compania   = c03_compania
	  AND a.c03_tipo_ret   = rm_c03.c03_tipo_ret
	  AND a.c03_porcentaje = rm_c03.c03_porcentaje
	  AND a.c03_codigo_sri = rm_retsri[i].c03_codigo_sri
	INTO TEMP t1
UPDATE ordt003
	SET c03_fecha_fin_porc = fec_fin
	WHERE c03_compania       = rm_c03.c03_compania
	  AND c03_codigo_sri     = rm_retsri[i].c03_codigo_sri
	  AND c03_fecha_fin_porc IS NULL
	  AND c03_estado         = 'A'
	  AND NOT EXISTS
		(SELECT * FROM t1
			WHERE tip_r   = c03_tipo_ret
			  AND porc_r  = c03_porcentaje
			  AND cod_sri = c03_codigo_sri)
IF STATUS < 0 THEN
	DROP TABLE t1
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('El codigo ' || rm_retsri[i].c03_codigo_sri CLIPPED || ' no se puede dar de baja en otros tipos de porcentaje retencion. Por favor llame al ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	LET int_flag = 1
	RETURN 0
END IF
DROP TABLE t1
WHENEVER ERROR STOP
RETURN 1

END FUNCTION



FUNCTION control_consulta()
DEFINE query		CHAR(1200)
DEFINE expr_sql		CHAR(600)
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE rm_c02.*, rm_c03.* TO NULL
CALL muestra_botones()
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON c02_tipo_ret, c02_porcentaje, c02_nombre
	ON KEY(F2)
	AFTER FIELD c02_tipo_ret
		LET rm_c02.c02_tipo_ret = GET_FLDBUF(c02_tipo_ret)
		DISPLAY BY NAME rm_c02.c02_tipo_ret
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
		CALL muestra_botones()
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID ',
		' FROM ordt002 ',
		' WHERE c02_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 2, 3, c02_nombre '
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_c02.*, num_reg
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
	CALL muestra_botones()
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0, vm_num_det)

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0, vm_num_det)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0, vm_num_det)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current		SMALLINT
DEFINE num_rows			SMALLINT
DEFINE nrow                     SMALLINT
                                                                                
LET nrow = 19
IF vg_gui = 1 THEN
	LET nrow = 1
END IF
DISPLAY "" AT nrow, 1
DISPLAY row_current, " de ", num_rows AT nrow, 67

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_c02.* FROM ordt002 WHERE ROWID = num_registro
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_c02.c02_tipo_ret, rm_c02.c02_porcentaje, rm_c02.c02_nombre
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i, lim		SMALLINT

CALL cargar_detalle()
LET lim = fgl_scr_size('rm_retsri')
FOR i = 1 TO lim
	CLEAR rm_retsri[i].*
END FOR
IF vm_num_det < lim THEN
	LET lim = vm_num_det
END IF
CALL muestra_contadores_det(0, vm_num_det)
FOR i = 1 TO lim
	DISPLAY rm_retsri[i].* TO rm_retsri[i].*
END FOR
CALL muestra_adi(1)

END FUNCTION



FUNCTION ubicarse_detalle()
DEFINE query		CHAR(1200)
DEFINE i, j, col	SMALLINT

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col           = 1
LET vm_columna_1  = col
LET vm_columna_2  = 3
LET rm_orden[col] = 'ASC'
WHILE TRUE
	LET query = 'SELECT c03_codigo_sri, c03_concepto_ret,',
			' c03_fecha_ini_porc, c03_fecha_fin_porc,',
			' c03_ingresa_proc, c03_estado,',
			' c03_usuario_modifi, c03_fecha_modifi,',
			' c03_usuario_elimin, c03_fecha_elimin',
			' FROM ordt003 ',
			' WHERE c03_compania   = ', vg_codcia,
			'   AND c03_tipo_ret   = "', rm_c02.c02_tipo_ret, '"',
			'   AND c03_porcentaje = ', rm_c02.c02_porcentaje,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE cons_c03 FROM query
	DECLARE q_c03_3 CURSOR FOR cons_c03
	LET vm_num_det = 1
	FOREACH q_c03_3 INTO rm_retsri[vm_num_det].*, rm_audi[vm_num_det].*
		LET vm_num_det = vm_num_det + 1
		IF vm_num_det > vm_max_det THEN
			CALL fl_mensaje_arreglo_incompleto()
			EXIT PROGRAM
		END IF
	END FOREACH
	LET vm_num_det = vm_num_det - 1
	LET int_flag = 0
	CALL set_count(vm_num_det)
	DISPLAY ARRAY rm_retsri TO rm_retsri.*
	       	ON KEY(INTERRUPT)   
			LET int_flag = 1
	       	        EXIT DISPLAY  
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 5
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 6
			EXIT DISPLAY
		--#BEFORE DISPLAY 
			--#CALL dialog.keysetlabel('ACCEPT', '')   
			--#CALL dialog.keysetlabel('RETURN', '')   
		--#BEFORE ROW 
			--#LET i = arr_curr()	
			--#LET j = scr_line()
			--#CALL muestra_contadores_det(i, vm_num_det)
			--#CALL muestra_adi(i)
	        --#AFTER DISPLAY
	                --#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION muestra_adi(i)
DEFINE i		SMALLINT

DISPLAY BY NAME rm_audi[i].*

END FUNCTION



FUNCTION muestra_botones()

--#DISPLAY 'Codigo'		TO tit_col1 
--#DISPLAY 'Concepto'		TO tit_col2 
--#DISPLAY 'Fecha Ini.'		TO tit_col3 
--#DISPLAY 'Fecha Fin.'		TO tit_col4 
--#DISPLAY 'I'			TO tit_col5 
--#DISPLAY 'E'			TO tit_col6 

END FUNCTION
