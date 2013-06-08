------------------------------------------------------------------------------
-- Titulo           : repp235.4gl - Cambio de precios masivo
-- Elaboracion      : 06-Abr-2004
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp235 base modulo compania [codigo] [flag]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_r85   	RECORD LIKE rept085.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE vm_row_current   SMALLINT        	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT		-- MAXIMO DE FILAS LEIDAS
DEFINE rm_orden 	ARRAY[15] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp235.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 AND num_args() <> 5 THEN
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'repp235'
CALL fl_activar_base_datos(vg_base)
IF num_args() <> 3 THEN
	UPDATE gent054 SET g54_estado = 'A'
		WHERE g54_modulo  = vg_modulo
		  AND g54_proceso = vg_proceso
		  AND g54_estado  = 'R'
END IF
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
IF num_args() <> 3 THEN
	UPDATE gent054 SET g54_estado = 'R'
		WHERE g54_modulo  = vg_modulo
		  AND g54_proceso = vg_proceso
		  AND g54_estado  = 'A'
END IF
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
IF num_args() = 5 THEN
	CALL muestra_detalle()
	EXIT PROGRAM
END IF
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
OPEN WINDOW w_inventario AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf235_1 FROM '../forms/repf235_1'
ELSE
	OPEN FORM f_repf235_1 FROM '../forms/repf235_1c'
END IF
DISPLAY FORM f_repf235_1
INITIALIZE rm_r85.* TO NULL
LET vm_max_rows    = 1000
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Reversar'
		HIDE OPTION 'Detalle Items'
		IF num_args() <> 3 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			IF num_args() = 4 THEN
				CALL control_consulta()
				SHOW OPTION 'Detalle Items'
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 'Cambiar precios por parametros.'
		CALL control_ingreso()
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Reversar'
			SHOW OPTION 'Detalle Items'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Reversar'
			SHOW OPTION 'Detalle Items'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
				HIDE OPTION 'Reversar'
				HIDE OPTION 'Detalle Items'
			END IF
		ELSE
			SHOW OPTION 'Reversar'
			SHOW OPTION 'Detalle Items'
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('E') 'Reversar' 'Reversa el registro corriente. '
		CALL control_reversar()
	COMMAND KEY('D') 'Detalle Items' 'Muestra detalle de Items. '
		CALL muestra_detalle()
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		CALL control_muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL control_muestra_anterior_registro()
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



FUNCTION control_ingreso()
DEFINE cuantos		INTEGER
DEFINE num_aux		INTEGER
DEFINE mensaje		VARCHAR(100)

CLEAR FORM
OPTIONS INPUT WRAP
INITIALIZE rm_r85.* TO NULL
LET rm_r85.r85_compania    = vg_codcia
LET rm_r85.r85_fec_camprec = TODAY
LET rm_r85.r85_estado      = 'A'
LET rm_r85.r85_precio_nue  = 0
LET rm_r85.r85_porc_aum    = 0
LET rm_r85.r85_porc_dec    = 0
LET rm_r85.r85_usuario     = vg_usuario
LET rm_r85.r85_fecing      = CURRENT
DISPLAY BY NAME rm_r85.r85_fec_camprec, rm_r85.r85_estado,rm_r85.r85_precio_nue,
		rm_r85.r85_porc_aum, rm_r85.r85_porc_dec, rm_r85.r85_fecing,
		rm_r85.r85_usuario
CALL muestra_estado()
CALL leer_parametros()
IF NOT int_flag THEN
	BEGIN WORK
		IF NOT cambia_precios_items_masivos() THEN
			DROP TABLE tmp_prec1
			ROLLBACK WORK
			CLEAR FORM
			IF vm_num_rows > 0 THEN
				CALL lee_muestra_registro(
						vm_r_rows[vm_row_current])
			END IF
			CALL muestra_contadores(vm_row_current, vm_num_rows)
			RETURN
		END IF
		SELECT NVL(MAX(r85_codigo), 0) + 1 INTO rm_r85.r85_codigo
			FROM rept085
			WHERE r85_compania = rm_r85.r85_compania
		LET rm_r85.r85_fecing = CURRENT
        	INSERT INTO rept085 VALUES (rm_r85.*)
		LET num_aux = SQLCA.SQLERRD[6] 
		CALL genera_detalle()
        	IF vm_num_rows = vm_max_rows THEN
	                LET vm_num_rows = 1
	        ELSE
	                LET vm_num_rows = vm_num_rows + 1
	        END IF
		LET vm_r_rows[vm_num_rows] = num_aux
		LET vm_row_current = vm_num_rows
	COMMIT WORK
	SELECT COUNT(*) INTO cuantos FROM tmp_prec1
	DROP TABLE tmp_prec1
	LET mensaje = 'Se actualizaron precios de ', cuantos USING "<<<<&",
			' Items.'
	CALL fl_mostrar_mensaje(mensaje, 'info')
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1200)
DEFINE capitulo		LIKE gent016.g16_capitulo
DEFINE r_g16		RECORD LIKE gent016.*
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE r_r77		RECORD LIKE rept077.*

CLEAR FORM
IF num_args() <> 4 THEN
	INITIALIZE capitulo TO NULL
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r85_codigo, r85_fec_camprec, r85_estado,
		r85_referencia, r85_division, r85_linea, r85_cod_grupo,
		r85_cod_clase, r85_marca, r85_cod_util, r85_partida,
		r85_precio_nue, r85_porc_aum, r85_porc_dec, r85_usuario
	        ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(r85_division) THEN
				CALL fl_ayuda_lineas_rep(vg_codcia)
					RETURNING r_r03.r03_codigo,
						  r_r03.r03_nombre
				IF r_r03.r03_codigo IS NOT NULL THEN
					LET rm_r85.r85_division=r_r03.r03_codigo
					DISPLAY BY NAME rm_r85.r85_division,
							r_r03.r03_nombre
				END IF
			END IF
			IF INFIELD(r85_linea) THEN
				CALL fl_ayuda_sublinea_rep(vg_codcia,
							rm_r85.r85_division)
					RETURNING r_r70.r70_sub_linea,
						  r_r70.r70_desc_sub
				IF r_r70.r70_sub_linea IS NOT NULL THEN
					LET rm_r85.r85_linea=r_r70.r70_sub_linea
					DISPLAY BY NAME rm_r85.r85_linea,
							r_r70.r70_desc_sub
				END IF
			END IF
			IF INFIELD(r85_cod_grupo) THEN
				CALL fl_ayuda_grupo_ventas_rep(vg_codcia,
							rm_r85.r85_division,
							rm_r85.r85_linea)
		     		RETURNING r_r71.r71_cod_grupo,
		     			  r_r71.r71_desc_grupo
				IF r_r71.r71_cod_grupo IS NOT NULL THEN
					LET rm_r85.r85_cod_grupo =
							r_r71.r71_cod_grupo
					DISPLAY BY NAME rm_r85.r85_cod_grupo,
							r_r71.r71_desc_grupo
				END IF
			END IF
			IF INFIELD(r85_cod_clase) THEN
				CALL fl_ayuda_clase_ventas_rep(vg_codcia,
							rm_r85.r85_division,
							rm_r85.r85_linea,
							rm_r85.r85_cod_grupo)
					RETURNING r_r72.r72_cod_clase,
				     		  r_r72.r72_desc_clase
				IF r_r72.r72_cod_clase IS NOT NULL THEN
					LET rm_r85.r85_cod_clase =
							r_r72.r72_cod_clase
					DISPLAY BY NAME rm_r85.r85_cod_clase,
							r_r72.r72_desc_clase
				END IF
			END IF
			IF INFIELD(r85_marca) THEN
				CALL fl_ayuda_marcas_rep_asignadas(vg_codcia, 
							rm_r85.r85_marca)
		  			RETURNING r_r73.r73_marca
				IF r_r73.r73_marca IS NOT NULL THEN
					LET rm_r85.r85_marca = r_r73.r73_marca
					CALL fl_lee_marca_rep(vg_codcia,
							rm_r85.r85_marca)
						RETURNING r_r73.*
					DISPLAY BY NAME rm_r85.r85_marca,
							r_r73.r73_desc_marca
		   		END IF
			END IF
			IF INFIELD(r85_cod_util) THEN
				CALL fl_ayuda_factor_utilidad_rep(vg_codcia)
			     		RETURNING r_r77.r77_codigo_util
			     	IF r_r77.r77_codigo_util IS NOT NULL THEN
					LET rm_r85.r85_cod_util =
							r_r77.r77_codigo_util
					DISPLAY BY NAME rm_r85.r85_cod_util
			     	END IF
			END IF
			IF INFIELD(r85_partida) THEN
				CALL fl_ayuda_partidas(capitulo)
					RETURNING r_g16.g16_partida
				IF r_g16.g16_partida IS NOT NULL THEN
					LET rm_r85.r85_partida=r_g16.g16_partida
					DISPLAY BY NAME rm_r85.r85_partida
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
ELSE
	LET expr_sql = ' r85_codigo   = ', arg_val(4)
END IF
LET query = 'SELECT *, ROWID FROM rept085 ',
		'WHERE r85_compania = ', vg_codcia,
		'  AND ', expr_sql CLIPPED,
		' ORDER BY r85_fec_camprec, r85_codigo'
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_r85.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() = 4 THEN
		EXIT PROGRAM
	END IF
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION leer_parametros()
DEFINE resp		CHAR(6)
DEFINE flag		CHAR(1)
DEFINE capitulo		LIKE gent016.g16_capitulo
DEFINE precio_nue	LIKE rept085.r85_precio_nue
DEFINE porc_aum		LIKE rept085.r85_porc_aum
DEFINE porc_dec		LIKE rept085.r85_porc_dec
DEFINE r_g16		RECORD LIKE gent016.*
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE r_r77		RECORD LIKE rept077.*

INITIALIZE capitulo TO NULL
LET int_flag = 0
INPUT BY NAME rm_r85.r85_referencia, rm_r85.r85_division, rm_r85.r85_linea,
	rm_r85.r85_cod_grupo, rm_r85.r85_cod_clase, rm_r85.r85_marca,
	rm_r85.r85_cod_util, rm_r85.r85_partida, rm_r85.r85_precio_nue,
	rm_r85.r85_porc_aum, rm_r85.r85_porc_dec
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_r85.r85_referencia, rm_r85.r85_division,
				 rm_r85.r85_linea, rm_r85.r85_cod_grupo,
				 rm_r85.r85_cod_clase, rm_r85.r85_marca,
				 rm_r85.r85_cod_util, rm_r85.r85_partida,
				 rm_r85.r85_precio_nue, rm_r85.r85_porc_aum,
				 rm_r85.r85_porc_dec)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				CLEAR FORM
				LET int_flag = 1
				--#RETURN
				EXIT INPUT
			END IF
		ELSE
			CLEAR FORM
			--#RETURN
			EXIT INPUT
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r85_division) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia)
				RETURNING r_r03.r03_codigo, r_r03.r03_nombre
			IF r_r03.r03_codigo IS NOT NULL THEN
				LET rm_r85.r85_division = r_r03.r03_codigo
				DISPLAY BY NAME rm_r85.r85_division,
						r_r03.r03_nombre
			END IF
		END IF
		IF INFIELD(r85_linea) THEN
			CALL fl_ayuda_sublinea_rep(vg_codcia,
							rm_r85.r85_division)
				RETURNING r_r70.r70_sub_linea,
					  r_r70.r70_desc_sub
			IF r_r70.r70_sub_linea IS NOT NULL THEN
				LET rm_r85.r85_linea = r_r70.r70_sub_linea
				DISPLAY BY NAME rm_r85.r85_linea,
						r_r70.r70_desc_sub
			END IF
		END IF
		IF INFIELD(r85_cod_grupo) THEN
			CALL fl_ayuda_grupo_ventas_rep(vg_codcia,
							rm_r85.r85_division,
							rm_r85.r85_linea)
		     		RETURNING r_r71.r71_cod_grupo,
		     			  r_r71.r71_desc_grupo
			IF r_r71.r71_cod_grupo IS NOT NULL THEN
				LET rm_r85.r85_cod_grupo = r_r71.r71_cod_grupo
				DISPLAY BY NAME rm_r85.r85_cod_grupo,
						r_r71.r71_desc_grupo
			END IF
		END IF
		IF INFIELD(r85_cod_clase) THEN
			CALL fl_ayuda_clase_ventas_rep(vg_codcia,
							rm_r85.r85_division,
							rm_r85.r85_linea,
							rm_r85.r85_cod_grupo)
				RETURNING r_r72.r72_cod_clase,
			     		  r_r72.r72_desc_clase
			IF r_r72.r72_cod_clase IS NOT NULL THEN
				LET rm_r85.r85_cod_clase = r_r72.r72_cod_clase
				DISPLAY BY NAME rm_r85.r85_cod_clase,
						r_r72.r72_desc_clase
			END IF
		END IF
		IF INFIELD(r85_marca) THEN
			CALL fl_ayuda_marcas_rep_asignadas(vg_codcia, 
							rm_r85.r85_marca)
	  			RETURNING r_r73.r73_marca
			IF r_r73.r73_marca IS NOT NULL THEN
				LET rm_r85.r85_marca = r_r73.r73_marca
				CALL fl_lee_marca_rep(vg_codcia,
							rm_r85.r85_marca)
					RETURNING r_r73.*
				DISPLAY BY NAME rm_r85.r85_marca,
						r_r73.r73_desc_marca
	   		END IF
		END IF
		IF INFIELD(r85_cod_util) THEN
			CALL fl_ayuda_factor_utilidad_rep(vg_codcia)
		     		RETURNING r_r77.r77_codigo_util
		     	IF r_r77.r77_codigo_util IS NOT NULL THEN
				LET rm_r85.r85_cod_util = r_r77.r77_codigo_util
				DISPLAY BY NAME rm_r85.r85_cod_util
		     	END IF
		END IF
		IF INFIELD(r85_partida) THEN
			CALL fl_ayuda_partidas(capitulo)
				RETURNING r_g16.g16_partida
			IF r_g16.g16_partida IS NOT NULL THEN
				LET rm_r85.r85_partida = r_g16.g16_partida
				DISPLAY BY NAME rm_r85.r85_partida
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD r85_precio_nue
		LET precio_nue = rm_r85.r85_precio_nue
	BEFORE FIELD r85_porc_aum
		LET porc_aum = rm_r85.r85_porc_aum
	BEFORE FIELD r85_porc_dec
		LET porc_dec = rm_r85.r85_porc_dec
	AFTER FIELD r85_division
		IF rm_r85.r85_division IS NOT NULL THEN
			CALL fl_lee_linea_rep(vg_codcia, rm_r85.r85_division)
				RETURNING r_r03.*
			IF r_r03.r03_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Division no existe.','exclamation')
				NEXT FIELD r85_division
			END IF
			DISPLAY BY NAME r_r03.r03_nombre
			IF r_r03.r03_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r85_division
			END IF
		ELSE
			CLEAR r03_nombre
		END IF
	AFTER FIELD r85_linea
		IF rm_r85.r85_linea IS NOT NULL THEN
			CALL fl_retorna_sublinea_rep(vg_codcia,rm_r85.r85_linea)
				RETURNING r_r70.*, flag
			IF flag = 0 THEN
				IF r_r70.r70_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Linea no existe.','exclamation')
					NEXT FIELD r85_linea
				END IF
			END IF
			DISPLAY BY NAME r_r70.r70_desc_sub
		ELSE 
		     	CLEAR r70_desc_sub
                END IF
	AFTER FIELD r85_cod_grupo
                IF rm_r85.r85_cod_grupo IS NOT NULL THEN
			CALL fl_retorna_grupo_rep(vg_codcia,
							rm_r85.r85_cod_grupo)
				RETURNING r_r71.*, flag
			IF flag = 0 THEN
				IF r_r71.r71_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Grupo no existe.','exclamation')
					NEXT FIELD r85_cod_grupo
				END IF
			END IF
			DISPLAY BY NAME r_r71.r71_desc_grupo
		ELSE 
		     	CLEAR r71_desc_grupo
                END IF
	AFTER FIELD r85_cod_clase
                IF rm_r85.r85_cod_clase IS NOT NULL THEN
			CALL fl_retorna_clase_rep(vg_codcia,
							rm_r85.r85_cod_clase)
				RETURNING r_r72.*, flag
			IF flag = 0 THEN
				IF r_r72.r72_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Clase no existe.','exclamation')
					NEXT FIELD r85_cod_clase
				END IF
			END IF
			DISPLAY BY NAME r_r72.r72_desc_clase
		ELSE 
		     	CLEAR r72_desc_clase
                END IF
	AFTER FIELD r85_marca 
		IF rm_r85.r85_marca IS NOT NULL THEN
			CALL fl_lee_marca_rep(vg_codcia, rm_r85.r85_marca)
				RETURNING r_r73.*
			IF r_r73.r73_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Marca no existe.','exclamation')
				NEXT FIELD r85_marca
			END IF
			DISPLAY BY NAME r_r73.r73_desc_marca
		ELSE
			CLEAR r73_desc_marca
		END IF
	AFTER FIELD r85_partida
		IF rm_r85.r85_partida IS NOT NULL THEN
			CALL fl_lee_partida(rm_r85.r85_partida)
				RETURNING r_g16.*
			IF r_g16.g16_partida IS NULL THEN
				CALL fl_mostrar_mensaje('Partida no existe.','exclamation')
				NEXT FIELD r85_partida
			END IF
		ELSE
			CLEAR r85_partida
		END IF
	AFTER FIELD r85_precio_nue
		IF rm_r85.r85_precio_nue IS NULL THEN
			LET rm_r85.r85_precio_nue = precio_nue
		END IF
		IF rm_r85.r85_porc_aum > 0 OR rm_r85.r85_porc_dec > 0 THEN
			LET rm_r85.r85_precio_nue = 0
		END IF
		DISPLAY BY NAME rm_r85.r85_precio_nue
	AFTER FIELD r85_porc_aum
		IF rm_r85.r85_porc_aum IS NULL THEN
			LET rm_r85.r85_porc_aum = porc_aum
		END IF
		IF rm_r85.r85_precio_nue > 0 OR rm_r85.r85_porc_dec > 0 THEN
			LET rm_r85.r85_porc_aum = 0
		END IF
		DISPLAY BY NAME rm_r85.r85_porc_aum
	AFTER FIELD r85_porc_dec
		IF rm_r85.r85_porc_dec IS NULL THEN
			LET rm_r85.r85_porc_dec = porc_dec
		END IF
		IF rm_r85.r85_precio_nue > 0 OR rm_r85.r85_porc_aum > 0 THEN
			LET rm_r85.r85_porc_dec = 0
		END IF
		DISPLAY BY NAME rm_r85.r85_porc_dec
	AFTER INPUT
		IF rm_r85.r85_precio_nue = 0 AND rm_r85.r85_porc_aum = 0 AND
		   rm_r85.r85_porc_dec = 0 THEN
			CALL fl_mostrar_mensaje('Al menos uno de los parametros de Precio Nuevo, Porc. Aumento o Porc. Decremento deben ser mayor a Cero.', 'exclamation')
			NEXT FIELD r85_precio_nue
		END IF
END INPUT
IF NOT int_flag THEN
	ERROR 'Generando Items para cambio precio . . . espere por favor'
		ATTRIBUTE(NORMAL)
END IF

END FUNCTION



FUNCTION control_muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1 
END IF	
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1 
END IF
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r85.* FROM rept085 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con Indice: ' || num_row,
				'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_r85.r85_codigo, rm_r85.r85_fec_camprec,rm_r85.r85_referencia,
		rm_r85.r85_division, rm_r85.r85_linea, rm_r85.r85_cod_grupo,
		rm_r85.r85_cod_clase, rm_r85.r85_marca, rm_r85.r85_cod_util,
		rm_r85.r85_partida, rm_r85.r85_precio_nue, rm_r85.r85_porc_aum,
		rm_r85.r85_porc_dec, rm_r85.r85_fec_reversa, rm_r85.r85_usuario,
		rm_r85.r85_fecing
CALL fl_lee_linea_rep(vg_codcia, rm_r85.r85_division) RETURNING r_r03.*
DISPLAY BY NAME r_r03.r03_nombre
CALL fl_lee_sublinea_rep(vg_codcia, rm_r85.r85_division, rm_r85.r85_linea)
		RETURNING r_r70.*
DISPLAY BY NAME r_r70.r70_desc_sub
CALL fl_lee_grupo_rep(vg_codcia, rm_r85.r85_division, rm_r85.r85_linea,
				rm_r85.r85_cod_grupo)
		RETURNING r_r71.*
DISPLAY BY NAME r_r71.r71_desc_grupo
CALL fl_lee_clase_rep(vg_codcia, rm_r85.r85_division, rm_r85.r85_linea,
				rm_r85.r85_cod_grupo, rm_r85.r85_cod_clase)
		RETURNING r_r72.*
DISPLAY BY NAME r_r72.r72_desc_clase
CALL fl_lee_marca_rep(vg_codcia, rm_r85.r85_marca) RETURNING r_r73.*
DISPLAY BY NAME r_r73.r73_desc_marca
CALL muestra_estado()

END FUNCTION


                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
DEFINE nrow                     SMALLINT
                                                                                
LET nrow = 18
IF vg_gui = 1 THEN
	LET nrow = 1
END IF
DISPLAY "" AT nrow, 1
DISPLAY row_current, " de ", num_rows AT nrow, 67

END FUNCTION



FUNCTION cambia_precios_items_masivos()
DEFINE cuantos		INTEGER
DEFINE mensaje		VARCHAR(100)
DEFINE expr_div		VARCHAR(100)
DEFINE expr_lin		VARCHAR(100)
DEFINE expr_grp		VARCHAR(100)
DEFINE expr_cla		VARCHAR(100)
DEFINE expr_mar		VARCHAR(100)
DEFINE expr_par		VARCHAR(100)
DEFINE expr_uti		VARCHAR(100)
DEFINE query		CHAR(1200)

LET expr_div = NULL
IF rm_r85.r85_division IS NOT NULL THEN
	LET expr_div = '   AND r10_linea     = "', rm_r85.r85_division CLIPPED,
						'"'
END IF
LET expr_lin = NULL
IF rm_r85.r85_linea IS NOT NULL THEN
	LET expr_lin = '   AND r10_sub_linea = "', rm_r85.r85_linea CLIPPED, '"'
END IF
LET expr_grp = NULL
IF rm_r85.r85_cod_grupo IS NOT NULL THEN
	LET expr_grp = '   AND r10_cod_grupo = "', rm_r85.r85_cod_grupo CLIPPED,
						 '"'
END IF
LET expr_cla = NULL
IF rm_r85.r85_cod_clase IS NOT NULL THEN
	LET expr_cla = '   AND r10_cod_clase = "', rm_r85.r85_cod_clase CLIPPED,
						 '"'
END IF
LET expr_mar = NULL
IF rm_r85.r85_marca IS NOT NULL THEN
	LET expr_mar = '   AND r10_marca     = "', rm_r85.r85_marca CLIPPED, '"'
END IF
LET expr_uti = NULL
IF rm_r85.r85_cod_util IS NOT NULL THEN
	LET expr_uti = '   AND r10_cod_util  = "', rm_r85.r85_cod_util CLIPPED,
						'"'
END IF
LET expr_par = NULL
IF rm_r85.r85_partida IS NOT NULL THEN
	LET expr_par = '   AND r10_partida   = "', rm_r85.r85_partida CLIPPED,
						'"'
END IF
LET query = 'SELECT r10_codigo item, r10_precio_mb precio_n, ',
		'r10_precio_ant precio_a, r10_fec_camprec fecha_p, ',
		'r10_precio_mb precio_c ',
		' FROM rept010 ',
		' WHERE r10_compania  = ', vg_codcia,
		'   AND r10_estado    = "A" ',
			expr_par CLIPPED,
			expr_uti CLIPPED,
			expr_div CLIPPED,
			expr_lin CLIPPED,
			expr_grp CLIPPED,
			expr_cla CLIPPED,
			expr_mar CLIPPED,
		' INTO TEMP tmp_prec1 '
PREPARE tabla_temp FROM query
EXECUTE tabla_temp
SELECT COUNT(*) INTO cuantos FROM tmp_prec1
IF cuantos = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
END IF
IF rm_r85.r85_precio_nue > 0 THEN
	UPDATE tmp_prec1 SET precio_c = rm_r85.r85_precio_nue WHERE 1 = 1
END IF
IF rm_r85.r85_porc_aum > 0 THEN
	UPDATE tmp_prec1
		SET precio_c = precio_c +
				(precio_c * (rm_r85.r85_porc_aum / 100))
		WHERE 1 = 1
END IF
IF rm_r85.r85_porc_dec > 0 THEN
	UPDATE tmp_prec1
		SET precio_c = precio_c -
				((precio_c * rm_r85.r85_porc_dec) / 100)
		WHERE 1 = 1
END IF
UPDATE rept010 SET r10_precio_ant  = r10_precio_mb,
		   r10_precio_mb   = (select precio_c from tmp_prec1
						where item = r10_codigo),
		   r10_fec_camprec = CURRENT
	WHERE r10_compania = vg_codcia
	  AND r10_codigo   in (select item from tmp_prec1)
IF STATUS < 0 THEN
	LET mensaje = 'Existe uno o varios Item(s) que esta(n) bloqueado(s) por otro proceso. No se actualizaran cambios en el Item. '
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION genera_detalle()
DEFINE r_r86		RECORD LIKE rept086.*

DECLARE q_t1 CURSOR FOR SELECT * FROM tmp_prec1 ORDER BY item
LET r_r86.r86_compania  = vg_codcia
LET r_r86.r86_codigo    = rm_r85.r85_codigo
LET r_r86.r86_secuencia = 1
FOREACH q_t1 INTO r_r86.r86_item, r_r86.r86_precio_mb, r_r86.r86_precio_ant,
			r_r86.r86_fec_camprec, r_r86.r86_precio_nue
	INSERT INTO rept086 VALUES(r_r86.*)
	LET r_r86.r86_secuencia = r_r86.r86_secuencia + 1
END FOREACH

END FUNCTION



FUNCTION muestra_estado()

IF rm_r85.r85_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
END IF
IF rm_r85.r85_estado = 'R' THEN
	DISPLAY 'REVERSADO' TO tit_estado
END IF
DISPLAY BY NAME rm_r85.r85_estado

END FUNCTION



FUNCTION muestra_detalle()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE v_num_det	INTEGER
DEFINE i,j,l,col,resul	SMALLINT
DEFINE query		CHAR(800)
DEFINE r_detalle	ARRAY [1000] OF RECORD
				r86_item	LIKE rept086.r86_item,
				r86_precio_mb	LIKE rept086.r86_precio_mb,
				r86_precio_ant	LIKE rept086.r86_precio_ant,
				r86_fec_camprec	LIKE rept086.r86_fec_camprec,
				r86_precio_nue	LIKE rept086.r86_precio_nue
			END RECORD
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*

LET lin_menu = 0
LET row_ini  = 4
LET num_rows = 19
LET num_cols = 74
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_detalle AT row_ini, 04 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_repf235_2 FROM '../forms/repf235_2'
ELSE
	OPEN FORM f_repf235_2 FROM '../forms/repf235_2c'
END IF
DISPLAY FORM f_repf235_2
CALL mostrar_botones_detalle()
IF num_args() = 5 THEN
	LET rm_r85.r85_codigo = arg_val(4)
END IF
LET query = 'SELECT r86_item, r86_precio_mb, r86_precio_ant, ',
		'r86_fec_camprec, r86_precio_nue ',
		' FROM rept086 ',
		'WHERE r86_compania = ', vg_codcia,
		'  AND r86_codigo   = ', rm_r85.r85_codigo,
		' INTO TEMP tmp_detalle '
PREPARE q_detalle FROM query
EXECUTE q_detalle
LET col           = 1
LET rm_orden[col] = 'ASC'
LET vm_columna_1  = col
LET vm_columna_2  = 4
WHILE TRUE
	LET query = 'SELECT * FROM tmp_detalle ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE det FROM query
	DECLARE q_det CURSOR FOR det
	LET v_num_det = 1
        FOREACH q_det INTO r_detalle[v_num_det].*
                LET v_num_det = v_num_det + 1
                IF v_num_det > 1000 THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET v_num_det = v_num_det - 1
	LET int_flag = 0
	CALL set_count(v_num_det)
	DISPLAY ARRAY r_detalle TO r_detalle.*
		--#BEFORE ROW
			--#LET i = arr_curr()
	        	--#LET j = scr_line()
			--#DISPLAY i TO cur_row
			--#DISPLAY v_num_det TO max_row
			--#CALL fl_lee_item(vg_codcia, r_detalle[i].r86_item)
				--#RETURNING r_r10.*
			--#DISPLAY BY NAME r_r10.r10_nombre
			--#CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea,
						--#r_r10.r10_sub_linea,
						--#r_r10.r10_cod_grupo,
						--#r_r10.r10_cod_clase)
				--#RETURNING r_r72.*
			--#DISPLAY BY NAME r_r72.r72_desc_clase
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_item(r_detalle[i].r86_item)
			LET int_flag = 0
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
DROP TABLE tmp_detalle
CLOSE WINDOW w_detalle

END FUNCTION



FUNCTION mostrar_botones_detalle()

--#DISPLAY "Item"			TO tit_col1
--#DISPLAY "Precio"			TO tit_col2
--#DISPLAY "Precio Anter."		TO tit_col3
--#DISPLAY "Fecha Cambio Precio"	TO tit_col4
--#DISPLAY "Precio Nuevo"		TO tit_col5

END FUNCTION



FUNCTION control_reversar()
DEFINE run_prog		CHAR(10)
DEFINE comando		CHAR(400)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, ' repp236 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', rm_r85.r85_codigo
RUN comando
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION ver_item(item)
DEFINE item		LIKE rept010.r10_codigo
DEFINE run_prog		CHAR(10)
DEFINE comando		CHAR(400)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, ' repp108 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' "', item, '"'
RUN comando

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
