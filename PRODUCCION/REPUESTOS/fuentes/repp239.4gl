------------------------------------------------------------------------------
-- Titulo           : repp239.4gl - Conteo Fisico del Inventario
-- Elaboracion      : 29-dic-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp239 base módulo compañía localidad (grafico)
--                    fglgo repp239 base módulo compañía localidad (caracter)
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g02		RECORD LIKE gent002.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_vend		RECORD LIKE rept001.*
DEFINE rm_r89		RECORD LIKE rept089.*
DEFINE vm_r_rows	ARRAY [20000] OF INTEGER
DEFINE vm_num_rows      SMALLINT
DEFINE vm_row_current   SMALLINT
DEFINE vm_max_rows      SMALLINT
DEFINE rm_dif		ARRAY [50] OF RECORD
				r89_usuario	LIKE rept089.r89_usuario,
				r89_suma	LIKE rept089.r89_suma
			END RECORD



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp239.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 9 THEN
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp239'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag
IF int_flag THEN
	RETURN
END IF
LET vm_max_rows = 20000
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
IF rm_g01.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compania.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_g02.*
IF rm_g02.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 20
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repp239 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf239_1 FROM "../forms/repf239_1"
ELSE
	OPEN FORM f_repf239_1 FROM "../forms/repf239_1c"
END IF
DISPLAY FORM f_repf239_1
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
DECLARE qu_vd CURSOR FOR SELECT * FROM rept001
	WHERE r01_compania   = vg_codcia
	  AND r01_user_owner = vg_usuario
OPEN qu_vd
INITIALIZE rm_vend.* TO NULL
FETCH qu_vd INTO rm_vend.*
IF STATUS = NOTFOUND THEN
	IF rm_g05.g05_tipo = 'UF' THEN
		CALL fl_mostrar_mensaje('Usted no está configurado en la tabla de vendedores/bodegueros.','stop')
		RETURN
	END IF
END IF
INITIALIZE rm_r89.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Diferencia'
		IF num_args() = 9 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Diferencia'
                	CALL control_consulta()
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar registro corriente. '
                CALL control_ingreso()
                IF vm_num_rows <= 1 THEN
                        SHOW OPTION 'Modificar'
			SHOW OPTION 'Diferencia'
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
                        	HIDE OPTION 'Modificar'
				HIDE OPTION 'Diferencia'
                        END IF
                ELSE
                        SHOW OPTION 'Modificar'
			SHOW OPTION 'Diferencia'
                        SHOW OPTION 'Avanzar'
                END IF
	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
                CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
                CALL control_consulta()
                IF vm_num_rows <= 1 THEN
                        SHOW OPTION 'Modificar'
			SHOW OPTION 'Diferencia'
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
                        	HIDE OPTION 'Modificar'
				HIDE OPTION 'Diferencia'
                        END IF
                ELSE
                        SHOW OPTION 'Modificar'
			SHOW OPTION 'Diferencia'
                        SHOW OPTION 'Avanzar'
                END IF
                IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('D') 'Diferencia'
		CALL muestra_otra_difrencia()
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
	COMMAND KEY('R') 'Retroceder' 'Ver anterior registro. '
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



FUNCTION bloquear_registro()

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rept089
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_r89.*
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN 1
END IF
WHENEVER ERROR STOP
RETURN 0

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_r89		RECORD LIKE rept089.*

CLEAR FORM
CALL datos_defaults()
IF rm_r89.r89_bodega IS NULL THEN
	{--
	IF vg_usuario <> 'HSALAZAR' THEN
		CALL fl_mostrar_mensaje('Su usuario no esta configurado para registrar INVENTARIO FISICO.', 'exclamation')
		RETURN
	END IF
	--}
END IF
CALL muestra_datos_reg()
CALL leer_datos('I')
IF NOT int_flag THEN
	SELECT NVL(MAX(r89_secuencia), 0) + 1 INTO rm_r89.r89_secuencia
		FROM rept089
		WHERE r89_compania  = rm_r89.r89_compania
		  AND r89_localidad = rm_r89.r89_localidad
		  AND r89_usuario   = rm_r89.r89_usuario
		  AND r89_anio      = rm_r89.r89_anio
		  AND r89_mes       = rm_r89.r89_mes
	LET rm_r89.r89_fecing = fl_current()
	IF rm_r89.r89_stock_act IS NULL THEN
		LET rm_r89.r89_stock_act = 0
	END IF
	INSERT INTO rept089 VALUES(rm_r89.*)
	CALL ubicar_posicion(SQLCA.SQLERRD[6])
	CALL muestra_datos_reg()
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_modificacion()

CALL mostrar_registro(vm_r_rows[vm_row_current])
IF bloquear_registro() THEN
	ROLLBACK WORK
	RETURN
END IF
CALL leer_datos('M')
IF int_flag THEN
	ROLLBACK WORK
	CALL mostrar_registro(vm_r_rows[vm_row_current])
	RETURN
END IF
LET rm_r89.r89_usu_modifi = vg_usuario
LET rm_r89.r89_fec_modifi = fl_current()
UPDATE rept089 SET * = rm_r89.* WHERE CURRENT OF q_up
COMMIT WORK
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(600)
DEFINE num_reg		INTEGER
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE r_r89		RECORD LIKE rept089.*

CLEAR FORM
IF num_args() = 4 THEN
	INITIALIZE r_r21.* TO NULL
	LET rm_r89.r89_usuario = vg_usuario
	SELECT MAX(YEAR(r89_fecing))
		INTO rm_r89.r89_anio
		FROM rept089
		WHERE r89_compania  = vg_codcia
		  AND r89_localidad = vg_codloc
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r89_bodega, r89_anio, r89_item,
		r89_secuencia, r89_bueno, r89_incompleto, r89_mal_est, r89_suma,
		r89_stock_act, r89_usuario, r89_usu_modifi
		ON KEY(F1, CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(r89_bodega) THEN
				LET rm_r89.r89_bodega = GET_FLDBUF(r89_bodega)
				CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc,
							'A', 'F', 'A', 'T', '2')
					RETURNING r_r02.r02_codigo,
						  r_r02.r02_nombre 
				LET int_flag = 0
				IF r_r02.r02_codigo IS NOT NULL THEN
					DISPLAY r_r02.r02_codigo TO r89_bodega
					DISPLAY BY NAME r_r02.r02_nombre
				END IF
			END IF
			IF INFIELD(r89_item) THEN
				LET rm_r89.r89_item = GET_FLDBUF(r89_item)
				CALL fl_ayuda_maestro_items_stock(vg_codcia,
						r_r21.r21_grupo_linea,
						rm_r89.r89_bodega)
	                     		RETURNING r_r10.r10_codigo,
						  r_r10.r10_nombre,
						  r_r10.r10_linea,
						  r_r10.r10_precio_mb,
						  r_r11.r11_bodega,
						  r_r11.r11_stock_act
				LET int_flag = 0
				IF r_r10.r10_codigo IS NOT NULL THEN
					DISPLAY r_r10.r10_codigo TO r89_item
					DISPLAY BY NAME r_r10.r10_nombre
				END IF
			END IF
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1", "")
			--#CALL dialog.keysetlabel("CONTROL-W", "")
			IF rm_g05.g05_tipo = 'UF' OR
			   (rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G')
			THEN
				DISPLAY BY NAME rm_r89.r89_usuario
			END IF
			DISPLAY BY NAME rm_r89.r89_anio
		AFTER FIELD r89_bodega
			LET rm_r89.r89_bodega = GET_FLDBUF(r89_bodega)	
			IF rm_r89.r89_bodega IS NOT NULL THEN
				CALL fl_lee_bodega_rep(vg_codcia,
							rm_r89.r89_bodega)
					RETURNING r_r02.*
				IF r_r02.r02_compania IS NULL THEN
					CALL fl_mostrar_mensaje('No existe esta Bodega.','exclamation')
					NEXT FIELD r89_bodega
				END IF
				DISPLAY BY NAME r_r02.r02_nombre
				IF r_r02.r02_estado = 'B' THEN
					CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD r89_bodega
				END IF
			ELSE
				CLEAR r02_nombre
			END IF
		AFTER FIELD r89_item
			LET rm_r89.r89_item = GET_FLDBUF(r89_item)	
			IF rm_r89.r89_item IS NOT NULL THEN
				CALL fl_lee_item(vg_codcia, rm_r89.r89_item)
					RETURNING r_r10.*
				IF r_r10.r10_compania IS NULL THEN
					CALL fl_mostrar_mensaje('No existe este Item.','exclamation')
					NEXT FIELD r89_item
				END IF
				DISPLAY BY NAME r_r10.r10_nombre
				IF r_r10.r10_estado = 'B' THEN
					CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD r89_item
				END IF
			ELSE
				CLEAR r10_nombre
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
ELSE
	LET expr_sql = '       r89_bodega    = "', arg_val(5), '"',
		       '   AND r89_item      = "', arg_val(6), '"',
		       '   AND r89_usuario   = "', arg_val(7), '"',
		       '   AND r89_anio      =  ', arg_val(8),
		       '   AND r89_mes       =  ', arg_val(9)
END IF
LET query = 'SELECT *, ROWID FROM rept089 ',
		' WHERE r89_compania  = ', vg_codcia,
		'   AND r89_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		--'   AND r89_anio     >= 2006 ',
		' ORDER BY r89_usuario, r89_secuencia DESC'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO r_r89.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() <> 4 THEN
		EXIT PROGRAM
	END IF
	CLEAR FORM
	LET vm_row_current = 0
	LET vm_num_rows    = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET vm_row_current = 1
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL mostrar_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION datos_defaults()

INITIALIZE rm_r89.* TO NULL
LET rm_r89.r89_compania   = vg_codcia
LET rm_r89.r89_localidad  = vg_codloc
IF vg_usuario = 'PABLMONT' OR vg_usuario = 'CARLCACE' OR vg_usuario = 'DOUGCAMP'
THEN
	LET rm_r89.r89_bodega = '60'
END IF
IF vg_usuario = 'KARIARIC' THEN
	LET rm_r89.r89_bodega = '62'
END IF
IF vg_usuario = 'HERIVALE' OR vg_usuario = 'MOISCALD' THEN
	LET rm_r89.r89_bodega = '64'
END IF
IF vg_usuario = 'WASHVERA' THEN
	LET rm_r89.r89_bodega = 'E0'
END IF
IF vg_usuario = 'DIANMEND' THEN
	LET rm_r89.r89_bodega = 'E2'
END IF
SELECT NVL(MAX(YEAR(r11_fec_corte)), YEAR(vg_fecha))
	INTO rm_r89.r89_anio
	FROM resp_exis
	WHERE r11_compania = vg_codcia
LET rm_r89.r89_mes        = MONTH(vg_fecha)
LET rm_r89.r89_stock_act  = 0
LET rm_r89.r89_bueno      = 0
LET rm_r89.r89_incompleto = 0
LET rm_r89.r89_mal_est    = 0
LET rm_r89.r89_suma       = 0
LET rm_r89.r89_fecha      = vg_fecha
LET rm_r89.r89_usuario    = vg_usuario
LET rm_r89.r89_fecing     = fl_current()
CALL calcular_diferencia()

END FUNCTION



FUNCTION leer_datos(flag)
DEFINE flag		CHAR(1)
DEFINE resp      	CHAR(6)
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r31		RECORD LIKE rept031.*
DEFINE r_resp		RECORD LIKE resp_exis.*
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE r_r89		RECORD LIKE rept089.*
DEFINE bod_aux		LIKE rept002.r02_codigo
DEFINE item_aux		LIKE rept010.r10_codigo
DEFINE stock_dan	LIKE resp_exis.r11_stock_act

INITIALIZE r_r21.* TO NULL
LET int_flag  = 0 
INPUT BY NAME rm_r89.r89_bodega, rm_r89.r89_item, rm_r89.r89_bueno,
	rm_r89.r89_incompleto, rm_r89.r89_mal_est
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_r89.r89_bodega, rm_r89.r89_item,
				 rm_r89.r89_bueno, rm_r89.r89_incompleto,
				 rm_r89.r89_mal_est)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				CLEAR FORM
				EXIT INPUT
			END IF
		ELSE
			CLEAR FORM
			EXIT INPUT
                END IF       	
        ON KEY(F1, CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r89_bodega) THEN
			IF flag = 'M' THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', 'F', 'A', 'T', '2')
				RETURNING r_r02.r02_codigo,
					  r_r02.r02_nombre 
			LET int_flag = 0
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET rm_r89.r89_bodega = r_r02.r02_codigo
				DISPLAY r_r02.r02_codigo TO r89_bodega
				DISPLAY BY NAME r_r02.r02_nombre
			END IF
		END IF
		IF INFIELD(r89_item) THEN
			IF flag = 'M' THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_maestro_items_stock(vg_codcia,
					r_r21.r21_grupo_linea,rm_r89.r89_bodega)
                     		RETURNING r_r10.r10_codigo, r_r10.r10_nombre,
					  r_r10.r10_linea, r_r10.r10_precio_mb,
					  r_r11.r11_bodega, r_r11.r11_stock_act
			LET int_flag = 0
			IF r_r10.r10_codigo IS NOT NULL THEN
				LET rm_r89.r89_item = r_r10.r10_codigo
				DISPLAY r_r10.r10_codigo TO r89_item
				DISPLAY BY NAME r_r10.r10_nombre
			END IF
		END IF
	ON KEY(F5)
		CALL muestra_otra_difrencia()
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD r89_bodega
		{--
		IF vg_usuario <> 'HSALAZAR' THEN
			NEXT FIELD NEXT
		END IF
		--}
		IF flag = 'M' THEN
			LET bod_aux  = rm_r89.r89_bodega
			LET item_aux = rm_r89.r89_item
		END IF
	BEFORE FIELD r89_item
		IF flag = 'M' THEN
			LET bod_aux  = rm_r89.r89_bodega
			LET item_aux = rm_r89.r89_item
		END IF
	AFTER FIELD r89_bodega
		IF flag = 'M' THEN
			LET rm_r89.r89_bodega = bod_aux
			CALL fl_lee_bodega_rep(vg_codcia, rm_r89.r89_bodega)
				RETURNING r_r02.*
			DISPLAY BY NAME rm_r89.r89_bodega, r_r02.r02_nombre
			CONTINUE INPUT
		END IF
		IF rm_r89.r89_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_r89.r89_bodega)
				RETURNING r_r02.*
			IF r_r02.r02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe esta Bodega.','exclamation')
				NEXT FIELD r89_bodega
			END IF
			DISPLAY BY NAME r_r02.r02_nombre
			IF r_r02.r02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r89_bodega
			END IF
			IF r_r02.r02_area <> 'R' THEN
				CALL fl_mostrar_mensaje('Esta Bodega no es de Inventario.','exclamation')
				NEXT FIELD r89_bodega
			END IF
			IF r_r02.r02_tipo <> 'F' THEN
				CALL fl_mostrar_mensaje('Esta Bodega no es Fisica.','exclamation')
				NEXT FIELD r89_bodega
			END IF
			IF r_r02.r02_localidad <> vg_codloc THEN
				CALL fl_mostrar_mensaje('Esta Bodega no es de esta Localidad.','exclamation')
				NEXT FIELD r89_bodega
			END IF
		ELSE
			CLEAR r02_nombre
		END IF
	AFTER FIELD r89_item
		IF flag = 'M' THEN
			LET rm_r89.r89_item = item_aux
			CALL fl_lee_item(vg_codcia, rm_r89.r89_item)
				RETURNING r_r10.*
			DISPLAY BY NAME rm_r89.r89_item, r_r10.r10_nombre
			CONTINUE INPUT
		END IF
		IF rm_r89.r89_bodega IS NULL THEN
			CALL fl_mostrar_mensaje('Digite primero la Bodega.','exclamation')
			NEXT FIELD r89_bodega
		END IF
		IF rm_r89.r89_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_r89.r89_item)
				RETURNING r_r10.*
			IF r_r10.r10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este Item.','exclamation')
				LET rm_r89.r89_item = NULL
				DISPLAY BY NAME rm_r89.r89_item
				NEXT FIELD r89_item
			END IF
			DISPLAY BY NAME r_r10.r10_nombre
			IF r_r10.r10_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r89_item
			END IF
			CALL lee_registro_fisico(vg_codcia, vg_codloc,
					rm_r89.r89_bodega, rm_r89.r89_item,
					rm_r89.r89_usuario, rm_r89.r89_anio,
					rm_r89.r89_mes)
				RETURNING r_r89.*
			IF r_r89.r89_compania IS NOT NULL THEN
				CALL fl_mostrar_mensaje('El Item de esta Bodega ya fue ingresado, modifíquelo si desea actualizarlo.','exclamation')
				NEXT FIELD r89_item
			END IF
			CALL lee_resp_exis(vg_codcia, rm_r89.r89_bodega,
						rm_r89.r89_item)
				RETURNING r_resp.*
			IF r_resp.r11_compania IS NULL THEN
				DECLARE q_r31 CURSOR FOR
					SELECT * FROM rept031
					WHERE r31_compania = vg_codcia
					  AND r31_bodega   = rm_r89.r89_bodega
					  AND r31_item     = rm_r89.r89_item
					ORDER BY r31_ano DESC, r31_mes DESC
				OPEN q_r31
				FETCH q_r31 INTO r_r31.*
				IF STATUS = NOTFOUND THEN
					--CLOSE q_r31
					--FREE q_r31
					CALL fl_mostrar_mensaje('Este Item no tiene registro en el Maestro de Existencias.', 'exclamation')
					--NEXT FIELD r89_item
				END IF
				CLOSE q_r31
				FREE q_r31
				LET r_resp.r11_stock_act = r_r31.r31_stock
			ELSE
				IF NOT pertenece_item_bodega() THEN
					CALL fl_mostrar_mensaje('Este Item no pertenece a esta Bodega.', 'exclamation')
					--NEXT FIELD r89_item
				END IF
			END IF
			--CALL retorna_stock_danado() RETURNING stock_dan
			LET stock_dan = 0
			LET rm_r89.r89_stock_act = r_resp.r11_stock_act +
							stock_dan
			LET rm_r89.r89_fec_corte = r_resp.r11_fec_corte
			DISPLAY BY NAME rm_r89.r89_stock_act,
					rm_r89.r89_fec_corte
			CALL calcular_valores()
			IF r_resp.r11_fec_corte IS NULL THEN
				CALL fl_mostrar_mensaje('La fecha de corte de este item en esta bodega no existe. LLAME AL ADMINISTRADOR.', 'exclamation')
				CONTINUE INPUT
			END IF
		ELSE
			CLEAR r10_nombre
		END IF
	AFTER FIELD r89_bueno, r89_incompleto, r89_mal_est
		CALL calcular_valores()
	AFTER INPUT
		CALL calcular_valores()
END INPUT

END FUNCTION



FUNCTION retorna_reg_rowid()
DEFINE num_rowid	INTEGER

SELECT ROWID INTO num_rowid FROM rept089
	WHERE r89_compania  = vg_codcia
	  AND r89_localidad = vg_codloc
	  AND r89_bodega    = rm_r89.r89_bodega
	  AND r89_item      = rm_r89.r89_item
CALL ubicar_posicion(num_rowid)
CALL mostrar_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION ubicar_posicion(num)
DEFINE num		INTEGER

IF vm_num_rows = vm_max_rows OR vm_num_rows = 0 THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_r_rows[vm_num_rows] = num
LET vm_row_current         = vm_num_rows

END FUNCTION



FUNCTION pertenece_item_bodega()
DEFINE resul		SMALLINT
DEFINE r_resp		RECORD LIKE resp_exis.*

DECLARE q_veri CURSOR FOR
	SELECT * FROM resp_exis
		WHERE r11_compania = vg_codcia
		  AND r11_item     = rm_r89.r89_item
LET resul = 0
FOREACH q_veri INTO r_resp.*
	IF rm_r89.r89_bodega = r_resp.r11_bodega THEN
		LET resul = 1
		EXIT FOREACH
	END IF
END FOREACH
RETURN resul

END FUNCTION



FUNCTION retorna_stock_danado()
DEFINE r_r31		RECORD LIKE rept031.*
DEFINE stock_dan	LIKE resp_exis.r11_stock_act

SELECT NVL(r11_stock_act, 0) INTO stock_dan
	FROM resp_exis
	WHERE r11_compania = vg_codcia
	  AND r11_bodega IN
		(SELECT te_bodega_dan FROM te_boddan
			WHERE te_compania  = r11_compania
			  AND te_localidad = vg_codloc
			  AND te_bodega    = rm_r89.r89_bodega)
	  AND r11_item     = rm_r89.r89_item
IF STATUS = NOTFOUND THEN
	INITIALIZE r_r31.* TO NULL
	DECLARE q_dan CURSOR FOR
		SELECT * FROM rept031
			WHERE r31_compania = vg_codcia
			  AND r31_bodega IN
				(SELECT te_bodega_dan FROM te_boddan
					WHERE te_compania  = r31_compania
					  AND te_localidad = vg_codloc
					  AND te_bodega    = rm_r89.r89_bodega)
			  AND r31_item     = rm_r89.r89_item
			ORDER BY r31_ano DESC, r31_mes DESC
	OPEN q_dan
	FETCH q_dan INTO r_r31.*
	CLOSE q_dan
	FREE q_dan
	IF r_r31.r31_compania IS NULL THEN
		LET r_r31.r31_stock = 0
	END IF
	LET stock_dan = r_r31.r31_stock
END IF
RETURN stock_dan

END FUNCTION



FUNCTION calcular_valores()

LET rm_r89.r89_suma = rm_r89.r89_bueno + rm_r89.r89_incompleto +
			rm_r89.r89_mal_est
DISPLAY BY NAME rm_r89.r89_suma
CALL calcular_diferencia()

END FUNCTION



FUNCTION cursor_dif(flag)
DEFINE flag		SMALLINT
DEFINE query		CHAR(800)
DEFINE expr_usu		VARCHAR(100)

LET expr_usu = NULL
IF flag = 1 THEN
	LET expr_usu = '   AND r89_usuario  <> "', rm_r89.r89_usuario, '"'
END IF
LET query = 'SELECT * FROM rept089 ',
		' WHERE r89_compania  = ', vg_codcia,
		'   AND r89_localidad = ', vg_codloc,
		'   AND r89_bodega    = "', rm_r89.r89_bodega, '"',
		'   AND r89_item      = "', rm_r89.r89_item CLIPPED, '"',
		expr_usu CLIPPED,
		'   AND r89_anio      = ', rm_r89.r89_anio,
		'   AND r89_mes       = ', rm_r89.r89_mes,
		' ORDER BY r89_usuario '
PREPARE cons_dif FROM query
DECLARE q_dif CURSOR FOR cons_dif

END FUNCTION



FUNCTION calcular_diferencia()
DEFINE r_r89		RECORD LIKE rept089.*
DEFINE tit_diferencia	DECIMAL(8,2)
DEFINE total		DECIMAL(8,2)

LET total = 0
CALL cursor_dif(1)
FOREACH q_dif INTO r_r89.*
	LET total = total + r_r89.r89_suma
END FOREACH
LET tit_diferencia = rm_r89.r89_suma + total - rm_r89.r89_stock_act
DISPLAY BY NAME tit_diferencia

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
        LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
        LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE num_fil		SMALLINT
DEFINE num_col		SMALLINT

LET num_fil = 1
LET num_col = 65
IF vg_gui = 0 THEN
	LET num_fil = 3
	LET num_col = 66
END IF
DISPLAY "" AT num_fil, num_col
DISPLAY row_current, " de ", num_rows AT num_fil, num_col

END FUNCTION



FUNCTION mostrar_registro(num_reg)
DEFINE num_reg		INTEGER
DEFINE mensaje		VARCHAR(100)

IF vm_num_rows <= 0 THEN
	RETURN
END IF
DECLARE q_dt CURSOR FOR
	SELECT * FROM rept089
		WHERE ROWID = num_reg
OPEN q_dt
FETCH q_dt INTO rm_r89.*
IF STATUS = NOTFOUND THEN
	LET mensaje = 'No existe registro con ROWID: ',
			vm_row_current USING "<<<&"
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN
END IF	
CALL muestra_datos_reg()
CLOSE q_dt

END FUNCTION



FUNCTION muestra_datos_reg()
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*

DISPLAY BY NAME rm_r89.r89_bodega, rm_r89.r89_item, rm_r89.r89_secuencia,
		rm_r89.r89_stock_act, rm_r89.r89_fec_corte, rm_r89.r89_bueno,
		rm_r89.r89_incompleto, rm_r89.r89_mal_est, rm_r89.r89_suma,
		rm_r89.r89_anio, rm_r89.r89_usuario, rm_r89.r89_usu_modifi,
		rm_r89.r89_fecing, rm_r89.r89_fec_modifi
CALL calcular_diferencia()
CALL fl_lee_bodega_rep(vg_codcia, rm_r89.r89_bodega) RETURNING r_r02.*
CALL fl_lee_item(vg_codcia, rm_r89.r89_item) RETURNING r_r10.*
DISPLAY BY NAME r_r02.r02_nombre, r_r10.r10_nombre

END FUNCTION



FUNCTION lee_registro_fisico(codcia, codloc, bodega, item, usuario, anio, mes)
DEFINE codcia		LIKE rept089.r89_compania
DEFINE codloc		LIKE rept089.r89_localidad
DEFINE bodega		LIKE rept089.r89_bodega
DEFINE item		LIKE rept089.r89_item
DEFINE usuario		LIKE rept089.r89_usuario
DEFINE anio		LIKE rept089.r89_anio
DEFINE mes		LIKE rept089.r89_mes
DEFINE r_r89		RECORD LIKE rept089.*

INITIALIZE r_r89.* TO NULL
SELECT * INTO r_r89.* FROM rept089
	WHERE r89_compania  = codcia
	  AND r89_localidad = codloc
	  AND r89_bodega    = bodega
	  AND r89_item      = item
	  AND r89_usuario   = usuario
	  AND r89_anio      = anio
	  --AND r89_mes       = mes
RETURN r_r89.*

END FUNCTION



FUNCTION lee_resp_exis(codcia, bodega, item)
DEFINE codcia		LIKE resp_exis.r11_compania
DEFINE bodega		LIKE resp_exis.r11_bodega
DEFINE item		LIKE resp_exis.r11_item
DEFINE r_resp		RECORD LIKE resp_exis.*

INITIALIZE r_resp.* TO NULL
SELECT * INTO r_resp.*
	FROM resp_exis
	WHERE r11_compania = codcia
	  AND r11_bodega   = bodega
	  AND r11_item     = item
RETURN r_resp.*

END FUNCTION



FUNCTION muestra_otra_difrencia()
DEFINE r_r89		RECORD LIKE rept089.*
DEFINE tit_total	DECIMAL (8,2)
DEFINE tit_diferencia	DECIMAL (8,2)
DEFINE i, j		SMALLINT
DEFINE row_ini		SMALLINT

LET row_ini = 3
IF vg_gui = 0 THEN
	LET row_ini = 6
END IF
OPEN WINDOW w_cont_2 AT row_ini, 49 WITH 14 ROWS, 30 COLUMNS
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
IF vg_gui = 1 THEN                                                              
	OPEN FORM f_repf239_2 FROM '../forms/repf239_2'
ELSE
	OPEN FORM f_repf239_2 FROM '../forms/repf239_2c'
END IF
DISPLAY FORM f_repf239_2
--#DISPLAY "Usuario"	TO tit_col1
--#DISPLAY "Total Ing."	TO tit_col2
FOR j = 1 TO 50
	INITIALIZE rm_dif[j].* TO NULL
END FOR
DISPLAY BY NAME rm_r89.r89_stock_act
CALL cursor_dif(2)
LET i = 1
LET tit_total = 0
FOREACH q_dif INTO r_r89.*
	LET rm_dif[i].r89_usuario = r_r89.r89_usuario
	LET rm_dif[i].r89_suma    = r_r89.r89_suma
       	LET tit_total             = tit_total + r_r89.r89_suma
	LET i = i + 1
	IF i > 50 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 0
	CLOSE WINDOW w_cont_2
	RETURN
END IF
LET tit_diferencia = tit_total - rm_r89.r89_stock_act
FOR j = 1 TO fgl_scr_size('rm_dif')
	IF j > i THEN
		EXIT FOR
	END IF
	DISPLAY rm_dif[j].* TO rm_dif[j].*
END FOR
DISPLAY BY NAME tit_total, tit_diferencia
CALL set_count(i)
DISPLAY ARRAY rm_dif TO rm_dif.*
	ON KEY(INTERRUPT)   
		EXIT DISPLAY  
	ON KEY(F1,CONTROL-W) 
		CALL llamar_visor_teclas()
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
LET int_flag = 0
CLOSE WINDOW w_cont_2
RETURN

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
