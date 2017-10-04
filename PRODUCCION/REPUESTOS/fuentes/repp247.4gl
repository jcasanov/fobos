--------------------------------------------------------------------------------
-- Titulo           : repp247.4gl - Cambio de Codigo (Traspaso de items)
-- Elaboracion      : 09-Jul-2009
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp247 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows		ARRAY [20000] OF INTEGER
DEFINE vm_row_current	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE rm_orden 	ARRAY[15] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_cons_sql	CHAR(400)
DEFINE rm_r43		RECORD LIKE rept043.*
DEFINE item_cons	LIKE rept010.r10_codigo
DEFINE desc_ite_c	LIKE rept010.r10_nombre
DEFINE rm_detalle	ARRAY [20000] OF RECORD
				r44_bodega_ori	LIKE rept044.r44_bodega_ori,
				r44_item_ori	LIKE rept044.r44_item_ori,
				r44_stock_ori	LIKE rept044.r44_stock_ori,
				r44_costo_ori	LIKE rept044.r44_costo_ori,
				r44_bodega_tra	LIKE rept044.r44_bodega_tra,
				r44_item_tra	LIKE rept044.r44_item_tra,
				r44_cant_tra	LIKE rept044.r44_cant_tra,
				r44_stock_tra	LIKE rept044.r44_stock_tra,
				r44_costo_tra	LIKE rept044.r44_costo_tra
			END RECORD
DEFINE rm_adi		ARRAY [20000] OF RECORD
				r43_cod_clase	LIKE rept043.r43_cod_clase,
				r43_desc_clase	LIKE rept043.r43_desc_clase,
				r44_desc_clase_t LIKE rept044.r44_desc_clase_t,
				r44_desc_tra	LIKE rept044.r44_desc_ori,
				r44_sto_ant_tra	LIKE rept044.r44_sto_ant_tra,
				r44_cos_ant_tra	LIKE rept044.r44_cos_ant_tra,
				r44_division_t	LIKE rept044.r44_division_t
			END RECORD
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g04		RECORD LIKE gent004.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_r00		RECORD LIKE rept000.*
DEFINE rm_r01		RECORD LIKE rept001.*
DEFINE r_loc 	   	ARRAY[50] OF RECORD
				bod_loc		LIKE rept002.r02_codigo,
				nom_bod_loc	LIKE rept002.r02_nombre,
				stock_loc	LIKE rept011.r11_stock_act
			END RECORD 
DEFINE r_loc2 	   	ARRAY[50] OF RECORD
				bod_loc		LIKE rept002.r02_codigo,
				nom_bod_loc	LIKE rept002.r02_nombre,
				stock_loc	LIKE rept011.r11_stock_act,
				cant_loc	LIKE rept011.r11_stock_act
			END RECORD 
DEFINE r_rem		ARRAY[50] OF RECORD      	
				bod_rem		LIKE rept002.r02_codigo,
				nom_bod_rem	LIKE rept002.r02_nombre,
				stock_rem	LIKE rept011.r11_stock_act
			END RECORD                      	
DEFINE i_loc, i_rem	SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp247.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp247'
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
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
IF rm_r00.r00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No esta creada una compañía para el módulo de inventarios.','stop')
	RETURN
END IF
IF rm_r00.r00_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('La compania esta con estado BLOQUEADO.','stop')
	RETURN
END IF
CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag
IF int_flag THEN
	RETURN
END IF
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*
INITIALIZE rm_r01.* TO NULL
DECLARE qu_vd CURSOR FOR
	SELECT * FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_user_owner = vg_usuario
OPEN qu_vd
FETCH qu_vd INTO rm_r01.*
IF STATUS = NOTFOUND THEN
	--IF rm_g05.g05_tipo = 'UF' THEN
		FREE qu_vd
		CALL fl_mostrar_mensaje('Usted no esta configurado en la tabla de vendedores/bodegueros.','stop')
		RETURN
	--END IF
END IF
FREE qu_vd
LET vm_max_det     = 20000
LET vm_row_current = 0
LET vm_num_rows	   = 0
LET vm_max_rows    = 20000
LET lin_menu       = 0
LET row_ini        = 3
LET num_rows       = 22
LET num_cols       = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repf247_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf247_1 FROM "../forms/repf247_1"
ELSE
	OPEN FORM f_repf247_1 FROM "../forms/repf247_1c"
END IF
DISPLAY FORM f_repf247_1
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
CALL muestra_contadores(0, 0)
CALL muestra_contadores_det(0, 0, 0, 0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL setear_botones_det()
CALL control_repp247()
{--
MENU 'OPCIONES'
	COMMAND KEY('T') 'Cambio de C�digo' 'Traspaso de Items.'
		CALL control_repp247()
	COMMAND KEY('C') 'Composici�n Items' 'Compone un Items a partir de otros �tems.'
		CALL control_repp248()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU
--}

END FUNCTION



FUNCTION control_repp247()

CALL muestra_contadores(0, 0)
CALL muestra_contadores_det(0, 0, 0, 0)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle Trans.'
		HIDE OPTION 'Ver Detalle'
		HIDE OPTION 'Imprimir'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		HIDE OPTION 'Imprimir'
		CALL control_ingreso()
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_row_current > 0 THEN
			SHOW OPTION 'Detalle Trans.'
			SHOW OPTION 'Ver Detalle'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		HIDE OPTION 'Imprimir'
		CALL control_consulta()
		IF vm_num_rows < 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Detalle Trans.'
			SHOW OPTION 'Imprimir'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Detalle Trans.'
				HIDE OPTION 'Ver Detalle'
				HIDE OPTION 'Imprimir'
			END IF
		ELSE
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Detalle Trans.'
			SHOW OPTION 'Imprimir'
			IF vm_num_rows = 1 THEN
				HIDE OPTION 'Avanzar'
				HIDE OPTION 'Retroceder'
			ELSE
				SHOW OPTION 'Avanzar'
			END IF
		END IF
        COMMAND KEY('P') 'Imprimir' 'Imprime comprobante.'
		CALL control_imprimir()
        COMMAND KEY('T') 'Detalle Trans.' 'Detalle transacciones generadas.'
		CALL control_detalle_trans()
	COMMAND KEY('D') 'Ver Detalle' 'Ver detalle del Registro.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_detalle()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		HIDE OPTION 'Imprimir'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
                IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
                END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		HIDE OPTION 'Imprimir'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
                IF vm_num_rows > 0 THEN
                	SHOW OPTION 'Imprimir'
                END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_repp248()
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(100)

LET prog  = 'repp248'
LET param = NULL
IF NOT fl_control_acceso_proceso_men(vg_usuario,vg_codcia, vg_modulo, prog) THEN
	RETURN
END IF
CALL fl_ejecuta_comando('REPUESTOS', vg_modulo, prog, param, 1)

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_r45		RECORD LIKE rept045.*
DEFINE num_aux		INTEGER

CALL borrar_cabecera()
CALL borrar_detalle()
LET rm_r43.r43_compania   = vg_codcia
LET rm_r43.r43_localidad  = vg_codloc
LET rm_r43.r43_cod_ventas = rm_r01.r01_codigo
LET rm_r43.r43_usuario    = vg_usuario
LET rm_r43.r43_fecing     = fl_current()
DISPLAY BY NAME rm_r43.r43_cod_ventas, rm_r01.r01_nombres, rm_r43.r43_usuario,
		rm_r43.r43_fecing
CALL lee_datos()
IF int_flag THEN
	CALL mostrar_salir()
	RETURN
END IF
CALL generar_tabla_temporal()
CALL cargar_detalle()
IF vm_num_det = 0 THEN
	DROP TABLE tmp_item
	DROP TABLE tmp_item2
	CALL fl_mensaje_consulta_sin_registros()
	CALL mostrar_salir()
	RETURN
END IF
CALL ingresar_detalle()
IF int_flag THEN
	DROP TABLE tmp_item
	DROP TABLE tmp_item2
	CALL mostrar_salir()
	RETURN
END IF
BEGIN WORK
	CALL insertar_cabecera_traspaso() RETURNING num_aux
	IF NOT insertar_detalle_traspaso() THEN
		DROP TABLE tmp_item
		DROP TABLE tmp_item2
		ROLLBACK WORK
		CALL mostrar_salir()
		RETURN
	END IF
	IF NOT procesar_trans_aj('A-') THEN
		CALL mostrar_salir()
		RETURN
	END IF
	IF NOT procesar_trans_aj('A+') THEN
		CALL mostrar_salir()
		RETURN
	END IF
	IF NOT procesar_trans_aj('AC') THEN
		CALL mostrar_salir()
		RETURN
	END IF
COMMIT WORK
DROP TABLE tmp_item
DROP TABLE tmp_item2
IF vg_codloc <> 2 AND vg_codloc <> 4 THEN
	DECLARE q_cont_ajuste CURSOR WITH HOLD FOR
		SELECT * FROM rept045
		WHERE r45_compania  = vg_codcia
		  AND r45_localidad = vg_codloc
		  AND r45_traspaso  = rm_r43.r43_traspaso
		  AND r45_cod_tran  = 'AC'
		ORDER BY r45_num_tran
	FOREACH q_cont_ajuste INTO r_r45.*
		IF r_r45.r45_cod_tran = 'AC' THEN
			LET r_r45.r45_cod_tran = 'TC'
		END IF
		CALL fl_control_master_contab_repuestos(r_r45.r45_compania,
							r_r45.r45_localidad,
							r_r45.r45_cod_tran,
							r_r45.r45_num_tran)
	END FOREACH
END IF
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
        LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current       = vm_num_rows
LET vm_rows[vm_num_rows] = num_aux
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mostrar_mensaje('Cambio de Codigo Procesado OK.', 'info')
CALL control_imprimir()
CALL control_detalle_trans()

END FUNCTION



FUNCTION lee_datos()
DEFINE resp 		CHAR(6)
DEFINE flag		CHAR(1)
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE grupo_linea	LIKE gent020.g20_grupo_linea

LET grupo_linea = NULL
LET int_flag    = 0
{
INPUT BY NAME rm_r43.r43_division, rm_r43.r43_sub_linea, rm_r43.r43_cod_grupo,
	rm_r43.r43_cod_clase, rm_r43.r43_marca, item_cons, rm_r43.r43_referencia
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(r43_division,r43_sub_linea, r43_cod_grupo,
				     r43_cod_clase, r43_marca, item_cons,
				     r43_referencia)
--}
INPUT BY NAME item_cons, rm_r43.r43_referencia
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(item_cons, r43_referencia) THEN
			EXIT INPUT
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		{--
		IF INFIELD(r43_division) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia)
				RETURNING r_r03.r03_codigo, r_r03.r03_nombre
			IF r_r03.r03_codigo IS NOT NULL THEN
				LET rm_r43.r43_division = r_r03.r03_codigo
				LET rm_r43.r43_nom_div  = r_r03.r03_nombre
				DISPLAY BY NAME rm_r43.r43_division,
						rm_r43.r43_nom_div
			END IF
		END IF
		--}
		IF INFIELD(item_cons) THEN
			CALL fl_ayuda_maestro_items_stock(vg_codcia,
					grupo_linea, rm_r00.r00_bodega_fact)
				RETURNING r_r10.r10_codigo, r_r10.r10_nombre,
					  r_r10.r10_linea, r_r10.r10_precio_mb,
					  r_r11.r11_bodega, r_r11.r11_stock_act
			IF r_r10.r10_codigo IS NOT NULL THEN
				LET item_cons            = r_r10.r10_codigo
				LET desc_ite_c           = r_r10.r10_nombre
				CALL fl_lee_item(vg_codcia, item_cons)
					RETURNING r_r10.*
				LET rm_r43.r43_division  = r_r10.r10_linea
				LET rm_r43.r43_sub_linea = r_r10.r10_sub_linea
				LET rm_r43.r43_cod_grupo = r_r10.r10_cod_grupo
				LET rm_r43.r43_cod_clase = r_r10.r10_cod_clase
				LET rm_r43.r43_marca     = r_r10.r10_marca
				CALL fl_lee_linea_rep(vg_codcia,
							rm_r43.r43_division)
					RETURNING r_r03.*
				CALL fl_lee_sublinea_rep(vg_codcia,
							rm_r43.r43_division,
							rm_r43.r43_sub_linea)
					RETURNING r_r70.*
				CALL fl_lee_grupo_rep(vg_codcia,
							rm_r43.r43_division,
							rm_r43.r43_sub_linea,
							rm_r43.r43_cod_grupo)
					RETURNING r_r71.*
				CALL fl_lee_clase_rep(vg_codcia,
							rm_r43.r43_division,
							rm_r43.r43_sub_linea,
							rm_r43.r43_cod_grupo,
							rm_r43.r43_cod_clase)
					RETURNING r_r72.*
				CALL fl_lee_marca_rep(vg_codcia,
							rm_r43.r43_marca)
					RETURNING r_r73.*
				LET rm_r43.r43_nom_div    = r_r03.r03_nombre
				LET rm_r43.r43_desc_sub   = r_r70.r70_desc_sub
				LET rm_r43.r43_desc_grupo = r_r71.r71_desc_grupo
				LET rm_r43.r43_desc_clase = r_r72.r72_desc_clase
				LET rm_r43.r43_desc_marca = r_r73.r73_desc_marca
				DISPLAY BY NAME item_cons, desc_ite_c
						{
						rm_r43.r43_division,
						rm_r43.r43_nom_div
						rm_r43.r43_sub_linea,
						rm_r43.r43_desc_sub,
						rm_r43.r43_cod_grupo,
						rm_r43.r43_desc_grupo,
						rm_r43.r43_cod_clase,
						rm_r43.r43_desc_clase,
						rm_r43.r43_marca,
						rm_r43.r43_desc_marca
						}
			END IF
		END IF
		{--
		IF INFIELD(r43_sub_linea) THEN
			CALL fl_ayuda_sublinea_rep(vg_codcia,
							rm_r43.r43_division)
				RETURNING r_r70.r70_sub_linea,r_r70.r70_desc_sub
			IF r_r70.r70_sub_linea IS NOT NULL THEN
				LET rm_r43.r43_sub_linea = r_r70.r70_sub_linea
				LET rm_r43.r43_desc_sub  = r_r70.r70_desc_sub
				DISPLAY BY NAME rm_r43.r43_sub_linea,
						rm_r43.r43_desc_sub
			END IF
		END IF
		IF INFIELD(r43_cod_grupo) THEN
			CALL fl_ayuda_grupo_ventas_rep(vg_codcia,
						rm_r43.r43_division,
						rm_r43.r43_sub_linea)
				RETURNING r_r71.r71_cod_grupo,
					  r_r71.r71_desc_grupo
			IF r_r71.r71_cod_grupo IS NOT NULL THEN
				LET rm_r43.r43_cod_grupo  = r_r71.r71_cod_grupo
				LET rm_r43.r43_desc_grupo = r_r71.r71_desc_grupo
				DISPLAY BY NAME rm_r43.r43_cod_grupo,
						rm_r43.r43_desc_grupo
			END IF
		END IF
		IF INFIELD(r43_cod_clase) THEN
			CALL fl_ayuda_clase_ventas_rep(vg_codcia,
							rm_r43.r43_division,
							rm_r43.r43_sub_linea,
							rm_r43.r43_cod_grupo)
				RETURNING r_r72.r72_cod_clase,
					  r_r72.r72_desc_clase
			IF r_r72.r72_cod_clase IS NOT NULL THEN
				LET rm_r43.r43_cod_clase  = r_r72.r72_cod_clase
				LET rm_r43.r43_desc_clase = r_r72.r72_desc_clase
				DISPLAY BY NAME rm_r43.r43_cod_clase,
						rm_r43.r43_desc_clase
			END IF
		END IF
		IF INFIELD(r43_marca) THEN
			CALL fl_ayuda_marcas_rep_asignadas(vg_codcia,
							rm_r43.r43_cod_clase)
				RETURNING r_r73.r73_marca
			IF r_r73.r73_marca IS NOT NULL THEN
				LET rm_r43.r43_marca      = r_r73.r73_marca
				CALL fl_lee_marca_rep(vg_codcia,
							rm_r43.r43_marca)
					RETURNING r_r73.*
				LET rm_r43.r43_desc_marca = r_r73.r73_desc_marca
				DISPLAY BY NAME rm_r43.r43_marca,
						rm_r43.r43_desc_marca
			END IF
		END IF
		--}
		LET int_flag = 0
	{--
	AFTER FIELD r43_division
		IF rm_r43.r43_division IS NOT NULL THEN
			CALL fl_lee_linea_rep(vg_codcia, rm_r43.r43_division)
				RETURNING r_r03.*
			IF r_r03.r03_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('División no existe.', 'exclamation')
				NEXT FIELD r43_division
			END IF
			LET rm_r43.r43_nom_div = r_r03.r03_nombre
			DISPLAY BY NAME rm_r43.r43_nom_div
		ELSE
			LET rm_r43.r43_nom_div = NULL
			CLEAR r43_nom_div
		END IF
		--}
	AFTER FIELD item_cons
		IF item_cons IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, item_cons) RETURNING r_r10.*
			IF r_r10.r10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Item no existe.', 'exclamation')
				NEXT FIELD item_cons
			END IF
			LET desc_ite_c           = r_r10.r10_nombre
			LET rm_r43.r43_division  = r_r10.r10_linea
			LET rm_r43.r43_sub_linea = r_r10.r10_sub_linea
			LET rm_r43.r43_cod_grupo = r_r10.r10_cod_grupo
			LET rm_r43.r43_cod_clase = r_r10.r10_cod_clase
			LET rm_r43.r43_marca     = r_r10.r10_marca
			CALL fl_lee_linea_rep(vg_codcia, rm_r43.r43_division)
				RETURNING r_r03.*
			CALL fl_lee_sublinea_rep(vg_codcia, rm_r43.r43_division,
						rm_r43.r43_sub_linea)
				RETURNING r_r70.*
			CALL fl_lee_grupo_rep(vg_codcia, rm_r43.r43_division,
						rm_r43.r43_sub_linea,
						rm_r43.r43_cod_grupo)
				RETURNING r_r71.*
			CALL fl_lee_clase_rep(vg_codcia, rm_r43.r43_division,
						rm_r43.r43_sub_linea,
						rm_r43.r43_cod_grupo,
						rm_r43.r43_cod_clase)
				RETURNING r_r72.*
			CALL fl_lee_marca_rep(vg_codcia, rm_r43.r43_marca)
				RETURNING r_r73.*
			LET rm_r43.r43_nom_div    = r_r03.r03_nombre
			LET rm_r43.r43_desc_sub   = r_r70.r70_desc_sub
			LET rm_r43.r43_desc_grupo = r_r71.r71_desc_grupo
			LET rm_r43.r43_desc_clase = r_r72.r72_desc_clase
			LET rm_r43.r43_desc_marca = r_r73.r73_desc_marca
			DISPLAY BY NAME item_cons, desc_ite_c
					{--
					rm_r43.r43_division, rm_r43.r43_nom_div,
					rm_r43.r43_sub_linea,
					rm_r43.r43_desc_sub,
					rm_r43.r43_cod_grupo,
					rm_r43.r43_desc_grupo,
					rm_r43.r43_cod_clase,
					rm_r43.r43_desc_clase, rm_r43.r43_marca,
					rm_r43.r43_desc_marca
					}
			IF r_r03.r03_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Division tiene estado BLOQUEADO.', 'exclamation')
				NEXT FIELD item_cons
			END IF
			IF r_r10.r10_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Item tiene estado de BLOQUEADO.', 'exclamation')
				NEXT FIELD item_cons
			END IF
			IF r_r10.r10_costo_mb = 0.01 THEN
				CALL fl_mostrar_mensaje('Debe estar configurado correctamente en costo del item origen y NO con costo 0.01.', 'exclamation')
				NEXT FIELD item_cons
			END IF
		ELSE
			LET desc_ite_c            = NULL
			LET rm_r43.r43_division   = NULL
			LET rm_r43.r43_sub_linea  = NULL
			LET rm_r43.r43_cod_grupo  = NULL
			LET rm_r43.r43_cod_clase  = NULL
			LET rm_r43.r43_marca      = NULL
			LET rm_r43.r43_nom_div    = NULL
			LET rm_r43.r43_desc_sub   = NULL
			LET rm_r43.r43_desc_grupo = NULL
			LET rm_r43.r43_desc_clase = NULL
			LET rm_r43.r43_desc_marca = NULL
			CLEAR desc_ite_c
			{--
			CLEAR desc_ite_c, r43_division, r43_sub_linea,
				r43_cod_grupo, r43_cod_clase, r43_marca,
				r43_nom_div, r43_desc_sub, r43_desc_grupo,
				r43_desc_clase, r43_desc_marca
			--}
		END IF
	{--
	AFTER FIELD r43_sub_linea
		IF rm_r43.r43_sub_linea IS NOT NULL THEN
			CALL fl_retorna_sublinea_rep(vg_codcia,
							rm_r43.r43_sub_linea)
				RETURNING r_r70.*, flag
			IF flag = 0 THEN
				IF r_r70.r70_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Línea no existe.', 'exclamation')
					NEXT FIELD r43_sub_linea
				END IF
			END IF
			LET rm_r43.r43_desc_sub = r_r70.r70_desc_sub
			DISPLAY BY NAME rm_r43.r43_desc_sub
		ELSE
			LET rm_r43.r43_desc_sub = NULL
			CLEAR r43_desc_sub
		END IF
	AFTER FIELD r43_cod_grupo
		IF rm_r43.r43_cod_grupo IS NOT NULL THEN
			CALL fl_retorna_grupo_rep(vg_codcia,
							rm_r43.r43_cod_grupo)
				RETURNING r_r71.*, flag
			IF flag = 0 THEN
				IF r_r71.r71_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Grupo no existe.','exclamation')
					NEXT FIELD r43_cod_grupo
				END IF
			END IF
			LET rm_r43.r43_desc_grupo = r_r71.r71_desc_grupo
			DISPLAY BY NAME rm_r43.r43_desc_grupo
		ELSE
			LET rm_r43.r43_desc_grupo = NULL
			CLEAR r43_desc_grupo
		END IF
	AFTER FIELD r43_cod_clase
		IF rm_r43.r43_cod_clase IS NOT NULL THEN
			CALL fl_retorna_clase_rep(vg_codcia,
							rm_r43.r43_cod_clase)
				RETURNING r_r72.*, flag
			IF flag = 0 THEN
				IF r_r72.r72_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Clase no existe.', 'exclamation')
					NEXT FIELD r43_cod_clase
				END IF
			END IF
			LET rm_r43.r43_desc_clase = r_r72.r72_desc_clase
			DISPLAY BY NAME rm_r43.r43_desc_clase
		ELSE
			LET rm_r43.r43_desc_clase = NULL
			CLEAR r43_desc_clase
		END IF
	AFTER FIELD r43_marca 
		IF rm_r43.r43_marca IS NOT NULL THEN
			CALL fl_lee_marca_rep(vg_codcia, rm_r43.r43_marca)
				RETURNING r_r73.*
			IF r_r73.r73_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Marca no existe.', 'exclamation')
				NEXT FIELD r43_marca
			END IF
			LET rm_r43.r43_desc_marca = r_r73.r73_desc_marca
			DISPLAY BY NAME rm_r43.r43_desc_marca
		ELSE
			LET rm_r43.r43_desc_marca = NULL
			CLEAR r43_desc_marca
		END IF
		--}
	AFTER INPUT
		LET rm_r43.r43_referencia = rm_r43.r43_referencia CLIPPED
		IF rm_r43.r43_referencia IS NULL THEN
			CALL fl_mostrar_mensaje('Digite la referencia.', 'exclamation')
			NEXT FIELD r43_referencia
		END IF
END INPUT

END FUNCTION



FUNCTION ingresar_detalle()
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10, r_r10_2	RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE grupo_linea	LIKE gent020.g20_grupo_linea
DEFINE stock_loc	LIKE rept011.r11_stock_act
DEFINE bd		LIKE rept011.r11_bodega
DEFINE sl, cl, cant	LIKE rept011.r11_stock_act
DEFINE sto_tra		LIKE rept011.r11_stock_act
DEFINE resp 		CHAR(6)
DEFINE mensaje		VARCHAR(150)
DEFINE i, j, k, l	SMALLINT
DEFINE encontro		SMALLINT
DEFINE query 		CHAR(400)

{--
CREATE TEMP TABLE temp_sto(
		bod_loc		CHAR(2), 
		item_o		CHAR(15),
		item_t		CHAR(15),
		stock_loc	DECIMAL(8,2),
		cant_loc	DECIMAL(8,2)
	)
--}
LET grupo_linea = NULL
LET int_flag    = 0
CALL set_count(vm_num_det)
INPUT ARRAY rm_detalle WITHOUT DEFAULTS FROM rm_detalle.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(r44_bodega_tra) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A',
							'T', 'R', 'T', '1')
				RETURNING r_r02.r02_codigo, r_r02.r02_nombre
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET rm_detalle[i].r44_bodega_tra =
								r_r02.r02_codigo
				DISPLAY rm_detalle[i].r44_bodega_tra TO
					rm_detalle[j].r44_bodega_tra
			END IF
		END IF
		IF INFIELD(r44_item_tra) THEN
			CALL fl_ayuda_maestro_items_stock(vg_codcia,
					grupo_linea, rm_r00.r00_bodega_fact)
				RETURNING r_r10.r10_codigo, r_r10.r10_nombre,
					  r_r10.r10_linea, r_r10.r10_precio_mb,
					  r_r11.r11_bodega, r_r11.r11_stock_act
			IF r_r10.r10_codigo IS NOT NULL THEN
				LET rm_detalle[i].r44_bodega_tra =
								r_r11.r11_bodega
				LET rm_detalle[i].r44_item_tra =r_r10.r10_codigo
				LET rm_detalle[i].r44_cant_tra = NULL
				DISPLAY rm_detalle[i].r44_bodega_tra TO
					rm_detalle[j].r44_bodega_tra
				DISPLAY rm_detalle[i].r44_cant_tra TO
					rm_detalle[j].r44_cant_tra
				CALL retorna_item_tra(i, j) RETURNING sto_tra
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			LET i = arr_curr()
			CALL mostrar_item(rm_detalle[i].r44_item_ori)
			LET int_flag = 0
		END IF
	ON KEY(F6)
		IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			LET i = arr_curr()
			IF rm_detalle[i].r44_item_tra IS NOT NULL THEN
				CALL mostrar_item(rm_detalle[i].r44_item_tra)
				LET int_flag = 0
			END IF
		END IF
	ON KEY(F7)
		LET i = arr_curr()
		CALL control_stock_tra(rm_detalle[i].r44_item_ori, 'O', 0)
		LET int_flag = 0
	ON KEY(F8)
		LET i = arr_curr()
		IF rm_detalle[i].r44_item_tra IS NOT NULL THEN
			CALL control_stock_tra(rm_detalle[i].r44_item_tra, 'D',
						i)
			LET int_flag = 0
			CALL fl_obtiene_costo_item(vg_codcia,
						rg_gen.g00_moneda_base,
						rm_detalle[i].r44_item_tra,
						rm_detalle[i].r44_cant_tra,
						rm_detalle[i].r44_costo_ori)
				RETURNING rm_detalle[i].r44_costo_tra
			DISPLAY rm_detalle[i].* TO rm_detalle[j].*
		END IF
	{--
	ON KEY(F9)
		LET i = arr_curr()
		IF rm_detalle[i].r44_item_tra IS NOT NULL THEN
			CALL control_stock_tra(rm_detalle[i].r44_item_ori, 'T',
						i)
			LET int_flag = 0
		END IF
	--}
	ON KEY(F9)
		LET i = arr_curr()
		LET j = scr_line()
		CALL borrar_linea_det(i, j)
		CALL dialog.keysetlabel("F6", "")
	BEFORE INPUT 
		--#CALL dialog.keysetlabel('DELETE','')
		--#CALL dialog.keysetlabel('INSERT','')
		--#CALL dialog.keysetlabel("F7","Stock Item Origen")
		--#CALL dialog.keysetlabel("F9","Borrar Linea")
	BEFORE DELETE
		CANCEL DELETE
	BEFORE INSERT
		CANCEL INSERT
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		CALL mostrar_etiquetas(i)
		IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			CALL dialog.keysetlabel("F5", "Item Origen")
			IF rm_detalle[i].r44_item_tra IS NOT NULL THEN
				CALL dialog.keysetlabel("F6", "Item Destino")
				CALL dialog.keysetlabel("F8","Stock Item Dest.")
			ELSE
				CALL dialog.keysetlabel("F6", "")
				CALL dialog.keysetlabel("F8", "")
			END IF
		ELSE
			CALL dialog.keysetlabel("F5", "")
			CALL dialog.keysetlabel("F6", "")
		END IF
	{--
	BEFORE FIELD r44_cant_tra
		IF rm_detalle[i].r44_item_tra IS NOT NULL THEN
			IF rm_r43.r43_bodega_ori IS NULL THEN
				CALL control_stock_tra(
					rm_detalle[i].r44_item_ori, 'T', i)
				SELECT NVL(SUM(cant_loc), 0)
					INTO rm_detalle[i].r44_cant_tra
					FROM temp_sto
					WHERE item_o =rm_detalle[i].r44_item_ori
				DISPLAY rm_detalle[i].r44_cant_tra
					TO rm_detalle[j].r44_cant_tra
				LET cant = rm_detalle[i].r44_cant_tra
			END IF
		END IF
	--}
	AFTER FIELD r44_bodega_tra
		IF rm_detalle[i].r44_bodega_tra IS NULL THEN
			NEXT FIELD r44_item_tra
		END IF
		IF rm_detalle[i].r44_bodega_tra IS NULL THEN
			LET rm_detalle[i].r44_bodega_tra =
						rm_detalle[i].r44_bodega_ori
			DISPLAY rm_detalle[i].r44_bodega_tra TO
				rm_detalle[j].r44_bodega_tra
		END IF
		IF rm_detalle[i].r44_bodega_tra IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia,
						rm_detalle[i].r44_bodega_tra)
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Bodega no existe.', 'exclamation')
				NEXT FIELD r44_bodega_tra
			END IF
			IF r_r02.r02_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Bodega esta bloqueada.','exclamation')
				NEXT FIELD r44_bodega_tra
			END IF
			IF r_r02.r02_area <> 'R' THEN
				CALL fl_mostrar_mensaje('La Bodega debe ser de INVENTAIRO.','exclamation')
				NEXT FIELD r44_bodega_tra
			END IF
			IF r_r02.r02_tipo_ident <> 'V' AND
			   r_r02.r02_tipo_ident <> 'I'
			THEN
				CALL fl_mostrar_mensaje('La Bodega debe ser de tipo comun y no Contratos o Reserva.','exclamation')
				NEXT FIELD r44_bodega_tra
			END IF
		END IF
	AFTER FIELD r44_item_tra
		IF FIELD_TOUCHED(r44_item_tra) THEN
			CALL retorna_item_tra(i, j) RETURNING sto_tra
		END IF
		IF rm_detalle[i].r44_item_tra IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_detalle[i].r44_item_tra)
				RETURNING r_r10.*
			IF r_r10.r10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Item no existe.', 'exclamation')
				NEXT FIELD r44_item_tra
			END IF
			IF rm_detalle[i].r44_bodega_tra IS NULL THEN
				LET rm_detalle[i].r44_bodega_tra =
						rm_detalle[i].r44_bodega_ori
				DISPLAY rm_detalle[i].r44_bodega_tra TO
					rm_detalle[j].r44_bodega_tra
			END IF
			CALL dialog.keysetlabel("F6", "Item Destino")
			CALL dialog.keysetlabel("F8", "Stock Item Dest.")
			IF rm_detalle[i].r44_cant_tra IS NULL THEN
				CALL retorna_item_tra(i, j) RETURNING sto_tra
			END IF
			IF r_r10.r10_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Item tiene estado de BLOQUEADO.', 'exclamation')
				NEXT FIELD r44_item_tra
			END IF
			IF rm_detalle[i].r44_item_ori =
			   rm_detalle[i].r44_item_tra
			THEN
				CALL fl_mostrar_mensaje('El Item de traspaso debe ser diferente al Item de origen.', 'exclamation')
				NEXT FIELD r44_item_tra
			END IF
			CALL fl_lee_item(vg_codcia, rm_detalle[i].r44_item_ori)
				RETURNING r_r10_2.*
			IF r_r10.r10_uni_med <> r_r10_2.r10_uni_med THEN
				CALL fl_mostrar_mensaje('Las unidades de medida deben ser iguales en ambos Items.', 'exclamation')
				NEXT FIELD r44_item_tra
			END IF
			IF rm_detalle[i].r44_costo_ori = 0.01 THEN
				CALL fl_mostrar_mensaje('Debe estar configurado correctamente en costo del item origen y NO con costo 0.01.', 'exclamation')
				NEXT FIELD r44_item_tra
			END IF
			IF rm_detalle[i].r44_costo_tra = 0.01 THEN
				CALL fl_mostrar_mensaje('Debe estar configurado correctamente en costo del item destino y NO con costo 0.01.', 'exclamation')
				NEXT FIELD r44_item_tra
			END IF
			LET rm_adi[i].r44_division_t = r_r10.r10_linea
			LET rm_adi[i].r44_desc_tra   = r_r10.r10_nombre
			CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea,
						r_r10.r10_sub_linea,
						r_r10.r10_cod_grupo,
						r_r10.r10_cod_clase)
				RETURNING r_r72.*
			LET rm_adi[i].r44_desc_clase_t = r_r72.r72_desc_clase
			CALL mostrar_etiquetas(i)
			NEXT FIELD r44_cant_tra
		ELSE
			CALL dialog.keysetlabel("F6", "")
			CALL borrar_linea_det(i, j)
		END IF
	AFTER FIELD r44_cant_tra
		IF rm_detalle[i].r44_item_tra IS NULL THEN
			CONTINUE INPUT
		END IF
		IF FIELD_TOUCHED(r44_cant_tra) THEN
			IF NOT muestra_linea_det(i, j) THEN
				NEXT FIELD r44_item_tra
			END IF
		END IF
		{--
		IF FIELD_TOUCHED(r44_cant_tra) THEN
			IF cant <> rm_detalle[i].r44_cant_tra AND
			   rm_r43.r43_bodega_ori IS NULL
			THEN
				CALL control_stock_tra(
					rm_detalle[i].r44_item_ori, 'T', i)
				SELECT NVL(SUM(cant_loc), 0)
					INTO rm_detalle[i].r44_cant_tra
					FROM temp_sto
					WHERE item_o =rm_detalle[i].r44_item_ori
				DISPLAY rm_detalle[i].r44_cant_tra
					TO rm_detalle[j].r44_cant_tra
				LET cant = rm_detalle[i].r44_cant_tra
			END IF
		END IF
		--}
		IF rm_detalle[i].r44_cant_tra IS NOT NULL THEN
			CALL obtener_stock_local(rm_detalle[i].r44_bodega_ori,
						rm_detalle[i].r44_item_ori)
				RETURNING stock_loc
			IF rm_detalle[i].r44_cant_tra > stock_loc THEN
				LET mensaje = 'La cantidad a traspasar no ',
						'puede ser mayor que ',
						stock_loc USING "---,--&.##",
						' que es el STOCK LOCAL.'
				{--
				IF rm_r43.r43_bodega_ori IS NOT NULL THEN
					LET mensaje = mensaje CLIPPED,
							' STOCK BODEGA.'
				ELSE
					LET mensaje = mensaje CLIPPED,
							' STOCK LOCAL.'
				END IF
				--}
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				NEXT FIELD r44_cant_tra
			END IF
			IF NOT muestra_linea_det(i, j) THEN
				NEXT FIELD r44_item_tra
			END IF
		ELSE
			CALL retorna_item_tra(i, j) RETURNING sto_tra
		END IF
	AFTER INPUT
		LET l = 0
		FOR k = 1 TO vm_num_det
			IF rm_detalle[k].r44_item_tra IS NULL THEN
				LET l = l + 1
			END IF
		END FOR
		IF l = vm_num_det THEN
			CALL fl_mostrar_mensaje('Al menos debe traspasar un item.', 'exclamation')
			CONTINUE INPUT
		END IF
		FOR k = 1 TO vm_num_det
			IF rm_detalle[k].r44_item_tra IS NOT NULL THEN
				IF rm_detalle[k].r44_cant_tra IS NULL THEN
					CALL fl_mostrar_mensaje('Digite la cantidad a traspasar del item: ' || rm_detalle[k].r44_item_tra CLIPPED || '.', 'exclamation')
					CONTINUE INPUT
				END IF
			END IF
		END FOR
		FOR k = 1 TO vm_num_det - 1
			IF rm_detalle[k].r44_bodega_tra IS NULL THEN
				CONTINUE FOR
			END IF
			IF rm_detalle[k].r44_item_tra IS NULL THEN
				CONTINUE FOR
			END IF
			FOR l = k + 1 TO vm_num_det
				IF rm_detalle[l].r44_bodega_tra IS NULL THEN
					CONTINUE FOR
				END IF
				IF rm_detalle[l].r44_item_tra IS NULL THEN
					CONTINUE FOR
				END IF
				IF (rm_detalle[k].r44_bodega_tra =
				    rm_detalle[l].r44_bodega_tra) AND
				   (rm_detalle[k].r44_item_tra =
				    rm_detalle[l].r44_item_tra)
				THEN
					LET i        = k
					LET encontro = 1
					EXIT FOR
				END IF
			END FOR
		END FOR
		IF encontro THEN
			LET mensaje = 'El item: ',
					rm_detalle[i].r44_item_tra CLIPPED,
					' esta repetido. Por favor borrelo',
					' para continuar.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			CONTINUE INPUT
		END IF
		FOR k = 1 TO vm_num_det
			IF rm_detalle[k].r44_item_tra IS NOT NULL THEN
				{--
				LET query = 'SELECT bod_loc, stock_loc, ',
						'cant_loc ',
						'FROM temp_sto ',
						'WHERE item_t = "',
					rm_detalle[k].r44_item_tra CLIPPED, '"'
				PREPARE cons_sto2 FROM query
				DECLARE q_sto2 CURSOR WITH HOLD FOR cons_sto2
				LET i = 0
				FOREACH q_sto2 INTO bd, sl, cl
					LET rm_adi[k].r44_bodega_tra = bd
					INSERT INTO tmp_item2
					VALUES (rm_detalle[k].r44_item_ori,
						rm_detalle[k].r44_stock_ori,
						rm_detalle[k].r44_costo_ori,
						rm_detalle[k].r44_item_tra, cl,
						sl, rm_detalle[k].r44_costo_tra,
						rm_adi[k].*)
					LET i = 1
				END FOREACH
				IF i = 0 THEN
					IF rm_r43.r43_bodega_ori IS NOT NULL
					THEN
						LET rm_adi[k].r44_bodega_tra =
							rm_r43.r43_bodega_ori
					END IF
				--}
					INSERT INTO tmp_item2
						VALUES (rm_detalle[k].*,
						rm_adi[k].r44_desc_clase_t,
							rm_adi[k].r44_desc_tra,
						rm_adi[k].r44_sto_ant_tra,
						rm_adi[k].r44_cos_ant_tra,
						rm_adi[k].r44_division_t)
				--END IF
			END IF
		END FOR
END INPUT
IF rm_r43.r43_cod_clase IS NULL THEN
	CLEAR r43_cod_clase, r43_desc_clase
END IF
CALL muestra_contadores_det(0, vm_num_det, 0, vm_num_det)
--DROP TABLE temp_sto

END FUNCTION



FUNCTION borrar_linea_det(i, j)
DEFINE i, j		SMALLINT

LET rm_detalle[i].r44_bodega_tra = NULL
LET rm_detalle[i].r44_item_tra   = NULL
LET rm_detalle[i].r44_cant_tra   = NULL
LET rm_detalle[i].r44_stock_tra  = NULL
LET rm_detalle[i].r44_costo_tra  = NULL
LET rm_adi[i].r44_division_t     = NULL
DISPLAY rm_detalle[i].r44_bodega_tra TO rm_detalle[j].r44_bodega_tra
DISPLAY rm_detalle[i].r44_item_tra   TO rm_detalle[j].r44_item_tra
DISPLAY rm_detalle[i].r44_cant_tra   TO rm_detalle[j].r44_cant_tra
DISPLAY rm_detalle[i].r44_stock_tra  TO rm_detalle[j].r44_stock_tra
DISPLAY rm_detalle[i].r44_costo_tra  TO rm_detalle[j].r44_costo_tra

END FUNCTION



FUNCTION muestra_linea_det(i, j)
DEFINE i, j		SMALLINT
DEFINE sto_tra		LIKE rept011.r11_stock_act

CALL retorna_item_tra(i, j) RETURNING sto_tra
CALL fl_obtiene_costo_item(vg_codcia, rg_gen.g00_moneda_base,
				rm_detalle[i].r44_item_tra,
				rm_detalle[i].r44_cant_tra,
				rm_detalle[i].r44_costo_ori)
	RETURNING rm_detalle[i].r44_costo_tra
IF rm_detalle[i].r44_costo_tra = 0.01 THEN
	CALL fl_mostrar_mensaje('Debe estar configurado correctamente en costo del item traspaso.', 'exclamation')
	RETURN 0
END IF
IF sto_tra = 0 THEN
	LET rm_detalle[i].r44_stock_tra = rm_detalle[i].r44_cant_tra
ELSE
	LET rm_detalle[i].r44_stock_tra = rm_detalle[i].r44_stock_tra +
					  rm_detalle[i].r44_cant_tra
END IF
DISPLAY rm_detalle[i].r44_stock_tra TO rm_detalle[j].r44_stock_tra
DISPLAY rm_detalle[i].r44_costo_tra TO rm_detalle[j].r44_costo_tra
RETURN 1

END FUNCTION



FUNCTION control_consulta()
DEFINE flag		CHAR(1)
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE expr_sql		CHAR(1500)
DEFINE query		CHAR(3000)

CALL borrar_cabecera()
CALL borrar_detalle()
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON r43_traspaso, r43_cod_ventas,
		r43_referencia, r43_usuario, r43_fecing
{--
CONSTRUCT BY NAME expr_sql ON r43_traspaso, r43_cod_ventas, r43_division,
		r43_nom_div, r43_sub_linea, r43_desc_sub, r43_cod_grupo,
		r43_desc_grupo, r43_cod_clase, r43_desc_clase, r43_marca,
		r43_desc_marca, r43_referencia, r43_usuario, r43_fecing
--}
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
	ON KEY(F2)
		IF INFIELD(r43_cod_ventas) AND (rm_g05.g05_tipo <> 'UF' OR
		   rm_r01.r01_tipo = 'J' OR rm_r01.r01_tipo = 'G')
		THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'A', 'A')
				RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN
				LET rm_r43.r43_cod_ventas = r_r01.r01_codigo
				DISPLAY BY NAME rm_r43.r43_cod_ventas,
						r_r01.r01_nombres
			END IF
		END IF
		{--
		IF INFIELD(r43_division) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia)
				RETURNING r_r03.r03_codigo, r_r03.r03_nombre
			IF r_r03.r03_codigo IS NOT NULL THEN
				LET rm_r43.r43_division = r_r03.r03_codigo
				LET rm_r43.r43_nom_div  = r_r03.r03_nombre
				DISPLAY BY NAME rm_r43.r43_division,
						rm_r43.r43_nom_div
			END IF
		END IF
		IF INFIELD(r43_sub_linea) THEN
			CALL fl_ayuda_sublinea_rep(vg_codcia,
							rm_r43.r43_division)
				RETURNING r_r70.r70_sub_linea,r_r70.r70_desc_sub
			IF r_r70.r70_sub_linea IS NOT NULL THEN
				LET rm_r43.r43_sub_linea = r_r70.r70_sub_linea
				LET rm_r43.r43_desc_sub  = r_r70.r70_desc_sub
				DISPLAY BY NAME rm_r43.r43_sub_linea,
						rm_r43.r43_desc_sub
			END IF
		END IF
		IF INFIELD(r43_cod_grupo) THEN
			CALL fl_ayuda_grupo_ventas_rep(vg_codcia,
						rm_r43.r43_division,
						rm_r43.r43_sub_linea)
				RETURNING r_r71.r71_cod_grupo,
					  r_r71.r71_desc_grupo
			IF r_r71.r71_cod_grupo IS NOT NULL THEN
				LET rm_r43.r43_cod_grupo  = r_r71.r71_cod_grupo
				LET rm_r43.r43_desc_grupo = r_r71.r71_desc_grupo
				DISPLAY BY NAME rm_r43.r43_cod_grupo,
						rm_r43.r43_desc_grupo
			END IF
		END IF
		IF INFIELD(r43_cod_clase) THEN
			CALL fl_ayuda_clase_ventas_rep(vg_codcia,
							rm_r43.r43_division,
							rm_r43.r43_sub_linea,
							rm_r43.r43_cod_grupo)
				RETURNING r_r72.r72_cod_clase,
					  r_r72.r72_desc_clase
			IF r_r72.r72_cod_clase IS NOT NULL THEN
				LET rm_r43.r43_cod_clase  = r_r72.r72_cod_clase
				LET rm_r43.r43_desc_clase = r_r72.r72_desc_clase
				DISPLAY BY NAME rm_r43.r43_cod_clase,
						rm_r43.r43_desc_clase
			END IF
		END IF
		IF INFIELD(r43_marca) THEN
			CALL fl_ayuda_marcas_rep_asignadas(vg_codcia,
							rm_r43.r43_cod_clase)
				RETURNING r_r73.r73_marca
			IF r_r73.r73_marca IS NOT NULL THEN
				LET rm_r43.r43_marca      = r_r73.r73_marca
				CALL fl_lee_marca_rep(vg_codcia,
							rm_r43.r43_marca)
					RETURNING r_r73.*
				LET rm_r43.r43_desc_marca = r_r73.r73_desc_marca
				DISPLAY BY NAME rm_r43.r43_marca,
						rm_r43.r43_desc_marca
			END IF
		END IF
		--}
		LET int_flag = 0
	AFTER FIELD r43_cod_ventas
		IF rm_r01.r01_tipo <> 'J' AND rm_r01.r01_tipo <> 'G' THEN
			LET rm_r43.r43_cod_ventas = rm_r01.r01_codigo
			DISPLAY BY NAME rm_r43.r43_cod_ventas,rm_r01.r01_nombres
		END IF
		LET r_r01.r01_codigo = GET_FLDBUF(r43_cod_ventas)
		IF r_r01.r01_codigo IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, r_r01.r01_codigo)
				RETURNING r_r01.*
			LET rm_r43.r43_cod_ventas = r_r01.r01_codigo
			DISPLAY BY NAME rm_r43.r43_cod_ventas,rm_r01.r01_nombres
		ELSE
			LET rm_r43.r43_cod_ventas = NULL
			CLEAR r01_nombres
		END IF
	{--
	AFTER FIELD r43_division
		LET rm_r43.r43_division = GET_FLDBUF(r43_division)
		IF rm_r43.r43_division IS NOT NULL THEN
			CALL fl_lee_linea_rep(vg_codcia, rm_r43.r43_division)
				RETURNING r_r03.*
			IF r_r03.r03_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('División no existe.', 'exclamation')
				NEXT FIELD r43_division
			END IF
			LET rm_r43.r43_nom_div = r_r03.r03_nombre
			DISPLAY BY NAME rm_r43.r43_nom_div
		ELSE
			LET rm_r43.r43_nom_div = NULL
			CLEAR r43_nom_div
		END IF
	AFTER FIELD r43_sub_linea
		LET rm_r43.r43_sub_linea = GET_FLDBUF(r43_sub_linea)
		IF rm_r43.r43_sub_linea IS NOT NULL THEN
			CALL fl_retorna_sublinea_rep(vg_codcia,
							rm_r43.r43_sub_linea)
				RETURNING r_r70.*, flag
			IF flag = 0 THEN
				IF r_r70.r70_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Línea no existe.', 'exclamation')
					NEXT FIELD r43_sub_linea
				END IF
			END IF
			LET rm_r43.r43_desc_sub = r_r70.r70_desc_sub
			DISPLAY BY NAME rm_r43.r43_desc_sub
		ELSE
			LET rm_r43.r43_desc_sub = NULL
			CLEAR r43_desc_sub
		END IF
	AFTER FIELD r43_cod_grupo
		LET rm_r43.r43_cod_grupo = GET_FLDBUF(r43_cod_grupo)
		IF rm_r43.r43_cod_grupo IS NOT NULL THEN
			CALL fl_retorna_grupo_rep(vg_codcia,
							rm_r43.r43_cod_grupo)
				RETURNING r_r71.*, flag
			IF flag = 0 THEN
				IF r_r71.r71_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Grupo no existe.','exclamation')
					NEXT FIELD r43_cod_grupo
				END IF
			END IF
			LET rm_r43.r43_desc_grupo = r_r71.r71_desc_grupo
			DISPLAY BY NAME rm_r43.r43_desc_grupo
		ELSE
			LET rm_r43.r43_desc_grupo = NULL
			CLEAR r43_desc_grupo
		END IF
	AFTER FIELD r43_cod_clase
		LET rm_r43.r43_cod_clase = GET_FLDBUF(r43_cod_clase)
		IF rm_r43.r43_cod_clase IS NOT NULL THEN
			CALL fl_retorna_clase_rep(vg_codcia,
							rm_r43.r43_cod_clase)
				RETURNING r_r72.*, flag
			IF flag = 0 THEN
				IF r_r72.r72_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Clase no existe.', 'exclamation')
					NEXT FIELD r43_cod_clase
				END IF
			END IF
			LET rm_r43.r43_desc_clase = r_r72.r72_desc_clase
			DISPLAY BY NAME rm_r43.r43_desc_clase
		ELSE
			LET rm_r43.r43_desc_clase = NULL
			CLEAR r43_desc_clase
		END IF
	AFTER FIELD r43_marca 
		LET rm_r43.r43_marca = GET_FLDBUF(r43_marca)
		IF rm_r43.r43_marca IS NOT NULL THEN
			CALL fl_lee_marca_rep(vg_codcia, rm_r43.r43_marca)
				RETURNING r_r73.*
			IF r_r73.r73_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Marca no existe.', 'exclamation')
				NEXT FIELD r43_marca
			END IF
			LET rm_r43.r43_desc_marca = r_r73.r73_desc_marca
			DISPLAY BY NAME rm_r43.r43_desc_marca
		ELSE
			LET rm_r43.r43_desc_marca = NULL
			CLEAR r43_desc_marca
		END IF
	--}
END CONSTRUCT
IF int_flag THEN
	CALL mostrar_salir()
	RETURN
END IF
LET query = 'SELECT *, ROWID ',
		' FROM rept043 ',
		' WHERE r43_compania  = ', vg_codcia,
		'   AND r43_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 3'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r43.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL borrar_cabecera()
	CALL borrar_detalle()
	LET vm_num_rows    = 0
	LET vm_row_current = 0
	LET vm_num_det     = 0
	CALL muestra_contadores(0, 0)
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION insertar_cabecera_traspaso()
DEFINE num_aux		INTEGER

WHILE TRUE
	SELECT NVL(MAX(r43_traspaso) + 1, 1)
		INTO rm_r43.r43_traspaso
		FROM rept043
		WHERE r43_compania  = rm_r43.r43_compania
		  AND r43_localidad = rm_r43.r43_localidad
	LET rm_r43.r43_fecing = fl_current()
	WHENEVER ERROR CONTINUE
	INSERT INTO rept043 VALUES (rm_r43.*)
	IF STATUS = 0 THEN
		LET num_aux = SQLCA.SQLERRD[6]
		WHENEVER ERROR STOP
		EXIT WHILE
	END IF
END WHILE
WHENEVER ERROR STOP
RETURN num_aux

END FUNCTION



FUNCTION insertar_detalle_traspaso()
DEFINE r_det		RECORD
				bod_ori		LIKE rept044.r44_bodega_ori,
				item_ori	LIKE rept044.r44_item_ori,
				stock_ori	LIKE rept044.r44_stock_ori,
				costo_ori	LIKE rept044.r44_costo_ori,
				bod_tra		LIKE rept044.r44_bodega_tra,
				item_tra	LIKE rept044.r44_item_tra,
				cant_tra	LIKE rept044.r44_cant_tra,
				stock_tra	LIKE rept044.r44_stock_tra,
				costo_tra	LIKE rept044.r44_costo_tra
			END RECORD
DEFINE r_adi		RECORD
				desc_clase_t	LIKE rept044.r44_desc_clase_t,
				desc_tra	LIKE rept044.r44_desc_ori,
				sto_ant_tra	LIKE rept044.r44_sto_ant_tra,
				cos_ant_tra	LIKE rept044.r44_cos_ant_tra,
				div_tra		LIKE rept044.r44_division_t
			END RECORD
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE r_r44		RECORD LIKE rept044.*
DEFINE i, resul		SMALLINT

WHENEVER ERROR CONTINUE
DELETE FROM rept044
	WHERE r44_compania  = rm_r43.r43_compania
	  AND r44_localidad = rm_r43.r43_localidad
	  AND r44_traspaso  = rm_r43.r43_traspaso
IF STATUS <> 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se puede eliminar el detalle del traspaso. Llame al ADMINISTRADOR.', 'exclamation')
	RETURN 0
END IF
WHENEVER ERROR STOP
DECLARE q_ins_r44 CURSOR FOR SELECT * FROM tmp_item2 ORDER BY 1, 2
LET resul = 1
LET i     = 1
FOREACH q_ins_r44 INTO r_det.*, r_adi.*
	INITIALIZE r_r44.* TO NULL
	LET r_r44.r44_compania     = rm_r43.r43_compania
	LET r_r44.r44_localidad    = rm_r43.r43_localidad
	LET r_r44.r44_traspaso     = rm_r43.r43_traspaso
	LET r_r44.r44_secuencia    = i
	LET r_r44.r44_bodega_ori   = r_det.bod_ori
	LET r_r44.r44_item_ori     = r_det.item_ori CLIPPED
	CALL fl_lee_item(vg_codcia, r_r44.r44_item_ori) RETURNING r_r10.*
	LET r_r44.r44_desc_ori     = r_r10.r10_nombre CLIPPED
	LET r_r44.r44_stock_ori    = r_det.stock_ori
	LET r_r44.r44_costo_ori    = r_det.costo_ori
	LET r_r44.r44_bodega_tra   = r_det.bod_tra
	LET r_r44.r44_item_tra     = r_det.item_tra CLIPPED
	CALL fl_lee_item(vg_codcia, r_r44.r44_item_tra) RETURNING r_r10.*
	LET r_r44.r44_desc_tra     = r_r10.r10_nombre CLIPPED
	LET r_r44.r44_cant_tra     = r_det.cant_tra
	LET r_r44.r44_stock_tra    = r_det.stock_tra
	LET r_r44.r44_costo_tra    = r_det.costo_tra
	LET r_r44.r44_sto_ant_tra  = r_adi.sto_ant_tra
	LET r_r44.r44_cos_ant_tra  = r_adi.cos_ant_tra
	LET r_r44.r44_division_t   = r_r10.r10_linea
	CALL fl_lee_linea_rep(vg_codcia, r_r44.r44_division_t) RETURNING r_r03.*
	LET r_r44.r44_nom_div_t    = r_r03.r03_nombre
	LET r_r44.r44_sub_linea_t  = r_r10.r10_sub_linea
	CALL fl_lee_sublinea_rep(vg_codcia, r_r44.r44_division_t,
				r_r44.r44_sub_linea_t)
		RETURNING r_r70.*
	LET r_r44.r44_desc_sub_t   = r_r70.r70_desc_sub
	LET r_r44.r44_cod_grupo_t  = r_r10.r10_cod_grupo
	CALL fl_lee_grupo_rep(vg_codcia, r_r44.r44_division_t,
				r_r44.r44_sub_linea_t, r_r44.r44_cod_grupo_t)
		RETURNING r_r71.*
	LET r_r44.r44_desc_grupo_t = r_r71.r71_desc_grupo
	LET r_r44.r44_cod_clase_t  = r_r10.r10_cod_clase
	CALL fl_lee_clase_rep(vg_codcia, r_r44.r44_division_t,
				r_r44.r44_sub_linea_t, r_r44.r44_cod_grupo_t,
				r_r44.r44_cod_clase_t)
		RETURNING r_r72.*
	LET r_r44.r44_desc_clase_t = r_r72.r72_desc_clase
	LET r_r44.r44_marca_t      = r_r10.r10_marca
	CALL fl_lee_marca_rep(vg_codcia, r_r44.r44_marca_t) RETURNING r_r73.*
	LET r_r44.r44_desc_marca_t = r_r73.r73_desc_marca
	LET r_r44.r44_usuario      = rm_r43.r43_usuario
	LET r_r44.r44_fecing       = fl_current()
	WHENEVER ERROR CONTINUE
	INSERT INTO rept044 VALUES (r_r44.*)
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('No se puede insertar el detalle del traspaso. Llame al ADMINISTRADOR.', 'exclamation')
		LET resul = 0
		EXIT FOREACH
	END IF
	WHENEVER ERROR STOP
	LET i = i + 1
END FOREACH
RETURN resul

END FUNCTION



FUNCTION procesar_trans_aj(cod_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran

IF NOT transaccion_aj(cod_tran) THEN
	ROLLBACK WORK
	DROP TABLE tmp_item
	DROP TABLE tmp_item2
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION retorna_ciudad()
DEFINE ciudad		LIKE gent002.g02_ciudad

IF vg_codloc = 1 OR vg_codloc = 6 THEN
	LET ciudad = 1
ELSE
	LET ciudad = 45
END IF
RETURN ciudad

END FUNCTION



FUNCTION generar_tabla_temporal()
DEFINE query		CHAR(3500)
DEFINE expr_grp		VARCHAR(100)
DEFINE expr_cla		VARCHAR(100)

LET expr_grp = NULL
IF rm_r43.r43_cod_grupo IS NOT NULL THEN
	LET expr_grp = '   AND r10_cod_grupo = "', rm_r43.r43_cod_grupo, '"'
END IF
LET expr_cla = NULL
IF rm_r43.r43_cod_clase IS NOT NULL THEN
	LET expr_cla = '   AND r10_cod_clase = "', rm_r43.r43_cod_clase, '"'
END IF
LET query = 'SELECT r10_linea division, r11_bodega bodega, r10_codigo item, ',
			'r10_nombre descripcion, r11_stock_act stock, ',
			'r10_costo_mb costo, r02_localidad local, ',
			'r10_cod_clase clase, ',
			'(SELECT r72_desc_clase ',
				'FROM rept072 ',
				'WHERE r72_compania  = r10_compania ',
				'  AND r72_linea     = r10_linea ',
				'  AND r72_sub_linea = r10_sub_linea ',
				'  AND r72_cod_grupo = r10_cod_grupo ',
				'  AND r72_cod_clase = r10_cod_clase) desc_c ',
		' FROM rept010, rept011, rept002, gent002 ',
		' WHERE r10_compania   = ', vg_codcia,

		-- OJO PROVISIONAL
		'   AND r10_codigo     = "', item_cons, '"',
		--

		'   AND r10_estado     = "A" ',
		'   AND r10_linea      = "', rm_r43.r43_division CLIPPED, '"',
		'   AND r10_sub_linea  = "', rm_r43.r43_sub_linea, '"',
		expr_grp CLIPPED,
		expr_cla CLIPPED,
		'   AND r10_marca      = "', rm_r43.r43_marca, '"',
		'   AND r11_compania   = r10_compania ',
		'   AND r11_item       = r10_codigo ',
		'   AND r11_stock_act  > 0 ',
		'   AND r02_compania   = r11_compania ',
		'   AND r02_codigo     = r11_bodega ',
		'   AND r02_tipo      <> "S" ',
		'   AND g02_compania   = r02_compania ',
		'   AND g02_localidad  = r02_localidad ',
		'   AND g02_ciudad     = ', retorna_ciudad(),
		' INTO TEMP tmp_item '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
SELECT bodega bod_ori, item item_ori, stock stock_ori, costo costo_ori,
	bodega bod_tra, item item_tra, stock cant_tra, stock stock_tra,
	costo costo_tra, desc_c desc_c_t, descripcion desc_tra,
	stock sto_ant_tra, costo cos_ant_tra, division lin_tra
	FROM tmp_item
	WHERE division = 'a'
	INTO TEMP tmp_item2

END FUNCTION



FUNCTION cargar_detalle()
DEFINE r_det		RECORD
				r44_bodega_ori	LIKE rept044.r44_bodega_ori,
				r44_item_ori	LIKE rept044.r44_item_ori,
				r44_stock_ori	LIKE rept044.r44_stock_ori,
				r44_costo_ori	LIKE rept044.r44_costo_ori,
				r43_cod_clase	LIKE rept043.r43_cod_clase,
				r43_desc_clase	LIKE rept043.r43_desc_clase
			END RECORD

DECLARE q_det CURSOR FOR 
	SELECT bodega, item, NVL(SUM(stock), 0) stock_ori, costo, clase, desc_c
		FROM tmp_item
		WHERE local = vg_codloc
		GROUP BY 1, 2, 4, 5, 6
		ORDER BY 3 DESC, 2
LET vm_num_det = 1
FOREACH q_det INTO r_det.*
	LET rm_detalle[vm_num_det].r44_bodega_ori = r_det.r44_bodega_ori
	LET rm_detalle[vm_num_det].r44_item_ori   = r_det.r44_item_ori
	LET rm_detalle[vm_num_det].r44_stock_ori  = r_det.r44_stock_ori
	LET rm_detalle[vm_num_det].r44_costo_ori  = r_det.r44_costo_ori
	LET rm_adi[vm_num_det].r43_cod_clase      = r_det.r43_cod_clase
	LET rm_adi[vm_num_det].r43_desc_clase     = r_det.r43_desc_clase
	LET vm_num_det                            = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		CALL fl_mensaje_arreglo_incompleto()
		LET vm_num_det = 0
		EXIT FOREACH
	END IF
END FOREACH
IF vm_num_det > 0 THEN
	LET vm_num_det = vm_num_det - 1
END IF

END FUNCTION



FUNCTION retorna_item_tra(indice, j)
DEFINE indice, j	SMALLINT
DEFINE query		CHAR(3000)
DEFINE sto_tra		LIKE rept011.r11_stock_act

INITIALIZE sto_tra TO NULL
LET query = 'SELECT r10_codigo, NVL(SUM(r11_stock_act), 0), r10_costo_mb ',
		' FROM rept010, rept011, rept002, gent002 ',
		' WHERE r10_compania   = ', vg_codcia,
		'   AND r10_codigo     = "',
					rm_detalle[indice].r44_item_tra CLIPPED,
					'"',
		'   AND r10_estado     = "A" ',
		'   AND r11_compania   = r10_compania ',
		'   AND r11_item       = r10_codigo ',
		'   AND r02_compania   = r11_compania ',
		'   AND r02_codigo     = r11_bodega ',
		'   AND r02_tipo      <> "S" ',
		'   AND g02_compania   = r02_compania ',
		'   AND g02_localidad  = r02_localidad ',
		'   AND g02_ciudad     = ', retorna_ciudad(),
		' GROUP BY 1, 3 '
PREPARE cons_sto FROM query
DECLARE q_sto CURSOR FOR cons_sto
OPEN q_sto
FETCH q_sto INTO rm_detalle[indice].r44_item_tra, sto_tra,
		rm_detalle[indice].r44_costo_tra
LET rm_detalle[indice].r44_stock_tra = sto_tra
CLOSE q_sto
FREE q_sto
DISPLAY rm_detalle[indice].r44_item_tra  TO rm_detalle[j].r44_item_tra
IF rm_detalle[indice].r44_stock_tra IS NULL THEN
	LET rm_detalle[indice].r44_stock_tra = 0
END IF
IF rm_detalle[indice].r44_costo_tra IS NULL THEN
	LET rm_detalle[indice].r44_costo_tra = rm_detalle[indice].r44_costo_ori
END IF
DISPLAY rm_detalle[indice].r44_stock_tra TO rm_detalle[j].r44_stock_tra
DISPLAY rm_detalle[indice].r44_costo_tra TO rm_detalle[j].r44_costo_tra
LET rm_adi[indice].r44_sto_ant_tra = rm_detalle[indice].r44_stock_tra
LET rm_adi[indice].r44_cos_ant_tra = rm_detalle[indice].r44_costo_tra
RETURN sto_tra

END FUNCTION



FUNCTION mostrar_salir()

IF vm_num_rows = 0 THEN
	CALL borrar_cabecera()
	CALL borrar_detalle()
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION muestra_contadores(num_cur, max_cur)
DEFINE num_cur, max_cur	SMALLINT

DISPLAY BY NAME num_cur, max_cur

END FUNCTION



FUNCTION muestra_contadores_det(num_row1, max_row1, num_row2, max_row2)
DEFINE num_row1, max_row1 SMALLINT
DEFINE num_row2, max_row2 SMALLINT

DISPLAY BY NAME num_row1, max_row1, num_row2, max_row2

END FUNCTION



FUNCTION borrar_cabecera()

INITIALIZE rm_r43.*, item_cons, desc_ite_c TO NULL
CLEAR num_cur, max_cur, item_cons, desc_ite_c, r43_traspaso, r43_cod_ventas,
	r01_nombres, r43_referencia, r44_desc_clase_t, r44_desc_tra,
	r43_usuario, r43_fecing
{
CLEAR num_cur, max_cur, r43_traspaso, r43_cod_ventas, r01_nombres,
	r43_division, r43_nom_div, r43_sub_linea, r43_desc_sub, r43_cod_grupo,
	r43_desc_grupo, r43_cod_clase, r43_desc_clase, r43_marca,
	r43_desc_marca, r43_referencia, r44_desc_clase_t, r44_desc_tra,
	r43_usuario, r43_fecing
}

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
FOR i = 1 TO vm_max_det
	INITIALIZE rm_detalle[i].*, rm_adi[i].* TO NULL
END FOR
CLEAR num_row1, num_row2, max_row1, max_row2

END FUNCTION



FUNCTION setear_botones_det()

DISPLAY "BO"		TO tit_col1
DISPLAY "Item O."	TO tit_col2
DISPLAY "Stock O."	TO tit_col3
DISPLAY "Costo O."	TO tit_col4

DISPLAY "BT"		TO tit_col5
DISPLAY "Item T."	TO tit_col6
DISPLAY "Cant. T."	TO tit_col7
DISPLAY "Stock T."	TO tit_col8
DISPLAY "Costo T."	TO tit_col9

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row		INTEGER
DEFINE r_r01		RECORD LIKE rept001.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
CALL borrar_cabecera()
SELECT * INTO rm_r43.* FROM rept043 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con indice: ', row USING "<<<<<<&"
END IF
CALL fl_lee_vendedor_rep(vg_codcia, rm_r43.r43_cod_ventas) RETURNING r_r01.*
DISPLAY BY NAME rm_r43.r43_traspaso, rm_r43.r43_cod_ventas, r_r01.r01_nombres,
		rm_r43.r43_referencia, rm_r43.r43_usuario, rm_r43.r43_fecing
{
DISPLAY BY NAME rm_r43.r43_traspaso, rm_r43.r43_cod_ventas, r_r01.r01_nombres,
		rm_r43.r43_division, rm_r43.r43_nom_div, rm_r43.r43_sub_linea,
		rm_r43.r43_desc_sub, rm_r43.r43_cod_grupo,rm_r43.r43_desc_grupo,
		rm_r43.r43_cod_clase, rm_r43.r43_desc_clase, rm_r43.r43_marca,
		rm_r43.r43_desc_marca, rm_r43.r43_referencia,rm_r43.r43_usuario,
		rm_r43.r43_fecing
}
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i, lim 		SMALLINT
DEFINE query 		CHAR(800)
DEFINE sec		LIKE rept044.r44_secuencia

CALL borrar_detalle()
LET query = 'SELECT r44_bodega_ori, r44_item_ori, r44_stock_ori, ',
			'r44_costo_ori, r44_bodega_tra, r44_item_tra, ',
			'r44_cant_tra, r44_stock_tra, r44_costo_tra, ',
			'r44_desc_clase_t, r44_desc_tra, r44_secuencia ',
		' FROM rept044 ',
            	' WHERE r44_compania  = ', vg_codcia, 
	    	'   AND r44_localidad = ', vg_codloc,
	    	'   AND r44_traspaso  = ', rm_r43.r43_traspaso,
	    	' ORDER BY r44_secuencia'
PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
LET vm_num_det = 1
FOREACH q_cons2 INTO rm_detalle[vm_num_det].*,
			rm_adi[vm_num_det].r44_desc_clase_t,
			rm_adi[vm_num_det].r44_desc_tra, sec
	LET vm_num_det = vm_num_det + 1
        IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_det = vm_num_det - 1
IF vm_num_det = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_det = 0
	CALL borrar_detalle()
	RETURN
END IF
LET lim = vm_num_det
IF vm_num_det > fgl_scr_size('rm_detalle') THEN
	LET lim = fgl_scr_size('rm_detalle')
END IF
FOR i = 1 TO lim
	DISPLAY rm_detalle[i].* TO rm_detalle[i].*
END FOR
CALL muestra_contadores_det(0, vm_num_det, 0, vm_num_det)

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



FUNCTION control_ver_detalle()
DEFINE i, j 		SMALLINT

LET int_flag = 0
CALL set_count(vm_num_det)
DISPLAY ARRAY rm_detalle TO rm_detalle.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			LET i = arr_curr()
			CALL mostrar_item(rm_detalle[i].r44_item_ori)
			LET int_flag = 0
		END IF
	ON KEY(F6)
		IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			LET i = arr_curr()
			CALL mostrar_item(rm_detalle[i].r44_item_tra)
			LET int_flag = 0
		END IF
	ON KEY(F7)
		CALL control_detalle_trans()
		LET int_flag = 0
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel("ACCEPT", "")
                --#CALL dialog.keysetlabel("F7", "Detalle Trans.")
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL mostrar_etiquetas(i)
		--#IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE' THEN
			--#CALL dialog.keysetlabel("F5", "Item Origen")
			--#CALL dialog.keysetlabel("F6", "Item Destino")
		--#ELSE
			--#CALL dialog.keysetlabel("F5", "")
			--#CALL dialog.keysetlabel("F6", "")
		--#END IF
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
{
IF rm_r43.r43_cod_clase IS NULL THEN
	CLEAR r43_cod_clase, r43_desc_clase
END IF
}
CLEAR r44_desc_clase_t, r44_desc_tra
CALL muestra_contadores_det(0, vm_num_det, 0, vm_num_det)

END FUNCTION



FUNCTION transaccion_aj(cod_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE r_dato		RECORD
				division	LIKE rept020.r20_linea,
				bodega		LIKE rept019.r19_bodega_ori
			END RECORD
DEFINE query		CHAR(800)
DEFINE resul		SMALLINT

CASE cod_tran
	WHEN 'A-'
		LET query = 'SELECT UNIQUE division, bodega ',
				' FROM tmp_item ',
				' WHERE item  IN (SELECT item_ori ',
						'FROM tmp_item2 ',
						'WHERE bod_tra = bodega) ',
				'   AND local  = ', vg_codloc,
				' ORDER BY 2 '
	WHEN 'A+'
		LET query = 'SELECT UNIQUE lin_tra, bod_tra ',
				' FROM tmp_item2, rept010, tmp_item ',
				' WHERE r10_compania = ', vg_codcia,
				'   AND r10_codigo   = item_tra ',
				'   AND bodega       = bod_tra ',
				'   AND item         = item_ori ',
				' ORDER BY 2 '
	WHEN 'AC'
		LET query = 'SELECT UNIQUE lin_tra ',
				' FROM tmp_item2, rept010, tmp_item ',
				' WHERE r10_compania = ', vg_codcia,
				'   AND r10_codigo   = item_tra ',
				'   AND bodega       = bod_tra ',
				'   AND item         = item_ori ',
				' ORDER BY 1 '
END CASE
PREPARE cons_aj FROM query
DECLARE qu_ajuste CURSOR FOR cons_aj
LET resul = 1
FOREACH qu_ajuste INTO r_dato.*
	IF NOT generar_ajuste(r_dato.*, cod_tran) THEN
		LET resul = 0
		EXIT FOREACH
	END IF
END FOREACH
RETURN resul

END FUNCTION



FUNCTION generar_ajuste(r_dato, cod_tran)
DEFINE r_dato		RECORD
				division	LIKE rept020.r20_linea,
				bodega		LIKE rept019.r19_bodega_ori
			END RECORD
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE i		LIKE rept020.r20_orden
DEFINE item		LIKE rept011.r11_item
DEFINE usuario		LIKE gent005.g05_usuario
DEFINE cantidad		DECIMAL(13,4)
DEFINE costo_ing	DECIMAL(12,2)
DEFINE costo_nue	DECIMAL(12,2)
DEFINE mensaje 		VARCHAR(200)
DEFINE query		CHAR(1000)
DEFINE resul		SMALLINT
DEFINE varusu		VARCHAR(100)
DEFINE resp		CHAR(6)

DEFINE fecha_actual DATETIME YEAR TO SECOND

INITIALIZE r_r19.*, r_r20.* TO NULL
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'RE', 'AA', cod_tran)
	RETURNING num_tran
CASE num_tran
	WHEN 0
		CALL fl_mostrar_mensaje('No existe control de secuencia para el ' || cod_tran || ', no se puede asignar un numero de transaccion.', 'stop')
		ROLLBACK WORK
		EXIT PROGRAM
	WHEN -1
		SET LOCK MODE TO WAIT
		WHILE num_tran = -1
			IF num_tran <> -1 THEN
				EXIT WHILE
			END IF
			CALL fl_actualiza_control_secuencias(vg_codcia,
						vg_codloc, 'RE', 'AA', cod_tran)
				RETURNING num_tran
		END WHILE
		SET LOCK MODE TO NOT WAIT
END CASE
LET r_r19.r19_compania    = vg_codcia
LET r_r19.r19_localidad   = vg_codloc
LET r_r19.r19_cod_tran    = cod_tran
LET r_r19.r19_num_tran    = num_tran
LET r_r19.r19_cont_cred   = 'C'
LET r_r19.r19_referencia  = 'TRASP.# ', rm_r43.r43_traspaso USING "<<<<<&"
IF cod_tran <> 'A-' THEN
	CALL retorna_referencia(cod_tran, r_r19.r19_referencia)
		RETURNING r_r19.r19_referencia
END IF
LET r_r19.r19_referencia = r_r19.r19_referencia CLIPPED, '. ',
				rm_r43.r43_referencia CLIPPED
LET r_r19.r19_nomcli      = ' '
LET r_r19.r19_dircli      = ' '
LET r_r19.r19_telcli      = ' '
LET r_r19.r19_cedruc      = ' '
LET r_r19.r19_vendedor    = rm_r01.r01_codigo
LET r_r19.r19_descuento   = 0
LET r_r19.r19_porc_impto  = 0
IF cod_tran = 'AC' THEN
	LET r_r19.r19_bodega_ori  = rm_r00.r00_bodega_fact
	LET r_r19.r19_bodega_dest = rm_r00.r00_bodega_fact
ELSE
	LET r_r19.r19_bodega_ori  = r_dato.bodega
	LET r_r19.r19_bodega_dest = r_dato.bodega
END IF
LET r_r19.r19_moneda 	  = rg_gen.g00_moneda_base
LET r_r19.r19_paridad     = rg_gen.g00_decimal_mb
LET r_r19.r19_precision   = rg_gen.g00_decimal_mb
LET r_r19.r19_tot_costo   = 0
LET r_r19.r19_tot_bruto   = 0
LET r_r19.r19_tot_dscto   = 0
LET r_r19.r19_tot_neto 	  = 0
LET r_r19.r19_flete 	  = 0
LET r_r19.r19_usuario 	  = vg_usuario
LET r_r19.r19_fecing 	  = fl_current()
INSERT INTO rept019 VALUES (r_r19.*)
CASE cod_tran
	WHEN 'A-'
		LET query = 'SELECT item, ',
					'NVL((SELECT cant_tra ',
						'FROM tmp_item2 ',
						'WHERE bod_tra  = bodega ',
						'  AND item_ori = item), 0) ',
				' FROM tmp_item ',
				' WHERE item   IN (SELECT item_ori ',
						'FROM tmp_item2 ',
						'WHERE bod_tra = bodega) ',
				'   AND bodega  = "', r_dato.bodega, '"',
				'   AND local   = ', vg_codloc,
				' ORDER BY 1, 2 '
	WHEN 'A+'
		LET query = 'SELECT item_tra, cant_tra ',
				' FROM tmp_item2, tmp_item ',
				' WHERE lin_tra = "', r_dato.division, '"',
				'   AND bod_tra = "', r_dato.bodega, '"',
				'   AND bodega  = bod_tra ',
				'   AND item    = item_ori ',
				' ORDER BY 1, 2 '
	WHEN 'AC'
		LET query = 'SELECT UNIQUE item_tra, costo_ori ',
				' FROM tmp_item2, rept010 ',
				' WHERE r10_compania = ', vg_codcia,
				'   AND r10_codigo   = item_tra ',
				'   AND r10_linea    = "', r_dato.division, '"',
				' ORDER BY 1, 2 '
END CASE
PREPARE cons_det2 FROM query
DECLARE q_det2 CURSOR FOR cons_det2
LET resul = 1
LET i     = 1
FOREACH q_det2 INTO item, cantidad
	IF cod_tran = 'A-' THEN
		SELECT a.* FROM tmp_item a
			WHERE a.item   = item
			  AND a.bodega = r_dato.bodega
		IF STATUS = NOTFOUND THEN
			CONTINUE FOREACH
		END IF
	END IF
	IF cod_tran = 'AC' THEN
		LET costo_ing = cantidad
		--CALL obtener_stock_local(item) RETURNING cantidad
		SELECT NVL(SUM(cant_tra), 0)
			INTO cantidad
			FROM tmp_item2
			WHERE item_tra = item
		LET r_r11.r11_stock_ant = cantidad
	ELSE
		CALL fl_lee_stock_rep(vg_codcia, r_dato.bodega, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
			LET r_r11.r11_stock_act = 0
		END IF
	END IF
    	LET r_r20.r20_compania 	 = r_r19.r19_compania
    	LET r_r20.r20_localidad	 = r_r19.r19_localidad
    	LET r_r20.r20_cod_tran 	 = r_r19.r19_cod_tran
    	LET r_r20.r20_num_tran 	 = r_r19.r19_num_tran
	IF cod_tran = 'AC' THEN
		LET r_r20.r20_bodega = rm_r00.r00_bodega_fact
	ELSE
	    	LET r_r20.r20_bodega = r_dato.bodega
	END IF
    	LET r_r20.r20_item 	 = item
    	LET r_r20.r20_orden 	 = i
    	LET r_r20.r20_cant_ped 	 = cantidad
    	LET r_r20.r20_cant_ven   = cantidad
	LET r_r20.r20_cant_dev 	 = 0
	LET r_r20.r20_cant_ent   = 0
	LET r_r20.r20_descuento  = 0
	LET r_r20.r20_val_descto = 0
	IF cod_tran = 'AC' THEN
		CALL fl_obtiene_costo_item_tras(vg_codcia,r_r19.r19_moneda,item,
						cantidad, costo_ing)
			RETURNING costo_nue
	END IF
	CALL fl_lee_item(r_r19.r19_compania, item) RETURNING r_r10.*
    	LET r_r20.r20_costo 	 = r_r10.r10_costo_mb
    	LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
    	LET r_r20.r20_costant_ma = r_r10.r10_costo_ma
    	LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
    	LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
	IF cod_tran = 'AC' THEN
		LET r_r10.r10_costo_mb    = costo_nue
		LET r_r10.r10_costult_mb  = costo_ing
		--LET r_r20.r20_costnue_mb  = costo_nue
		LET r_r20.r20_costnue_mb  = costo_ing
    		LET r_r20.r20_costo 	  = costo_nue
		WHENEVER ERROR CONTINUE
        LET fecha_actual = fl_current()
		WHILE TRUE
			UPDATE rept010
				SET r10_costo_mb    = r_r10.r10_costo_mb,
				    r10_costult_mb  = r_r10.r10_costult_mb,
				    r10_usu_cosrepo = vg_usuario,
				    r10_fec_cosrepo = fecha_actual
				WHERE r10_compania = vg_codcia
				  AND r10_codigo   = item
			IF STATUS = 0 THEN
				EXIT WHILE
			END IF
			DECLARE q_blo CURSOR FOR
				SELECT UNIQUE s.username
					FROM sysmaster:syslocks l,
						sysmaster:syssessions s
					WHERE type    = "U"
					  AND sid     <> DBINFO('sessionid')
					  AND owner   = sid
					  AND tabname = 'rept010'
					  AND rowidlk = (SELECT ROWID
							FROM rept010
							WHERE r10_compania =
								vg_codcia
							  AND r10_codigo   =
								item)
			LET varusu = NULL
			FOREACH q_blo INTO usuario
				IF varusu IS NULL THEN
					LET varusu = UPSHIFT(usuario) CLIPPED
				ELSE
					LET varusu = varusu CLIPPED, ' ',
							UPSHIFT(usuario) CLIPPED
				END IF
			END FOREACH
			LET mensaje = 'El Item ', r_r20.r20_item CLIPPED,
					' esta siendo bloqueado por el ',
					'usuario ', varusu CLIPPED,
					'. Desea intentar nuevamente con el ',
					'ajuste (A+) del traspaso ?'
			CALL fl_hacer_pregunta(mensaje, 'Yes') RETURNING resp
			IF resp = 'Yes' THEN
				CONTINUE WHILE
			END IF
			ROLLBACK WORK
			WHENEVER ERROR STOP
			LET mensaje = 'No se ha podido actualizar el costo del',
					' Item ', r_r20.r20_item CLIPPED,
					'. Esta bloqueado por el usuario ',
					UPSHIFT(usuario) CLIPPED,
					'. LLAME AL ADMINISTRADOR.'
			CALL fl_mostrar_mensaje(mensaje, 'stop')
			EXIT PROGRAM
		END WHILE
		WHENEVER ERROR STOP
	END IF
	IF r_r19.r19_moneda <> rg_gen.g00_moneda_base THEN
		LET r_r10.r10_precio_mb = r_r10.r10_precio_ma
		LET r_r10.r10_costo_mb  = r_r10.r10_costo_ma
	END IF	
    	LET r_r20.r20_precio 	 = r_r10.r10_precio_mb
    	LET r_r20.r20_val_impto  = 0
    	LET r_r20.r20_fob 	 = r_r10.r10_fob
    	LET r_r20.r20_linea 	 = r_r10.r10_linea
    	LET r_r20.r20_rotacion 	 = r_r10.r10_rotacion
    	LET r_r20.r20_ubicacion  = '.'
	IF cod_tran <> 'AC' THEN
    		LET r_r20.r20_stock_ant = r_r11.r11_stock_act
	ELSE
    		LET r_r20.r20_stock_ant = cantidad
	END IF
	IF r_r20.r20_stock_ant IS NULL THEN
		LET r_r20.r20_stock_ant = 0
	END IF
	IF cod_tran <> 'AC' THEN
		CALL fl_lee_stock_rep(vg_codcia, r_dato.bodega, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
    			LET r_r11.r11_stock_act = 0
			IF cod_tran = 'A+' THEN
				INSERT INTO rept011
					(r11_compania, r11_bodega, r11_item,
					 r11_ubicacion, r11_stock_ant,
					 r11_stock_act, r11_ing_dia,r11_egr_dia)
					VALUES (vg_codcia,r_r19.r19_bodega_dest,
						item, 'SN', 0, cantidad,
						cantidad, 0)
			ELSE
				INSERT INTO rept011
					(r11_compania, r11_bodega, r11_item,
					 r11_ubicacion, r11_stock_ant,
					 r11_stock_act, r11_ing_dia,r11_egr_dia)
					VALUES (vg_codcia,r_r19.r19_bodega_dest,
						item, 'SN', 0, cantidad, 0,
						cantidad)
			END IF
		ELSE
			IF cod_tran = 'A+' THEN
				SET LOCK MODE TO WAIT
				WHENEVER ERROR CONTINUE
				UPDATE rept011
					SET r11_stock_act = r11_stock_act +
								cantidad,
					    r11_ing_dia   = r11_ing_dia   +
								cantidad
					WHERE r11_compania = vg_codcia
					  AND r11_bodega   = r_dato.bodega
					  AND r11_item     = item
				IF STATUS <> 0 THEN
					WHENEVER ERROR STOP
					SET LOCK MODE TO NOT WAIT
					LET resul = 0
					CALL fl_mostrar_mensaje('Ha ocurrido un error al actualizar (incrementar) el stock en el ' || cod_tran || '. Llame al ADMINISTRADOR.', 'exclamation')
					EXIT FOREACH
				END IF
				WHENEVER ERROR STOP
				SET LOCK MODE TO NOT WAIT
			ELSE
				CALL fl_lee_stock_rep(vg_codcia, r_dato.bodega,
							item)
					RETURNING r_r11.*
				IF r_r11.r11_compania IS NULL THEN
					LET r_r11.r11_stock_act = 0
				END IF
				LET mensaje = 'ITEM: ', item
				IF r_r11.r11_stock_act <= 0 THEN
					LET resul   = 0
					LET mensaje = mensaje CLIPPED,
					' no tiene stock y se nesecita: ',
					cantidad USING '####&.##',
					'. No puede ajustar para este Traspaso.'
					CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
					EXIT FOREACH
				END IF
				IF r_r11.r11_stock_act < cantidad THEN
					LET resul   = 0
					LET mensaje = mensaje CLIPPED,
					' solo tiene stock: ',
					r_r11.r11_stock_act USING '####&.##', 
					' y se nesecita: ',
					cantidad USING '####&.##',
					'. No puede ajustar para este Traspaso.'
					CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
					EXIT FOREACH
				END IF
				SET LOCK MODE TO WAIT
				WHENEVER ERROR CONTINUE
				UPDATE rept011
					SET r11_stock_act = r11_stock_act -
								cantidad,
					    r11_egr_dia   = r11_egr_dia   +
								cantidad
					WHERE r11_compania = vg_codcia
					  AND r11_bodega   = r_dato.bodega
					  AND r11_item     = item
				IF STATUS <> 0 THEN
					WHENEVER ERROR STOP
					SET LOCK MODE TO NOT WAIT
					LET resul = 0
					CALL fl_mostrar_mensaje('Ha ocurrido un error al actualizar (disminuir) el stock en el ' || cod_tran || '. Llame al ADMINISTRADOR.', 'exclamation')
					EXIT FOREACH
				END IF
				WHENEVER ERROR STOP
				SET LOCK MODE TO NOT WAIT
			END IF
		END IF
	END IF
	LET r_r20.r20_stock_bd   = 0
	LET r_r20.r20_fecing     = fl_current()
	INSERT INTO rept020 VALUES (r_r20.*)
	IF r_r20.r20_cod_tran <> 'AC' THEN
		LET r_r19.r19_tot_costo = r_r19.r19_tot_costo +
					(cantidad * r_r20.r20_costo)
	ELSE
		LET r_r19.r19_tot_costo = r_r19.r19_tot_costo +
					(cantidad * r_r20.r20_costnue_mb)
	END IF
END FOREACH
IF NOT resul THEN
	RETURN resul
END IF
IF i = 0 OR i IS NULL THEN
	DELETE FROM rept019
		WHERE r19_compania  = r_r19.r19_compania
		  AND r19_localidad = r_r19.r19_localidad
		  AND r19_cod_tran  = r_r19.r19_cod_tran
		  AND r19_num_tran  = r_r19.r19_num_tran
ELSE
	UPDATE rept019
		SET r19_tot_costo = r_r19.r19_tot_costo,
		    r19_tot_bruto = r_r19.r19_tot_costo,
		    r19_tot_neto  = r_r19.r19_tot_costo
		WHERE r19_compania  = r_r19.r19_compania
		  AND r19_localidad = r_r19.r19_localidad
		  AND r19_cod_tran  = r_r19.r19_cod_tran
		  AND r19_num_tran  = r_r19.r19_num_tran 
	INSERT INTO rept045
		VALUES (rm_r43.r43_compania, rm_r43.r43_localidad,
			rm_r43.r43_traspaso, r_r19.r19_cod_tran,
			r_r19.r19_num_tran, rm_r43.r43_usuario, fecha_actual)
	{--
	IF ctos = 1 THEN
		LET mensaje = 'Se genero el ajuste para traspaso: ',
				r_r19.r19_cod_tran, ' ',
				r_r19.r19_num_tran USING "<<<<<<&", '.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'info')
	END IF
	--}
END IF
RETURN resul

END FUNCTION



FUNCTION retorna_referencia(cod_tran, referencia)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE referencia	LIKE rept019.r19_referencia
DEFINE r_r45		RECORD LIKE rept045.*
DEFINE ulti		SMALLINT

CASE cod_tran
	WHEN 'A+' LET cod_tran = 'A-'
	WHEN 'AC' LET cod_tran = 'A+'
END CASE
LET referencia = referencia CLIPPED, '. ', cod_tran, ':'
DECLARE q_r45 CURSOR FOR
	SELECT * FROM rept045
		WHERE r45_compania  = vg_codcia
		  AND r45_localidad = vg_codloc
		  AND r45_traspaso  = rm_r43.r43_traspaso
		  AND r45_cod_tran  = cod_tran
		ORDER BY r45_num_tran
FOREACH q_r45 INTO r_r45.*
	LET referencia = referencia CLIPPED, ' ',
			r_r45.r45_num_tran USING "<<<<<&", ', '
END FOREACH
LET referencia = referencia CLIPPED
LET ulti       = LENGTH(referencia)
IF referencia[ulti, ulti] = ',' THEN
	LET referencia = referencia[1, ulti - 1] CLIPPED
END IF
RETURN referencia CLIPPED

END FUNCTION



FUNCTION obtener_stock_local(bodega, item)
DEFINE bodega		LIKE rept011.r11_bodega
DEFINE item		LIKE rept010.r10_codigo
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE query		CHAR(1000)
DEFINE expr_loc		VARCHAR(100)

LET expr_loc  = '  AND r02_localidad IN (', vg_codloc
IF vg_codloc = 1 THEN
	LET expr_loc = expr_loc CLIPPED, ', 2) '
END IF
IF vg_codloc = 3 THEN
	LET expr_loc = expr_loc CLIPPED, ', 4, 5) '
END IF
IF vg_codloc >= 4 THEN
	LET expr_loc = expr_loc CLIPPED, ') '
END IF
LET query = 'SELECT NVL(SUM(r11_stock_act), 0) sto_tot ',
		' FROM rept011, rept002 ',
		' WHERE r11_compania   = ', vg_codcia,
		'   AND r11_bodega     = "', bodega, '"',
		'   AND r11_item       = "', item CLIPPED, '"',
		'   AND r11_stock_act  > 0 ',
		'   AND r02_compania   = r11_compania ',
		'   AND r02_codigo     = r11_bodega ',
		'   AND r02_tipo      <> "S" ',
		expr_loc CLIPPED,
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
SELECT * INTO stock FROM t1
DROP TABLE t1
RETURN stock

END FUNCTION



FUNCTION mostrar_item(item)
DEFINE item		LIKE rept020.r20_item
DEFINE param		VARCHAR(60)

LET param = ' ', vg_codloc, ' "', item CLIPPED, '"'
CALL ejecuta_comando('REPUESTOS', vg_modulo, 'repp108 ', param)

END FUNCTION



FUNCTION control_imprimir()
DEFINE r_rep		RECORD
				num_lin		SMALLINT,
				bod_ori		LIKE rept044.r44_bodega_ori,
				item_ori	LIKE rept044.r44_item_ori,
				desc_ori	LIKE rept044.r44_desc_ori,
				cla_ori		LIKE rept043.r43_desc_clase,
				unid_ori	LIKE rept010.r10_uni_med,
				bod_tra		LIKE rept044.r44_bodega_tra,
				item_tra	LIKE rept044.r44_item_tra,
				desc_tra	LIKE rept044.r44_desc_tra,
				cla_tra		LIKE rept044.r44_desc_clase_t,
				mar_tra		LIKE rept044.r44_marca_t,
				cant_tra	LIKE rept044.r44_cant_tra,
				unid_tra	LIKE rept010.r10_uni_med
			END RECORD
DEFINE comando		VARCHAR(100)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r44		RECORD LIKE rept044.*
DEFINE r_r72		RECORD LIKE rept072.*

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
DECLARE q_imp CURSOR FOR
	SELECT * FROM rept044
		WHERE r44_compania  = vg_codcia
		  AND r44_localidad = vg_codloc
		  AND r44_traspaso  = rm_r43.r43_traspaso
		ORDER BY r44_secuencia ASC
START REPORT report_traspaso TO PIPE comando
LET r_rep.num_lin = 0
FOREACH q_imp INTO r_r44.*
	LET r_rep.num_lin  = r_rep.num_lin + 1
	LET r_rep.bod_ori  = r_r44.r44_bodega_ori
	LET r_rep.item_ori = r_r44.r44_item_ori
	LET r_rep.desc_ori = r_r44.r44_desc_ori
	CALL fl_lee_item(vg_codcia,r_r44.r44_item_ori) RETURNING r_r10.*
	IF rm_r43.r43_cod_clase IS NULL THEN
		IF rm_r43.r43_cod_grupo IS NOT NULL THEN
			LET r_r10.r10_cod_grupo = rm_r43.r43_cod_grupo
		END IF
		CALL fl_lee_clase_rep(vg_codcia, rm_r43.r43_division,
				rm_r43.r43_sub_linea, r_r10.r10_cod_grupo,
				r_r10.r10_cod_clase)
			RETURNING r_r72.*
		LET r_rep.cla_ori = r_r72.r72_desc_clase
	ELSE
		LET r_rep.cla_ori = rm_r43.r43_desc_clase
	END IF
	LET r_rep.unid_ori = UPSHIFT(r_r10.r10_uni_med)
	LET r_rep.bod_tra  = r_r44.r44_bodega_tra
	CALL fl_lee_item(vg_codcia, r_r44.r44_item_tra) RETURNING r_r10.*
	LET r_rep.item_tra = r_r44.r44_item_tra
	LET r_rep.desc_tra = r_r44.r44_desc_tra
	LET r_rep.cla_tra  = r_r44.r44_desc_clase_t
	LET r_rep.mar_tra  = r_r44.r44_marca_t
	LET r_rep.cant_tra = r_r44.r44_cant_tra
	LET r_rep.unid_tra = UPSHIFT(r_r10.r10_uni_med)
	OUTPUT TO REPORT report_traspaso(r_rep.*)
END FOREACH
FINISH REPORT report_traspaso

END FUNCTION



REPORT report_traspaso(r_rep)
DEFINE r_rep		RECORD
				num_lin		SMALLINT,
				bod_ori		LIKE rept044.r44_bodega_ori,
				item_ori	LIKE rept044.r44_item_ori,
				desc_ori	LIKE rept044.r44_desc_ori,
				cla_ori		LIKE rept043.r43_desc_clase,
				unid_ori	LIKE rept010.r10_uni_med,
				bod_tra		LIKE rept044.r44_bodega_tra,
				item_tra	LIKE rept044.r44_item_tra,
				desc_tra	LIKE rept044.r44_desc_tra,
				cla_tra		LIKE rept044.r44_desc_clase_t,
				mar_tra		LIKE rept044.r44_marca_t,
				cant_tra	LIKE rept044.r44_cant_tra,
				unid_tra	LIKE rept010.r10_uni_med
			END RECORD
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE documento	VARCHAR(60)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	3
	PAGE LENGTH	44

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo    = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET documento = "COMPROBANTE DE TRASPASO No. ",
			rm_r43.r43_traspaso USING "<<<<<<&"
	CALL fl_justifica_titulo('D', rm_r43.r43_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', documento CLIPPED, 80) RETURNING titulo
	LET titulo = modulo, titulo
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rm_g01.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 027, "DIVISION ORIGEN : ", rm_r43.r43_division CLIPPED,
			" ", rm_r43.r43_nom_div CLIPPED
	PRINT COLUMN 027, "LINEA ORIGEN    : ", rm_r43.r43_sub_linea CLIPPED,
			" ", rm_r43.r43_desc_sub CLIPPED
	PRINT COLUMN 027, "GRUPO ORIGEN    : ", rm_r43.r43_cod_grupo CLIPPED,
			" ", rm_r43.r43_desc_grupo CLIPPED
	PRINT COLUMN 027, "MARCA ORIGEN    : ", rm_r43.r43_marca CLIPPED,
			" ", rm_r43.r43_desc_marca CLIPPED
	PRINT COLUMN 001, "FECHA IMPRESION: ", DATE(vg_fecha) USING 'dd-mm-yyyy',
		1 SPACES, TIME,
	      COLUMN 045, "REFERENCIA : ", rm_r43.r43_referencia CLIPPED,
	      COLUMN 123, usuario CLIPPED
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
	{--
	PRINT COLUMN 001, "L.",
	      COLUMN 006, "BO",
	      COLUMN 009, "ITEM O",
	      COLUMN 017, "DESCRIPCION ORIGEN",
	      COLUMN 059, "UNI. O.",
	      COLUMN 067, "BT",
	      COLUMN 070, "ITEM T",
	      COLUMN 077, "DESCRIPCION TRASPASO",
	      COLUMN 123, "U.T./CANT."
	--}
	PRINT COLUMN 001, "L.",
	      COLUMN 006, "BD",
	      COLUMN 010, "ITEM",
	      COLUMN 020, "DESCRIPCION ORIGEN",
	      COLUMN 096, "MARCA",
	      COLUMN 104, "UNI. MED.",
	      COLUMN 125, "CANTIDAD"
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	{--
	NEED 2 LINES
	PRINT COLUMN 001, r_rep.num_lin		USING "&&&",
	      COLUMN 006, r_rep.bod_ori		CLIPPED,
	      COLUMN 009, r_rep.item_ori[1,6]	CLIPPED,
	      COLUMN 017, r_rep.cla_ori[1,41]	CLIPPED,
	      COLUMN 059, r_rep.unid_ori	CLIPPED,
	      COLUMN 067, r_rep.bod_tra		CLIPPED,
	      COLUMN 070, r_rep.item_tra[1,6]	CLIPPED,
	      COLUMN 077, r_rep.cla_tra[1,45]	CLIPPED,
	      COLUMN 123, r_rep.unid_tra	CLIPPED
	PRINT COLUMN 009, r_rep.desc_ori[1,48]	CLIPPED,
	      COLUMN 059, r_rep.cant_tra * (-1)	USING '---,--&.##',
	      COLUMN 070, r_rep.desc_tra[1,46]	CLIPPED,
	      COLUMN 116, r_rep.mar_tra		CLIPPED,
	      COLUMN 123, r_rep.cant_tra	USING '---,--&.##'
	--}
	NEED 5 LINES
	PRINT COLUMN 001, r_rep.num_lin		USING "&&&",
	      COLUMN 006, r_rep.bod_ori		CLIPPED,
	      COLUMN 010, r_rep.item_ori[1, 9]	CLIPPED,
	      COLUMN 020, r_rep.cla_ori		CLIPPED
	PRINT COLUMN 022, r_rep.desc_ori	CLIPPED,
	      COLUMN 104, r_rep.unid_ori	CLIPPED,
	      COLUMN 123, r_rep.cant_tra * (-1)	USING '---,--&.##'
	SKIP 1 LINES
	PRINT COLUMN 008, r_rep.bod_tra		CLIPPED,
	      COLUMN 012, r_rep.item_tra[1, 9]	CLIPPED,
	      COLUMN 022, r_rep.cla_tra		CLIPPED
	PRINT COLUMN 024, r_rep.desc_tra	CLIPPED,
	      COLUMN 096, r_rep.mar_tra		CLIPPED,
	      COLUMN 104, r_rep.unid_tra	CLIPPED,
	      COLUMN 123, r_rep.cant_tra	USING '---,--&.##'
	
PAGE TRAILER
	PRINT COLUMN 027, "AUTORIZADO_______________________";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION control_detalle_trans()
DEFINE r_det		ARRAY[500] OF RECORD
				cod_tran	LIKE rept019.r19_cod_tran,
				num_tran	LIKE rept019.r19_num_tran,
				bodega		LIKE rept019.r19_bodega_ori,
				referencia	LIKE rept019.r19_referencia,
				tipo_comp	LIKE rept040.r40_tipo_comp,
				num_comp	LIKE rept040.r40_num_comp
			END RECORD
DEFINE num_row, i	SMALLINT
DEFINE max_row		SMALLINT
DEFINE query		CHAR(1500)

LET query = 'SELECT r19_cod_tran, r19_num_tran, ',
			'CASE WHEN r19_cod_tran = "AC" ',
				'THEN "" ',
				'ELSE r19_bodega_ori ',
			'END, r19_referencia, r40_tipo_comp, r40_num_comp ',
		' FROM rept045, rept019, OUTER rept040 ',
		' WHERE r45_compania  = ', vg_codcia,
		'   AND r45_localidad = ', vg_codloc,
		'   AND r45_traspaso  = ', rm_r43.r43_traspaso,
		'   AND r19_compania  = r45_compania ',
		'   AND r19_localidad = r45_localidad ',
		'   AND r19_cod_tran  = r45_cod_tran ',
		'   AND r19_num_tran  = r45_num_tran ',
		'   AND r40_compania  = r19_compania ',
		'   AND r40_localidad = r19_localidad ',
		'   AND r40_cod_tran  = r19_cod_tran ',
		'   AND r40_num_tran  = r19_num_tran ',
		' ORDER BY 1, 2 '
PREPARE cons_dett FROM query
DECLARE q_cursor1 CURSOR FOR cons_dett
LET max_row = 500
LET num_row = 1
FOREACH q_cursor1 INTO r_det[num_row].*
	LET num_row = num_row + 1
	IF num_row > max_row THEN
		EXIT FOREACH
	END IF
END FOREACH
LET num_row = num_row - 1
IF num_row = 0 THEN
	CALL fl_mostrar_mensaje('No se ha generado ninguna transaccion. Llame al Administrador.', 'exclamation')
	RETURN
END IF
OPEN WINDOW w_repf247_2 AT 08, 05 WITH 14 ROWS, 71 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
		MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_repf247_2 FROM '../forms/repf247_2'
ELSE
	OPEN FORM f_repf247_2 FROM '../forms/repf247_2c'
END IF
DISPLAY FORM f_repf247_2
--#DISPLAY 'Transaccion' TO tit_col1
--#DISPLAY 'BD'          TO tit_col2
--#DISPLAY 'Referencia'  TO tit_col3
--#DISPLAY 'Comprobante' TO tit_col4
LET int_flag = 0
CALL set_count(num_row)
DISPLAY ARRAY r_det TO r_det.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		LET i = arr_curr()
		IF r_det[i].tipo_comp IS NOT NULL THEN
			CALL ver_contabilizacion(r_det[i].tipo_comp,
							r_det[i].num_comp)	
			LET int_flag = 0
		END IF
	ON KEY(F6)
		LET i = arr_curr()
		CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
					r_det[i].cod_tran, r_det[i].num_tran)
		LET int_flag = 0
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#DISPLAY i       TO num_row
		--#DISPLAY num_row TO max_row
		--#IF r_det[i].tipo_comp IS NOT NULL THEN
			--#CALL dialog.keysetlabel('F5', 'Contabilizacion')
		--#ELSE
			--#CALL dialog.keysetlabel('F5', '')
		--#END IF
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY
LET int_flag = 0
CLOSE WINDOW w_repf247_2
RETURN

END FUNCTION



FUNCTION ver_contabilizacion(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE param		VARCHAR(60)

LET param = ' "', tipo_comp, '" ', num_comp CLIPPED
CALL ejecuta_comando('CONTABILIDAD', 'CB', 'ctbp201 ', param)

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
		vg_separador, 'fuentes', vg_separador, run_prog, prog,
		vg_base, ' ', mod, ' ', vg_codcia, ' ', param
RUN comando

END FUNCTION



FUNCTION control_stock_tra(codigo, flag, pos)
DEFINE codigo		LIKE rept010.r10_codigo
DEFINE flag		CHAR(1)
DEFINE pos		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE tot_stock_loc	DECIMAL (8,2)
DEFINE tot_stock_rem	DECIMAL (8,2)
DEFINE tot_stock_gen 	DECIMAL (8,2)
DEFINE i, salir, lim	SMALLINT
DEFINE row_ini		SMALLINT
DEFINE query		CHAR(400)

CALL fl_lee_item(vg_codcia, codigo) RETURNING r_r10.*
IF r_r10.r10_compania IS NULL THEN
	RETURN
END IF
LET row_ini = 3
IF vg_gui = 0 THEN
	LET row_ini = 2
END IF
IF flag <> 'T' THEN
	OPEN WINDOW w_repf247_3 AT row_ini, 31 WITH 21 ROWS, 48 COLUMNS
		ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
	IF vg_gui = 1 THEN
		OPEN FORM f_repf247_3 FROM '../forms/repf247_3'
	ELSE
		OPEN FORM f_repf247_3 FROM '../forms/repf247_3c'
	END IF
	DISPLAY FORM f_repf247_3
ELSE
	OPEN WINDOW w_repf247_4 AT row_ini, 20 WITH 21 ROWS, 59 COLUMNS
		ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
	IF vg_gui = 1 THEN
		OPEN FORM f_repf247_4 FROM '../forms/repf247_4'
	ELSE
		OPEN FORM f_repf247_4 FROM '../forms/repf247_4c'
	END IF
	DISPLAY FORM f_repf247_4
	--DELETE FROM temp_sto WHERE item_o = codigo
END IF
CREATE TEMP TABLE temp_loc(
		bod_loc		CHAR(2), 
		nom_bod_loc	CHAR(30),
		stock_loc	DECIMAL(8,2),
		cant_loc	DECIMAL(8,2)
	)
CREATE TEMP TABLE temp_rem(
		bod_rem		CHAR(2), 
		nom_bod_rem	CHAR(30),
		stock_rem	DECIMAL(8,2)
	)
CALL mostrar_cabecera_bodegas_ln(flag)
DISPLAY BY NAME codigo, r_r10.r10_nombre
DECLARE q_eme CURSOR FOR
	SELECT * FROM rept011
		WHERE r11_compania = vg_codcia
		  AND r11_item     = codigo
		  AND r11_stock_act > 0
		ORDER BY r11_stock_act DESC, r11_bodega
LET i_loc = 0
LET i_rem = 0
LET tot_stock_loc = 0
LET tot_stock_rem = 0
FOREACH q_eme INTO r_r11.*
	CALL fl_lee_bodega_rep(vg_codcia, r_r11.r11_bodega) RETURNING r_r02.*
        IF r_r02.r02_tipo = 'S' THEN
		CONTINUE FOREACH
	END IF
        IF r_r02.r02_localidad = vg_codloc THEN
		IF flag <> 'D' THEN
			{--
			IF rm_r43.r43_bodega_ori IS NOT NULL THEN
				IF rm_r43.r43_bodega_ori <> r_r11.r11_bodega
				THEN
					CONTINUE FOREACH
				END IF
			END IF
			--}
		END IF
		LET i_loc = i_loc + 1
		IF flag <> 'T' THEN
			LET r_loc[i_loc].bod_loc      = r_r11.r11_bodega
			LET r_loc[i_loc].nom_bod_loc  = r_r02.r02_nombre
			LET r_loc[i_loc].stock_loc    = r_r11.r11_stock_act
		ELSE
			LET r_loc2[i_loc].bod_loc     = r_r11.r11_bodega
			LET r_loc2[i_loc].nom_bod_loc = r_r02.r02_nombre
			LET r_loc2[i_loc].stock_loc   = r_r11.r11_stock_act
			LET r_loc2[i_loc].cant_loc    = 0
		END IF
		LET tot_stock_loc = tot_stock_loc + r_r11.r11_stock_act
		INSERT INTO temp_loc
			VALUES (r_r11.r11_bodega, r_r02.r02_nombre,
				r_r11.r11_stock_act, NULL)
	ELSE
		LET i_rem = i_rem + 1
		LET r_rem[i_rem].bod_rem     = r_r11.r11_bodega
		LET r_rem[i_rem].nom_bod_rem = r_r02.r02_nombre
		LET r_rem[i_rem].stock_rem   = r_r11.r11_stock_act
		LET tot_stock_rem          = tot_stock_rem + r_r11.r11_stock_act
		INSERT INTO temp_rem VALUES (r_rem[i_rem].*)
	END IF
END FOREACH
IF i_loc = 0 AND i_rem = 0 THEN
	DROP TABLE temp_loc
	DROP TABLE temp_rem
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 0
	IF flag <> 'T' THEN
		CLOSE WINDOW w_repf247_3
	ELSE
		CLOSE WINDOW w_repf247_4
	END IF
	RETURN
END IF
LET tot_stock_gen = tot_stock_loc + tot_stock_rem
IF flag <> 'T' THEN
	LET lim = fgl_scr_size('r_loc')
ELSE
	LET lim = fgl_scr_size('r_loc2')
END IF
FOR i = 1 TO lim
	IF i > i_loc THEN
		EXIT FOR
	END IF
	IF flag <> 'T' THEN
		DISPLAY r_loc[i].*  TO r_loc[i].*
	ELSE
		DISPLAY r_loc2[i].* TO r_loc2[i].*
	END IF
END FOR
FOR i = 1 TO fgl_scr_size('r_rem')      
	IF i > i_rem THEN               
		EXIT FOR                
	END IF                          
	DISPLAY r_rem[i].* TO r_rem[i].*
END FOR                            
DISPLAY BY NAME tot_stock_loc, tot_stock_rem, tot_stock_gen
LET salir = 0
IF i_loc > 0 THEN
	IF flag <> 'T' THEN
		CALL control_detalle_bodega_loc(flag, pos) RETURNING salir
	ELSE
		{--
		CALL control_detalle_cant_bodega_loc(flag, pos) RETURNING salir
		LET query = 'INSERT INTO temp_sto ',
				'SELECT bod_loc, "', codigo CLIPPED, '", "',
					rm_detalle[pos].r44_item_tra CLIPPED,
					'", stock_loc, cant_loc ',
					'FROM temp_loc ',
					'WHERE cant_loc IS NOT NULL '
		PREPARE exec_sto FROM query
		EXECUTE exec_sto
		--}
	END IF
END IF
IF i_rem > 0 AND salir = 0 THEN
	CALL control_detalle_bodega_rem(flag, pos) RETURNING salir
END IF
DROP TABLE temp_loc
DROP TABLE temp_rem
LET int_flag = 0
IF flag <> 'T' THEN
	CLOSE WINDOW w_repf247_3
ELSE
	CLOSE WINDOW w_repf247_4
END IF
RETURN

END FUNCTION



{--
FUNCTION control_detalle_cant_bodega_loc(flag, pos)
DEFINE flag		CHAR(1)
DEFINE pos		SMALLINT
DEFINE resp		CHAR(6)
DEFINE i, j, k, l	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE query		CHAR(400)
DEFINE tot_cant_loc	DECIMAL(10,2)

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col          = 3
LET vm_columna_1 = col
LET vm_columna_2 = 1
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT * FROM temp_loc ',
			'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				',', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE loc2 FROM query
	DECLARE q_loc2 CURSOR FOR loc2
	LET k = 1
	LET tot_cant_loc = 0
	FOREACH q_loc2 INTO r_loc2[k].*
		IF r_loc2[k].cant_loc IS NOT NULL THEN
			LET tot_cant_loc = tot_cant_loc + r_loc2[k].cant_loc
		END IF
		LET k = k + 1
		IF k > i_loc THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET k     = k - 1
	LET salir = 0
	CALL muestra_contadores_det_tot(1, i_loc, 0, i_rem)
	DISPLAY BY NAME tot_cant_loc
	CALL set_count(k)
	INPUT ARRAY r_loc2 WITHOUT DEFAULTS FROM r_loc2.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET salir    = 1
				LET int_flag = 1
				EXIT INPUT
			END IF
		ON KEY(F5)
			IF i_rem > 0 THEN
				CALL muestra_contadores_det_tot(0, i_loc, 1,
								i_rem)
				CALL control_detalle_bodega_rem(flag, pos)
					RETURNING salir
				IF salir = 1 THEN
					EXIT INPUT
				END IF
			END IF
		ON KEY(F15)
			LET col = 1
			EXIT INPUT
		ON KEY(F16)
			LET col = 2
			EXIT INPUT
		ON KEY(F17)
			LET col = 3
			EXIT INPUT
		ON KEY(F18)
			LET col = 4
			EXIT INPUT
		BEFORE INPUT
			CALL dialog.keysetlabel('DELETE','')
			CALL dialog.keysetlabel('INSERT','')
			IF i_rem > 0 THEN
				CALL dialog.keysetlabel("F5","Remotas") 
			ELSE
				CALL dialog.keysetlabel("F5","") 
			END IF
		BEFORE DELETE
			CANCEL DELETE
		BEFORE INSERT
			CANCEL INSERT
		BEFORE ROW 
			LET i = arr_curr()	
			LET j = scr_line()
			CALL muestra_contadores_det_tot(i, i_loc, 0, i_rem)
		AFTER FIELD cant_loc
			IF r_loc2[i].cant_loc IS NOT NULL THEN
				IF r_loc2[i].cant_loc > r_loc2[i].stock_loc THEN
					CALL fl_mostrar_mensaje('La cantidad a traspasar no puede ser mayor que el stock de la bodega.', 'exclamation')
					NEXT FIELD cant_loc
				END IF
				UPDATE temp_loc
					SET cant_loc = r_loc2[i].cant_loc
					WHERE bod_loc = r_loc2[i].bod_loc
			ELSE
				UPDATE temp_loc
					SET cant_loc = NULL
					WHERE bod_loc = r_loc2[i].bod_loc
			END IF
		AFTER ROW 
			LET tot_cant_loc = 0
			FOR l = 1 TO k
				IF r_loc2[l].cant_loc IS NULL THEN
					CONTINUE FOR
				END IF
				LET tot_cant_loc = tot_cant_loc +
							r_loc2[l].cant_loc
			END FOR
			DISPLAY BY NAME tot_cant_loc
	        AFTER INPUT
			LET tot_cant_loc = 0
			FOR l = 1 TO k
				IF r_loc2[l].cant_loc IS NULL THEN
					CONTINUE FOR
				END IF
				LET tot_cant_loc = tot_cant_loc +
							r_loc2[l].cant_loc
			END FOR
			DISPLAY BY NAME tot_cant_loc
			IF tot_cant_loc = 0 THEN
				CALL fl_mostrar_mensaje('Al menos debe digitar un valor mayor a cero en cantidad a traspasar de cualquiera de las bodegas.', 'info')
				CONTINUE INPUT
			END IF
			IF tot_cant_loc > rm_detalle[pos].r44_cant_tra THEN
				CALL fl_mostrar_mensaje('El total de la cantidad a traspasar no puede ser mayor que la cantidad de traspaso digitada para este item.', 'exclamation')
				CONTINUE INPUT
			END IF
			LET salir = 1
	END INPUT
	IF salir = 1 THEN
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
RETURN salir

END FUNCTION 
--}



FUNCTION control_detalle_bodega_loc(flag, pos)
DEFINE flag		CHAR(1)
DEFINE pos		SMALLINT
DEFINE i, j, salir	SMALLINT
DEFINE col 		SMALLINT
DEFINE query		CHAR(400)

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col          = 3
LET vm_columna_1 = col
LET vm_columna_2 = 1
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT bod_loc, nom_bod_loc, stock_loc FROM temp_loc ',
			'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				',', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE loc FROM query
	DECLARE q_loc CURSOR FOR loc 
	LET i = 1
	FOREACH q_loc INTO r_loc[i].*
		LET i = i + 1
		IF i > i_loc THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	LET salir = 0
	CALL muestra_contadores_det_tot(1, i_loc, 0, i_rem)
	CALL set_count(i)
	DISPLAY ARRAY r_loc TO r_loc.*
        	ON KEY(INTERRUPT)   
			LET salir = 1
        	        EXIT DISPLAY  
        	ON KEY(RETURN)   
			LET i = arr_curr()
			CALL muestra_contadores_det_tot(i, i_loc, 0, i_rem)
			IF flag = 'D' THEN
				LET rm_detalle[pos].r44_bodega_tra =
							r_loc[i].bod_loc
				LET rm_detalle[pos].r44_stock_tra  =
							r_loc[i].stock_loc
				LET salir = 1
        		        EXIT DISPLAY
			END IF
		ON KEY(F5)
			IF i_rem > 0 THEN
				CALL muestra_contadores_det_tot(0, i_loc, 1,
								i_rem)
				CALL control_detalle_bodega_rem(flag, pos)
					RETURNING salir
				IF salir = 1 THEN
					EXIT DISPLAY
				END IF
			END IF
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		--#BEFORE DISPLAY 
			--#CALL dialog.keysetlabel('ACCEPT', '')   
			--#IF i_rem > 0 THEN
				--#CALL dialog.keysetlabel("F5","Remotas") 
			--#ELSE
				--#CALL dialog.keysetlabel("F5","") 
			--#END IF
		--#BEFORE ROW 
			--#LET i = arr_curr()	
			--#LET j = scr_line()
			--#CALL muestra_contadores_det_tot(i, i_loc, 0, i_rem)
	        --#AFTER DISPLAY  
	                --#CONTINUE DISPLAY  
	END DISPLAY
	IF salir = 1 THEN
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
RETURN salir

END FUNCTION 



FUNCTION control_detalle_bodega_rem(flag, pos)
DEFINE flag		CHAR(1)
DEFINE pos		SMALLINT
DEFINE i, j, salir 	SMALLINT
DEFINE col 		SMALLINT
DEFINE query		CHAR(400)

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col          = 3
LET vm_columna_1 = col
LET vm_columna_2 = 1
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT * FROM temp_rem ',
			'ORDER BY ',
				vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
				vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE rem FROM query
	DECLARE q_rem CURSOR FOR rem 
	LET i = 1
	FOREACH q_rem INTO r_rem[i].*
		LET i = i + 1
		IF i > i_rem THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	LET salir = 0
	CALL muestra_contadores_det_tot(0, i_loc, 1, i_rem)
	CALL set_count(i)
	DISPLAY ARRAY r_rem TO r_rem.*
        	ON KEY(INTERRUPT)   
			LET salir = 1
	                EXIT DISPLAY  
		ON KEY(RETURN)
			LET i = arr_curr()	
			LET j = scr_line()
			CALL muestra_contadores_det_tot(0, i_loc, i, i_rem)
		ON KEY(F5)
			IF i_loc > 0 THEN
				CALL muestra_contadores_det_tot(1, i_loc, 0,
								i_rem)
				IF flag <> 'T' THEN
					CALL control_detalle_bodega_loc(flag,
									pos)
						RETURNING salir
				ELSE
					--CALL control_detalle_cant_bodega_loc(
								--flag, pos)
						--RETURNING salir
				END IF
				IF salir = 1 THEN
					EXIT DISPLAY
				END IF
			END IF
		ON KEY(F18)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 3
			EXIT DISPLAY
	        --#BEFORE DISPLAY 
	                --#CALL dialog.keysetlabel('ACCEPT', '')   
			--#CALL dialog.keysetlabel("F1","") 
			--#IF i_loc > 0 THEN
				--#CALL dialog.keysetlabel("F5","Locales") 
			--#ELSE
				--#CALL dialog.keysetlabel("F5","") 
			--#END IF
				--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#BEFORE ROW 
			--#LET i = arr_curr()	
			--#LET j = scr_line()
			--#CALL muestra_contadores_det_tot(0, i_loc, i, i_rem)
	        --#AFTER DISPLAY  
	                --#CONTINUE DISPLAY  
	END DISPLAY 
	IF salir = 1 THEN
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
RETURN salir

END FUNCTION 



FUNCTION muestra_contadores_det_tot(num_row_l, max_row_l, num_row_r, max_row_r)
DEFINE num_row_l, max_row_l	SMALLINT
DEFINE num_row_r, max_row_r	SMALLINT

DISPLAY BY NAME num_row_l, max_row_l, num_row_r, max_row_r

END FUNCTION 



FUNCTION mostrar_cabecera_bodegas_ln(flag)
DEFINE flag		CHAR(1)

IF flag <> 'T' THEN
	DISPLAY 'BD'			TO tit_col1
	DISPLAY 'Bodegas Locales'	TO tit_col2
	DISPLAY 'Stock'			TO tit_col3
	DISPLAY 'BD'			TO tit_col4
	DISPLAY 'Bodegas Remotas'	TO tit_col5
	DISPLAY 'Stock'			TO tit_col6
ELSE
	DISPLAY 'BD'			TO tit_col1
	DISPLAY 'Bodegas Locales'	TO tit_col2
	DISPLAY 'Stock'			TO tit_col3
	DISPLAY 'Cant. Tra.'		TO tit_col4
	DISPLAY 'BD'			TO tit_col5
	DISPLAY 'Bodegas Remotas'	TO tit_col6
	DISPLAY 'Stock'			TO tit_col7
END IF

END FUNCTION 



FUNCTION mostrar_etiquetas(i)
DEFINE i		SMALLINT

CALL muestra_contadores_det(i, vm_num_det, i, vm_num_det)
DISPLAY rm_adi[i].r44_desc_clase_t TO r44_desc_clase_t
DISPLAY rm_adi[i].r44_desc_tra     TO r44_desc_tra
{
IF rm_r43.r43_cod_clase IS NULL THEN
	DISPLAY rm_adi[i].r43_cod_clase  TO r43_cod_clase
	DISPLAY rm_adi[i].r43_desc_clase TO r43_desc_clase
END IF
}

END FUNCTION 
