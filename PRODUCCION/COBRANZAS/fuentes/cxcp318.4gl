--------------------------------------------------------------------------------
-- Titulo           : cxcp318.4gl - Consulta de Documentos
-- Elaboracion      : 12-Oct-2008
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp318 base modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par 		RECORD
				tipo_doc	LIKE cxct021.z21_tipo_doc,
				nom_doc		VARCHAR(30),
				ind_doc		CHAR(1),
				modulo		LIKE gent050.g50_modulo,
				nom_mod		LIKE gent050.g50_nombre,
				fecha_ini	DATE,
				fecha_fin	DATE
			END RECORD
DEFINE rm_detalle 	ARRAY[20000] OF RECORD
				localidad	LIKE cxct020.z20_localidad,
				tip_doc		LIKE cxct020.z20_tipo_doc,
				num_doc		VARCHAR(18),
				fecha		LIKE cxct020.z20_fecha_emi,
				nomcli		LIKE cxct001.z01_nomcli,
				valor_doc	LIKE cxct020.z20_valor_cap,
				saldo_doc	LIKE cxct020.z20_saldo_cap
			END RECORD
DEFINE rm_adi		ARRAY[20000] OF RECORD
				cod_cp		LIKE cxct001.z01_codcli,
				numero		VARCHAR(15),
				dividendo	SMALLINT,
				arean		LIKE cxct020.z20_areaneg,
				cod_tran	LIKE cxct020.z20_cod_tran,
				num_tran	LIKE cxct020.z20_num_tran,
				tipo_comp	LIKE cxct040.z40_tipo_comp,
				num_comp	LIKE cxct040.z40_num_comp
			END RECORD
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_num_rows	INTEGER
DEFINE vm_max_rows	INTEGER
DEFINE tot_valor	DECIMAL(14,2)
DEFINE tot_saldo	DECIMAL(14,2)
DEFINE vm_num_ret	SMALLINT
DEFINE vm_max_ret	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp318.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp318'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
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
OPEN WINDOW w_cxcf318_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf318_1 FROM "../forms/cxcf318_1"
ELSE
	OPEN FORM f_cxcf318_1 FROM "../forms/cxcf318_1c"
END IF
DISPLAY FORM f_cxcf318_1
INITIALIZE rm_par.* TO NULL
LET vm_max_rows      = 20000
LET vm_num_rows      = 0
LET rm_par.modulo    = vg_modulo
CALL fl_lee_modulo(rm_par.modulo) RETURNING r_g50.*
LET rm_par.nom_mod   = r_g50.g50_nombre
LET rm_par.fecha_ini = MDY(MONTH(TODAY), 01, YEAR(TODAY))
LET rm_par.fecha_fin = TODAY
LET rm_par.ind_doc   = 'D'
CALL titulos_columnas()
DISPLAY BY NAME rm_par.*
CALL muestra_contadores_det(0, vm_num_rows)
WHILE TRUE
	LET vm_num_rows = 0
	CALL borrar_detalle()
	CALL lee_parametros() 
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL genera_tabla_trabajo()
	IF vm_num_rows = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		DROP TABLE temp_doc
		CONTINUE WHILE
	END IF
	CALL muestra_datos()
	DROP TABLE temp_doc
END WHILE
CLOSE WINDOW w_cxcf318_1
EXIT PROGRAM

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
FOR i = 1 TO vm_max_rows
	INITIALIZE rm_detalle[i].*, rm_adi[i].* TO NULL
END FOR
CLEAR tot_valor, tot_saldo, cliprov, num_row, max_row

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_p04		RECORD LIKE cxpt004.*
DEFINE cod_mod		LIKE gent050.g50_modulo
DEFINE fec_ini, fec_fin	DATE

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(tipo_doc) THEN
			CASE rm_par.modulo
				WHEN 'CO'
				CALL fl_ayuda_tipo_documento_cobranzas('0')
					RETURNING r_z04.z04_tipo_doc,
						  r_z04.z04_nombre
				IF r_z04.z04_tipo_doc IS NOT NULL THEN
					LET rm_par.tipo_doc = r_z04.z04_tipo_doc
					LET rm_par.nom_doc  = r_z04.z04_nombre
					DISPLAY BY NAME rm_par.*
				END IF 
				WHEN 'TE'
				CALL fl_ayuda_tipo_documento_tesoreria('0')
					RETURNING r_p04.p04_tipo_doc,
						  r_p04.p04_nombre
				IF r_p04.p04_tipo_doc IS NOT NULL THEN
					LET rm_par.tipo_doc = r_p04.p04_tipo_doc
					LET rm_par.nom_doc  = r_p04.p04_nombre
					DISPLAY BY NAME rm_par.*
				END IF 
			END CASE
		END IF
		IF INFIELD(modulo) THEN
			CALL fl_ayuda_modulos()
				RETURNING r_g50.g50_modulo, r_g50.g50_nombre
			IF r_g50.g50_modulo IS NOT NULL THEN
				LET rm_par.modulo  = r_g50.g50_modulo
				LET rm_par.nom_mod = r_g50.g50_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD modulo
		LET cod_mod = rm_par.modulo
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD tipo_doc 
		IF rm_par.tipo_doc IS NOT NULL THEN
			CASE rm_par.modulo
				WHEN 'CO'
					CALL fl_lee_tipo_doc(rm_par.tipo_doc)
						RETURNING r_z04.* 
					IF r_z04.z04_tipo_doc IS NULL THEN
						CALL fl_mostrar_mensaje('Tipo de documento no existe.', 'exclamation')
						NEXT FIELD tipo_doc
					END IF
					IF r_z04.z04_tipo = 'T' THEN
						CALL fl_mostrar_mensaje('Tipo de documento no puede ser una transaccion.', 'exclamation')
						NEXT FIELD tipo_doc
					END IF
					LET rm_par.tipo_doc = r_z04.z04_tipo_doc
					LET rm_par.nom_doc  = r_z04.z04_nombre
					DISPLAY BY NAME rm_par.*
				WHEN 'TE'
					CALL fl_lee_tipo_doc_tesoreria(
								rm_par.tipo_doc)
						RETURNING r_p04.* 
					IF r_p04.p04_tipo_doc IS NULL THEN
						CALL fl_mostrar_mensaje('Tipo de documento no existe.', 'exclamation')
						NEXT FIELD tipo_doc
					END IF
					IF r_p04.p04_tipo = 'T' THEN
						CALL fl_mostrar_mensaje('Tipo de documento no puede ser una transaccion.', 'exclamation')
						NEXT FIELD tipo_doc
					END IF
					LET rm_par.tipo_doc = r_p04.p04_tipo_doc
					LET rm_par.nom_doc  = r_p04.p04_nombre
					DISPLAY BY NAME rm_par.*
			END CASE
		ELSE
			LET rm_par.tipo_doc = NULL
			LET rm_par.nom_doc  = NULL
			CLEAR tipo_doc, nom_doc
		END IF
	AFTER FIELD modulo
		IF rm_par.modulo IS NULL THEN
			LET rm_par.modulo  = cod_mod
			CALL fl_lee_modulo(rm_par.modulo) RETURNING r_g50.*
			LET rm_par.nom_mod = r_g50.g50_nombre
			DISPLAY BY NAME rm_par.modulo, rm_par.nom_mod
		END IF
		IF rm_par.modulo <> 'CO' AND rm_par.modulo <> 'TE' THEN
			CALL fl_mostrar_mensaje('El modulo solo puede ser COBRANZAS o TESORERIA.', 'info')
			LET rm_par.modulo  = 'CO'
			CALL fl_lee_modulo(rm_par.modulo) RETURNING r_g50.*
			LET rm_par.nom_mod = r_g50.g50_nombre
			DISPLAY BY NAME rm_par.modulo, rm_par.nom_mod
		END IF
		CALL fl_lee_modulo(rm_par.modulo) RETURNING r_g50.*
		IF r_g50.g50_modulo IS NULL THEN
			CALL fl_mostrar_mensaje('Modulo no existe.', 'exclamation')
			NEXT FIELD g50_modulo
		END IF
		LET rm_par.nom_mod = r_g50.g50_nombre
		DISPLAY BY NAME rm_par.nom_mod
		CALL etiqueta()
	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NULL THEN
			LET rm_par.fecha_ini = fec_ini
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
		IF rm_par.fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor que la fecha de hoy.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NULL THEN
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
		IF rm_par.fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha final no puede ser mayor que la fecha de hoy.', 'exclamation')
			NEXT FIELD fecha_fin
		END IF
	AFTER INPUT 
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor que la fecha final.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT
IF rm_par.ind_doc IS NULL THEN
	LET rm_par.ind_doc = 'D'
END IF

END FUNCTION



FUNCTION titulos_columnas()

--#DISPLAY 'LC'			TO tit_col1
--#DISPLAY 'TD'			TO tit_col2
--#DISPLAY 'Numero'		TO tit_col3
--#DISPLAY 'Fecha Emi.'		TO tit_col4
--#CALL etiqueta()
--#DISPLAY 'Valor Doc.'		TO tit_col6
--#DISPLAY 'S a l d o'		TO tit_col7

END FUNCTION



FUNCTION etiqueta()

--#IF rm_par.modulo = 'CO' THEN
	--#DISPLAY 'Clientes'	 TO tit_col5
--#ELSE
	--#DISPLAY 'Proveedores' TO tit_col5
--#END IF

END FUNCTION



FUNCTION genera_tabla_trabajo()
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_p04		RECORD LIKE cxpt004.*
DEFINE query		CHAR(5000)
DEFINE expr_tip		VARCHAR(100)

LET expr_tip = NULL
IF rm_par.tipo_doc IS NOT NULL THEN
	CASE rm_par.modulo
		WHEN 'CO'
			CALL fl_lee_tipo_doc(rm_par.tipo_doc) RETURNING r_z04.* 
			IF r_z04.z04_tipo = 'D' THEN
				LET expr_tip = '   AND z20_tipo_doc = "',
						rm_par.tipo_doc, '"'
			END IF
			IF r_z04.z04_tipo = 'F' THEN
				LET expr_tip = '   AND z21_tipo_doc = "',
						rm_par.tipo_doc, '"'
			END IF
		WHEN 'TE'
			CALL fl_lee_tipo_doc_tesoreria(rm_par.tipo_doc)
				RETURNING r_p04.* 
			IF r_p04.p04_tipo = 'D' THEN
				LET expr_tip = '   AND p20_tipo_doc = "',
						rm_par.tipo_doc, '"'
			END IF
			IF r_p04.p04_tipo = 'F' THEN
				LET expr_tip = '   AND p21_tipo_doc = "',
						rm_par.tipo_doc, '"'
			END IF
	END CASE
END IF
LET query = 'SELECT z20_localidad loc, z20_tipo_doc tp, TRIM(z20_num_doc) ||',
		' "-" || LPAD(z20_dividendo, 2, 0) num_doc, z20_fecha_emi ',
		'fec_emi, z01_nomcli cliprov, z20_valor_cap valor, ',
		'z20_saldo_cap saldo, z01_codcli cod_cp, z20_num_doc numero, ',
		'z20_dividendo dividendo, z20_areaneg areaneg, z20_cod_tran ',
		'cod_tran, z20_num_tran num_tran, z41_tipo_comp tipo_comp, ',
		'z41_num_comp num_comp',
		' FROM cxct020, cxct001, OUTER cxct041 ',
		' WHERE z20_compania  = 999 ',
		'   AND z01_codcli    = z20_codcli ',
		'   AND z41_compania  = z20_compania ',
		'   AND z41_localidad = z20_localidad ',
		'   AND z41_codcli    = z20_codcli ',
		'   AND z41_tipo_doc  = z20_tipo_doc ',
		'   AND z41_num_doc   = z20_num_doc ',
		'   AND z41_dividendo = z20_dividendo ',
		' INTO TEMP temp_doc '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
CASE rm_par.modulo
	WHEN 'CO'
		IF rm_par.tipo_doc IS NOT NULL THEN
			CALL fl_lee_tipo_doc(rm_par.tipo_doc) RETURNING r_z04.* 
			IF r_z04.z04_tipo = 'D' THEN
				CALL cargar_tmp_deu('z', expr_tip, 1)
				IF vg_codloc < 6 THEN
					CALL cargar_tmp_deu('z', expr_tip, 0)
				END IF
			END IF
			IF r_z04.z04_tipo = 'F' THEN
				CALL cargar_tmp_fav('z', expr_tip, 1)
				IF vg_codloc < 6 THEN
					CALL cargar_tmp_fav('z', expr_tip, 0)
				END IF
			END IF
			LET rm_par.ind_doc = r_z04.z04_tipo
		ELSE
			CASE rm_par.ind_doc
				WHEN 'D'
					CALL cargar_tmp_deu('z', expr_tip, 1)
					IF vg_codloc < 6 THEN
						CALL cargar_tmp_deu('z', expr_tip, 0)
					END IF
				WHEN 'F'
					CALL cargar_tmp_fav('z', expr_tip, 1)
					IF vg_codloc < 6 THEN
						CALL cargar_tmp_fav('z', expr_tip, 0)
					END IF
				WHEN 'T'
					CALL cargar_tmp_deu('z', expr_tip, 1)
					CALL cargar_tmp_fav('z', expr_tip, 1)
					IF vg_codloc < 6 THEN
						CALL cargar_tmp_deu('z', expr_tip, 0)
						CALL cargar_tmp_fav('z', expr_tip, 0)
					END IF
			END CASE
		END IF
	WHEN 'TE'
		IF rm_par.tipo_doc IS NOT NULL THEN
			CALL fl_lee_tipo_doc_tesoreria(rm_par.tipo_doc)
				RETURNING r_p04.* 
			IF r_p04.p04_tipo = 'D' THEN
				CALL cargar_tmp_deu('p', expr_tip, 1)
			END IF
			IF r_p04.p04_tipo = 'F' THEN
				CALL cargar_tmp_fav('p', expr_tip, 1)
			END IF
			LET rm_par.ind_doc = r_p04.p04_tipo
		ELSE
			CASE rm_par.ind_doc
				WHEN 'D'
					CALL cargar_tmp_deu('p', expr_tip, 1)
				WHEN 'F'
					CALL cargar_tmp_fav('p', expr_tip, 1)
				WHEN 'T'
					CALL cargar_tmp_deu('p', expr_tip, 1)
					CALL cargar_tmp_fav('p', expr_tip, 1)
			END CASE
		END IF
END CASE
SELECT COUNT(*) INTO vm_num_rows FROM temp_doc

END FUNCTION



FUNCTION cargar_tmp_deu(pref, expr_tip, flag)
DEFINE pref		CHAR(1)
DEFINE expr_tip		VARCHAR(100)
DEFINE flag		SMALLINT
DEFINE query		CHAR(5000)

LET query = 'INSERT INTO temp_doc ',
		query_deudor_cob_tes(pref, expr_tip, flag) CLIPPED
PREPARE exec_tmp1 FROM query
EXECUTE exec_tmp1

END FUNCTION



FUNCTION cargar_tmp_fav(pref, expr_tip, flag)
DEFINE pref		CHAR(1)
DEFINE expr_tip		VARCHAR(100)
DEFINE flag		SMALLINT
DEFINE query		CHAR(5000)

LET query = 'INSERT INTO temp_doc ',
		query_a_favor_cob_tes(pref, expr_tip, flag) CLIPPED
PREPARE exec_tmp2 FROM query
EXECUTE exec_tmp2

END FUNCTION



FUNCTION query_deudor_cob_tes(pref, expr_tip, flag)
DEFINE pref		CHAR(1)
DEFINE expr_tip		VARCHAR(100)
DEFINE flag		SMALLINT
DEFINE query		CHAR(1200)
DEFINE campo1		VARCHAR(15)
DEFINE campo2		VARCHAR(15)
DEFINE campo3		VARCHAR(15)
DEFINE campos		VARCHAR(100)
DEFINE tabla1		VARCHAR(10)
DEFINE tabla2, tabla3	VARCHAR(50)
DEFINE expr_tab		VARCHAR(100)
DEFINE expr_cp		VARCHAR(100)
DEFINE expr_joi		VARCHAR(100)

CASE pref
	WHEN 'z'
		LET campo1   = 'z01_nomcli '
		LET campo2   = 'z01_codcli '
		LET campo3   = 'z20_areaneg '
		LET campos   = 'z20_cod_tran cod_t, z20_num_tran num_t, '
		LET tabla1   = 'cxct020'
		LET tabla2   = 'cxct001'
		LET tabla3   = 'cxct041'
		LET expr_cp  = '   AND z01_codcli    = z20_codcli '
		LET expr_joi = '   AND z41_codcli    = z20_codcli '
	WHEN 'p'
		LET campo1   = 'p01_nomprov '
		LET campo2   = 'p01_codprov '
		LET campo3   = '0 '
		LET campos   = '"OC" cod_t, CASE WHEN p20_referencia[1, 9] = ',
				'"RECEPCION" THEN 0 ELSE p20_numero_oc END',
				' num_t, '
		LET tabla1   = 'cxpt020'
		LET tabla2   = 'cxpt001'
		LET tabla3   = 'cxpt041'
		LET expr_cp  = '   AND p01_codprov   = p20_codprov '
		LET expr_joi = '   AND p41_codprov   = p20_codprov '
END CASE
LET expr_tab = ' FROM ', tabla1 CLIPPED, ', '
IF flag = 0 THEN
	LET expr_tab = ' FROM ', retorna_base_loc() CLIPPED, tabla1 CLIPPED,', '
	LET tabla2 = retorna_base_loc() CLIPPED, tabla2
	LET tabla3 = retorna_base_loc() CLIPPED, tabla3
END IF
LET query = 'SELECT ', pref, '20_localidad loc, ', pref, '20_tipo_doc tp, ',
		'TRIM(', pref, '20_num_doc) || "-" || ', pref,
		'20_dividendo num_doc, ', pref, '20_fecha_emi fec_emi, ',
		campo1 CLIPPED,' cliprov, ', pref, '20_valor_cap valor, ',
		pref, '20_saldo_cap saldo, ', campo2 CLIPPED, ' cod_cp, ',
		pref, '20_num_doc numero, ', pref, '20_dividendo dividendo, ',
		campo3 CLIPPED, ' areaneg, ', campos CLIPPED, ' ',
		pref, '41_tipo_comp tipo_comp, ', pref, '41_num_comp num_comp',
		expr_tab CLIPPED, ' ', tabla2 CLIPPED, ', OUTER ',
			tabla3 CLIPPED,
		' WHERE ', pref, '20_compania   = ', vg_codcia,
		expr_tip CLIPPED,
		'   AND ', pref, '20_fecha_emi  BETWEEN "', rm_par.fecha_ini, 
						 '" AND "', rm_par.fecha_fin,
							'"',
		expr_cp CLIPPED,
		'   AND ', pref, '41_compania  = ', pref, '20_compania ',
		'   AND ', pref, '41_localidad = ', pref, '20_localidad ',
		expr_joi CLIPPED,
		'   AND ', pref, '41_tipo_doc  = ', pref, '20_tipo_doc ',
		'   AND ', pref, '41_num_doc   = ', pref, '20_num_doc ',
		'   AND ', pref, '41_dividendo = ', pref, '20_dividendo '
RETURN query CLIPPED

END FUNCTION



FUNCTION query_a_favor_cob_tes(pref, expr_tip, flag)
DEFINE pref		CHAR(1)
DEFINE expr_tip		VARCHAR(100)
DEFINE flag		SMALLINT
DEFINE query		CHAR(1200)
DEFINE campo1		VARCHAR(15)
DEFINE campo2		VARCHAR(15)
DEFINE campo3		VARCHAR(15)
DEFINE campos		VARCHAR(200)
DEFINE tabla1		VARCHAR(10)
DEFINE tabla2, tabla3	VARCHAR(50)
DEFINE expr_tab		VARCHAR(100)
DEFINE expr_cp		VARCHAR(100)
DEFINE expr_joi		VARCHAR(100)

CASE pref
	WHEN 'z'
		LET campo1   = 'z01_nomcli '
		LET campo2   = 'z01_codcli '
		LET campo3   = 'z21_areaneg '
		LET campos   = 'z21_cod_tran cod_t, z21_num_tran num_t, '
		LET tabla1   = 'cxct021'
		LET tabla2   = 'cxct001'
		LET tabla3   = 'cxct040'
		LET expr_cp  = '   AND z01_codcli    = z21_codcli '
		LET expr_joi = '   AND z40_codcli    = z21_codcli '
	WHEN 'p'
		LET campo1   = 'p01_nomprov '
		LET campo2   = 'p01_codprov '
		LET campo3   = '0 '
		LET campos   = 'CASE WHEN p21_referencia[1, 10] = ',
				'"DEVOLUCION" THEN "DC" ELSE "XX" END',
				' cod_t, CASE WHEN p21_referencia[1, 10] = ',
				'"DEVOLUCION" THEN SUBSTRING(p21_referencia ',
					'FROM 29) + 0 ELSE 0 END',
				' num_t, '
		LET tabla1   = 'cxpt021'
		LET tabla2   = 'cxpt001'
		LET tabla3   = 'cxpt040'
		LET expr_cp  = '   AND p01_codprov   = p21_codprov '
		LET expr_joi = '   AND p40_codprov   = p21_codprov '
END CASE
LET expr_tab = ' FROM ', tabla1 CLIPPED, ', '
IF flag = 0 THEN
	LET expr_tab = ' FROM ', retorna_base_loc() CLIPPED, tabla1 CLIPPED,', '
	LET tabla2 = retorna_base_loc() CLIPPED, tabla2
	LET tabla3 = retorna_base_loc() CLIPPED, tabla3
END IF
LET query = 'SELECT ', pref, '21_localidad loc, ', pref, '21_tipo_doc tp, ',
		pref, '21_num_doc || " " num_doc, ',
		pref, '21_fecha_emi fec_emi, ', campo1 CLIPPED,' cliprov, ',
		pref, '21_valor * (-1) valor, ', pref, '21_saldo * (-1) saldo,',
		' ', campo2 CLIPPED, ' cod_cp, ', pref, '21_num_doc numero, ',
		'0 dividendo, ', campo3 CLIPPED, ' areaneg, ', campos CLIPPED,
		' ', pref, '40_tipo_comp tipo_comp, ', pref,
		'40_num_comp num_comp',
		expr_tab CLIPPED, ' ', tabla2 CLIPPED, ', OUTER ',
			tabla3 CLIPPED,
		' WHERE ', pref, '21_compania   = ', vg_codcia,
		expr_tip CLIPPED,
		'   AND ', pref, '21_fecha_emi  BETWEEN "', rm_par.fecha_ini, 
						 '" AND "', rm_par.fecha_fin,
							'"',
		expr_cp CLIPPED,
		'   AND ', pref, '40_compania  = ', pref, '21_compania ',
		'   AND ', pref, '40_localidad = ', pref, '21_localidad ',
		expr_joi CLIPPED,
		'   AND ', pref, '40_tipo_doc  = ', pref, '21_tipo_doc ',
		'   AND ', pref, '40_num_doc   = ', pref, '21_num_doc '
RETURN query CLIPPED

END FUNCTION



FUNCTION muestra_datos()
DEFINE query		CHAR(300)
DEFINE col, num_row	INTEGER
DEFINE cuantos		INTEGER
DEFINE pos_arr, i	SMALLINT
DEFINE tipo_comp	LIKE ctbt013.b13_tipo_comp
DEFINE num_comp		LIKE ctbt013.b13_num_comp

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 4
LET vm_columna_2 = 3
WHILE TRUE
	LET query = 'SELECT * FROM temp_doc ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE cons_temp FROM query
	DECLARE q_tmp CURSOR FOR cons_temp
	LET num_row   = 1
	LET tot_valor = 0
	LET tot_saldo = 0
	FOREACH q_tmp INTO rm_detalle[num_row].*, rm_adi[num_row].*
		LET tot_valor = tot_valor + rm_detalle[num_row].valor_doc
		LET tot_saldo = tot_saldo + rm_detalle[num_row].saldo_doc
		LET num_row   = num_row + 1
		IF num_row > vm_max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_rows = num_row - 1
	DISPLAY BY NAME tot_valor, tot_saldo
	LET int_flag = 0
	CALL set_count(vm_num_rows)
	DISPLAY ARRAY rm_detalle TO rm_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET pos_arr = arr_curr()
			CALL mostrar_comp_contable(pos_arr)
				   RETURNING tipo_comp, num_comp, cuantos
			IF tipo_comp IS NOT NULL AND cuantos = 1 THEN
				CALL contabilizacion(tipo_comp, num_comp)
			END IF
			LET int_flag = 0
		ON KEY(F6)
			LET pos_arr = arr_curr()
			IF (rm_detalle[pos_arr].tip_doc <> 'PA' AND
			    rm_detalle[pos_arr].tip_doc <> 'PR') OR
			    rm_par.modulo = 'TE'
			THEN
				CONTINUE DISPLAY
			END IF
			CALL fl_muestra_forma_pago_caja(vg_codcia,
						rm_detalle[pos_arr].localidad,
						rm_adi[pos_arr].arean,
						rm_adi[pos_arr].cod_cp,
						rm_detalle[pos_arr].tip_doc,
						rm_detalle[pos_arr].num_doc)
			LET int_flag = 0
		ON KEY(F7)
			LET pos_arr = arr_curr()
			IF rm_par.modulo = 'CO' THEN
			CALL muestra_movimientos_documento_cxc(vg_codcia,
						rm_detalle[pos_arr].localidad,
						rm_adi[pos_arr].cod_cp,
						rm_detalle[pos_arr].tip_doc,
						rm_adi[pos_arr].numero,
						rm_adi[pos_arr].dividendo,
						rm_adi[pos_arr].arean, pos_arr)
			ELSE
			CALL muestra_movimientos_documento_cxp(vg_codcia,
						rm_adi[pos_arr].cod_cp,
						rm_detalle[pos_arr].tip_doc,
						rm_adi[pos_arr].numero,
						rm_adi[pos_arr].dividendo,
						pos_arr)
			END IF
			LET int_flag = 0
		ON KEY(F8)
			LET pos_arr = arr_curr()
			CALL ver_documento(pos_arr)
			LET int_flag = 0
		ON KEY(F9)
			LET pos_arr = arr_curr()
			IF (rm_detalle[pos_arr].tip_doc = 'PA'  OR
			    rm_detalle[pos_arr].tip_doc = 'PR') OR
			    rm_adi[pos_arr].cod_tran IS NULL
			THEN
				CONTINUE DISPLAY
			END IF
			CALL ver_transaccion(pos_arr)
			LET int_flag = 0
		ON KEY(F10)
			LET pos_arr = arr_curr()
			IF (rm_detalle[pos_arr].tip_doc <> 'ND' AND
			    rm_detalle[pos_arr].tip_doc <> 'DO' AND
			    rm_detalle[pos_arr].tip_doc <> 'NC') OR
			    rm_par.modulo = 'TE'
			THEN
				CONTINUE DISPLAY
			END IF
			CALL imprimir_comprobante(pos_arr)
			LET int_flag = 0
		ON KEY(F11)
			CALL control_imprimir()
			LET int_flag = 0
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET col      = 7
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
		--#BEFORE ROW
			--#LET pos_arr = arr_curr()
			--#CALL muestra_contadores_det(pos_arr, vm_num_rows)
			--#DISPLAY rm_detalle[pos_arr].nomcli TO cliprov
			--#IF (rm_detalle[pos_arr].tip_doc <> 'PA' AND
				--#rm_detalle[pos_arr].tip_doc <> 'PR') OR
			    --#rm_par.modulo = 'TE'
			--#THEN
				--#CALL dialog.keysetlabel("F6", "")
			--#ELSE
				--#CALL dialog.keysetlabel("F6", "Pago Caja")
			--#END IF
			--#IF (rm_detalle[pos_arr].tip_doc = 'PA'  OR
			    --#rm_detalle[pos_arr].tip_doc = 'PR') OR
			    --#rm_adi[pos_arr].cod_tran IS NULL
			--#THEN
				--#CALL dialog.keysetlabel("F9", "")
			--#ELSE
				--#CALL dialog.keysetlabel("F9", "Transaccion")
			--#END IF
			--#IF (rm_detalle[pos_arr].tip_doc <> 'ND' AND
			    --#rm_detalle[pos_arr].tip_doc <> 'DO' AND
			    --#rm_detalle[pos_arr].tip_doc <> 'NC') OR
			    --#rm_par.modulo = 'TE'
			--#THEN
				--#CALL dialog.keysetlabel("F10", "")
			--#ELSE
				--#CALL dialog.keysetlabel("F10", "Imprimir Compr.")
			--#END IF
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



FUNCTION mostrar_comp_contable(j)
DEFINE j		SMALLINT
DEFINE r_det		ARRAY[50] OF RECORD
				tipo_comp	LIKE rept040.r40_tipo_comp,
				num_comp	LIKE rept040.r40_num_comp,
				fecha		LIKE ctbt012.b12_fec_proceso,
				subtipo		LIKE ctbt004.b04_nombre
			END RECORD
DEFINE query		CHAR(1000)
DEFINE expr_tran	VARCHAR(100)
DEFINE i, l, max_rows	SMALLINT

IF rm_adi[j].tipo_comp IS NOT NULL THEN
	RETURN rm_adi[j].tipo_comp, rm_adi[j].num_comp, 1
END IF
LET max_rows = 50
LET query    = NULL
CASE rm_par.modulo
	WHEN 'CO'
		IF rm_adi[j].arean = 1 AND rm_adi[j].cod_tran IS NOT NULL THEN
			LET query = 'SELECT r40_tipo_comp, r40_num_comp, ',
					'b12_fec_proceso, b04_nombre ',
					'FROM rept040, ctbt012, OUTER ctbt004 ',
					'WHERE r40_compania  = ', vg_codcia,
					'  AND r40_localidad = ',
							rm_detalle[j].localidad,
					'  AND r40_cod_tran  = "',
							rm_adi[j].cod_tran, '"',
					'  AND r40_num_tran  = ',
							rm_adi[j].num_tran,
					'  AND b12_compania  = r40_compania ',
					'  AND b12_tipo_comp = r40_tipo_comp ',
					'  AND b12_num_comp  = r40_num_comp ',
					'  AND b04_compania  = b12_compania ',
					'  AND b04_subtipo   = b12_subtipo '
		END IF
		IF rm_adi[j].arean = 2 THEN
			LET query = 'SELECT t50_tipo_comp, t50_num_comp, ',
					'b12_fec_proceso, b04_nombre ',
					'FROM talt050, ctbt012, OUTER ctbt004 ',
					'WHERE t50_compania  = ', vg_codcia,
					'  AND t50_localidad = ',
							rm_detalle[j].localidad,
					'  AND t50_factura   = ',
							rm_adi[j].num_tran,
					'  AND b12_compania  = t50_compania ',
					'  AND b12_tipo_comp = t50_tipo_comp ',
					'  AND b12_num_comp  = t50_num_comp ',
					'  AND b04_compania  = b12_compania ',
					'  AND b04_subtipo   = b12_subtipo  '
		END IF
	WHEN 'TE'
		IF rm_adi[j].cod_tran <> 'XX' AND rm_adi[j].num_tran <> 0 THEN
			LET expr_tran = '  AND r19_cod_tran   = "',
							rm_adi[j].cod_tran, '"',
					'  AND r19_num_tran   = ',
							rm_adi[j].num_tran
			IF rm_adi[j].cod_tran = 'OC' THEN
				LET expr_tran = '  AND r19_oc_interna = ',
							rm_adi[j].num_tran
			END IF
			LET query = 'SELECT r40_tipo_comp, r40_num_comp, ',
					'b12_fec_proceso, b04_nombre ',
					'FROM rept019, rept040, ctbt012, ',
						'OUTER ctbt004 ',
					'WHERE r19_compania   = ', vg_codcia,
					'  AND r19_localidad  = ',
							rm_detalle[j].localidad,
					expr_tran CLIPPED,
					'  AND r40_compania   = r19_compania ',
					'  AND r40_localidad  = r19_localidad ',
					'  AND r40_cod_tran   = r19_cod_tran ',
					'  AND r40_num_tran   = r19_num_tran ',
					'  AND b12_compania   = r40_compania ',
					'  AND b12_tipo_comp  = r40_tipo_comp ',
					'  AND b12_num_comp   = r40_num_comp ',
					'  AND b04_compania   = b12_compania ',
					'  AND b04_subtipo    = b12_subtipo '
		END IF
		IF rm_adi[j].cod_tran = 'OC' AND rm_adi[j].num_tran = 0 THEN
			LET query = 'SELECT c40_tipo_comp, c40_num_comp, ',
					'b12_fec_proceso, b04_nombre ',
					'FROM ordt013, ordt040, ctbt012, ',
						'OUTER ctbt004 ',
					'WHERE c13_compania   = ', vg_codcia,
					'  AND c13_localidad  = ',
							rm_detalle[j].localidad,
					'  AND c13_num_guia   = "',
							rm_adi[j].numero, '" ',
					'  AND c40_compania   = c13_compania ',
					'  AND c40_localidad  = c13_localidad ',
					'  AND c40_numero_oc  = c13_numero_oc ',
					'  AND b12_compania   = c40_compania ',
					'  AND b12_tipo_comp  = c40_tipo_comp ',
					'  AND b12_num_comp   = c40_num_comp ',
					'  AND b04_compania   = b12_compania ',
					'  AND b04_subtipo    = b12_subtipo '
		END IF
END CASE
IF query IS NULL THEN
	INITIALIZE r_det[1].* TO NULL
	RETURN r_det[1].tipo_comp, r_det[1].num_comp, 0
END IF
PREPARE cons_cursor1 FROM query
DECLARE q_cursor1 CURSOR FOR cons_cursor1
LET i = 1
FOREACH q_cursor1 INTO r_det[i].*
	LET i = i + 1
	IF i > max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	INITIALIZE r_det[1].* TO NULL
	RETURN r_det[1].tipo_comp, r_det[1].num_comp, 0
END IF
IF i = 1 THEN
	RETURN r_det[i].tipo_comp, r_det[i].num_comp, i
END IF
LET l = i
OPEN WINDOW w_talf309_2 AT 10, 11 WITH 09 ROWS, 60 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
IF vg_gui = 1 THEN
	OPEN FORM f_talf309_2 FROM '../../TALLER/forms/talf309_2'
ELSE
	OPEN FORM f_talf309_2 FROM '../../TALLER/forms/talf309_2c'
END IF
DISPLAY FORM f_talf309_2
--#DISPLAY 'Comprobante' TO bt_tipo_comp
--#DISPLAY 'Fecha'       TO bt_fecha    
--#DISPLAY 'Subtipo'     TO bt_subtipo  
CALL set_count(i)
DISPLAY ARRAY r_det TO r_det.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F5)
		LET i = arr_curr()
		CALL contabilizacion(r_det[i].tipo_comp, r_det[i].num_comp)	
		LET int_flag = 0
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
	--#BEFORE ROW
		--#LET i = arr_curr()
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY
LET i = arr_curr()
CLOSE WINDOW w_talf309_2
RETURN r_det[i].tipo_comp, r_det[i].num_comp, l

END FUNCTION



FUNCTION contabilizacion(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt013.b13_tipo_comp
DEFINE num_comp		LIKE ctbt013.b13_num_comp
DEFINE comando		VARCHAR(200)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
		vg_separador, 'fuentes', vg_separador, '; fglrun ctbp201 ',
		vg_base, ' "CB" ', vg_codcia, ' ', tipo_comp, ' ', num_comp
RUN comando

END FUNCTION



FUNCTION muestra_movimientos_documento_cxc(codcia, codloc, codcli, tipo_doc,
					num_doc, dividendo, areaneg, pos)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE tipo_doc		LIKE cxct020.z20_tipo_doc
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE dividendo	LIKE cxct020.z20_dividendo
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE pos		SMALLINT
DEFINE r_cli		RECORD LIKE cxct001.*
DEFINE max_rows, i, col	SMALLINT
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_pago		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE expr_sql		VARCHAR(400)
DEFINE r_aux		ARRAY[100] OF RECORD
				loc		LIKE gent002.g02_localidad,
				tipo		LIKE cxct023.z23_tipo_favor
			END RECORD
DEFINE r_pdoc		ARRAY[100] OF RECORD
				z23_tipo_trn	LIKE cxct023.z23_tipo_trn,
				z23_num_trn	LIKE cxct023.z23_num_trn,
				z22_fecha_emi	LIKE cxct022.z22_fecha_emi,
				z22_referencia	LIKE cxct022.z22_referencia,
				val_pago	DECIMAL(14,2)
			END RECORD
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE expr_loc		VARCHAR(50)
DEFINE expr_fec		VARCHAR(100)
DEFINE fecha1, fecha2	LIKE cxct022.z22_fecing

LET max_rows  = 100
LET num_rows2 = 16
LET num_cols  = 76
IF vg_gui = 0 THEN
	LET num_rows2 = 15
	LET num_cols  = 77
END IF
OPEN WINDOW w_mdoc AT 06, 03 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF dividendo > 0 THEN
	OPEN FORM f_movdoc FROM "../forms/cxcf314_5"
ELSE
	OPEN FORM f_movdoc FROM "../forms/cxcf314_6"
END IF
DISPLAY FORM f_movdoc
--#DISPLAY 'TP'                  TO tit_col1 
--#DISPLAY 'Número'              TO tit_col2 
--#DISPLAY 'Fecha Pago'          TO tit_col3
--#DISPLAY 'R e f e r e n c i a' TO tit_col4 
--#DISPLAY 'V a l o r'           TO tit_col5
CALL fl_lee_cliente_general(codcli) RETURNING r_cli.*
IF r_cli.z01_codcli IS NULL THEN
	CALL fl_mostrar_mensaje('No existe cliente: ' || codcli, 'exclamation')
	CLOSE WINDOW w_mdoc
	RETURN
END IF
DISPLAY BY NAME r_cli.z01_codcli, r_cli.z01_nomcli
IF dividendo <> 0 THEN
	CLEAR z23_tipo_doc, z23_num_doc, z23_div_doc
	DISPLAY tipo_doc, num_doc, dividendo
	     TO z23_tipo_doc, z23_num_doc, z23_div_doc
ELSE
	CLEAR z23_tipo_favor, z23_doc_favor
	DISPLAY tipo_doc, num_doc TO z23_tipo_favor, z23_doc_favor
END IF
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'DESC'
LET columna_1  = 3
LET columna_2  = 1
LET expr_loc   = ' '
IF codloc IS NOT NULL THEN
	LET expr_loc = '   AND z23_localidad = ', codloc
END IF
LET fecha2   = EXTEND(TODAY, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET fecha1   = EXTEND(rm_detalle[pos].fecha, YEAR TO SECOND)
LET expr_fec = '   AND z22_fecing    BETWEEN "', fecha1,
				      '" AND "', fecha2, '"'
LET expr_sql = '   AND z23_tipo_doc   = ? ',
		'   AND z23_num_doc    = ? ',
		'   AND z23_div_doc    = ? '
IF dividendo = 0 THEN
	LET expr_sql = '   AND z23_tipo_favor = ? ',
			'   AND z23_doc_favor  = ? '
END IF
WHILE TRUE
	LET query = 'SELECT z23_tipo_trn, z23_num_trn, z22_fecha_emi, ',
			'   z22_referencia, z23_valor_cap + z23_valor_int, ',
			'   z23_localidad, z23_tipo_favor ',
	        	' FROM cxct023, cxct022 ',
			' WHERE z23_compania   = ? ', 
			expr_loc CLIPPED,
		        '   AND z23_codcli     = ? ',
			expr_sql CLIPPED,
			'   AND z22_compania   = z23_compania ',
			'   AND z22_localidad  = z23_localidad ',
			'   AND z22_codcli     = z23_codcli ',
			'   AND z22_tipo_trn   = z23_tipo_trn  ',
			'   AND z22_num_trn    = z23_num_trn ',
			expr_fec CLIPPED,
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE dpgc FROM query
	DECLARE q_dpgc CURSOR FOR dpgc
	LET i        = 1
	LET tot_pago = 0
	IF dividendo <> 0 THEN
		OPEN q_dpgc USING codcia, codcli, tipo_doc, num_doc, dividendo
	ELSE
		OPEN q_dpgc USING codcia, codcli, tipo_doc, num_doc
	END IF
	WHILE TRUE
		FETCH q_dpgc INTO r_pdoc[i].*, r_aux[i].*
		IF STATUS = NOTFOUND THEN
			EXIT WHILE
		END IF
		LET tot_pago = tot_pago + r_pdoc[i].val_pago 
		LET i = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dpgc
	FREE q_dpgc
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fl_mostrar_mensaje('Documento no tiene movimientos.','exclamation')
		CLOSE WINDOW w_mdoc
		RETURN
	END IF
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY BY NAME tot_pago
	DISPLAY ARRAY r_pdoc TO r_pdoc.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL fl_muestra_forma_pago_caja(codcia, r_aux[i].loc,
							areaneg, codcli,
							r_pdoc[i].z23_tipo_trn,
							r_pdoc[i].z23_num_trn) 
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_documento_tran(codcia, codcli,
				r_pdoc[i].z23_tipo_trn, r_pdoc[i].z23_num_trn,
				r_aux[i].*)
			LET int_flag = 0
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_contadores_det(i, num_rows)
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> columna_1 THEN
		LET columna_2          = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1          = col 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_mdoc

END FUNCTION



FUNCTION muestra_movimientos_documento_cxp(codcia, codprov, tipo_doc, num_doc,
						dividendo, pos)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE tipo_doc		LIKE cxpt020.p20_tipo_doc
DEFINE num_doc		LIKE cxpt020.p20_num_doc
DEFINE dividendo	LIKE cxpt020.p20_dividendo
DEFINE pos		SMALLINT
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE max_rows, i, col	SMALLINT
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_pago		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE expr_sql		VARCHAR(400)
DEFINE r_aux		ARRAY[100] OF RECORD
				tipo		LIKE cxpt023.p23_tipo_favor
			END RECORD
DEFINE r_pdoc		ARRAY[100] OF RECORD
				p23_tipo_trn	LIKE cxpt023.p23_tipo_trn,
				p23_num_trn	LIKE cxpt023.p23_num_trn,
				p22_fecha_emi	LIKE cxpt022.p22_fecha_emi,
				p22_referencia	LIKE cxpt022.p22_referencia,
				val_pago	DECIMAL(14,2)
			END RECORD
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE expr_fec		VARCHAR(100)
DEFINE fecha1, fecha2	LIKE cxpt022.p22_fecing

LET max_rows  = 100
LET num_rows2 = 16
LET num_cols  = 76
IF vg_gui = 0 THEN
	LET num_rows2 = 15
	LET num_cols  = 77
END IF
OPEN WINDOW w_mdoc AT 06, 03 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF dividendo > 0 THEN
	OPEN FORM f_movdoc FROM "../../TESORERIA/forms/cxpf314_5"
ELSE
	OPEN FORM f_movdoc FROM "../../TESORERIA/forms/cxpf314_6"
END IF
DISPLAY FORM f_movdoc
--#DISPLAY 'TP'                  TO tit_col1 
--#DISPLAY 'Número'              TO tit_col2 
--#DISPLAY 'Fecha Pago'          TO tit_col3
--#DISPLAY 'R e f e r e n c i a' TO tit_col4 
--#DISPLAY 'V a l o r'           TO tit_col5
CALL fl_lee_proveedor(codprov) RETURNING r_prov.*
IF r_prov.p01_codprov IS NULL THEN
	CALL fl_mostrar_mensaje('No existe proveedor: ' || codprov, 'exclamation')
	CLOSE WINDOW w_mdoc
	RETURN
END IF
DISPLAY BY NAME r_prov.p01_codprov, r_prov.p01_nomprov
IF dividendo <> 0 THEN
	CLEAR p23_tipo_doc, p23_num_doc, p23_div_doc
	DISPLAY tipo_doc, num_doc, dividendo
	     TO p23_tipo_doc, p23_num_doc, p23_div_doc
ELSE
	CLEAR p23_tipo_favor, p23_doc_favor
	DISPLAY tipo_doc, num_doc TO p23_tipo_favor, p23_doc_favor
END IF
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'DESC'
LET columna_1  = 3
LET columna_2  = 1
LET fecha2   = EXTEND(TODAY, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET fecha1   = EXTEND(rm_detalle[pos].fecha, YEAR TO SECOND)
LET expr_fec = '   AND p22_fecing    BETWEEN "', fecha1,
					      '" AND "', fecha2, '"'
LET expr_sql = '   AND p23_tipo_doc   = ? ',
		'   AND p23_num_doc    = ? ',
		'   AND p23_div_doc    = ? '
IF dividendo = 0 THEN
	LET expr_sql = '   AND p23_tipo_favor = ? ',
			'   AND p23_doc_favor  = ? '
END IF
WHILE TRUE
	LET query = 'SELECT p23_tipo_trn, p23_num_trn, p22_fecha_emi, ',
			'   p22_referencia, p23_valor_cap + p23_valor_int, ',
			'   p23_tipo_favor ',
	        	' FROM cxpt023, cxpt022 ',
			' WHERE p23_compania   = ? ', 
			'   AND p23_localidad  = ', vg_codloc,
		        '   AND p23_codprov    = ? ',
			expr_sql CLIPPED,
			'   AND p22_compania   = p23_compania ',
			'   AND p22_localidad  = p23_localidad ',
			'   AND p22_codprov    = p23_codprov ',
			'   AND p22_tipo_trn   = p23_tipo_trn  ',
			'   AND p22_num_trn    = p23_num_trn ',
			expr_fec CLIPPED,
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE dpgc2 FROM query
	DECLARE q_dpgc2 CURSOR FOR dpgc2
	LET i        = 1
	LET tot_pago = 0
	IF dividendo <> 0 THEN
		OPEN q_dpgc2 USING codcia, codprov, tipo_doc, num_doc, dividendo
	ELSE
		OPEN q_dpgc2 USING codcia, codprov, tipo_doc, num_doc
	END IF
	WHILE TRUE
		FETCH q_dpgc2 INTO r_pdoc[i].*, r_aux[i].*
		IF STATUS = NOTFOUND THEN
			EXIT WHILE
		END IF
		LET tot_pago = tot_pago + r_pdoc[i].val_pago 
		LET i = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dpgc2
	FREE q_dpgc2
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fl_mostrar_mensaje('Documento no tiene movimientos.','exclamation')
		CLOSE WINDOW w_mdoc
		RETURN
	END IF
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY BY NAME tot_pago
	DISPLAY ARRAY r_pdoc TO r_pdoc.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL muestra_cheque_emitido(codcia, codprov,
							r_pdoc[i].p23_tipo_trn,
							r_pdoc[i].p23_num_trn) 
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_documento_tran(codcia, codprov,
				r_pdoc[i].p23_tipo_trn, r_pdoc[i].p23_num_trn,
				vg_codloc, r_aux[i].tipo)
			LET int_flag = 0
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_contadores_det(i, num_rows)
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> columna_1 THEN
		LET columna_2          = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1          = col 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_mdoc

END FUNCTION



FUNCTION ver_documento(i)
DEFINE i		INTEGER
DEFINE prog		VARCHAR(10)
DEFINE expr		VARCHAR(40)
DEFINE comando          VARCHAR(200)

LET prog = 'cxcp200 '
IF rm_par.modulo = 'TE' THEN
	LET prog = 'cxpp200 '
END IF
LET expr = rm_adi[i].dividendo, ' ', rm_detalle[i].fecha
IF rm_detalle[i].valor_doc < 0 THEN
	LET prog = 'cxcp201 '
	IF rm_par.modulo = 'TE' THEN
		LET prog = 'cxpp201 '
	END IF
	LET expr = ' ', rm_detalle[i].fecha
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, rm_par.nom_mod CLIPPED,
		vg_separador, 'fuentes', vg_separador, '; fglrun ',
		prog CLIPPED, ' ', vg_base, ' ', rm_par.modulo, ' ', vg_codcia,
		' ', rm_detalle[i].localidad, ' ', rm_adi[i].cod_cp, ' ',
		rm_detalle[i].tip_doc, ' ', rm_adi[i].numero, ' ', expr CLIPPED
RUN comando

END FUNCTION



FUNCTION ver_transaccion(i)
DEFINE i		INTEGER
DEFINE r_t28		RECORD LIKE talt028.*
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE estado		LIKE ordt013.c13_estado
DEFINE prog		VARCHAR(10)
DEFINE expr		VARCHAR(40)
DEFINE comando          VARCHAR(200)

IF (rm_adi[i].arean = 0 OR rm_adi[i].arean = 1) AND
   (rm_adi[i].cod_tran <> 'XX') AND
   (rm_detalle[i].tip_doc = 'FA' OR rm_detalle[i].tip_doc = 'NC')
THEN
	LET cod_tran = rm_adi[i].cod_tran
	LET num_tran = rm_adi[i].num_tran
	IF rm_adi[i].arean = 0 AND rm_detalle[i].tip_doc = 'FA' THEN
		DECLARE q_cl CURSOR FOR
			SELECT r19_cod_tran, r19_num_tran
				FROM rept019
				WHERE r19_compania   = vg_codcia
				  AND r19_localidad  = rm_detalle[i].localidad
				  AND r19_oc_interna = rm_adi[i].num_tran
		OPEN q_cl
		FETCH q_cl INTO cod_tran, num_tran
		CLOSE q_cl
		FREE q_cl
	END IF
	CALL fl_ver_transaccion_rep(vg_codcia, rm_detalle[i].localidad,
					cod_tran, num_tran)
END IF
IF rm_adi[i].cod_tran = 'OC' AND
  (rm_adi[i].num_tran = 0 OR rm_adi[i].num_tran IS NULL)
THEN
	DECLARE q_rec CURSOR FOR
		SELECT c13_numero_oc, c13_estado
			FROM ordt013
			WHERE c13_compania  = vg_codcia
			  AND c13_localidad = rm_detalle[i].localidad
			  AND c13_num_guia  = rm_adi[i].numero
	OPEN q_rec
	FETCH q_rec INTO num_tran, estado
	CLOSE q_rec
	FREE q_rec
	LET prog = 'ordp202'
	IF estado = 'E' THEN
		LET prog = 'ordp204'
	END IF
	LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS',
			vg_separador, 'fuentes; ', 'fglrun ', prog CLIPPED, ' ',
			vg_base, ' OC ', vg_codcia, ' ',rm_detalle[i].localidad,
			' ', num_tran
	RUN comando
END IF
IF rm_adi[i].arean = 2 THEN
	LET prog = 'talp308 '
	LET expr = rm_adi[i].num_tran
	IF rm_detalle[i].tip_doc = 'NC' THEN
		SELECT * INTO r_t28.*
			FROM talt028
			WHERE t28_compania  = vg_codcia
			  AND t28_localidad = rm_detalle[i].localidad
			  AND t28_factura   = rm_adi[i].num_tran
		LET prog = 'talp211 '
		LET expr = r_t28.t28_num_dev
	END IF
	LET comando = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
			vg_separador, 'fuentes; ', 'fglrun ', prog CLIPPED, ' ',
			vg_base, ' TA ', vg_codcia, ' ',rm_detalle[i].localidad,
			' ', expr CLIPPED
	RUN comando
END IF
IF rm_adi[i].cod_tran IS NOT NULL AND rm_detalle[i].tip_doc = 'DI' THEN
	--CALL control_retenciones(i)
END IF

END FUNCTION



FUNCTION imprimir_comprobante(i)
DEFINE i		SMALLINT
DEFINE comando          VARCHAR(200)

IF (rm_detalle[i].tip_doc = 'ND' OR rm_detalle[i].tip_doc = 'DO') THEN
	LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
			vg_separador, 'fuentes', vg_separador, '; fglrun ',
			'cxcp415 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,' ',
			rm_detalle[i].localidad, ' ', rm_adi[i].cod_cp,
			' "', rm_detalle[i].tip_doc, '" ', rm_adi[i].numero,
			' ', rm_adi[i].dividendo
END IF
IF rm_detalle[i].tip_doc = 'NC' THEN
	LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
			vg_separador, 'fuentes', vg_separador, '; fglrun ',
			'cxcp414 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,' ',
			rm_detalle[i].localidad, ' ', rm_adi[i].cod_cp,
			' "', rm_detalle[i].tip_doc, '" ', rm_adi[i].numero
END IF
RUN comando

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT imprimir_listado TO PIPE comando
FOR i = 1 TO vm_num_rows
	OUTPUT TO REPORT imprimir_listado(i)
END FOR
FINISH REPORT imprimir_listado

END FUNCTION



REPORT imprimir_listado(i)
DEFINE i, j		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(32)
DEFINE usuario		VARCHAR(19)
DEFINE escape		SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_dob1		SMALLINT
DEFINE act_dob2		SMALLINT
DEFINE des_dob		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	96
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	CALL fl_justifica_titulo('C', "LISTADO DOCUMENTOS COB./TES.", 39)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 012, ASCII escape, ASCII act_dob1, ASCII act_dob2,
	      COLUMN 016, titulo CLIPPED,
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_12cpi
	SKIP 1 LINES
	CALL fl_justifica_titulo('D', 'USUARIO: ' || vg_usuario, 19)
		RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	PRINT COLUMN 001, r_g01.g01_razonsocial CLIPPED,
	      COLUMN 089, 'PAG. ', PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 090, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	IF rm_par.tipo_doc IS NOT NULL THEN
		PRINT COLUMN 028, '** DOCUMENTO    : ',
			rm_par.tipo_doc, ' ',
			rm_par.nom_doc CLIPPED
	END IF
	PRINT COLUMN 028, '** MODULO       : ', rm_par.modulo CLIPPED, ' ',
			rm_par.nom_mod CLIPPED
	PRINT COLUMN 028, '** TIPO         : ', rm_par.ind_doc, ' ',
		retorna_ind_doc(rm_par.ind_doc) CLIPPED
	PRINT COLUMN 028, '** PERIODO      : ',
			rm_par.fecha_ini USING "dd-mm-yyyy", '  -  ',
			rm_par.fecha_fin USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, 'FECHA IMPRESION  : ', DATE(TODAY) USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 078, usuario
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------'
	PRINT COLUMN 001, 'LC',
	      COLUMN 004, 'TD',
	      COLUMN 007, 'NUMERO DOCUMENTO',
	      COLUMN 026, 'FECHA EMI.';
	IF rm_par.modulo = 'CO' THEN
		PRINT COLUMN 046, 'C L I E N T E S';
	ELSE
		PRINT COLUMN 043, 'P R O V E E D O R E S';
	END IF
	PRINT COLUMN 072, '  VALOR DOC.',
	      COLUMN 085, '  SALDO DOC.'
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------'

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_detalle[i].localidad	USING "&&",
	      COLUMN 004, rm_detalle[i].tip_doc,
	      COLUMN 007, rm_detalle[i].num_doc		CLIPPED,
	      COLUMN 026, rm_detalle[i].fecha		USING "dd-mm-yyyy",
	      COLUMN 037, rm_detalle[i].nomcli[1, 34]	CLIPPED,
	      COLUMN 072, rm_detalle[i].valor_doc	USING "-,---,--&.##",
	      COLUMN 085, rm_detalle[i].saldo_doc	USING "-,---,--&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 072, '------------',
	      COLUMN 085, '------------'
	PRINT COLUMN 059, 'TOTALES ==>',
	      COLUMN 072, SUM(rm_detalle[i].valor_doc) USING "-,---,--&.##",
	      COLUMN 085, SUM(rm_detalle[i].saldo_doc) USING "-,---,--&.##";
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION retorna_ind_doc(ind_doc)
DEFINE ind_doc		CHAR(1)
DEFINE nom_cr		VARCHAR(15)

CASE ind_doc
	WHEN 'D' LET nom_cr = 'DEUDOR'
	WHEN 'F' LET nom_cr = 'A FAVOR'
	WHEN 'T' LET nom_cr = 'T O D O S'
END CASE
RETURN nom_cr

END FUNCTION



FUNCTION ver_documento_tran(codcia, codcli, tipo_trn, num_trn, loc, tipo)
DEFINE codcia		LIKE cxct022.z22_compania
DEFINE codcli		LIKE cxct022.z22_codcli
DEFINE tipo_trn		LIKE cxct022.z22_tipo_trn
DEFINE num_trn		LIKE cxct022.z22_num_trn
DEFINE loc		LIKE cxct022.z22_localidad
DEFINE tipo		LIKE cxct023.z23_tipo_favor
DEFINE comando		VARCHAR(200)
DEFINE prog		CHAR(10)

LET prog = 'cxcp202 '
IF rm_par.modulo = 'TE' THEN
	LET prog = 'cxpp202 '
END IF
IF tipo IS NOT NULL THEN
	LET prog = 'cxcp203 '
	IF rm_par.modulo = 'TE' THEN
		LET prog = 'cxpp203 '
	END IF
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, rm_par.nom_mod CLIPPED,
		vg_separador, 'fuentes', vg_separador, '; fglrun ', prog,
		vg_base, ' ', rm_par.modulo, ' ', codcia, ' ', loc, ' ', codcli,
		' ', tipo_trn, ' ', num_trn
RUN comando

END FUNCTION



FUNCTION muestra_cheque_emitido(codcia, codprov, tipo_trn, num_trn)
DEFINE codcia		LIKE cxpt024.p24_compania
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE tipo_trn		LIKE cxpt022.p22_tipo_trn
DEFINE num_trn		LIKE cxpt022.p22_num_trn
DEFINE r_p24		RECORD LIKE cxpt024.*
DEFINE r_ban		RECORD LIKE gent008.*
DEFINE r_td		RECORD LIKE cxpt004.*
DEFINE r_fav		RECORD LIKE cxpt021.*
DEFINE r_trn		RECORD LIKE cxpt022.*
DEFINE orden_pago	INTEGER

CALL fl_lee_tipo_doc_tesoreria(tipo_trn) RETURNING r_td.*
IF r_td.p04_tipo IS NULL THEN
	RETURN
END IF
LET orden_pago = NULL
IF r_td.p04_tipo = 'F' THEN
	CALL fl_lee_documento_favor_cxp(codcia, vg_codloc, codprov, tipo_trn, 
					num_trn)
		RETURNING r_fav.*
	LET orden_pago = r_fav.p21_orden_pago
ELSE
	CALL fl_lee_transaccion_cxp(codcia, vg_codloc, codprov, tipo_trn, 
					num_trn)
		RETURNING r_trn.*
	LET orden_pago = r_trn.p22_orden_pago
END IF
CALL fl_lee_orden_pago_cxp(codcia, vg_codloc, orden_pago) RETURNING r_p24.*
IF r_p24.p24_orden_pago IS NULL THEN
	RETURN
END IF
OPEN WINDOW w_pch AT 07, 18 WITH 08 ROWS, 49 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER, MENU LINE 0)
OPEN FORM f_cxpf315_6 FROM "../../TESORERIA/forms/cxpf315_6"
DISPLAY FORM f_cxpf315_6
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro en órdenes de pago.','exclamation')
	CLOSE WINDOW w_pch
	RETURN
END IF
CALL fl_lee_banco_general(r_p24.p24_banco) RETURNING r_ban.*
DISPLAY r_ban.g08_nombre TO banco
DISPLAY BY NAME r_p24.p24_numero_cta, r_p24.p24_numero_che,
		r_p24.p24_tip_contable, r_p24.p24_num_contable
LET int_flag = 0
MENU 'OPCIONES'
	COMMAND KEY('C') 'Diario Contable' 
		CALL contabilizacion(r_p24.p24_tip_contable,
					 r_p24.p24_num_contable)
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU
LET int_flag = 0
CLOSE WINDOW w_pch

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



{-- OJO: FALTA DE IMPLEMENTAR
FUNCTION control_retenciones(i)
DEFINE i		SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE j10_tipo_destino	LIKE cajt010.j10_tipo_destino
DEFINE j10_num_destino	LIKE cajt010.j10_num_destino
DEFINE row_ini, col_ini	SMALLINT
DEFINE row_fin, col_fin	SMALLINT
DEFINE valor_bruto	DECIMAL(14,2)
DEFINE valor_impto	DECIMAL(14,2)
DEFINE subtotal		DECIMAL(14,2)
DEFINE flete		DECIMAL(14,2)
DEFINE valor_fact	DECIMAL(14,2)

LET row_ini = 04
LET row_fin = 20
LET col_ini = 02
LET col_fin = 78
IF vg_gui = 0 THEN
	LET row_ini = 05
	LET row_fin = 18
	LET col_ini = 03
	LET col_fin = 77
END IF
OPEN WINDOW w_cxcf211_2 AT row_ini, col_ini WITH row_fin ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf211_2 FROM '../forms/cxcf211_2'
ELSE
	OPEN FORM f_cxcf211_2 FROM '../forms/cxcf211_2c'
END IF
DISPLAY FORM f_cxcf211_2
LET vm_num_ret = 0
LET vm_max_ret = 50
CALL borrar_retenciones()
--#DISPLAY 'TP'		 TO tit_col1
--#DISPLAY 'T'		 TO tit_col2
--#DISPLAY '%'		 TO tit_col3
--#DISPLAY 'Cod. SRI' 	 TO tit_col4
--#DISPLAY 'Descripcion' TO tit_col5
--#DISPLAY 'Base Imp.'	 TO tit_col6
--#DISPLAY 'Valor Ret.'	 TO tit_col7
DISPLAY rm_detalle[i].j14_num_fact_sri TO num_sri
LET j10_tipo_destino = rm_adi[i].cod_tran
LET j10_num_destino  = rm_adi[i].num_tran
CASE rm_adi[i].j10_areaneg
	WHEN 1
		CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
				rm_detalle[i].j14_localidad,
				rm_adi[i].j14_cod_tran, rm_adi[i].j14_num_tran)
			RETURNING r_r19.*
		IF r_r19.r19_compania IS NULL THEN
			CALL lee_cabecera_transaccion_loc(vg_codcia,
						rm_detalle[i].j14_localidad,
						rm_adi[i].j14_cod_tran,
						rm_adi[i].j14_num_tran)
				RETURNING r_r19.*
		END IF
		LET valor_bruto = r_r19.r19_tot_bruto - r_r19.r19_tot_dscto
		LET valor_impto = r_r19.r19_tot_neto  - r_r19.r19_tot_bruto +
					r_r19.r19_tot_dscto - r_r19.r19_flete
		LET subtotal    = valor_bruto + valor_impto
		LET flete       = r_r19.r19_flete
		LET valor_fact  = subtotal + flete
	WHEN 2
		CALL fl_lee_factura_taller(vg_codcia,
						rm_detalle[i].j14_localidad,
						rm_adi[i].j14_num_tran)
			RETURNING r_t23.*
		LET valor_bruto = r_t23.t23_tot_bruto - r_t23.t23_tot_dscto
		LET valor_impto = r_t23.t23_val_impto
		LET subtotal    = valor_bruto + valor_impto
		LET flete       = NULL
		LET valor_fact  = subtotal
END CASE
DISPLAY rm_adi[i].j10_codcli     TO j10_codcli
DISPLAY rm_detalle[i].z01_nomcli TO j10_nomcli
DISPLAY BY NAME valor_bruto, valor_impto, subtotal, flete, valor_fact,
		j10_tipo_destino, j10_num_destino
CALL consulta_retenciones(i)
LET int_flag = 0
CLOSE WINDOW w_cxcf211_2
RETURN

END FUNCTION



FUNCTION borrar_retenciones()
DEFINE i		SMALLINT

INITIALIZE rm_j14.* TO NULL
FOR i = 1 TO fgl_scr_size('rm_detret')
	CLEAR rm_detret[i].*
END FOR
FOR i = 1 TO vm_max_ret
	INITIALIZE rm_detret[i].* TO NULL
END FOR
CLEAR j14_num_ret_sri, j14_autorizacion, j14_fecha_emi, num_row, max_row,
	tot_base_imp, tot_valor_ret, j10_codcli, j10_nomcli, valor_bruto,
	valor_impto, subtotal, flete, --j10_tipo_fuente, j10_num_fuente,
	j10_tipo_destino, j10_num_destino, num_sri, concepto_ret

END FUNCTION



FUNCTION consulta_retenciones(posi)
DEFINE posi		SMALLINT
DEFINE sec		LIKE cajt014.j14_sec_ret
DEFINE num_sri		LIKE rept038.r38_num_sri
DEFINE query		CHAR(2000)
DEFINE i, j		SMALLINT

LET query = 'SELECT j14_num_ret_sri, j14_autorizacion, j14_fecha_emi, ',
			'r38_num_sri, j14_codigo_pago, j14_tipo_ret, ',
			'j14_porc_ret, j14_codigo_sri, c03_concepto_ret, ',
			'j14_base_imp, j14_valor_ret, j14_sec_ret ',
		' FROM cajt014, ', retorna_base_loc() CLIPPED, 'rept038, ',
			'ordt003 ',
		' WHERE j14_compania    = ', vg_codcia,
		'   AND j14_localidad   = ', rm_detalle[posi].j14_localidad,
		'   AND j14_tipo_fuente = "', rm_adi[posi].j14_tipo_fuente, '"',
		'   AND j14_num_fuente  = ', rm_adi[posi].j14_num_fuente,
		'   AND j14_num_ret_sri = "', rm_detalle[posi].j14_num_ret_sri,
					 '"',
		'   AND j14_cod_tran    = "', rm_adi[posi].j14_cod_tran, '"',
		'   AND j14_num_tran    = ', rm_adi[posi].j14_num_tran,
		'   AND r38_compania    = j14_compania ',
		'   AND r38_localidad   = j14_localidad ',
		'   AND r38_tipo_doc    = j14_tipo_doc ',
		'   AND r38_tipo_fuente = j14_tipo_fue ',
		'   AND r38_cod_tran    = j14_cod_tran ',
		'   AND r38_num_tran    = j14_num_tran ',
		'   AND c03_compania    = j14_compania ',
		'   AND c03_tipo_ret    = j14_tipo_ret ',
		'   AND c03_porcentaje  = j14_porc_ret ',
		'   AND c03_codigo_sri  = j14_codigo_sri ',
		' ORDER BY j14_sec_ret '
PREPARE cons_ret3 FROM query
DECLARE q_ret3 CURSOR FOR cons_ret3
LET vm_num_ret = 1
FOREACH q_ret3 INTO rm_j14.j14_num_ret_sri, rm_j14.j14_autorizacion,
		rm_j14.j14_fecha_emi, num_sri, rm_detret[vm_num_ret].*, sec
	LET vm_num_ret = vm_num_ret + 1
	IF vm_num_ret > vm_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_ret = vm_num_ret - 1
IF vm_num_ret = 0 THEN
	RETURN
END IF
DISPLAY BY NAME rm_j14.j14_num_ret_sri, rm_j14.j14_autorizacion,
		rm_j14.j14_fecha_emi, num_sri
CALL calcular_tot_retencion(vm_num_ret)
CALL muestra_contadores_det(1, vm_num_ret)
CALL set_count(vm_num_ret)
DISPLAY ARRAY rm_detret TO rm_detret.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(RETURN)
		LET i = arr_curr()
        	LET j = scr_line()
		CALL muestra_contadores_det(i, vm_num_ret)
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel('RETURN','')
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(i, vm_num_ret)
		--#DISPLAY rm_detret[i].c03_concepto_ret TO concepto_ret
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
CALL muestra_contadores_det(0, vm_num_ret)

END FUNCTION



FUNCTION calcular_tot_retencion(lim)
DEFINE i, lim		SMALLINT

LET tot_base_imp  = 0
LET tot_valor_ret = 0
FOR i = 1 TO lim
	LET tot_base_imp  = tot_base_imp  + rm_detret[i].j14_base_imp
	LET tot_valor_ret = tot_valor_ret + rm_detret[i].j14_valor_ret
END FOR
DISPLAY BY NAME tot_base_imp, tot_valor_ret

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION lee_cabecera_transaccion_loc(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept019.r19_compania
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE query		CHAR(400)

INITIALIZE r_r19.* TO NULL
IF NOT (codloc = 2 OR codloc = 4) THEN
	RETURN r_r19.*
END IF
LET query = 'SELECT * FROM ', retorna_base_loc() CLIPPED, 'rept019 ',
		' WHERE r19_compania  = ', codcia,
		'   AND r19_localidad = ', codloc,
		'   AND r19_cod_tran  = "', cod_tran, '"',
		'   AND r19_num_tran  = ', num_tran
PREPARE cons_f_loc FROM query
DECLARE q_cons_f_loc CURSOR FOR cons_f_loc
OPEN q_cons_f_loc
FETCH q_cons_f_loc INTO r_r19.*
CLOSE q_cons_f_loc
FREE q_cons_f_loc
RETURN r_r19.*

END FUNCTION



FUNCTION lee_cabecera_preventa_loc(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept023.r23_compania
DEFINE codloc		LIKE rept023.r23_localidad
DEFINE cod_tran		LIKE rept023.r23_cod_tran
DEFINE num_tran		LIKE rept023.r23_num_tran
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE query		CHAR(400)

INITIALIZE r_r23.* TO NULL
IF NOT (codloc = 2 OR codloc = 4) THEN
	SELECT * INTO r_r23.*
		FROM rept023
		WHERE r23_compania  = codcia
		  AND r23_localidad = codloc
		  AND r23_cod_tran  = cod_tran
		  AND r23_num_tran  = num_tran
	RETURN r_r23.*
END IF
LET query = 'SELECT * FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
		' WHERE r23_compania  = ', codcia,
		'   AND r23_localidad = ', codloc,
		'   AND r23_cod_tran  = "', cod_tran, '"',
		'   AND r23_num_tran  = ', num_tran
PREPARE cons_p_loc FROM query
DECLARE q_cons_p_loc CURSOR FOR cons_p_loc
OPEN q_cons_p_loc
FETCH q_cons_p_loc INTO r_r23.*
CLOSE q_cons_p_loc
FREE q_cons_p_loc
RETURN r_r23.*

END FUNCTION



FUNCTION retorna_ret_fac(i)
DEFINE i		SMALLINT
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE cod_tr		LIKE cajt010.j10_tipo_destino
DEFINE num_tr		LIKE cajt010.j10_num_destino

CASE rm_adi[i].j10_areaneg
	WHEN 1 LET tipo_f = 'PR'
	WHEN 2 LET tipo_f = 'OT'
END CASE
LET cod_tr = rm_adi[i].j14_cod_tran
LET num_tr = rm_adi[i].j14_num_tran
RETURN tipo_f, cod_tr, num_tr

END FUNCTION



FUNCTION retorna_num_fue(i)
DEFINE i		SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE num_f		LIKE cajt010.j10_num_fuente

CASE rm_adi[i].j10_areaneg
	WHEN 1
		CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
				rm_detalle[i].j14_localidad,
				rm_adi[i].j14_cod_tran, rm_adi[i].j14_num_tran)
			RETURNING r_r19.*
		IF r_r19.r19_compania IS NULL THEN
			CALL lee_cabecera_transaccion_loc(vg_codcia,
						rm_detalle[i].j14_localidad,
						rm_adi[i].j14_cod_tran,
						rm_adi[i].j14_num_tran)
				RETURNING r_r19.*
		END IF
		CALL lee_cabecera_preventa_loc(r_r19.r19_compania,
						r_r19.r19_localidad,
						r_r19.r19_cod_tran,
						r_r19.r19_num_tran)
			RETURNING r_r23.*
		LET num_f = r_r23.r23_numprev
	WHEN 2
		CALL fl_lee_factura_taller(vg_codcia,
					rm_detalle[i].j14_localidad,
					rm_adi[i].j14_num_tran)
			RETURNING r_t23.*
		LET num_f = r_t23.t23_orden
END CASE
RETURN num_f

END FUNCTION
--}



FUNCTION retorna_base_loc()
DEFINE base_loc		VARCHAR(10)

LET base_loc = NULL
IF (vg_codloc = 2 OR vg_codloc = 4) OR (vg_codloc = 6 OR vg_codloc = 7) THEN
	RETURN base_loc CLIPPED
END IF
SELECT g56_base_datos INTO base_loc
	FROM gent056
	WHERE g56_compania  = vg_codcia
	  AND g56_localidad IN (2, 4)
IF base_loc IS NOT NULL THEN
	LET base_loc = base_loc CLIPPED, ':'
END IF
RETURN base_loc CLIPPED

END FUNCTION
