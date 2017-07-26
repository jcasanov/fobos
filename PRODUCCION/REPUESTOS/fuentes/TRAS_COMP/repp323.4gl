--------------------------------------------------------------------------------
-- Titulo           : repp323.4gl - Consulta ventas de items compuestos
-- Elaboracion      : 28-Sep-2010
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp323 base m√≥dulo compa√±√≠a localidad
--			[fec_ini] [fec_fin] [tipo = V, C Û D] [item]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE rm_orden 	ARRAY[15] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_par 		RECORD 
				fecha_ini	DATE,
				fecha_fin	DATE
			END RECORD
DEFINE rm_detalle	ARRAY [30000] OF RECORD
				item		LIKE rept010.r10_codigo,
				descripcion	LIKE rept010.r10_nombre,
				valor_bruto	LIKE rept019.r19_tot_bruto,
				valor_desc	LIKE rept019.r19_tot_dscto,
				subtotal	DECIMAL(12,2)
			END RECORD
DEFINE rm_adi		ARRAY [30000] OF RECORD
				desc_clase	LIKE rept072.r72_desc_clase,
				desc_item	LIKE rept010.r10_nombre,
				desc_marca	LIKE rept073.r73_desc_marca
			END RECORD
DEFINE r_det_tran	ARRAY [30000] OF RECORD
				ini_vend	LIKE rept001.r01_iniciales,
				cod_tran	LIKE rept020.r20_cod_tran,
				num_tran	LIKE rept020.r20_num_tran,
				fecha		DATE,
				valor_bruto	LIKE rept019.r19_tot_bruto,
				valor_desc	LIKE rept019.r19_tot_dscto,
				subtotal	DECIMAL(12,2)
			END RECORD
DEFINE r_det_carg	ARRAY [30000] OF RECORD
				fecha		DATE,
				carga		LIKE rept048.r48_sec_carga,
				referencia	LIKE rept048.r48_referencia,
				unid_carga	LIKE rept048.r48_carg_stock,
				costo		LIKE rept048.r48_costo_comp,
				marca		LIKE rept046.r46_marca_c
			END RECORD
DEFINE composicion	ARRAY[3000] OF LIKE rept048.r48_composicion
DEFINE rm_g05		RECORD LIKE gent005.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp323.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 8 THEN  -- Validar # par√°metros correcto
	CALL fl_mostrar_mensaje('N√∫mero de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp323'
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
LET vm_max_det = 30000
LET lin_menu   = 0
LET row_ini    = 3
LET num_rows   = 22
LET num_cols   = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
IF arg_val(7) <> 'V' AND arg_val(7) <> 'C' THEN
	OPEN WINDOW w_repp323 AT row_ini, 02
		WITH num_rows ROWS, num_cols COLUMNS
			ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST,
				MENU LINE lin_menu, MESSAGE LINE LAST, BORDER)
	IF vg_gui = 1 THEN
		OPEN FORM f_repf323_1 FROM "../forms/repf323_1"
	ELSE
		OPEN FORM f_repf323_1 FROM "../forms/repf323_1c"
	END IF
	DISPLAY FORM f_repf323_1
	CALL muestra_contadores_det(0, 0)
	CALL borrar_cabecera()
	CALL borrar_detalle()
	CALL mostrar_cabecera_forma()
END IF
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
LET vm_num_det = 0
IF num_args() = 4 THEN
	CALL control_consulta()
ELSE
	CALL llamada_desde_otro_programa()
END IF
IF arg_val(7) <> 'V' AND arg_val(7) <> 'C' THEN
	CLOSE WINDOW w_repp323
END IF
RETURN

END FUNCTION



FUNCTION control_consulta()

INITIALIZE rm_par.* TO NULL
LET rm_par.fecha_fin = TODAY
LET rm_par.fecha_ini = MDY(MONTH(rm_par.fecha_fin), 01, YEAR(rm_par.fecha_fin))
WHILE TRUE
	CALL borrar_detalle()
	CALL muestra_contadores_det(0, 0)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL mostrar_consulta()
END WHILE

END FUNCTION



FUNCTION llamada_desde_otro_programa()

INITIALIZE rm_par.* TO NULL
LET rm_par.fecha_ini = arg_val(5)
LET rm_par.fecha_fin = arg_val(6)
IF arg_val(7) = 'D' THEN
		CALL borrar_detalle()
		DISPLAY BY NAME rm_par.fecha_ini, rm_par.fecha_fin
		CALL muestra_contadores_det(0, 0)
		CALL mostrar_consulta()
ELSE
	IF preparar_tabla_temp_consulta() THEN
		LET vm_columna_1           = 1
		LET vm_columna_2           = 2
		LET rm_orden[vm_columna_1] = 'ASC'
		LET rm_orden[vm_columna_2] = 'ASC'
		CALL cargar_detalle_venta()
	END IF
	CASE arg_val(7)
		WHEN 'V' CALL detalle_venta(0)
		WHEN 'C' CALL detalle_carga(0)
	END CASE
	DROP TABLE tmp_vta
END IF

END FUNCTION



FUNCTION lee_parametros()
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD fecha_ini 
		IF rm_par.fecha_ini IS NULL THEN
			LET rm_par.fecha_ini = fec_ini     
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
		IF rm_par.fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin 
		IF rm_par.fecha_fin IS NULL THEN
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
		IF rm_par.fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha de t√©rmino no puede ser mayor a la de hoy.','exclamation')
			NEXT FIELD fecha_fin
		END IF
	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION mostrar_consulta()
DEFINE i, j, col, salir	SMALLINT

IF NOT preparar_tabla_temp_consulta() THEN
	RETURN
END IF
LET vm_columna_1           = 1
LET vm_columna_2           = 2
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'
INITIALIZE col TO NULL
LET salir = 0
WHILE NOT salir
	CALL cargar_detalle_venta()
	CALL mostrar_totales(1, vm_num_det)
	LET int_flag = 0
	CALL set_count(vm_num_det)
	DISPLAY ARRAY rm_detalle TO rm_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			LET salir    = 1
			EXIT DISPLAY
		ON KEY(F5)
			IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE'
			THEN
				LET i = arr_curr()
				CALL mostrar_item(rm_detalle[i].item)
				LET int_flag = 0
			END IF
		ON KEY(F6)
			LET i = arr_curr()
			CALL detalle_venta(i)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL detalle_carga(i)
			LET int_flag = 0
		ON KEY(F8)
			CALL imprimir_listado()
			LET int_flag = 0
		ON KEY(F9)
			CALL generar_archivo()
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
		BEFORE DISPLAY
			CALL dialog.keysetlabel("ACCEPT","")
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			IF rm_g05.g05_grupo = 'SI' OR rm_g05.g05_grupo = 'GE'
			THEN
				CALL dialog.keysetlabel("F5", "Item")
			ELSE
				CALL dialog.keysetlabel("F5", "")
			END IF
			CALL muestra_etiquetas(i)
		AFTER DISPLAY
			CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 OR salir THEN
		EXIT WHILE
	END IF
	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
DROP TABLE tmp_vta

END FUNCTION



FUNCTION preparar_tabla_temp_consulta()
DEFINE fec_ini, fec_fin	LIKE rept019.r19_fecing
DEFINE query		CHAR(6000)

LET fec_ini  = EXTEND(rm_par.fecha_ini, YEAR TO SECOND)
LET fec_fin  = EXTEND(rm_par.fecha_fin, YEAR TO SECOND)
		+ 23 UNITS HOUR + 59 UNITS MINUTE + 59 UNITS SECOND  
LET query = 'SELECT r19_cod_tran cod_tran, r19_num_tran num_tran, ',
		'(SELECT r01_iniciales ',
			'FROM rept001 ',
			'WHERE r01_compania = r19_compania ',
			'  AND r01_codigo   = r19_vendedor) ini_vend, ',
		'(SELECT r01_nombres ',
			'FROM rept001 ',
			'WHERE r01_compania = r19_compania ',
			'  AND r01_codigo   = r19_vendedor) vendedor, ',
		'DATE(r19_fecing) fecha, NVL(r19_codcli, 99) codcli, ',
		'r19_nomcli nomcli, r20_item item, ',
		'(SELECT r10_nombre ',
			'FROM rept010 ',
			'WHERE r10_compania = r20_compania ',
			'  AND r10_codigo   = r20_item) descripcion, ',
		'NVL(CASE WHEN r20_cod_tran = "FA" OR r20_cod_tran = "NV" ',
			'THEN (r20_cant_ven * r20_precio) ',
			'ELSE (r20_cant_ven * r20_precio) * (-1) ',
		'END, 0) tot_bruto, ',
		'NVL(CASE WHEN r20_cod_tran = "FA" OR r20_cod_tran = "NV" ',
			'THEN r20_val_descto ',
			'ELSE r20_val_descto * (-1) ',
		'END, 0) tot_dscto, ',
		'NVL(CASE WHEN r20_cod_tran = "FA" OR r20_cod_tran = "NV" ',
			'THEN ((r20_cant_ven * r20_precio) - r20_val_descto) ',
			'ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) ',
				' * (-1) ',
		'END, 0) subtotal, ',
		' (SELECT r72_desc_clase ',
			'FROM rept010, rept072 ',
			'WHERE r10_compania  = r20_compania ',
			'  AND r10_codigo    = r20_item ',
			'  AND r72_compania  = r10_compania ',
			'  AND r72_linea     = r10_linea ',
			'  AND r72_sub_linea = r10_sub_linea ',
			'  AND r72_cod_grupo = r10_cod_grupo ',
			'  AND r72_cod_clase = r10_cod_clase) desc_clase, ',
		' (SELECT r73_desc_marca ',
			'FROM rept010, rept073 ',
			'WHERE r10_compania  = r20_compania ',
			'  AND r10_codigo    = r20_item ',
			'  AND r73_compania  = r10_compania ',
			'  AND r73_marca     = r10_marca) desc_marca ',
		' FROM rept019, rept020 ',
		' WHERE r19_compania  = ', vg_codcia,
		'   AND r19_localidad = ', vg_codloc,
		'   AND r19_cod_tran  IN ("FA", "NV", "DF", "AF") ',
		'   AND r19_fecing    BETWEEN "', fec_ini, '"',
					' AND "', fec_fin, '"',
		'   AND r20_compania  = r19_compania ',
		'   AND r20_localidad = r19_localidad ',
		'   AND r20_cod_tran  = r19_cod_tran ',
		'   AND r20_num_tran  = r19_num_tran ',
		'   AND EXISTS ',
			'(SELECT 1 FROM rept046 ',
				'WHERE r46_compania    = r20_compania ',
				'  AND r46_item_comp   = r20_item ',
				'  AND r46_estado      = "C" ',
				'  AND r46_fec_cierre <= r20_fecing) ',
		' INTO TEMP tmp_vta '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
SELECT COUNT(UNIQUE item) INTO vm_num_det FROM tmp_vta
IF vm_num_det = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE tmp_vta
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION cargar_detalle_venta()
DEFINE i		SMALLINT
DEFINE query		CHAR(800)

LET query = "SELECT item, descripcion, SUM(tot_bruto), SUM(tot_dscto),",
		" SUM(subtotal), desc_clase, descripcion, desc_marca ",
		" FROM tmp_vta ",
		" GROUP BY 1, 2, 6, 7, 8 ",
               	" ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
			", ", vm_columna_2, " ", rm_orden[vm_columna_2]
PREPARE venta FROM query
DECLARE q_venta CURSOR FOR venta
LET i = 1
FOREACH q_venta INTO rm_detalle[i].*, rm_adi[i].*
	LET i = i + 1
	IF i > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH

END FUNCTION



FUNCTION borrar_cabecera()

INITIALIZE rm_par.* TO NULL
DISPLAY BY NAME rm_par.*

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0, 0)
FOR i = 1 TO fgl_scr_size('rm_detalle')
        INITIALIZE rm_detalle[i].*, rm_adi[i].* TO NULL
        CLEAR rm_detalle[i].*
END FOR
CLEAR total_bruto, total_desc, total, desc_clase, desc_item, desc_marca,
	num_row, max_row

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

--#DISPLAY "Items"		TO tit_col1
--#DISPLAY "DescripciÛn"	TO tit_col2
--#DISPLAY "Tot. Bruto"		TO tit_col3
--#DISPLAY "Tot. Dscto"		TO tit_col4
--#DISPLAY "Subtotal"		TO tit_col5

END FUNCTION



FUNCTION mostrar_totales(flag, max_row)
DEFINE flag		SMALLINT
DEFINE max_row		SMALLINT
DEFINE total_bruto	DECIMAL(12,2)
DEFINE total_desc	DECIMAL(12,2)
DEFINE total		DECIMAL(12,2)
DEFINE i		SMALLINT

LET total_bruto = 0
LET total_desc  = 0
LET total       = 0
FOR i = 1 TO max_row
	CASE flag
		WHEN 1
			LET total_bruto = total_bruto +rm_detalle[i].valor_bruto
			LET total_desc  = total_desc + rm_detalle[i].valor_desc
			LET total       = total + rm_detalle[i].subtotal
		WHEN 2
			LET total_bruto = total_bruto +r_det_tran[i].valor_bruto
			LET total_desc  = total_desc + r_det_tran[i].valor_desc
			LET total       = total + r_det_tran[i].subtotal
	END CASE
END FOR
DISPLAY BY NAME total_bruto, total_desc, total

END FUNCTION



FUNCTION muestra_etiquetas(i)
DEFINE i		SMALLINT

CALL muestra_contadores_det(i, vm_num_det)
DISPLAY BY NAME rm_adi[i].*

END FUNCTION



FUNCTION mostrar_item(item)
DEFINE item		LIKE rept020.r20_item
DEFINE param		VARCHAR(60)

LET param = ' "', item CLIPPED, '"'
CALL fl_ejecuta_comando('REPUESTOS', vg_modulo, 'repp108 ', param, 1)

END FUNCTION



FUNCTION detalle_venta(pos)
DEFINE pos		SMALLINT
DEFINE r_adi_tran	ARRAY [30000] OF RECORD
				codcli		LIKE rept019.r19_codcli,
				nomcli		LIKE rept019.r19_nomcli,
				vendedor	LIKE rept001.r01_nombres
			END RECORD
DEFINE num_row, i	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE query		CHAR(1500)

IF pos = 0 THEN
	FOR i = 1 TO vm_num_det
		IF rm_detalle[i].item = arg_val(8) THEN
			LET pos = i
			EXIT FOR
		END IF
	END FOR
END IF
LET query = 'SELECT ini_vend, cod_tran, num_tran, fecha, tot_bruto, ',
			'tot_dscto, subtotal, codcli, nomcli, vendedor ',
		' FROM tmp_vta ',
		' WHERE item = "', rm_detalle[pos].item CLIPPED, '"',
		' INTO TEMP tmp_det '
PREPARE exec_det FROM query
EXECUTE exec_det
SELECT COUNT(*) INTO num_row FROM tmp_det
IF num_row = 0 THEN
	DROP TABLE tmp_det
	CALL fl_mostrar_mensaje('No se ha generado ninguna transaccion.', 'exclamation')
	RETURN
END IF
OPEN WINDOW w_repf323_2 AT 05, 05 WITH 19 ROWS, 71 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
		MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_repf323_2 FROM '../forms/repf323_2'
ELSE
	OPEN FORM f_repf323_2 FROM '../forms/repf323_2c'
END IF
DISPLAY FORM f_repf323_2
DISPLAY BY NAME rm_detalle[pos].item, rm_adi[pos].desc_clase,
		rm_adi[pos].desc_item
--#DISPLAY 'Ven'        TO tit_col1
--#DISPLAY 'TP'         TO tit_col2
--#DISPLAY 'N˙mero'     TO tit_col3
--#DISPLAY 'Fecha'      TO tit_col4
--#DISPLAY "Tot. Bruto"	TO tit_col5
--#DISPLAY "Tot. Dscto"	TO tit_col6
--#DISPLAY "Subtotal"	TO tit_col7
LET vm_columna_1           = 4
LET vm_columna_2           = 3
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'
INITIALIZE col TO NULL
LET salir = 0
WHILE NOT salir
	LET query = "SELECT * FROM tmp_det ",
                   	" ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
				", ", vm_columna_2, " ", rm_orden[vm_columna_2]
	PREPARE cons_dett FROM query
	DECLARE q_cursor1 CURSOR FOR cons_dett
	LET num_row = 1
	FOREACH q_cursor1 INTO r_det_tran[num_row].*, r_adi_tran[num_row].*
		LET num_row = num_row + 1
		IF num_row > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET num_row = num_row - 1
	CALL mostrar_totales(2, num_row)
	LET int_flag = 0
	CALL set_count(num_row)
	DISPLAY ARRAY r_det_tran TO r_det_tran.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			LET salir    = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
							r_det_tran[i].cod_tran,
							r_det_tran[i].num_tran)
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL control_ver_estado_cuentas(r_adi_tran[i].codcli)
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
		ON KEY(F20)
			LET col = 6
			EXIT DISPLAY
		ON KEY(F21)
			LET col = 7
			EXIT DISPLAY
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT', '')
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_contadores_det(i, num_row)
			--#DISPLAY BY NAME r_adi_tran[i].*
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 OR salir THEN
		EXIT WHILE
	END IF
	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
DROP TABLE tmp_det
LET int_flag = 0
CLOSE WINDOW w_repf323_2
RETURN

END FUNCTION



FUNCTION control_ver_estado_cuentas(cliente)
DEFINE cliente		LIKE rept019.r19_codcli
DEFINE command_run 	VARCHAR(200)
DEFINE run_prog		CHAR(10)
DEFINE fecha		DATE

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
IF vg_gui = 0 THEN
	CALL fl_mostrar_mensaje('Este programa no esta para este tipo de terminales.', 'exclamation')
	RETURN
END IF
LET fecha       = TODAY
LET command_run = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
		vg_separador, 'fuentes', vg_separador, '; fglrun cxcp314 ',
		vg_base, ' "CO" ', vg_codcia, ' ', vg_codloc, ' ',
		rg_gen.g00_moneda_base, ' ', fecha, ' "T" 0.01 "N" 0 ', cliente
RUN command_run

END FUNCTION



FUNCTION detalle_carga(pos)
DEFINE pos		SMALLINT
DEFINE total_carga	DECIMAL(12,2)
DEFINE total_costo	DECIMAL(12,2)
DEFINE num_row, i	SMALLINT
DEFINE col, salir	SMALLINT
DEFINE query		CHAR(1500)

IF pos = 0 THEN
	FOR i = 1 TO vm_num_det
		IF rm_detalle[i].item = arg_val(8) THEN
			LET pos = i
			EXIT FOR
		END IF
	END FOR
END IF
LET query = 'SELECT DATE(r48_fec_cierre) fecha, r48_sec_carga, r48_referencia,',
			' r48_carg_stock, r48_costo_comp, r46_marca_c,',
			' r48_composicion ',
		' FROM rept048, rept046 ',
		' WHERE r48_compania    = ', vg_codcia,
		'   AND r48_localidad   = ', vg_codloc,
		'   AND r48_item_comp   = "', rm_detalle[pos].item CLIPPED, '"',
		'   AND r46_compania    = r48_compania ',
		'   AND r46_localidad   = r48_localidad ',
		'   AND r46_composicion = r48_composicion ',
		'   AND r46_item_comp   = r48_item_comp ',
		' INTO TEMP tmp_car '
PREPARE exec_det2 FROM query
EXECUTE exec_det2
SELECT COUNT(*) INTO num_row FROM tmp_car
IF num_row = 0 THEN
	DROP TABLE tmp_car
	CALL fl_mostrar_mensaje('No se ha generado ninguna carga.', 'exclamation')
	RETURN
END IF
OPEN WINDOW w_repf323_3 AT 06, 03 WITH 17 ROWS, 77 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
		MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_repf323_3 FROM '../forms/repf323_3'
ELSE
	OPEN FORM f_repf323_3 FROM '../forms/repf323_3c'
END IF
DISPLAY FORM f_repf323_3
DISPLAY BY NAME rm_detalle[pos].item, rm_adi[pos].desc_item
--#DISPLAY 'Fecha'      TO tit_col1
--#DISPLAY 'Carga'      TO tit_col2
--#DISPLAY 'Referencia' TO tit_col3
--#DISPLAY 'Uni. C.'	TO tit_col4
--#DISPLAY 'Costo'	TO tit_col5
--#DISPLAY 'Marca'	TO tit_col6
LET vm_columna_1           = 1
LET vm_columna_2           = 2
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'
INITIALIZE col TO NULL
LET salir = 0
WHILE NOT salir
	LET query = "SELECT * FROM tmp_car ",
                   	" ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
				", ", vm_columna_2, " ", rm_orden[vm_columna_2]
	PREPARE cons_dett2 FROM query
	DECLARE q_cursor2 CURSOR FOR cons_dett2
	LET total_carga = 0
	LET total_costo = 0
	LET num_row     = 1
	FOREACH q_cursor2 INTO r_det_carg[num_row].*, composicion[num_row]
		LET total_carga = total_carga + r_det_carg[num_row].unid_carga
		LET total_costo = total_costo + r_det_carg[num_row].costo
		LET num_row     = num_row + 1
		IF num_row > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET num_row  = num_row - 1
	DISPLAY BY NAME total_carga, total_costo
	LET int_flag = 0
	CALL set_count(num_row)
	DISPLAY ARRAY r_det_carg TO r_det_carg.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			LET salir    = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_carga(rm_detalle[pos].item, i)
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
		ON KEY(F20)
			LET col = 6
			EXIT DISPLAY
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT', '')
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_contadores_det(i, num_row)
			--#DISPLAY BY NAME composicion[i]
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 OR salir THEN
		EXIT WHILE
	END IF
	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
DROP TABLE tmp_car
LET int_flag = 0
CLOSE WINDOW w_repf323_3
RETURN

END FUNCTION



FUNCTION ver_carga(item, i)
DEFINE item		LIKE rept010.r10_codigo
DEFINE i		SMALLINT
DEFINE param		VARCHAR(60)

LET param = ' ', composicion[i], ' "', item CLIPPED, '" ', r_det_carg[i].carga
CALL fl_ejecuta_comando('REPUESTOS', vg_modulo, 'repp249 ', param, 1)

END FUNCTION



FUNCTION imprimir_listado()
DEFINE i		INTEGER
DEFINE comando		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT listado_ventas_item_compuesto TO PIPE comando
	FOR i = 1 TO vm_num_det
		OUTPUT TO REPORT listado_ventas_item_compuesto(rm_detalle[i].*,
								rm_adi[i].*)
	END FOR
FINISH REPORT listado_ventas_item_compuesto

END FUNCTION



REPORT listado_ventas_item_compuesto(r_rep)
DEFINE r_rep 		RECORD
				item		LIKE rept010.r10_codigo,
				descripcion	LIKE rept010.r10_nombre,
				valor_bruto	LIKE rept019.r19_tot_bruto,
				valor_desc	LIKE rept019.r19_tot_dscto,
				subtotal	DECIMAL(12,2),
				desc_clase	LIKE rept072.r72_desc_clase,
				desc_item	LIKE rept010.r10_nombre,
				desc_marca	LIKE rept073.r73_desc_marca
			END RECORD
DEFINE r_cia		RECORD LIKE gent001.*
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	0
	LEFT MARGIN	0
	RIGHT MARGIN	132 
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET modulo      = "MODULO: INVENTARIO"
	LET long        = LENGTH(modulo)
	LET usuario     = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO VENTAS ITEMS COMPUESTO', 80)
		RETURNING titulo
	CALL fl_lee_compania(vg_codcia) RETURNING r_cia.*
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_10cpi
	PRINT COLUMN 001, r_cia.g01_razonsocial,
  	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 026, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT COLUMN 052, "** FECHA INICIAL : ",
		rm_par.fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 052, "** FECHA FINAL   : ", 
		 rm_par.fecha_fin USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "ITEM",
	      COLUMN 016, "C L A S E",
	      COLUMN 047, "D E S C R I P C I O N",
	      COLUMN 082, "MARCA",
	      COLUMN 089, "   TOTAL BRUTO",
	      COLUMN 104, "  TOTAL DSCTO.",
	      COLUMN 119, "      SUBTOTAL"
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, r_rep.item[1, 6]		CLIPPED,
	      COLUMN 008, r_rep.desc_clase[1, 25]	CLIPPED,
	      COLUMN 034, r_rep.desc_item[1, 47]	CLIPPED,
	      COLUMN 082, r_rep.desc_marca[1, 6]	CLIPPED,
	      COLUMN 089, r_rep.valor_bruto		USING "---,---,--&.##",
	      COLUMN 104, r_rep.valor_desc		USING "---,---,--&.##",
	      COLUMN 119, r_rep.subtotal		USING "---,---,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 089, "--------------",
	      COLUMN 104, "--------------",
	      COLUMN 119, "--------------"
	PRINT COLUMN 076, "TOTALES ==>  ",
	      COLUMN 089, SUM(r_rep.valor_bruto)	USING "---,---,--&.##",
	      COLUMN 104, SUM(r_rep.valor_desc)		USING "---,---,--&.##",
	      COLUMN 119, SUM(r_rep.subtotal)		USING "---,---,--&.##"
	print ASCII escape;
	print ASCII desact_comp

END REPORT



FUNCTION generar_archivo()
DEFINE mensaje		VARCHAR(100)

ERROR 'Generando Archivo repp323.unl ... por favor espere'
UNLOAD TO "../../../tmp/repp323.unl"
	SELECT codcli, nomcli, cod_tran, num_tran, fecha, vendedor, item,
		desc_clase, descripcion, desc_marca, tot_bruto, tot_dscto,
		subtotal
		FROM tmp_vta
		ORDER BY 5 ASC, 2 ASC, 3 ASC, 4 ASC
RUN "mv ../../../tmp/repp323.unl $HOME/tmp/"
LET mensaje = FGL_GETENV("HOME"), '/tmp/repp323.unl'
CALL fl_mostrar_mensaje('Archivo Generado en: ' || mensaje, 'info')
ERROR ' '

END FUNCTION
