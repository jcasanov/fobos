------------------------------------------------------------------------------
-- Titulo           : repp238.4gl - Conteo Fisico del Inventario
-- Elaboracion      : 29-dic-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp238 base módulo compañía localidad (grafico)
--                    fglgo repp238 base módulo compañía localidad (caracter)
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g02		RECORD LIKE gent002.*
DEFINE rm_sto		RECORD LIKE te_stofis.*
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE vm_num_rows      SMALLINT
DEFINE vm_row_current   SMALLINT
DEFINE vm_max_rows      SMALLINT
DEFINE begin_act	SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp238.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp238'
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
LET vm_max_rows = 1000
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
LET num_rows = 18
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repp238 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf238 FROM "../forms/repf238_1"
ELSE
	OPEN FORM f_repf238 FROM "../forms/repf238_1c"
END IF
DISPLAY FORM f_repf238
INITIALIZE rm_sto.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar registro corriente. '
                CALL control_ingreso()
                IF vm_num_rows <= 1 THEN
                        SHOW OPTION 'Modificar'
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
                        	HIDE OPTION 'Modificar'
                        END IF
                ELSE
                        SHOW OPTION 'Modificar'
                        SHOW OPTION 'Avanzar'
                END IF
	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
                CALL control_modificacion(1)
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
                CALL control_consulta()
                IF vm_num_rows <= 1 THEN
                        SHOW OPTION 'Modificar'
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
                        	HIDE OPTION 'Modificar'
                        END IF
                ELSE
                        SHOW OPTION 'Modificar'
                        SHOW OPTION 'Avanzar'
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
	SELECT * FROM te_stofis
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_sto.*
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN 1
END IF
WHENEVER ERROR STOP
RETURN 0

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_sto		RECORD LIKE te_stofis.*

CLEAR FORM
CALL datos_defaults(1)
WHILE TRUE
	CALL muestra_datos_reg()
	CALL leer_datos('I')
	IF int_flag THEN
		IF begin_act THEN
			ROLLBACK WORK
		END IF
		EXIT WHILE
	END IF
	CALL lee_registro_fisico(vg_codcia, vg_codloc, rm_sto.te_bodega,
					rm_sto.te_item)
		RETURNING r_sto.*
	IF r_sto.te_compania IS NOT NULL THEN
                CALL control_modificacion(0)
		CALL datos_defaults(2)
		CONTINUE WHILE
	END IF
	LET rm_sto.te_fecing = fl_current()
	INSERT INTO te_stofis VALUES(rm_sto.*)
	CALL ubicar_posicion(SQLCA.SQLERRD[6])
	CALL fl_mensaje_registro_ingresado()
	CALL datos_defaults(2)
	CALL muestra_datos_reg()
END WHILE
IF vm_num_rows > 0 THEN
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_consulta()
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(600)
DEFINE num_reg		INTEGER
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE r_sto		RECORD LIKE te_stofis.*

CLEAR FORM
INITIALIZE r_r21.* TO NULL
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON te_bodega, te_fecha, te_item, te_bueno,
	te_incompleto, te_mal_est, te_suma, te_stock_act, te_usuario
	ON KEY(F1, CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(te_bodega) THEN
			LET rm_sto.te_bodega = GET_FLDBUF(te_bodega)
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', 'F', 'A', 'T', '2')
				RETURNING r_r02.r02_codigo,
					  r_r02.r02_nombre 
			LET int_flag = 0
			IF r_r02.r02_codigo IS NOT NULL THEN
				DISPLAY r_r02.r02_codigo TO te_bodega
				DISPLAY BY NAME r_r02.r02_nombre
			END IF
		END IF
		IF INFIELD(te_item) THEN
			LET rm_sto.te_item = GET_FLDBUF(te_item)
			CALL fl_ayuda_maestro_items_stock(vg_codcia,
					r_r21.r21_grupo_linea, rm_sto.te_bodega)
                     		RETURNING r_r10.r10_codigo, r_r10.r10_nombre,
					  r_r10.r10_linea, r_r10.r10_precio_mb,
					  r_r11.r11_bodega, r_r11.r11_stock_act
			LET int_flag = 0
			IF r_r10.r10_codigo IS NOT NULL THEN
				DISPLAY r_r10.r10_codigo TO te_item
				DISPLAY BY NAME r_r10.r10_nombre
			END IF
		END IF
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1", "")
		--#CALL dialog.keysetlabel("CONTROL-W", "")
	AFTER FIELD te_bodega
		LET rm_sto.te_bodega = GET_FLDBUF(te_bodega)	
		IF rm_sto.te_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_sto.te_bodega)
				RETURNING r_r02.*
			IF r_r02.r02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe esta Bodega.','exclamation')
				NEXT FIELD te_bodega
			END IF
			DISPLAY BY NAME r_r02.r02_nombre
			IF r_r02.r02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD te_bodega
			END IF
		ELSE
			CLEAR r02_nombre
		END IF
	AFTER FIELD te_item
		LET rm_sto.te_item = GET_FLDBUF(te_item)	
		IF rm_sto.te_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_sto.te_item)
				RETURNING r_r10.*
			IF r_r10.r10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este Item.','exclamation')
				NEXT FIELD te_item
			END IF
			DISPLAY BY NAME r_r10.r10_nombre
			IF r_r10.r10_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD te_item
			END IF
			IF rm_sto.te_bodega IS NOT NULL THEN
				CALL lee_registro_fisico(vg_codcia, vg_codloc,
						rm_sto.te_bodega,rm_sto.te_item)
					RETURNING r_sto.*
				IF r_sto.te_compania IS NOT NULL THEN
					LET rm_sto.* = r_sto.*
					CALL muestra_datos_reg()
				END IF
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
LET query = 'SELECT *, ROWID FROM te_stofis ',
		' WHERE te_compania  = ', vg_codcia,
		'   AND te_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY te_bodega, te_item '
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO r_sto.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
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



FUNCTION datos_defaults(flag)
DEFINE flag		SMALLINT

CASE flag
	WHEN 1
		INITIALIZE rm_sto.* TO NULL
	WHEN 2
		LET rm_sto.te_item       = NULL
		LET rm_sto.te_fec_modifi = NULL
END CASE
LET rm_sto.te_compania   = vg_codcia
LET rm_sto.te_localidad  = vg_codloc
LET rm_sto.te_stock_act  = 0
LET rm_sto.te_bueno      = 0
LET rm_sto.te_incompleto = 0
LET rm_sto.te_mal_est    = 0
LET rm_sto.te_suma       = 0
LET rm_sto.te_fecha      = vg_fecha
LET rm_sto.te_usuario    = vg_usuario
LET rm_sto.te_fecing     = fl_current()
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
DEFINE r_sto		RECORD LIKE te_stofis.*
DEFINE bod_aux		LIKE rept002.r02_codigo
DEFINE item_aux		LIKE rept010.r10_codigo
DEFINE stock_dan	LIKE resp_exis.r11_stock_act

INITIALIZE r_r21.* TO NULL
LET begin_act = 0
LET int_flag  = 0 
INPUT BY NAME rm_sto.te_bodega, rm_sto.te_item, rm_sto.te_bueno,
	rm_sto.te_incompleto, rm_sto.te_mal_est
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_sto.te_bodega, rm_sto.te_item,
				 rm_sto.te_bueno, rm_sto.te_incompleto,
				 rm_sto.te_mal_est)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				CLEAR FORM
				RETURN
			END IF
		ELSE
			CLEAR FORM
			RETURN
                END IF       	
        ON KEY(F1, CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(te_bodega) THEN
			IF flag = 'M' THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', 'F', 'A', 'T', '2')
				RETURNING r_r02.r02_codigo,
					  r_r02.r02_nombre 
			LET int_flag = 0
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET rm_sto.te_bodega = r_r02.r02_codigo
				DISPLAY r_r02.r02_codigo TO te_bodega
				DISPLAY BY NAME r_r02.r02_nombre
			END IF
		END IF
		IF INFIELD(te_item) THEN
			IF flag = 'M' THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_maestro_items_stock(vg_codcia,
					r_r21.r21_grupo_linea, rm_sto.te_bodega)
                     		RETURNING r_r10.r10_codigo, r_r10.r10_nombre,
					  r_r10.r10_linea, r_r10.r10_precio_mb,
					  r_r11.r11_bodega, r_r11.r11_stock_act
			LET int_flag = 0
			IF r_r10.r10_codigo IS NOT NULL THEN
				LET rm_sto.te_item = r_r10.r10_codigo
				DISPLAY r_r10.r10_codigo TO te_item
				DISPLAY BY NAME r_r10.r10_nombre
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD te_bodega, te_item
		IF flag = 'M' THEN
			LET bod_aux  = rm_sto.te_bodega
			LET item_aux = rm_sto.te_item
		END IF
	AFTER FIELD te_bodega
		IF flag = 'M' THEN
			LET rm_sto.te_bodega = bod_aux
			CALL fl_lee_bodega_rep(vg_codcia, rm_sto.te_bodega)
				RETURNING r_r02.*
			DISPLAY BY NAME rm_sto.te_bodega, r_r02.r02_nombre
			CONTINUE INPUT
		END IF
		IF rm_sto.te_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_sto.te_bodega)
				RETURNING r_r02.*
			IF r_r02.r02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe esta Bodega.','exclamation')
				NEXT FIELD te_bodega
			END IF
			DISPLAY BY NAME r_r02.r02_nombre
			IF r_r02.r02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD te_bodega
			END IF
			IF r_r02.r02_area <> 'R' THEN
				CALL fl_mostrar_mensaje('Esta Bodega no es de Inventario.','exclamation')
				NEXT FIELD te_bodega
			END IF
			IF r_r02.r02_tipo <> 'F' THEN
				CALL fl_mostrar_mensaje('Esta Bodega no es Fisica.','exclamation')
				NEXT FIELD te_bodega
			END IF
			IF r_r02.r02_localidad <> vg_codloc THEN
				CALL fl_mostrar_mensaje('Esta Bodega no es de esta Localidad.','exclamation')
				NEXT FIELD te_bodega
			END IF
		ELSE
			CLEAR r02_nombre
		END IF
	AFTER FIELD te_item
		IF flag = 'M' THEN
			LET rm_sto.te_item = item_aux
			CALL fl_lee_item(vg_codcia, rm_sto.te_item)
				RETURNING r_r10.*
			DISPLAY BY NAME rm_sto.te_item, r_r10.r10_nombre
			CONTINUE INPUT
		END IF
		IF rm_sto.te_bodega IS NULL THEN
			CALL fl_mostrar_mensaje('Digite primero la Bodega.','exclamation')
			NEXT FIELD te_bodega
		END IF
		IF rm_sto.te_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_sto.te_item)
				RETURNING r_r10.*
			IF r_r10.r10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este Item.','exclamation')
				LET rm_sto.te_item = NULL
				DISPLAY BY NAME rm_sto.te_item
				NEXT FIELD te_item
			END IF
			DISPLAY BY NAME r_r10.r10_nombre
			IF r_r10.r10_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD te_item
			END IF
			CALL lee_resp_exis(vg_codcia, rm_sto.te_bodega,
						rm_sto.te_item)
				RETURNING r_resp.*
			IF r_resp.r11_compania IS NULL THEN
				DECLARE q_r31 CURSOR FOR SELECT * INTO r_r31.*
					FROM rept031
					WHERE r31_compania = vg_codcia
					  AND r31_bodega   = rm_sto.te_bodega
					  AND r31_item     = rm_sto.te_item
					ORDER BY r31_ano DESC, r31_mes DESC
				OPEN q_r31
				FETCH q_r31 INTO r_r31.*
				IF STATUS = NOTFOUND THEN
					CLOSE q_r31
					FREE q_r31
					CALL fl_mostrar_mensaje('Este Item no tiene registro en el Maestro de Existencias.', 'exclamation')
					NEXT FIELD te_item
				END IF
				LET r_resp.r11_stock_act = r_r31.r31_stock
			ELSE
				IF NOT pertenece_item_bodega() THEN
					CALL fl_mostrar_mensaje('Este Item no pertenece a esta Bodega.', 'exclamation')
					NEXT FIELD te_item
				END IF
			END IF
			CALL retorna_stock_danado() RETURNING stock_dan
			LET rm_sto.te_stock_act = r_resp.r11_stock_act +
							stock_dan
			DISPLAY BY NAME rm_sto.te_stock_act
			IF flag = 'I' THEN
				CALL lee_registro_fisico(vg_codcia, vg_codloc,
						rm_sto.te_bodega,rm_sto.te_item)
					RETURNING r_sto.*
				IF r_sto.te_compania IS NOT NULL THEN
					LET rm_sto.* = r_sto.*
					LET rm_sto.te_usuario = vg_usuario
					CALL muestra_datos_reg()
					CALL retorna_reg_rowid()
					IF bloquear_registro() THEN
						ROLLBACK WORK
						CONTINUE INPUT
					END IF
					LET begin_act = 1
					IF rm_sto.te_stock_act <
					 (r_resp.r11_stock_act + stock_dan) THEN
						LET rm_sto.te_stock_act =
						r_resp.r11_stock_act + stock_dan
					     DISPLAY BY NAME rm_sto.te_stock_act
					END IF
					LET flag = 'M'
				END IF
			END IF
		ELSE
			CLEAR r10_nombre
		END IF
	AFTER FIELD te_bueno, te_incompleto, te_mal_est
		CALL calcular_valores()
	AFTER INPUT
		CALL calcular_valores()
END INPUT

END FUNCTION



FUNCTION control_modificacion(flag)
DEFINE flag		SMALLINT

IF flag THEN
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
END IF
LET rm_sto.te_fec_modifi = fl_current()
UPDATE te_stofis SET * = rm_sto.* WHERE CURRENT OF q_up
COMMIT WORK
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION retorna_reg_rowid()
DEFINE num_rowid	INTEGER

SELECT ROWID INTO num_rowid FROM te_stofis
	WHERE te_compania  = vg_codcia
	  AND te_localidad = vg_codloc
	  AND te_bodega    = rm_sto.te_bodega
	  AND te_item      = rm_sto.te_item
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
		  AND r11_item     = rm_sto.te_item
LET resul = 0
FOREACH q_veri INTO r_resp.*
	IF rm_sto.te_bodega = r_resp.r11_bodega THEN
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
			  AND te_bodega    = rm_sto.te_bodega)
	  AND r11_item     = rm_sto.te_item
IF STATUS = NOTFOUND THEN
	INITIALIZE r_r31.* TO NULL
	DECLARE q_dan CURSOR FOR
		SELECT * FROM rept031
			WHERE r31_compania = vg_codcia
			  AND r31_bodega IN
				(SELECT te_bodega_dan FROM te_boddan
					WHERE te_compania  = r31_compania
					  AND te_localidad = vg_codloc
					  AND te_bodega    = rm_sto.te_bodega)
			  AND r31_item     = rm_sto.te_item
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

LET rm_sto.te_suma = rm_sto.te_bueno + rm_sto.te_incompleto + rm_sto.te_mal_est
DISPLAY BY NAME rm_sto.te_suma
CALL calcular_diferencia()

END FUNCTION



FUNCTION calcular_diferencia()
DEFINE tit_diferencia	DECIMAL(8,2)

LET tit_diferencia = rm_sto.te_suma - rm_sto.te_stock_act
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
	SELECT * FROM te_stofis
		WHERE ROWID = num_reg
OPEN q_dt
FETCH q_dt INTO rm_sto.*
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

DISPLAY BY NAME rm_sto.te_bodega, rm_sto.te_item, rm_sto.te_stock_act,
		rm_sto.te_bueno, rm_sto.te_incompleto, rm_sto.te_mal_est,
		rm_sto.te_suma,	rm_sto.te_fecha, rm_sto.te_fec_modifi,
		rm_sto.te_usuario, rm_sto.te_fecing
CALL calcular_diferencia()
CALL fl_lee_bodega_rep(vg_codcia, rm_sto.te_bodega) RETURNING r_r02.*
CALL fl_lee_item(vg_codcia, rm_sto.te_item) RETURNING r_r10.*
DISPLAY BY NAME r_r02.r02_nombre, r_r10.r10_nombre

END FUNCTION



FUNCTION lee_registro_fisico(codcia, codloc, bodega, item)
DEFINE codcia		LIKE te_stofis.te_compania
DEFINE codloc		LIKE te_stofis.te_localidad
DEFINE bodega		LIKE te_stofis.te_bodega
DEFINE item		LIKE te_stofis.te_item
DEFINE r_sto		RECORD LIKE te_stofis.*

INITIALIZE r_sto.* TO NULL
SELECT * INTO r_sto.* FROM te_stofis
	WHERE te_compania  = codcia
	  AND te_localidad = codloc
	  AND te_bodega    = bodega
	  AND te_item      = item
RETURN r_sto.*

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



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
