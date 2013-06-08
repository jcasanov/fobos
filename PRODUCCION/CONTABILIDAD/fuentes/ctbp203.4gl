------------------------------------------------------------------------------
-- Titulo           : ctbp203.4gl - Conciliación Bancaria
-- Elaboracion      : 26-Ago-2002
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp203 base módulo compañía [num_concil]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog	VARCHAR(400)
DEFINE rm_g09		RECORD LIKE gent009.*
DEFINE rm_b10		RECORD LIKE ctbt010.*
DEFINE rm_b12		RECORD LIKE ctbt012.*
DEFINE rm_b13		RECORD LIKE ctbt013.*
DEFINE rm_b30		RECORD LIKE ctbt030.*
DEFINE vm_flag_mant	CHAR(1)
DEFINE vm_nivel		SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_max_mov	SMALLINT
DEFINE vm_num_mov	SMALLINT
DEFINE vm_max_res	SMALLINT
DEFINE vm_num_res	SMALLINT
DEFINE vm_flag_mov	SMALLINT
DEFINE vm_flag_fecini	CHAR(1)
DEFINE vm_total_deb	DECIMAL(14,2)
DEFINE vm_total_cre	DECIMAL(14,2)
DEFINE vm_total_val	DECIMAL(12,2)
DEFINE vm_total_con	DECIMAL(12,2)
DEFINE vm_total_chc	DECIMAL(12,2)
DEFINE vm_total_dep	DECIMAL(12,2)
DEFINE vm_r_rows	ARRAY [1000] OF LIKE ctbt030.b30_num_concil
DEFINE rm_orden 	ARRAY [10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_det 		ARRAY [1000] OF RECORD
				b13_fec_proceso	LIKE ctbt013.b13_fec_proceso,
				referencia	VARCHAR(120),
				b13_tipo_comp	LIKE ctbt013.b13_tipo_comp,
				b13_num_comp	LIKE ctbt013.b13_num_comp,
				tit_debito	DECIMAL(14,2),
				tit_credito	DECIMAL(14,2),
				conciliado	CHAR(1)
			END RECORD
DEFINE rm_referen	ARRAY [1000] OF RECORD
				b13_glosa	LIKE ctbt013.b13_glosa,
				referencia	VARCHAR(120),
				secuen		LIKE ctbt013.b13_secuencia,
				b13_tipo_doc	LIKE ctbt013.b13_tipo_doc
			END RECORD
DEFINE rm_mov		ARRAY [1000] OF RECORD
				b31_tipo_doc	LIKE ctbt031.b31_tipo_doc,
				b31_cuenta	LIKE ctbt031.b31_cuenta,
				b31_glosa	LIKE ctbt031.b31_glosa,
				valor		DECIMAL(12,2)
			END RECORD
DEFINE rm_mov_aux	ARRAY [1000] OF RECORD
				b31_tipo_doc	LIKE ctbt031.b31_tipo_doc,
				b31_cuenta	LIKE ctbt031.b31_cuenta,
				b31_glosa	LIKE ctbt031.b31_glosa,
				valor		DECIMAL(12,2)
			END RECORD
DEFINE vm_flag_det	ARRAY [1000] OF SMALLINT
DEFINE rm_resu		ARRAY [10] OF RECORD
				descripcion	VARCHAR(60,0),
				valor_concil	DECIMAL(12,2)
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
--CALL startlog('../logs/errores')
CALL startlog('../logs/ctbp203.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'ctbp203'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
CREATE TEMP TABLE temp_mov(
	orden			SMALLINT,
	b13_fec_proceso		DATE,
	referencia		VARCHAR(120),
	b13_tipo_comp		CHAR(2),
	b13_num_comp		CHAR(8),
	tit_debito		DECIMAL(14,2),
	tit_credito		DECIMAL(14,2),
	conciliado		CHAR(1),
	b13_glosa		VARCHAR(120),
	referen			VARCHAR(120),
	secuen			SMALLINT,
	b13_tipo_doc		CHAR(3),
	flag_det		SMALLINT)
LET vm_max_rows	= 1000
LET vm_max_det	= 1000
LET vm_max_mov	= 1000
LET vm_max_res	= 10
OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb FROM "../forms/ctbf203_1"
DISPLAY FORM f_ctb
LET vm_scr_lin     = 0
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_flag_mov    = 1
CALL inicializar_conciliacion()
CALL encerar_resumen()
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Reaperturar'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Imprimir'
		IF num_args() = 4 THEN
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			IF vm_num_rows = 0 THEN
				EXIT PROGRAM
			END IF
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('B') 'Conciliación'	'Conciliación Bancaria.'
		CALL sub_menu()
		IF vm_num_rows = 1 THEN
			IF num_args() <> 4 THEN
				SHOW OPTION 'Modificar'
				SHOW OPTION 'Eliminar'
				SHOW OPTION 'Imprimir'
				IF rm_b30.b30_estado = 'C' THEN
					SHOW OPTION 'Reaperturar'
				ELSE
					HIDE OPTION 'Reaperturar'
				END IF
				SHOW OPTION 'Detalle'
			END IF
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		CALL mostrar_botones_detalle()
	COMMAND KEY('M') 'Modificar' 	'Modificar registro corriente.'
		CALL control_modificacion()
	COMMAND KEY('P') 'Reaperturar'	'Reapertura último registro conciliado.'
		CALL control_reapertura()
		HIDE OPTION 'Reaperturar'
	COMMAND KEY('E') 'Eliminar'	'Elimina registro no conciliado.'
		CALL control_eliminacion()
	COMMAND KEY('C') 'Consultar'	'Consultar un registro.'
		HIDE OPTION 'Detalle'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Imprimir'
			IF rm_b30.b30_estado = 'C' THEN
				SHOW OPTION 'Reaperturar'
			ELSE
				HIDE OPTION 'Reaperturar'
			END IF
			SHOW OPTION 'Detalle'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Eliminar'
				HIDE OPTION 'Imprimir'
				IF rm_b30.b30_estado = 'C' THEN
					SHOW OPTION 'Reaperturar'
				ELSE
					HIDE OPTION 'Reaperturar'
				END IF
				HIDE OPTION 'Detalle'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Imprimir'
			IF rm_b30.b30_estado = 'C' THEN
				SHOW OPTION 'Reaperturar'
			ELSE
				HIDE OPTION 'Reaperturar'
			END IF
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Detalle'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		CALL mostrar_botones_detalle()
	COMMAND KEY('D') 'Detalle'	'Ver detalle de los movimientos.'
		CALL muestra_detalle_arr(0)
	COMMAND KEY('A') 'Avanzar' 	'Ver siguiente registro.'
		HIDE OPTION 'Detalle'
		CALL muestra_siguiente_registro(0)
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_b30.b30_estado = 'C' THEN
			SHOW OPTION 'Reaperturar'
		ELSE
			HIDE OPTION 'Reaperturar'
		END IF
		SHOW OPTION 'Detalle'
	COMMAND KEY('R') 'Retroceder' 	'Ver anterior registro.'
		HIDE OPTION 'Detalle'
		CALL muestra_anterior_registro(0)
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_b30.b30_estado = 'C' THEN
			SHOW OPTION 'Reaperturar'
		ELSE
			HIDE OPTION 'Reaperturar'
		END IF
		SHOW OPTION 'Detalle'
	COMMAND KEY('I') 'Imprimir'
		CALL control_impresion_conciliacion()
	COMMAND KEY('S') 'Salir'   	'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION sub_menu()
DEFINE resp		CHAR(6)
DEFINE resul, res	SMALLINT

LET resul = 2		-- SOLO UNA VEZ PARA ENTRAR AL MENU
MENU 'OPCIONES'
	BEFORE MENU
		IF rm_b30.b30_estado = 'E' THEN
			CALL fgl_winmessage(vg_producto, 'No puede conciliar una conciliación eliminada.', 'exclamation')
			IF resul = 0 THEN
				COMMIT WORK
			END IF
			EXIT MENU
		END IF
		HIDE OPTION 'Movimientos'
		HIDE OPTION 'Cerrar'
		HIDE OPTION 'Resumen'
		HIDE OPTION 'Detalle'
		IF rm_b30.b30_estado <> 'C' THEN
			IF num_args() <> 4 THEN
				SHOW OPTION 'Movimientos'
				SHOW OPTION 'Cerrar'
			END IF
		ELSE
			SHOW OPTION 'Resumen'
			SHOW OPTION 'Detalle'
		END IF
		IF num_args() = 4 THEN
			HIDE OPTION 'Ingresar'
			IF vm_num_mov = 0 THEN
				HIDE OPTION 'A Contabilizar'
			END IF
			SHOW OPTION 'Resumen'
			SHOW OPTION 'Detalle'
		END IF
		LET int_flag = 1
		IF vm_flag_mant = 'I' THEN
			CALL control_conciliacion()
			IF rm_b30.b30_estado = 'A' THEN
				SHOW OPTION 'Movimientos'
				SHOW OPTION 'Cerrar'
				HIDE OPTION 'Resumen'
				HIDE OPTION 'Detalle'
			ELSE
				HIDE OPTION 'Movimientos'
				HIDE OPTION 'Cerrar'
				SHOW OPTION 'Resumen'
				SHOW OPTION 'Detalle'
			END IF
			IF int_flag THEN
				EXIT MENU
			END IF
		END IF
		CALL bloqueo_cabecera() RETURNING resul
		IF resul = 1 THEN
			EXIT MENU
		END IF
		IF NOT int_flag THEN
			CLEAR FORM
			CALL mostrar_botones_detalle()
			IF vm_row_current > 0 THEN
	               		CALL mostrar_registro(
						vm_r_rows[vm_row_current], 1)
       			END IF
		END IF
	COMMAND KEY('I') 'Ingresar'	'Crea una nueva conciliación.'
		CALL inicializar_conciliacion()
		CALL control_conciliacion()
		IF resul = 0 THEN
			COMMIT WORK
		END IF
		CALL bloqueo_cabecera() RETURNING resul
		IF resul = 1 THEN
			EXIT MENU
		END IF
		IF NOT int_flag THEN
			CLEAR FORM
			CALL mostrar_botones_detalle()
			IF vm_row_current > 0 THEN
	               		CALL mostrar_registro(
						vm_r_rows[vm_row_current], 1)
       			END IF
		END IF
		IF rm_b30.b30_estado = 'A' THEN
			SHOW OPTION 'Movimientos'
			SHOW OPTION 'Cerrar'
			HIDE OPTION 'Resumen'
			HIDE OPTION 'Detalle'
		ELSE
			HIDE OPTION 'Movimientos'
			HIDE OPTION 'Cerrar'
			SHOW OPTION 'Resumen'
			SHOW OPTION 'Detalle'
		END IF
	COMMAND KEY('M') 'Movimientos'	'Trae los movimientos no Tarjados.'
		CALL control_movimientos()
		IF int_flag THEN
			CLEAR FORM
			CALL mostrar_botones_detalle()
			IF vm_row_current > 0 THEN
	               		CALL mostrar_registro(
						vm_r_rows[vm_row_current], 1)
       			END IF
		END IF
	COMMAND KEY('A') 'A Contabilizar' '.'
		CALL control_contabilizar()
	COMMAND KEY('C') 'Cerrar' 'Cierra la conciliación.'
		CALL control_cerrar()
		IF NOT int_flag THEN
			EXIT MENU
		END IF
	COMMAND KEY('R') 'Resumen'	'Muestra el resumen de la conciliación.'
		CALL control_resumen() RETURNING res
	COMMAND KEY('D') 'Detalle'	'Ver detalle de los movimientos.'
		CALL muestra_detalle_arr(0)
	COMMAND KEY('S') 'Salir' 'Sale del menú. '
		IF resul = 0 THEN
			COMMIT WORK
		END IF
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_conciliacion()

LET vm_num_det = 0
CALL muestra_contadores_det(0)
IF vm_flag_mant = 'I' THEN
	LET rm_b30.b30_estado = 'A'
	CALL muestra_estado()
END IF
CALL leer_cabecera()
IF NOT int_flag THEN
	IF vm_flag_fecini = 'I' OR vm_flag_mant = 'I' THEN
		LET rm_b30.b30_fecing  = CURRENT
		LET rm_b30.b30_usuario = vg_usuario
		SELECT MAX(b30_num_concil) INTO rm_b30.b30_num_concil
			FROM ctbt030
			WHERE b30_compania = vg_codcia
		IF rm_b30.b30_num_concil IS NULL THEN
			LET rm_b30.b30_num_concil = 1
		ELSE
			LET rm_b30.b30_num_concil = rm_b30.b30_num_concil + 1
		END IF
		INSERT INTO ctbt030 VALUES(rm_b30.*)
		LET vm_num_rows               = vm_num_rows + 1
		LET vm_row_current            = vm_num_rows
		LET vm_r_rows[vm_row_current] = rm_b30.b30_num_concil
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		CALL fl_mensaje_registro_ingresado()
		LET vm_flag_mant = 'M'
		LET vm_flag_mov  = 0
		LET int_flag 	 = 0
	END IF
ELSE
	CLEAR FORM
	CALL mostrar_botones_detalle()
	IF vm_row_current > 0 THEN
		LET vm_flag_mant = 'M'
		CALL mostrar_registro(vm_r_rows[vm_row_current], 1)
	END IF
END IF

END FUNCTION



FUNCTION control_movimientos()
DEFINE num_concil	LIKE ctbt030.b30_num_concil
DEFINE tipo		LIKE ctbt013.b13_tipo_comp
DEFINE num		LIKE ctbt013.b13_num_comp
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE i		SMALLINT

WHENEVER ERROR CONTINUE
IF rm_b30.b30_estado <> 'C' THEN
	DECLARE q_mov CURSOR FOR SELECT UNIQUE b13_tipo_comp, b13_num_comp
					FROM temp_mov
	FOREACH q_mov INTO tipo, num
		DECLARE q_mov2 CURSOR FOR SELECT * FROM ctbt012
			WHERE b12_compania  = vg_codcia
			  AND b12_tipo_comp = tipo
			  AND b12_num_comp  = num
			FOR UPDATE
		OPEN q_mov2
		FETCH q_mov2 INTO r_b12.*
		IF STATUS < 0 THEN
			ROLLBACK WORK
			CLOSE q_mov2
			FREE q_mov2
			CALL fgl_winmessage(vg_producto, 'Lo siento comprobante contable está bloqueado por otro proceso.', 'exclamation')
			WHENEVER ERROR STOP
			LET int_flag = 1
			RETURN
		END IF
		CLOSE q_mov2
		FREE q_mov2
		WHENEVER ERROR STOP
	END FOREACH
	CLOSE q_mov
	CALL muestra_detalle_arr(1)
	CALL leer_detalle()
ELSE
	CALL muestra_detalle_arr(0)
	LET int_flag = 0
END IF
IF NOT int_flag THEN
	CALL encerar_resumen()
	FOR i = 1 TO vm_num_det
		LET num_concil = 0
		IF rm_det[i].conciliado = 'S' THEN
			LET num_concil = rm_b30.b30_num_concil
		END IF
		IF vm_flag_det[i] = 0 THEN
			UPDATE ctbt013 SET b13_num_concil = num_concil
				WHERE b13_compania  = rm_b30.b30_compania
				  AND b13_tipo_comp = rm_det[i].b13_tipo_comp
				  AND b13_num_comp  = rm_det[i].b13_num_comp
				  AND b13_secuencia = rm_referen[i].secuen
			CALL calcula_che_gir_nocob(i)
			CALL calcula_dep_transito(i)
			IF rm_det[i].tit_credito < 0 THEN
				CALL calcula_otros_cre(i)
			END IF
			IF rm_det[i].tit_debito >= 0 THEN
				CALL calcula_otros_deb(i)
			END IF
		ELSE
			UPDATE ctbt032 SET b32_num_concil = num_concil
				WHERE b32_compania  = rm_b30.b30_compania
				  AND b32_tipo_comp = rm_det[i].b13_tipo_comp
				  AND b32_num_comp  = rm_det[i].b13_num_comp
				  AND b32_secuencia = rm_referen[i].secuen
			CALL calcula_che_gir_nocob(i)
		END IF
		UPDATE temp_mov SET conciliado = rm_det[i].conciliado
			WHERE b13_tipo_comp = rm_det[i].b13_tipo_comp
			  AND b13_num_comp  = rm_det[i].b13_num_comp
			  AND secuen        = rm_referen[i].secuen
	END FOR
	CALL llenar_contabilizar()
END IF

END FUNCTION



FUNCTION control_modificacion()
DEFINE resul		SMALLINT
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_b30.b30_estado = 'E' THEN
	CALL fgl_winmessage(vg_producto, 'No puede modificar una conciliación eliminada.', 'exclamation')
	RETURN
END IF
IF rm_b30.b30_estado = 'C' THEN
	CALL fgl_winmessage(vg_producto, 'No puede modificar una conciliación procesada.', 'exclamation')
	RETURN
END IF
CALL bloqueo_cabecera() RETURNING resul
IF resul = 1 THEN
	RETURN
END IF
CALL leer_cabecera()
IF NOT int_flag THEN
	UPDATE ctbt030 SET b30_saldo_ec = rm_b30.b30_saldo_ec
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CLEAR FORM
	CALL mostrar_botones_detalle()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current], 1)
	END IF
END IF
 
END FUNCTION



FUNCTION control_consulta()
DEFINE resul		SMALLINT
DEFINE banco		LIKE gent008.g08_banco
DEFINE nomban		LIKE gent008.g08_nombre
DEFINE tipocta		LIKE gent009.g09_tipo_cta
DEFINE numcta		LIKE gent009.g09_numero_cta
DEFINE num_concil	LIKE ctbt030.b30_num_concil
DEFINE expr_sql		VARCHAR(400)
DEFINE query		VARCHAR(800)

LET vm_flag_mov  = 0
CLEAR FORM
CALL mostrar_botones_detalle()
IF num_args() <> 4 THEN
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON b30_num_concil, b30_estado,b30_numero_cta,
		b30_fecha_ini, b30_fecha_fin, b30_saldo_ec
		ON KEY(F2)
			IF INFIELD(b30_num_concil) THEN
				CALL fl_ayuda_conciliacion(vg_codcia, NULL)
					RETURNING num_concil
				LET int_flag = 0
				IF num_concil IS NOT NULL THEN
               	              		LET rm_b30.b30_num_concil = num_concil 
					DISPLAY BY NAME rm_b30.b30_num_concil 
				END IF 
			END IF
			IF INFIELD(b30_numero_cta) THEN
				CALL fl_ayuda_cuenta_banco(vg_codcia, 'T')
					RETURNING banco, nomban, tipocta, numcta
				LET int_flag = 0
				IF banco IS NOT NULL THEN
	               	              	LET rm_b30.b30_numero_cta = numcta 
					DISPLAY BY NAME rm_b30.b30_numero_cta 
					DISPLAY nomban TO g08_nombre
				END IF 
			END IF
		AFTER FIELD b30_estado
			LET rm_b30.b30_estado = get_fldbuf(b30_estado)
			CALL muestra_estado()
	END CONSTRUCT
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(vm_r_rows[vm_row_current], 1)
			IF int_flag THEN
				LET int_flag = 0
				RETURN
			END IF
		ELSE
			CLEAR FORM
			CALL mostrar_botones_detalle()
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = '  b30_num_concil = ', arg_val(4)
END IF
LET query = 'SELECT b30_num_concil FROM ctbt030 ' ||
		'WHERE b30_compania = '|| vg_codcia ||
		'  AND ' || expr_sql CLIPPED
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO num_concil
	IF num_concil < 1 THEN
		CONTINUE FOREACH
	END IF
	LET vm_r_rows[vm_num_rows] = num_concil
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag       = 0
	LET vm_row_current = 0
	LET vm_flag_mant   = 'I'
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() = 4 THEN
		EXIT PROGRAM
	END IF
	CALL borrar_cabecera()
	CALL borrar_detalle()
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(0)
ELSE  
	LET vm_row_current = 1
	LET vm_flag_mant   = 'M'
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(0)
	CALL mostrar_registro(vm_r_rows[vm_row_current], 1)
	IF int_flag THEN
		LET int_flag = 0
		RETURN
	END IF
END IF

END FUNCTION



FUNCTION control_reapertura()
DEFINE confir		CHAR(6)
DEFINE fecha_cie	LIKE ctbt030.b30_fecha_cie
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b00		RECORD LIKE ctbt000.*
DEFINE r_b30		RECORD LIKE ctbt030.*

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_b30.b30_estado = 'A' THEN
	RETURN
END IF
IF rm_b30.b30_estado = 'E' THEN
	CALL fgl_winmessage(vg_producto, 'No puede reaperturar una conciliación eliminada.', 'exclamation')
	RETURN
END IF
DECLARE cur_react CURSOR FOR
	SELECT * FROM ctbt030
		WHERE b30_compania   = vg_codcia AND b30_estado = 'A' AND
		      b30_banco      = rm_b30.b30_banco AND 
		      b30_numero_cta = rm_b30.b30_numero_cta
		ORDER BY b30_num_concil DESC
OPEN cur_react
FETCH cur_react INTO r_b30.*
IF STATUS <> NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'No puede reaperturar la conciliación mientras halla una activa.', 'exclamation')
	RETURN
END IF
SELECT MAX(b30_fecha_cie) INTO fecha_cie FROM ctbt030
	WHERE b30_compania = vg_codcia
IF fecha_cie <> rm_b30.b30_fecha_cie THEN
	CALL fgl_winmessage(vg_producto, 'No puede reaperturar la conciliación porque no es la última conciliada.', 'exclamation')
	RETURN
END IF
LET int_flag = 1
CALL fgl_winquestion(vg_producto,'Seguro de reaperturar esta conciliación.','No','Yes|No|Cancel','question',1)
	RETURNING confir
IF confir <> 'Yes' THEN
	LET int_flag = 0
	RETURN
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_ba2 CURSOR FOR SELECT * FROM ctbt030
	WHERE b30_compania   = vg_codcia
	  AND b30_num_concil = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba2
FETCH q_ba2 INTO rm_b30.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
WHENEVER ERROR STOP
IF rm_b30.b30_tipcomp_gen IS NOT NULL THEN
	CALL fl_lee_comprobante_contable(vg_codcia, rm_b30.b30_tipcomp_gen,
					rm_b30.b30_numcomp_gen)
		RETURNING r_b12.*
	CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING r_b00.*
	IF r_b12.b12_fec_proceso <= r_b00.b00_fecha_cm THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Lo siento no puede reabrir una conciliación de un mes cerrado.', 'exclamation')
		RETURN
	END IF
END IF
CALL reapertura_registro()

END FUNCTION



FUNCTION reapertura_registro()

IF rm_b30.b30_estado = 'C' THEN
        DISPLAY 'ACTIVA' TO tit_estado
        LET rm_b30.b30_estado = 'A'
END IF
DISPLAY BY NAME rm_b30.b30_estado
UPDATE ctbt030
	SET b30_estado      = rm_b30.b30_estado,
	    b30_fecha_cie   = NULL,
	    b30_tipcomp_gen = NULL,
	    b30_numcomp_gen = NULL
	WHERE CURRENT OF q_ba2
WHENEVER ERROR CONTINUE
DECLARE q_del CURSOR FOR SELECT * FROM ctbt012
	WHERE b12_compania  = rm_b30.b30_compania
	  AND b12_tipo_comp = rm_b30.b30_tipcomp_gen
	  AND b12_num_comp  = rm_b30.b30_numcomp_gen
	FOR UPDATE
OPEN  q_del
FETCH q_del INTO rm_b12.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF  
COMMIT WORK
WHENEVER ERROR STOP
IF rm_b30.b30_tipcomp_gen IS NOT NULL THEN
	CALL fl_mayoriza_comprobante(vg_codcia, rm_b30.b30_tipcomp_gen, 
			     rm_b30.b30_numcomp_gen, 'D')
	UPDATE ctbt012 SET b12_estado     = 'E',
		   	   b12_fec_modifi = CURRENT
		WHERE b12_compania  = rm_b30.b30_compania
	  	  AND b12_tipo_comp = rm_b30.b30_tipcomp_gen
	  	  AND b12_num_comp  = rm_b30.b30_numcomp_gen
END IF
CALL fgl_winmessage(vg_producto, 'Conciliación ha sido reabierta.', 'info')

END FUNCTION



FUNCTION control_eliminacion()
DEFINE confir		CHAR(6)
DEFINE i		SMALLINT

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_b30.b30_estado = 'E' THEN
	CALL fgl_winmessage(vg_producto, 'No puede eliminar una conciliación eliminada.', 'exclamation')
	RETURN
END IF
IF rm_b30.b30_estado = 'C' THEN
	CALL fgl_winmessage(vg_producto, 'No puede eliminar una conciliación procesada.', 'exclamation')
	RETURN
END IF
FOR i = 1 TO vm_num_det
	IF rm_det[i].conciliado = 'S' THEN
		CALL fgl_winmessage(vg_producto, 'No puede eliminar una conciliación con movimientos chequeados.', 'exclamation')
		RETURN
	END IF
END FOR
FOR i = 1 TO vm_num_mov
	IF rm_mov[i].b31_tipo_doc IS NOT NULL THEN
		CALL fgl_winmessage(vg_producto, 'No puede eliminar una conciliación con movimientos en el E/C.', 'exclamation')
		RETURN
	END IF
END FOR
LET int_flag = 0
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_ba CURSOR FOR SELECT * FROM ctbt030
	WHERE b30_compania   = vg_codcia
	  AND b30_num_concil = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_b30.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
WHENEVER ERROR STOP
CALL fgl_winquestion(vg_producto,'Seguro de eliminar esta conciliación.','No','Yes|No|Cancel','question',1)
	RETURNING confir
IF confir <> 'Yes' THEN
	RETURN
END IF
LET int_flag = 1
CALL elimina_registro()
COMMIT WORK
CALL fgl_winmessage(vg_producto, 'Conciliación ha sido eliminada.', 'info')

END FUNCTION



FUNCTION elimina_registro()

IF rm_b30.b30_estado = 'A' THEN
        DISPLAY 'ELIMINADA' TO tit_estado
        LET rm_b30.b30_estado = 'E'
END IF
DISPLAY BY NAME rm_b30.b30_estado
UPDATE ctbt030 SET b30_estado = rm_b30.b30_estado WHERE CURRENT OF q_ba

END FUNCTION



FUNCTION control_impresion_conciliacion()
DEFINE num_concil	LIKE ctbt030.b30_num_concil

LET num_concil = rm_b30.b30_num_concil
IF num_args() = 4 THEN
	LET num_concil = arg_val(4)
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
	vg_separador, 'fuentes', vg_separador, '; fglrun ctbp408 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', num_concil
RUN vm_nuevoprog

END FUNCTION



FUNCTION leer_cabecera()
DEFINE resp		CHAR(6)
DEFINE banco		LIKE gent008.g08_banco
DEFINE nomban		LIKE gent008.g08_nombre
DEFINE tipocta		LIKE gent009.g09_tipo_cta
DEFINE numcta		LIKE gent009.g09_numero_cta
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE fecha_ini	DATE
DEFINE resul		SMALLINT

INITIALIZE banco TO NULL
LET int_flag = 0
INPUT BY NAME rm_b30.b30_numero_cta, rm_b30.b30_fecha_ini, rm_b30.b30_fecha_fin,	rm_b30.b30_saldo_ec
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_b30.b30_numero_cta,rm_b30.b30_fecha_ini,
				rm_b30.b30_fecha_fin, rm_b30.b30_saldo_ec)
		THEN
			RETURN
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			CALL borrar_cabecera()
			CALL borrar_detalle()
			LET int_flag = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(b30_numero_cta) THEN
			CALL fl_ayuda_cuenta_banco(vg_codcia, 'A')
				RETURNING banco, nomban, tipocta, numcta
			LET int_flag = 0
			IF banco IS NOT NULL THEN
               	              	LET rm_b30.b30_numero_cta = numcta 
				DISPLAY BY NAME rm_b30.b30_numero_cta 
				DISPLAY nomban TO g08_nombre
			END IF 
		END IF
	BEFORE FIELD b30_numero_cta, b30_fecha_ini, b30_fecha_fin
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD b30_numero_cta
		IF rm_b30.b30_numero_cta IS NOT NULL THEN
			DECLARE q_cta CURSOR FOR SELECT * FROM gent009
				WHERE g09_compania   = vg_codcia
				  AND g09_numero_cta = rm_b30.b30_numero_cta
			OPEN q_cta
			FETCH q_cta INTO rm_g09.*
			IF STATUS = NOTFOUND THEN
				CLOSE q_cta
				FREE q_cta
				CALL fgl_winmessage(vg_producto, 'No existe ese número de cuenta en la compañía.','exclamation')
				NEXT FIELD b30_numero_cta
			END IF
			CLOSE q_cta
			FREE q_cta
			CALL fl_lee_banco_general(rm_g09.g09_banco)
				RETURNING r_g08.*
			DISPLAY BY NAME r_g08.g08_nombre
			CALL validar_conciliacion() RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b30_numero_cta
			END IF
			IF vm_flag_fecini = 'N' THEN
				LET fecha_ini = rm_b30.b30_fecha_ini
			END IF
			CALL fl_lee_moneda(rm_g09.g09_moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Moneda no existe moneda base.','stop')
			        EXIT PROGRAM
			END IF
			DISPLAY r_g13.g13_nombre TO tit_moneda
			IF r_g13.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD b30_numero_cta
                        END IF
		ELSE
			CLEAR g08_nombre, tit_moneda
		END IF 
	AFTER FIELD b30_fecha_ini 
		IF vm_flag_fecini = 'I' THEN
			IF rm_b30.b30_fecha_ini IS NOT NULL THEN
				IF rm_b30.b30_fecha_ini > TODAY THEN
					CALL fgl_winmessage(vg_producto,'La Fecha Inicial no puede ser mayor a la de hoy.','exclamation')
					NEXT FIELD b30_fecha_ini
				END IF
			END IF
		END IF
		IF vm_flag_fecini = 'N' THEN
			LET rm_b30.b30_fecha_ini = fecha_ini
			DISPLAY BY NAME rm_b30.b30_fecha_ini
		END IF
	AFTER FIELD b30_fecha_fin 
		IF rm_b30.b30_fecha_fin IS NOT NULL THEN
			IF rm_b30.b30_fecha_fin > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La Fecha Final no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD b30_fecha_fin
			END IF
		END IF
	AFTER INPUT
		IF rm_b30.b30_fecha_fin < rm_b30.b30_fecha_ini THEN
			CALL fgl_winmessage(vg_producto,'La Fecha Final debe ser mayor a la Fecha Inicial.','exclamation')
			NEXT FIELD b30_fecha_fin
		END IF
		CALL obtener_saldo_cont()
END INPUT

END FUNCTION



FUNCTION leer_detalle()
DEFINE resp             CHAR(6)
DEFINE i,j		SMALLINT
DEFINE salir		SMALLINT

LET i 	     = 1
LET salir    = 0
OPTIONS
	INSERT KEY F30,
	DELETE KEY F31
WHILE NOT salir
	CALL set_count(vm_num_det)
	LET int_flag = 0
	INPUT ARRAY rm_det WITHOUT DEFAULTS FROM rm_det.*
		ON KEY(INTERRUPT)
       			LET int_flag = 0
	               	CALL fl_mensaje_abandonar_proceso()
		               	RETURNING resp
       			IF resp = 'Yes' THEN
				CALL muestra_lineas_detalle()
				CALL muestra_contadores_det(0)
 	      			LET int_flag = 1
				EXIT WHILE	
       	       		END IF	
		ON KEY(F5)
			CALL ver_comprobante(i)
			LET int_flag = 0
		BEFORE INPUT
			LET vm_scr_lin = fgl_scr_size('r_desp')
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel('INSERT','')
		BEFORE ROW
	       		LET i = arr_curr()
       			LET j = scr_line()
			CALL muestra_contadores_det(i)
			DISPLAY BY NAME rm_referen[i].b13_glosa
			DISPLAY rm_referen[i].referencia TO referen
		BEFORE INSERT
			EXIT INPUT
		AFTER INPUT
			LET salir = 1
	END INPUT
END WHILE
LET vm_num_det = arr_count()
RETURN

END FUNCTION



FUNCTION bloqueo_cabecera()

IF vm_num_rows = 0 THEN
	RETURN 2
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM ctbt030
	WHERE b30_compania   = vg_codcia
	  AND b30_num_concil = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_b30.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN 1
END IF
WHENEVER ERROR STOP
RETURN 0

END FUNCTION



FUNCTION validar_conciliacion()
DEFINE r_b30		RECORD LIKE ctbt030.*
DEFINE r_g14		RECORD LIKE gent014.*

LET rm_b30.b30_compania	= vg_codcia
LET rm_b30.b30_banco	= rm_g09.g09_banco
LET rm_b30.b30_aux_cont	= rm_g09.g09_aux_cont
LET rm_b30.b30_moneda	= rm_g09.g09_moneda
LET rm_b30.b30_paridad	= 1
LET rm_b30.b30_ch_nocob	= 0
LET rm_b30.b30_nd_banco	= 0
LET rm_b30.b30_nc_banco	= 0
LET rm_b30.b30_dp_tran	= 0
LET rm_b30.b30_db_otros	= 0
LET rm_b30.b30_cr_otros	= 0
LET rm_b30.b30_ch_tarj  = 0
LET rm_b30.b30_dp_tarj  = 0
IF rm_b30.b30_moneda <> rg_gen.g00_moneda_base THEN
	CALL fl_lee_factor_moneda(rm_b30.b30_moneda, rg_gen.g00_moneda_base)
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fgl_winmessage(vg_producto,'La paridad para está moneda no existe.','stop')
		EXIT PROGRAM
	END IF
	LET rm_b30.b30_paridad	= r_g14.g14_tasa
END IF
SELECT MAX(b30_num_concil) INTO rm_b30.b30_num_concil FROM ctbt030
	WHERE b30_compania   = vg_codcia
	  AND b30_banco	     = rm_g09.g09_banco
	  AND b30_numero_cta = rm_b30.b30_numero_cta
IF rm_b30.b30_num_concil = 0 OR rm_b30.b30_num_concil IS NULL THEN
	LET vm_flag_fecini   = 'I'
	RETURN 0
END IF
DECLARE q_b30 CURSOR FOR SELECT * FROM ctbt030
		WHERE b30_compania   = vg_codcia
		  AND b30_banco	     = rm_g09.g09_banco
		  AND b30_numero_cta = rm_b30.b30_numero_cta
OPEN q_b30
FETCH q_b30 INTO r_b30.*
IF STATUS <> NOTFOUND THEN
	FOREACH q_b30 INTO r_b30.*
		IF r_b30.b30_estado = 'A' THEN
			CALL fgl_winmessage(vg_producto,'Hay una conciliación activa para este banco. Por favor procésela.','exclamation')
			RETURN 1
		END IF
	END FOREACH
	IF r_b30.b30_estado = 'C' THEN
		LET rm_b30.b30_fecha_ini  = r_b30.b30_fecha_fin  + 1
		LET vm_flag_fecini        = 'N'
	ELSE
		LET vm_flag_fecini        = 'I'
	END IF
END IF
DISPLAY BY NAME rm_b30.b30_fecha_ini
CLOSE q_b30
FREE q_b30
RETURN 0

END FUNCTION



FUNCTION obtener_saldo_cont()
DEFINE fecha		DATE

CALL fl_lee_banco_compania(vg_codcia, rm_b30.b30_banco, rm_b30.b30_numero_cta)
	RETURNING rm_g09.*
IF rm_b30.b30_estado <> 'A' THEN
	RETURN
END IF
LET fecha = rm_b30.b30_fecha_fin
CALL fl_obtiene_saldo_contable(vg_codcia, rm_g09.g09_aux_cont,
				rm_g09.g09_moneda, fecha, 'A')
	RETURNING rm_b30.b30_saldo_cont

END FUNCTION



FUNCTION sacar_total()
DEFINE i	SMALLINT

LET vm_total_deb = 0
LET vm_total_cre = 0
FOR i = 1 TO vm_num_det
	LET vm_total_deb = vm_total_deb	+ rm_det[i].tit_debito
	LET vm_total_cre = vm_total_cre	+ rm_det[i].tit_credito
END FOR
DISPLAY vm_total_deb TO tit_total_deb
DISPLAY vm_total_cre TO tit_total_cre

END FUNCTION



FUNCTION muestra_siguiente_registro(i)
DEFINE i		SMALLINT

LET vm_flag_mov    = 0
IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(i)
CALL mostrar_registro(vm_r_rows[vm_row_current], 1)
IF int_flag THEN
	RETURN
END IF

END FUNCTION



FUNCTION muestra_anterior_registro(i)
DEFINE i		SMALLINT

LET vm_flag_mov    = 0
IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(i)
CALL mostrar_registro(vm_r_rows[vm_row_current], 1)
IF int_flag THEN
	RETURN
END IF

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 66
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro, flag)
DEFINE num_registro	LIKE ctbt030.b30_num_concil
DEFINE flag		SMALLINT
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g13		RECORD LIKE gent013.*

IF vm_num_rows > 0 THEN
	DECLARE q_dt CURSOR FOR SELECT * FROM ctbt030
			WHERE b30_compania   = vg_codcia
			  AND b30_num_concil = num_registro
	OPEN q_dt
	FETCH q_dt INTO rm_b30.*
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,
			'No existe registro con índice: ' || vm_row_current,
			'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_b30.b30_num_concil, rm_b30.b30_fecha_ini,
			rm_b30.b30_fecha_fin, rm_b30.b30_saldo_ec,
			rm_b30.b30_numero_cta
	CALL muestra_estado()
	CALL fl_lee_banco_general(rm_b30.b30_banco) RETURNING r_g08.*
	DISPLAY BY NAME r_g08.g08_nombre
	CALL fl_lee_moneda(rm_b30.b30_moneda) RETURNING r_g13.*
	DISPLAY r_g13.g13_nombre TO tit_moneda
	IF rm_b30.b30_estado <> 'E' THEN
		CALL muestra_detalle(rm_b30.b30_aux_cont, flag)
	ELSE
		LET vm_num_det = 0
		CALL borrar_detalle()
	END IF
	IF int_flag THEN
		RETURN
	END IF
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION muestra_detalle(num_reg, flag)
DEFINE num_reg		LIKE gent009.g09_aux_cont
DEFINE flag		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE numch		VARCHAR(10)
DEFINE orden		SMALLINT
DEFINE i,j		SMALLINT
DEFINE expr_concil	VARCHAR(100)
DEFINE expr_concil2	VARCHAR(100)
DEFINE flag_det		SMALLINT
DEFINE num_cheque	LIKE ctbt032.b32_num_cheque

LET int_flag = 0
CALL borrar_detalle()
IF vm_flag_mant = 'I' THEN
	LET expr_concil  = '  AND b13_num_concil = 0 '
	LET expr_concil2 = '  AND b32_num_concil = 0 '
ELSE
	LET expr_concil  = '  AND b13_num_concil IN (0, ',
				rm_b30.b30_num_concil CLIPPED, ')'
	LET expr_concil2 = '  AND b32_num_concil IN (0, ',
				rm_b30.b30_num_concil CLIPPED, ')'
END IF
DELETE FROM temp_mov
LET query = 'SELECT b13_compania, b13_tipo_comp, b13_num_comp, b13_secuencia, ',
		'b13_cuenta, b13_tipo_doc, b13_glosa, b13_valor_base, ',
		'b13_valor_aux, b13_num_concil, b13_filtro, b13_fec_proceso, ',
		'0, 0',
		' FROM ctbt013 ',
		' WHERE b13_compania     = ', vg_codcia,
		'   AND b13_cuenta       = "', num_reg, '"',
	        '   AND b13_fec_proceso <= "', rm_b30.b30_fecha_fin, '"',
		--expr_concil,
		' UNION ALL ',
		' SELECT b32_compania, b32_tipo_comp, b32_num_comp, ',
		' b32_secuencia, b32_cuenta, b32_tipo_doc, b32_glosa, ',
		' b32_valor_base, b32_valor_aux, b32_num_concil, 0, ',
		' b32_fec_proceso, b32_num_cheque, 1',
		'	FROM ctbt032 ',
		'	WHERE b32_compania     = ', vg_codcia,
		'  	  AND b32_cuenta       = "', num_reg, '"',
	        '         AND b32_fec_proceso <= "', rm_b30.b30_fecha_fin, '"',
		--expr_concil2,
		' ORDER BY 12, 2, 3 '
PREPARE cons1 FROM query	
DECLARE q_cons1 CURSOR FOR cons1
LET vm_num_det = 1
CALL encerar_resumen()
FOREACH q_cons1 INTO rm_b13.b13_compania, rm_b13.b13_tipo_comp,
    	rm_b13.b13_num_comp, rm_b13.b13_secuencia, rm_b13.b13_cuenta,
        rm_b13.b13_tipo_doc, rm_b13.b13_glosa, rm_b13.b13_valor_base,
        rm_b13.b13_valor_aux, rm_b13.b13_num_concil, rm_b13.b13_filtro,
        rm_b13.b13_fec_proceso, num_cheque, flag_det
	IF rm_b13.b13_fec_proceso > rm_b30.b30_fecha_fin THEN
		CONTINUE FOREACH
	END IF

	-- Parche por arranque de saldos que no debe ser conciliado.
	IF flag_det = 0 AND YEAR(rm_b13.b13_fec_proceso) <= 2002 AND
	   (rm_b13.b13_valor_base < -2000 OR rm_b13.b13_valor_base > 2000)
	THEN
		CONTINUE FOREACH
	END IF
	--

	IF vm_flag_mant = 'I' THEN
		IF rm_b13.b13_num_concil <> 0 THEN
			CONTINUE FOREACH
		END IF
	ELSE
		IF rm_b13.b13_num_concil <> 0 THEN
			IF rm_b30.b30_num_concil > rm_b13.b13_num_concil THEN
				CONTINUE FOREACH
			END IF
			IF rm_b13.b13_num_concil > rm_b30.b30_num_concil THEN
				LET rm_b13.b13_num_concil = 0
			END IF
		END IF
	END IF
	IF flag_det = 1 THEN
		LET rm_b12.b12_num_cheque = num_cheque
	ELSE
		CALL fl_lee_comprobante_contable(vg_codcia,rm_b13.b13_tipo_comp,
					         rm_b13.b13_num_comp)
			RETURNING rm_b12.*
		IF rm_b12.b12_estado = 'E' OR
	   		rm_b12.b12_moneda <> rm_g09.g09_moneda THEN
			CONTINUE FOREACH
		END IF
	END IF
	LET numch = NULL
	IF rm_b12.b12_num_cheque IS NOT NULL THEN
		LET numch = rm_b12.b12_num_cheque USING '&&&&&&'
	END IF
	LET rm_det[vm_num_det].b13_fec_proceso = rm_b13.b13_fec_proceso
	IF numch IS NOT NULL THEN
		LET rm_det[vm_num_det].referencia = 'CH-', numch CLIPPED
	ELSE
		IF rm_b13.b13_tipo_doc IS NOT NULL THEN
			LET rm_det[vm_num_det].referencia = rm_b13.b13_tipo_doc,
							    '-',
			 		                    rm_b13.b13_glosa
		ELSE
			LET rm_det[vm_num_det].referencia = rm_b13.b13_glosa
		END IF
	END IF
	LET rm_det[vm_num_det].b13_tipo_comp	= rm_b13.b13_tipo_comp
	LET rm_det[vm_num_det].b13_num_comp	= rm_b13.b13_num_comp
	CALL obtener_valores_deb_cre(vm_num_det, flag_det) RETURNING orden
	LET rm_det[vm_num_det].conciliado 	= 'N'
	LET rm_referen[vm_num_det].b13_tipo_doc = rm_b13.b13_tipo_doc
	IF rm_b13.b13_num_concil > 0 THEN
		LET rm_det[vm_num_det].conciliado = 'S'
	END IF
	IF flag_det = 0 THEN
		CALL calcula_che_gir_nocob(vm_num_det)
		CALL calcula_dep_transito(vm_num_det)
		IF rm_det[vm_num_det].tit_credito < 0 THEN
			CALL calcula_otros_cre(vm_num_det)
		END IF
		IF rm_det[vm_num_det].tit_debito >= 0 THEN
			CALL calcula_otros_deb(vm_num_det)
		END IF
	ELSE
		CALL calcula_che_gir_nocob(vm_num_det)
	END IF
	LET rm_referen[vm_num_det].b13_glosa    = rm_b13.b13_glosa
	LET rm_referen[vm_num_det].referencia   = rm_det[vm_num_det].referencia
	LET rm_referen[vm_num_det].secuen       = rm_b13.b13_secuencia
	LET vm_flag_det[vm_num_det]	        = flag_det
	INSERT INTO temp_mov VALUES(orden, rm_det[vm_num_det].*,
					rm_referen[vm_num_det].*, flag_det)
	LET vm_num_det = vm_num_det + 1
        IF vm_num_det > vm_max_det THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
        END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
DECLARE q_lo CURSOR FOR SELECT * FROM temp_mov
	ORDER BY 3, 2
LET vm_num_det = 1
FOREACH q_lo INTO orden, rm_det[vm_num_det].*,
		rm_referen[vm_num_det].*, vm_flag_det[vm_num_det]
	LET vm_num_det = vm_num_det + 1
END FOREACH
LET vm_num_det = vm_num_det - 1
CALL sacar_total()
CALL llenar_contabilizar()
CALL obtener_saldo_cont()
CALL muestra_detalle_arr(flag)

END FUNCTION



FUNCTION muestra_detalle_arr(flag)
DEFINE flag		SMALLINT
DEFINE i,j, col		SMALLINT
DEFINE orden		SMALLINT
DEFINE query		VARCHAR(800)
DEFINE orden_sql	VARCHAR(100)

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 3
LET vm_columna_2 = 2
LET col          = 3
WHILE TRUE
	LET orden_sql = 
		" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
		       	', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	LET query = 'SELECT * FROM temp_mov ', orden_sql
	PREPARE det FROM query
	DECLARE q_det CURSOR FOR det
	LET vm_num_det = 1
	FOREACH q_det INTO orden, rm_det[vm_num_det].*,
			rm_referen[vm_num_det].*, vm_flag_det[vm_num_det]
		LET vm_num_det = vm_num_det + 1
		IF vm_num_det > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_det = vm_num_det - 1
	IF vm_num_det = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	LET int_flag = 0
	CALL set_count(vm_num_det)
	DISPLAY ARRAY rm_det TO rm_det.*
		BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			IF flag THEN
				LET int_flag = 1
				EXIT DISPLAY
			END IF
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_contadores_det(i)
			DISPLAY BY NAME rm_referen[i].b13_glosa
			DISPLAY rm_referen[i].referencia TO referen
			IF vm_num_det = 0 THEN
				CALL muestra_contadores_det(0)
			END IF
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			CALL ver_comprobante(i)
			LET int_flag = 0
		ON KEY(F15)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 5
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 6
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 7
			EXIT DISPLAY
		ON KEY(F21)
			LET col = 8
			EXIT DISPLAY
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

END FUNCTION



FUNCTION obtener_valores_deb_cre(i, flag_det)
DEFINE i, ord, flag_det	SMALLINT

LET ord = 0
IF rm_b12.b12_moneda = rg_gen.g00_moneda_base OR flag_det = 1 THEN
	IF rm_b13.b13_valor_base >= 0 THEN
		LET rm_det[i].tit_debito  = rm_b13.b13_valor_base
		LET rm_det[i].tit_credito = 0
	ELSE
		LET rm_det[i].tit_debito  = 0
		LET rm_det[i].tit_credito = rm_b13.b13_valor_base
		LET ord = 1
	END IF
ELSE
	IF rm_b13.b13_valor_aux >= 0 THEN
		LET rm_det[i].tit_debito  = rm_b13.b13_valor_aux
		LET rm_det[i].tit_credito = 0
	ELSE
		LET rm_det[i].tit_debito  = 0
		LET rm_det[i].tit_credito = rm_b13.b13_valor_aux
		LET ord = 1
	END IF
END IF
RETURN ord

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR b30_num_concil, b30_estado, tit_estado, b30_numero_cta, g08_nombre,
	b30_fecha_ini, b30_fecha_fin, tit_moneda, b30_saldo_ec
INITIALIZE rm_g09.*, rm_b10.*, rm_b12.*, rm_b13.*, rm_b30.* TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].* TO NULL
        CLEAR rm_det[i].*
	LET rm_det[i].conciliado = 'N'
END FOR
CLEAR tit_total_deb, tit_total_cre, b13_glosa, referen

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 7, 62
DISPLAY cor, " de ", vm_num_det AT 7, 66

END FUNCTION


 
FUNCTION mostrar_botones_detalle()

DISPLAY 'Fecha'   	TO tit_col1
DISPLAY 'Referencia'	TO tit_col2
DISPLAY 'TP'      	TO tit_col3
DISPLAY 'Número'  	TO tit_col4
DISPLAY 'Débito'  	TO tit_col5
DISPLAY 'Crédito' 	TO tit_col6
DISPLAY 'C'       	TO tit_col7

END FUNCTION



FUNCTION muestra_lineas_detalle()
DEFINE i		SMALLINT
DEFINE lineas		SMALLINT

LET lineas = fgl_scr_size('rm_det')
FOR i = 1 TO lineas
	IF i <= vm_num_det THEN
		DISPLAY rm_det[i].* TO rm_det[i].*
	ELSE
		CLEAR rm_det[i].*
	END IF
END FOR

END FUNCTION



FUNCTION muestra_estado()

DISPLAY BY NAME rm_b30.b30_estado
IF rm_b30.b30_estado = 'A' THEN
	DISPLAY 'ACTIVA' TO tit_estado
END IF
IF rm_b30.b30_estado = 'C' THEN
	DISPLAY 'CONCILIADA' TO tit_estado
END IF
IF rm_b30.b30_estado = 'E' THEN
	DISPLAY 'ELIMINADA' TO tit_estado
END IF
RETURN

END FUNCTION



FUNCTION ver_comprobante(i)
DEFINE i		SMALLINT

IF vm_num_det = 0 THEN
	CALL fgl_winmessage(vg_producto,'No hay comprobante para mostrar.','exclamation')
	RETURN
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
	vg_separador, 'fuentes', vg_separador, '; fglrun ctbp201 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', '"', rm_det[i].b13_tipo_comp, '"',
	' ', '"', rm_det[i].b13_num_comp, '"'
RUN vm_nuevoprog

END FUNCTION



FUNCTION control_contabilizar()

OPEN WINDOW w_mov AT 05, 02
        WITH FORM '../forms/ctbf203_2'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   BORDER)
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Nivel no está configurado.','stop')
	EXIT PROGRAM
END IF
CALL mostrar_botones_mov()
IF vm_flag_mov = 0 THEN
	CALL llenar_contabilizar()
	DISPLAY vm_total_val TO tit_total_val
	LET vm_flag_mov  = 1
END IF
LET int_flag = 0
IF rm_b30.b30_estado <> 'C' AND num_args() <> 4 THEN
	CALL leer_contabilizar()
	IF NOT int_flag THEN
		CALL grabar_contabilizar()
	END IF
ELSE
	CALL sacar_total_mov(vm_num_mov)
	DISPLAY vm_total_val TO tit_total_val
	CALL muestra_detalle_mov()
END IF
CLOSE WINDOW w_mov
IF int_flag THEN
	RETURN
END IF

END FUNCTION



FUNCTION control_cerrar()
DEFINE tipo		CHAR(2)
DEFINE i		SMALLINT
DEFINE valor_base	DECIMAL(12,2)
DEFINE valor_aux	DECIMAL(12,2)
DEFINE num_concil	VARCHAR(10)
DEFINE secuencia	SMALLINT
DEFINE resul		SMALLINT

IF vm_num_det = 0 AND vm_num_mov = 0 THEN
	CALL fgl_winmessage(vg_producto, 'Conciliación no puede ser cerrada sin tener movimientos.', 'exclamation')
	RETURN
END IF
IF rm_b30.b30_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Conciliación no puede ser cerrada.', 'exclamation')
	RETURN
END IF
CALL control_resumen() RETURNING resul
IF resul = 1 THEN
	RETURN
END IF
LET int_flag = 1
LET tipo		= NULL 
LET rm_b12.b12_num_comp	= NULL
LET vm_num_mov = 0     -- SE ADICIONO ESTA LINEA PORQUE DITECA NO GENERA COMP.
IF vm_num_mov > 0 THEN
	LET num_concil		   = rm_b30.b30_num_concil 
	LET tipo 		   = 'DC'
	LET rm_b12.b12_fec_proceso = rm_b30.b30_fecha_fin
	LET rm_b12.b12_compania    = vg_codcia
	LET rm_b12.b12_tipo_comp   = tipo
	LET rm_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia, 
					rm_b12.b12_tipo_comp,
					YEAR(rm_b12.b12_fec_proceso), 
					MONTH(rm_b12.b12_fec_proceso))
	IF rm_b12.b12_num_comp = -1 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET rm_b12.b12_estado	   = 'A'
	LET rm_b12.b12_subtipo     = NULL
	LET rm_b12.b12_glosa       = 'CONCILIACION # ' || num_concil CLIPPED
	LET rm_b12.b12_benef_che   = NULL
	LET rm_b12.b12_num_cheque  = NULL
	LET rm_b12.b12_origen      = 'A'
	LET rm_b12.b12_moneda	   = rm_b30.b30_moneda
	LET rm_b12.b12_paridad	   = rm_b30.b30_paridad
	LET rm_b12.b12_fec_reversa = NULL
	LET rm_b12.b12_tip_reversa = NULL
	LET rm_b12.b12_num_reversa = NULL
	LET rm_b12.b12_fec_modifi  = NULL
	LET rm_b12.b12_modulo	   = 'CB'
	LET rm_b12.b12_usuario     = vg_usuario
	LET rm_b12.b12_fecing      = CURRENT
	INSERT INTO ctbt012 VALUES(rm_b12.*)
	FOR i = 1 TO vm_num_mov
		CALL obtener_valores_deb_cre_mov(i)
			RETURNING valor_base, valor_aux
		INSERT INTO ctbt013
			VALUES(vg_codcia, rm_b12.b12_tipo_comp,
				rm_b12.b12_num_comp, i,
				rm_mov[i].b31_cuenta,
				rm_mov[i].b31_tipo_doc,
				rm_mov[i].b31_glosa, valor_base,
				valor_aux, rm_b30.b30_num_concil,
				NULL, rm_b12.b12_fec_proceso)
	END FOR
	LET rm_b12.b12_glosa = rm_b12.b12_glosa CLIPPED, ' ',
				'(CONTRAPAR.)'
	IF rm_b30.b30_moneda = rg_gen.g00_moneda_base THEN
		LET valor_base = vm_total_val * (-1)
		LET valor_aux  = 0
	ELSE
		LET valor_base = 0
		LET valor_aux  = vm_total_val * (-1)
	END IF
	LET secuencia = vm_num_mov + 1
	INSERT INTO ctbt013
		VALUES(vg_codcia, rm_b12.b12_tipo_comp,
			rm_b12.b12_num_comp, secuencia,
			rm_b30.b30_aux_cont, NULL, rm_b12.b12_glosa,
			valor_base, valor_aux, rm_b30.b30_num_concil,
			NULL, rm_b12.b12_fec_proceso)
END IF
LET rm_b30.b30_estado = 'C'
UPDATE ctbt030 SET b30_estado       = rm_b30.b30_estado,
		   b30_fecha_cie    = CURRENT,
		   b30_tipcomp_gen  = tipo,
		   b30_numcomp_gen  = rm_b12.b12_num_comp,
		   b30_saldo_cont   = rm_b30.b30_saldo_cont,
		   b30_ch_nocob	    = rm_resu[1].valor_concil,
		   b30_nd_banco	    = rm_resu[2].valor_concil,
		   b30_nc_banco	    = rm_resu[3].valor_concil,
		   b30_dp_tran	    = rm_resu[4].valor_concil,
		   b30_db_otros	    = rm_resu[5].valor_concil,
		   b30_cr_otros	    = rm_resu[6].valor_concil,
		   b30_ch_tarj      = vm_total_chc,
		   b30_dp_tarj      = vm_total_dep
	WHERE CURRENT OF q_up
CALL muestra_estado()
COMMIT WORK
IF vm_num_mov > 0 THEN
	CALL fl_mayoriza_comprobante(vg_codcia,
		rm_b12.b12_tipo_comp, rm_b12.b12_num_comp, 'M')
END IF
CALL fgl_winmessage(vg_producto,'Conciliación ha sido cerrada.', 'info')

END FUNCTION



FUNCTION control_resumen()
DEFINE resul, i		SMALLINT

CALL obtener_saldo_cont()
OPEN WINDOW w_res AT 03, 08
        WITH FORM '../forms/ctbf203_3'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
CALL mostrar_botones_res()
LET rm_resu[1].descripcion = '(+) CHEQUES GIRADOS Y NO COBRADOS'
LET rm_resu[2].descripcion = '(-) N/D BANCARIAS NO CONTABILIZADAS'
LET rm_resu[3].descripcion = '(+) N/C NO CONTABILIZADAS'
LET rm_resu[4].descripcion = '(-) DEPOSITOS EN TRANSITO'
LET rm_resu[5].descripcion = '(+) OTROS CREDITOS CONTAB. Y QUE NO ESTAN EN E/C'
LET rm_resu[6].descripcion = '(-) OTROS DEBITOS CONTAB. Y QUE NO ESTAN EN E/C'
LET vm_total_con = rm_b30.b30_saldo_cont
LET vm_num_res   = 6
FOR i = 1 TO vm_num_res
	LET vm_total_con = vm_total_con + rm_resu[i].valor_concil
        IF vm_num_res > vm_max_res THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
        END IF
END FOR
DISPLAY rm_b30.b30_saldo_ec	TO saldo_ec
DISPLAY rm_b30.b30_fecha_fin	TO fecha_al
DISPLAY rm_b30.b30_saldo_cont	TO saldo_co
DISPLAY vm_total_con		TO tit_total_con
DISPLAY vm_total_chc		TO tit_total_chc
DISPLAY vm_total_dep		TO tit_total_dep
DISPLAY rm_b30.b30_tipcomp_gen	TO tipo_comp
DISPLAY rm_b30.b30_numcomp_gen	TO num_comp
LET int_flag = 0
CALL muestra_detalle_res() RETURNING resul
CLOSE WINDOW w_res
RETURN resul

END FUNCTION



FUNCTION leer_contabilizar()
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE codt_aux		LIKE ctbt007.b07_tipo_doc
DEFINE nomt_aux		LIKE ctbt007.b07_nombre
DEFINE r_b07		RECORD LIKE ctbt007.*
DEFINE resp             CHAR(6)
DEFINE i, j, k, l	SMALLINT
DEFINE resul		SMALLINT

OPTIONS INPUT WRAP
LET i = 1
LET int_flag = 0
CALL set_count(vm_num_mov)
INPUT ARRAY rm_mov WITHOUT DEFAULTS FROM rm_mov.*
	ON KEY(INTERRUPT)
       		LET int_flag = 0
               	CALL fl_mensaje_abandonar_proceso()
	               	RETURNING resp
       		IF resp = 'Yes' THEN
       			LET int_flag = 1
			FOR k = 1 TO vm_num_mov
				LET rm_mov[k].* = rm_mov_aux[k].*
			END FOR
        		RETURN
       	       	END IF	
	ON KEY(F2)
		IF INFIELD(b31_tipo_doc) THEN
			CALL fl_ayuda_tipos_documentos_fuentes()
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
               	              	LET rm_mov[i].b31_tipo_doc = codt_aux
				DISPLAY rm_mov[i].b31_tipo_doc TO 
					rm_mov[j].b31_tipo_doc
			END IF 
		END IF
		IF INFIELD(b31_cuenta) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
               	              	LET rm_mov[i].b31_cuenta = cod_aux
				DISPLAY rm_mov[i].b31_cuenta TO 
					rm_mov[j].b31_cuenta
			END IF 
		END IF
	BEFORE ROW
       		LET i = arr_curr()
       		LET j = scr_line()
		LET l = arr_count()
		CALL sacar_total_mov(l)
		DISPLAY vm_total_val TO tit_total_val
	AFTER FIELD b31_tipo_doc
		IF rm_mov[i].b31_tipo_doc IS NOT NULL THEN
		       CALL fl_lee_tipo_documento_fuente(rm_mov[i].b31_tipo_doc)
				RETURNING r_b07.*
			IF r_b07.b07_tipo_doc IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe ese Tipo de Documento.', 'exclamation')
				NEXT FIELD b31_tipo_doc
			END IF
			IF r_b07.b07_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD b31_tipo_doc
			END IF
		ELSE
			IF rm_mov[i].b31_cuenta IS NOT NULL THEN
				CALL fgl_winmessage(vg_producto, 'Digite Tipo de Documento.', 'exclamation')
				NEXT FIELD b31_tipo_doc
			END IF
		END IF
	AFTER FIELD b31_cuenta
		IF rm_mov[i].b31_cuenta IS NOT NULL THEN
			CALL validar_nivel_cuenta(i) RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b31_cuenta
			END IF
		END IF 
	AFTER FIELD valor
		IF rm_mov[i].valor IS NOT NULL THEN
			CALL sacar_total_mov(l)
			DISPLAY vm_total_val TO tit_total_val
		END IF
	AFTER INPUT
		LET vm_num_mov = arr_count()
		FOR k = 1 TO vm_num_mov
			LET rm_mov_aux[k].* = rm_mov[k].*
		END FOR
END INPUT

END FUNCTION



FUNCTION llenar_contabilizar()
DEFINE r_b31		RECORD LIKE ctbt031.*

DECLARE q_cont CURSOR FOR SELECT * FROM ctbt031
	WHERE b31_compania   = vg_codcia
	  AND b31_num_concil = rm_b30.b30_num_concil
       	ORDER BY b31_tipo_doc 
LET rm_resu[2].valor_concil = 0
LET rm_resu[3].valor_concil = 0
LET vm_num_mov = 1
FOREACH q_cont INTO r_b31.*
	LET rm_mov[vm_num_mov].b31_tipo_doc = r_b31.b31_tipo_doc
	LET rm_mov[vm_num_mov].b31_cuenta   = r_b31.b31_cuenta
	LET rm_mov[vm_num_mov].b31_glosa    = r_b31.b31_glosa
	IF rm_b30.b30_moneda = rg_gen.g00_moneda_base THEN
		LET rm_mov[vm_num_mov].valor = r_b31.b31_valor_base
	ELSE
		LET rm_mov[vm_num_mov].valor = r_b31.b31_valor_aux
	END IF
	LET rm_mov_aux[vm_num_mov].* = rm_mov[vm_num_mov].*
	IF rm_mov[vm_num_mov].valor >= 0 THEN
		CALL calcula_nd_contab(vm_num_mov)
	ELSE
		CALL calcula_nc_contab(vm_num_mov)
	END IF
	LET vm_num_mov = vm_num_mov + 1
        IF vm_num_mov > vm_max_mov THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
        END IF
END FOREACH
LET vm_num_mov = vm_num_mov - 1
CALL sacar_total_mov(vm_num_mov)
CLOSE q_cont

END FUNCTION



FUNCTION grabar_contabilizar()
DEFINE r_b31		RECORD LIKE ctbt031.*
DEFINE i		SMALLINT
DEFINE valor_base	DECIMAL(12,2)
DEFINE valor_aux	DECIMAL(12,2)

DELETE FROM ctbt031
	WHERE b31_compania   = vg_codcia
	  AND b31_num_concil = vm_r_rows[vm_row_current]
LET rm_resu[2].valor_concil = 0
LET rm_resu[3].valor_concil = 0
FOR i = 1 TO vm_num_mov
	CALL obtener_valores_deb_cre_mov(i) RETURNING valor_base, valor_aux
	INSERT INTO ctbt031 VALUES(vg_codcia, vm_r_rows[vm_row_current], i,
				rm_mov[i].b31_tipo_doc, rm_mov[i].b31_cuenta,
				rm_mov[i].b31_glosa, valor_base, valor_aux)
	IF rm_mov[i].valor >= 0 THEN
		CALL calcula_nd_contab(i)
	ELSE
		CALL calcula_nc_contab(i)
	END IF
END FOR

END FUNCTION



FUNCTION obtener_valores_deb_cre_mov(i)
DEFINE i		SMALLINT
DEFINE valor_base	DECIMAL(12,2)
DEFINE valor_aux	DECIMAL(12,2)

IF rm_b30.b30_moneda = rg_gen.g00_moneda_base THEN
	LET valor_base = rm_mov[i].valor
	LET valor_aux  = 0
ELSE
	LET valor_base = 0
	LET valor_aux  = rm_mov[i].valor
END IF
RETURN valor_base, valor_aux

END FUNCTION



FUNCTION validar_nivel_cuenta(i)
DEFINE i		SMALLINT
DEFINE r_ctb		RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, rm_mov[i].b31_cuenta) RETURNING r_ctb.*
IF r_ctb.b10_cuenta IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Cuenta no existe.','exclamation')
	RETURN 1
END IF
IF r_ctb.b10_nivel <> vm_nivel AND r_ctb.b10_nivel <> vm_nivel - 1
AND r_ctb.b10_nivel <> vm_nivel - 2 THEN
	CALL fgl_winmessage(vg_producto,'Cuenta debe ser mínimo del nivel ' || vm_nivel - 2 || '.', 'exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION sacar_total_mov(num_elm)
DEFINE num_elm, i	SMALLINT

LET vm_total_val = 0
FOR i = 1 TO num_elm
	LET vm_total_val = vm_total_val	+ rm_mov[i].valor
END FOR

END FUNCTION



FUNCTION mostrar_botones_mov()

DISPLAY 'Mov'   	TO tit_col1
DISPLAY 'Cuenta'	TO tit_col2
DISPLAY 'Glosa'      	TO tit_col3
DISPLAY 'Valor'  	TO tit_col4

END FUNCTION



FUNCTION muestra_detalle_mov()
DEFINE i,j              SMALLINT

CALL set_count(vm_num_mov)
DISPLAY ARRAY rm_mov TO rm_mov.*
	BEFORE ROW
        	LET i = arr_curr()
        	LET j = scr_line()
	BEFORE DISPLAY
        	--#CALL dialog.keysetlabel("ACCEPT","")
	AFTER DISPLAY
        	CONTINUE DISPLAY
	ON KEY(INTERRUPT)
        	EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION mostrar_botones_res()

DISPLAY 'Descripción'  	TO tit_col1
DISPLAY 'Totales'	TO tit_col2

END FUNCTION



FUNCTION muestra_detalle_res()
DEFINE i,j              SMALLINT

CALL set_count(vm_num_res)
DISPLAY ARRAY rm_resu TO rm_resu.*
	BEFORE ROW
        	LET i = arr_curr()
        	LET j = scr_line()
	BEFORE DISPLAY
        	--#CALL dialog.keysetlabel("ACCEPT","")
		IF rm_b30.b30_estado = 'C' THEN
   	     		--#CALL dialog.keysetlabel("F5","")
		ELSE
   	     		--#CALL dialog.keysetlabel("F5","Grabar")
		END IF
	AFTER DISPLAY
        	CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN 1
	ON KEY(F5)
		IF rm_b30.b30_estado <> 'C' THEN
			IF vm_total_con <> rm_b30.b30_saldo_ec THEN
				CALL fgl_winmessage(vg_producto, 'No puede cerrar la conciliación sin cuadrarla antes.', 'exclamation')
        			CONTINUE DISPLAY
			END IF
			LET int_flag = 0
       	 		EXIT DISPLAY
		END IF
        	CONTINUE DISPLAY
END DISPLAY
RETURN 0

END FUNCTION



FUNCTION inicializar_conciliacion()

CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_botones_detalle()
LET vm_flag_mant = 'I'

END FUNCTION



FUNCTION encerar_resumen()
DEFINE i		SMALLINT

LET vm_total_chc = 0
LET vm_total_dep = 0
FOR i = 1 TO vm_max_res
	LET rm_resu[i].valor_concil = 0
END FOR

END FUNCTION



FUNCTION calcula_che_gir_nocob(i)
DEFINE i		SMALLINT

IF rm_det[i].b13_fec_proceso <= rm_b30.b30_fecha_fin THEN
	IF rm_det[i].b13_tipo_comp = 'EG' OR 
	   rm_referen[i].b13_tipo_doc = 'CHE' THEN
		IF rm_det[i].conciliado = 'N' THEN
			LET rm_resu[1].valor_concil = rm_resu[1].valor_concil +
		          ((rm_det[i].tit_debito + rm_det[i].tit_credito) * -1)
		ELSE
			LET vm_total_chc = vm_total_chc +
			 	    rm_det[i].tit_debito + rm_det[i].tit_credito
		END IF
	END IF
END IF

END FUNCTION



FUNCTION calcula_nd_contab(i)
DEFINE i		SMALLINT

LET rm_resu[2].valor_concil = rm_resu[2].valor_concil + (rm_mov[i].valor * -1)

END FUNCTION



FUNCTION calcula_nc_contab(i)
DEFINE i		SMALLINT

LET rm_resu[3].valor_concil = rm_resu[3].valor_concil + (rm_mov[i].valor * -1)

END FUNCTION



FUNCTION calcula_dep_transito(i)
DEFINE i		SMALLINT

IF rm_det[i].b13_fec_proceso <= rm_b30.b30_fecha_fin THEN
	IF rm_det[i].b13_tipo_comp = 'DP' OR
	   rm_referen[i].b13_tipo_doc = 'DEP' THEN
		IF rm_det[i].conciliado = 'N' THEN
			LET rm_resu[4].valor_concil = rm_resu[4].valor_concil +
			   ((rm_det[i].tit_debito + rm_det[i].tit_credito) * -1)
		ELSE
			LET vm_total_dep = vm_total_dep +
			 	    rm_det[i].tit_debito + rm_det[i].tit_credito
		END IF
	END IF
END IF

END FUNCTION



FUNCTION calcula_otros_cre(i)
DEFINE i		SMALLINT

IF rm_det[i].b13_fec_proceso <= rm_b30.b30_fecha_fin THEN
	IF rm_det[i].conciliado = 'N' THEN
 		IF rm_det[i].b13_tipo_comp    <> 'EG'  AND
 		   rm_det[i].b13_tipo_comp    <> 'DP'  AND
	          (rm_referen[i].b13_tipo_doc IS NULL OR
	          (rm_referen[i].b13_tipo_doc <> 'CHE' AND
	           rm_referen[i].b13_tipo_doc <> 'DEP')) THEN
			LET rm_resu[5].valor_concil = rm_resu[5].valor_concil +
			  ((rm_det[i].tit_debito + rm_det[i].tit_credito) * -1)
		END IF
	END IF
END IF

END FUNCTION



FUNCTION calcula_otros_deb(i)
DEFINE i		SMALLINT

IF rm_det[i].b13_fec_proceso <= rm_b30.b30_fecha_fin THEN
	IF rm_det[i].conciliado = 'N' THEN
 		IF rm_det[i].b13_tipo_comp    <> 'EG'  AND
 		   rm_det[i].b13_tipo_comp    <> 'DP'  AND
	          (rm_referen[i].b13_tipo_doc IS NULL OR
                  (rm_referen[i].b13_tipo_doc <> 'CHE' AND
	           rm_referen[i].b13_tipo_doc <> 'DEP')) THEN
			LET rm_resu[6].valor_concil = rm_resu[6].valor_concil +
			  ((rm_det[i].tit_debito + rm_det[i].tit_credito) * -1)
		END IF
	END IF
END IF

END FUNCTION



FUNCTION no_validar_parametros()

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
