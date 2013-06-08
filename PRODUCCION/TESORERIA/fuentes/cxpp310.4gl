--------------------------------------------------------------------------------
-- Titulo           : cxpp310.4gl - Cons. Análisis Cartera Prov. (por fecha)
-- Elaboracion      : 25-Abr-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxpp310 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE rm_z60		RECORD LIKE cxct060.*
DEFINE num_doc		INTEGER
DEFINE num_fav		INTEGER
DEFINE num_prov		INTEGER
DEFINE num_max_prov	INTEGER
DEFINE rm_par 		RECORD
				moneda          LIKE gent013.g13_moneda,
				tit_mon         LIKE gent013.g13_nombre,
				tipprov		LIKE gent012.g12_subtipo,
				tit_tipprov	LIKE gent012.g12_nombre,
				ind_venc        CHAR(1),
				fecha_cart	DATE,
				ind_doc		CHAR(1)
			END RECORD
DEFINE rm_prov		ARRAY[32766] OF RECORD
				codprov		LIKE cxpt001.p01_codprov,
				nomprov		LIKE cxpt001.p01_nomprov,
				tot_pven 	DECIMAL(12,2),
				tot_venc 	DECIMAL(12,2),
				tot_saldo 	DECIMAL(12,2)
			END RECORD
DEFINE tot_1		DECIMAL(14,2)
DEFINE tot_2		DECIMAL(14,2)
DEFINE tot_3		DECIMAL(14,2)
DEFINE vm_fecha_ini	DATE
DEFINE vm_imprimir	CHAR(1)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp310.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 9 THEN	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxpp310'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*

CALL fl_nivel_isolation()
CALL fl_lee_fecha_carga_cxc(vg_codcia, vg_codloc) RETURNING rm_z60.*
IF rm_z60.z60_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe una fecha de carga para este módulo.', 'stop')
	EXIT PROGRAM
END IF
CREATE TEMP TABLE tempo_doc 
	(codprov	INTEGER,
	 nomprov	VARCHAR(100),
	 por_vencer	DECIMAL(12,2),
	 vencido	DECIMAL(12,2))
OPEN WINDOW w_imp AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_par FROM "../forms/cxpf310_1"
DISPLAY FORM f_par
LET num_max_prov = 32766
INITIALIZE rm_par.*, vm_fecha_ini TO NULL
CALL fl_lee_configuracion_facturacion() RETURNING r.*
LET rm_par.moneda = r.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
LET rm_par.tit_mon    = rm_mon.g13_nombre
LET rm_par.ind_venc   = 'T'
LET rm_par.fecha_cart = TODAY
LET rm_par.ind_doc    = 'D'
LET vm_fecha_ini      = rm_z60.z60_fecha_carga
LET vm_imprimir       = 'R'
CALL mostrar_botones()
IF num_args() >= 5 THEN
	CALL llamada_de_otro_programa()
END IF
CALL control_consulta()

END FUNCTION



FUNCTION llamada_de_otro_programa()
DEFINE r_g12		RECORD LIKE gent012.*

LET rm_par.moneda      = arg_val(5)
LET rm_par.ind_venc    = arg_val(6)
LET rm_par.fecha_cart  = arg_val(7)
LET rm_par.tipprov     = arg_val(8)
LET rm_par.ind_doc     = arg_val(9)
IF rm_par.tipprov = 0 THEN
	LET rm_par.tipprov = NULL
END IF
IF rm_par.tipprov IS NOT NULL THEN
	CALL fl_lee_subtipo_entidad('TP', rm_par.tipprov) RETURNING r_g12.*
	IF r_g12.g12_tiporeg IS NULL THEN
		CALL fl_mostrar_mensaje('No existe tipo de proveedor.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_par.tit_tipprov = r_g12.g12_nombre 
END IF
DISPLAY BY NAME rm_par.*

END FUNCTION



FUNCTION control_consulta()
DEFINE i		SMALLINT

WHILE TRUE
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET rm_orden[5]  = 'DESC'
	LET vm_columna_1 = 5
	LET vm_columna_2 = 1
	IF num_args() = 4 THEN
		CALL lee_parametros() 
		IF int_flag THEN
			RETURN
		END IF
	END IF
	CALL genera_tabla_trabajo_detalle()
	IF num_doc = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		DROP TABLE tmp_mov
		IF num_args() >= 5 THEN
			EXIT WHILE
		END IF
		CONTINUE WHILE
	END IF
	CALL genera_tabla_trabajo_resumen()
	IF num_prov = 0 THEN
		DROP TABLE tmp_mov
		IF num_args() >= 5 THEN
			EXIT WHILE
		END IF
		CONTINUE WHILE
	END IF
	CALL muestra_resumen_proveedores()
	DELETE FROM tempo_doc
	DROP TABLE tmp_mov
	IF num_args() >= 5 THEN
		EXIT WHILE
	END IF
END WHILE
DROP TABLE tempo_doc

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_mo		RECORD LIKE gent013.*
DEFINE r_se		RECORD LIKE gent012.*
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_mon		LIKE gent013.g13_nombre
DEFINE tiporeg		LIKE gent012.g12_tiporeg
DEFINE subtipo		LIKE gent012.g12_subtipo
DEFINE nomtipo		LIKE gent012.g12_nombre
DEFINE nombre		LIKE gent011.g11_nombre
DEFINE fec		DATE
DEFINE num		SMALLINT

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		CLOSE FORM f_par
		RETURN
	ON KEY(F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux, tit_mon, num
			IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda  = mon_aux
				LET rm_par.tit_mon = tit_mon
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
		IF INFIELD(tipprov) THEN
			CALL fl_ayuda_subtipo_entidad('TP') 
				RETURNING tiporeg, subtipo, nomtipo, nombre
			IF nomtipo IS NOT NULL THEN
				LET rm_par.tipprov     = subtipo
				LET rm_par.tit_tipprov = nomtipo
				DISPLAY BY NAME rm_par.tipprov,
						rm_par.tit_tipprov
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD fecha_cart
		LET fec = rm_par.fecha_cart
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda)
				RETURNING r_mo.*
			IF r_mo.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe moneda', 'exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.tit_mon = r_mo.g13_nombre 
			DISPLAY BY NAME rm_par.tit_mon
		ELSE
			LET rm_par.tit_mon = NULL
			DISPLAY BY NAME rm_par.tit_mon
		END IF
	AFTER FIELD tipprov
		IF rm_par.tipprov IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('TP', rm_par.tipprov)
				RETURNING r_se.*
			IF r_se.g12_tiporeg IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe tipo proveedor', 'exclamation')
				NEXT FIELD tipprov
			END IF
			LET rm_par.tit_tipprov = r_se.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipprov
		ELSE
			LET rm_par.tit_tipprov = NULL
			DISPLAY BY NAME rm_par.tit_tipprov
		END IF
	AFTER FIELD fecha_cart
		IF rm_par.fecha_cart IS NULL THEN
			LET rm_par.fecha_cart = fec
			DISPLAY BY NAME rm_par.fecha_cart
		END IF
END INPUT

END FUNCTION



FUNCTION genera_tabla_trabajo_detalle()
DEFINE fecha		LIKE cxpt022.p22_fecing
DEFINE query		CHAR(6000)
DEFINE subquery1	CHAR(3000)
DEFINE subquery2	CHAR(500)
DEFINE join_p22p23	CHAR(500)
DEFINE expr1		VARCHAR(100)

ERROR "Procesando documentos con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
INITIALIZE expr1 TO NULL
IF rm_par.tipprov IS NOT NULL THEN
	LET expr1 = '   AND p01_tipo_prov  = ', rm_par.tipprov
END IF
LET fecha = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET query = 'SELECT cxpt020.* ',
		' FROM cxpt020 ',
		' WHERE p20_compania   = ', vg_codcia,
		'   AND p20_localidad  = ', vg_codloc,
		'   AND p20_moneda     = "', rm_par.moneda, '"',
		'   AND p20_fecha_emi <= "', rm_par.fecha_cart, '"',
		' INTO TEMP tmp_p20 '
PREPARE cons_p20 FROM query
EXECUTE cons_p20
LET join_p22p23 = ' FROM cxpt023, cxpt022 ',
			' WHERE p23_compania  = p20_compania ',
			'   AND p23_localidad = p20_localidad ',
			'   AND p23_codprov   = p20_codprov ',
			'   AND p23_tipo_doc  = p20_tipo_doc ',
			'   AND p23_num_doc   = p20_num_doc ',
			'   AND p23_div_doc   = p20_dividendo ',
			'   AND p22_compania  = p23_compania ',
			'   AND p22_localidad = p23_localidad ',
			'   AND p22_codprov   = p23_codprov ',
			'   AND p22_tipo_trn  = p23_tipo_trn ',
			'   AND p22_num_trn   = p23_num_trn '
LET subquery1 = '(SELECT p23_valor_cap + p23_valor_int + p23_saldo_cap + ',
			'p23_saldo_int ',
		' FROM cxpt023, cxpt022 ',
		' WHERE p23_compania  = p20_compania ',
		'   AND p23_localidad = p20_localidad ',
		'   AND p23_codprov   = p20_codprov ',
		'   AND p23_tipo_doc  = p20_tipo_doc ',
		'   AND p23_num_doc   = p20_num_doc ',
		'   AND p23_div_doc   = p20_dividendo ',
		'   AND p23_orden     = (SELECT MAX(p23_orden) ',
					join_p22p23 CLIPPED,
					'   AND p22_fecing    = ',
					'(SELECT MAX(p22_fecing) ',
					join_p22p23 CLIPPED,
					'   AND p22_fecing   <= "', fecha,'"))',
		'   AND p22_compania  = p23_compania ',
		'   AND p22_localidad = p23_localidad ',
		'   AND p22_codprov   = p23_codprov ',
		'   AND p22_tipo_trn  = p23_tipo_trn ',
		'   AND p22_num_trn   = p23_num_trn ',
		'   AND p22_fecing    = (SELECT MAX(p22_fecing) ',
					join_p22p23 CLIPPED,
					'   AND p22_fecing   <= "', fecha, '"))'
LET subquery2 = ' (SELECT NVL(SUM(p23_valor_cap + p23_valor_int), 0) ',
		' FROM cxpt023 ',
		' WHERE p23_compania  = p20_compania ',
		'   AND p23_localidad = p20_localidad ',
		'   AND p23_codprov   = p20_codprov ',
		'   AND p23_tipo_doc  = p20_tipo_doc ',
		'   AND p23_num_doc   = p20_num_doc ',
		'   AND p23_div_doc   = p20_dividendo) '
LET query = ' SELECT p20_localidad, p20_codprov, p20_tipo_doc, ',
			'p20_num_doc, p20_dividendo, p01_nomprov, ',
			'p20_fecha_emi, p20_fecha_vcto, ',
			'(p20_valor_cap + p20_valor_int) valor_doc,',
			' NVL(', subquery1 CLIPPED, ', ',
			' CASE WHEN p20_fecha_emi <= "', vm_fecha_ini, '"',
				' THEN p20_saldo_cap + p20_saldo_int - ',
					subquery2 CLIPPED,
				' ELSE p20_valor_cap + p20_valor_int',
			' END) valor_mov ',
		' FROM tmp_p20, cxpt001 ',
		' WHERE p01_codprov    = p20_codprov ',
			expr1 CLIPPED,
		' INTO TEMP tmp_mov '
PREPARE stmnt1 FROM query
EXECUTE stmnt1
DROP TABLE tmp_p20
DELETE FROM tmp_mov WHERE valor_mov = 0
SELECT COUNT(*) INTO num_doc FROM tmp_mov 
ERROR ' '
LET num_fav = 0
IF num_doc > 0 AND rm_par.ind_doc = 'T' THEN
	CALL obtener_documentos_a_favor()
END IF

END FUNCTION



FUNCTION obtener_documentos_a_favor()
DEFINE fecha		LIKE cxpt022.p22_fecing
DEFINE query		CHAR(6000)
DEFINE subquery1	CHAR(1000)
DEFINE subquery2	CHAR(400)
DEFINE expr1, expr2	VARCHAR(100)

ERROR "Procesando documentos a favor con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
INITIALIZE expr1 TO NULL
IF rm_par.tipprov IS NOT NULL THEN
	LET expr1 = '   AND p01_tipo_prov  = ', rm_par.tipprov
END IF
LET query = 'SELECT cxpt021.* ',
		' FROM cxpt021 ',
		' WHERE p21_compania   = ', vg_codcia,
		'   AND p21_localidad  = ', vg_codloc,
		'   AND p21_moneda     = "', rm_par.moneda, '"',
		'   AND p21_fecha_emi <= "', rm_par.fecha_cart, '"',
		' INTO TEMP tmp_p21 '
PREPARE cons_p21 FROM query
EXECUTE cons_p21
LET fecha = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET subquery1 = '(SELECT SUM(p23_valor_cap + p23_valor_int) ',
		' FROM cxpt023, cxpt022 ',
		' WHERE p23_compania   = p21_compania ',
		'   AND p23_localidad  = p21_localidad ',
		'   AND p23_codprov    = p21_codprov ',
		'   AND p23_tipo_favor = p21_tipo_doc ',
		'   AND p23_doc_favor  = p21_num_doc ',
		'   AND p22_compania   = p23_compania ',
		'   AND p22_localidad  = p23_localidad ',
		'   AND p22_codprov    = p23_codprov ',
		'   AND p22_tipo_trn   = p23_tipo_trn ',
		'   AND p22_num_trn    = p23_num_trn ',
		'   AND p22_fecing     BETWEEN EXTEND(p21_fecha_emi, ',
						'YEAR TO SECOND)',
					 ' AND "', fecha, '")'
LET subquery2 = '(SELECT NVL(SUM(p23_valor_cap + p23_valor_int), 0) ',
		' FROM cxpt023 ',
		' WHERE p23_compania   = p21_compania ',
		'   AND p23_localidad  = p21_localidad ',
		'   AND p23_codprov    = p21_codprov ',
		'   AND p23_tipo_favor = p21_tipo_doc ',
		'   AND p23_doc_favor  = p21_num_doc) '
LET query = 'SELECT p21_localidad, p21_codprov, p21_tipo_doc, p21_num_doc,',
			' p01_nomprov, p21_fecha_emi, ',
			' NVL(CASE WHEN p21_fecha_emi > "', vm_fecha_ini, '"',
				' THEN p21_valor + ', subquery1 CLIPPED,
				' ELSE ', subquery2 CLIPPED, ' + p21_saldo - ',
					  subquery1 CLIPPED,
			' END, ',
			' CASE WHEN p21_fecha_emi <= "', vm_fecha_ini, '"',
				' THEN p21_saldo - ', subquery2 CLIPPED,
				' ELSE p21_valor',
			' END) * (-1) saldo_mov ',
		' FROM tmp_p21, cxpt001 ',
		' WHERE p01_codprov    = p21_codprov ',
			expr1 CLIPPED,
		' INTO TEMP tmp_fav '
PREPARE stmnt2 FROM query
EXECUTE stmnt2
DROP TABLE tmp_p21
DELETE FROM tmp_fav WHERE saldo_mov = 0
SELECT COUNT(*) INTO num_fav FROM tmp_fav
ERROR ' '
IF num_fav = 0 THEN
	DROP TABLE tmp_fav
	RETURN
END IF
SELECT p21_codprov, p01_nomprov, NVL(SUM(saldo_mov), 0) saldo_fav
	FROM tmp_fav
	GROUP BY 1, 2
	INTO TEMP tmp_sal_fav
DROP TABLE tmp_fav

END FUNCTION



FUNCTION genera_tabla_trabajo_resumen()
DEFINE query		CHAR(1200)
DEFINE subquery		CHAR(800)

ERROR "Generando resumen . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT p20_codprov prov1, valor_mov sald1 ',
		' FROM tmp_mov ',
		' WHERE p20_fecha_vcto >= "', rm_par.fecha_cart, '"',
		'   AND valor_mov       > 0 ',
		' INTO TEMP t1 '
PREPARE cons_t1_a FROM query
EXECUTE	cons_t1_a
LET query = 'SELECT p20_codprov prov2, valor_mov sald2 ',
		' FROM tmp_mov ',
		' WHERE p20_fecha_vcto < "', rm_par.fecha_cart, '"',
		'   AND valor_mov      > 0 ',
		' INTO TEMP t2 '
PREPARE cons_t2_a FROM query
EXECUTE	cons_t2_a
CASE rm_par.ind_venc
	WHEN 'P'
		LET subquery = '(SELECT NVL(SUM(sald1), 0) ',
				' FROM t1 ',
				' WHERE prov1 = p20_codprov), 0 '
	WHEN 'V'
		LET subquery = '0, (SELECT NVL(SUM(sald2), 0) ',
				' FROM t2 ',
				' WHERE prov2 = p20_codprov) '
	WHEN 'T'
		LET subquery = '(SELECT NVL(SUM(sald1), 0) ',
				' FROM t1 ',
				' WHERE prov1 = p20_codprov), ',
				'(SELECT NVL(SUM(sald2), 0) ',
				' FROM t2 ',
				' WHERE prov2 = p20_codprov) '
END CASE
LET query = 'INSERT INTO tempo_doc ',
		' SELECT p20_codprov, p01_nomprov, ',
			subquery CLIPPED,
			' FROM tmp_mov ',
			' GROUP BY 1, 2'
PREPARE cons_mov FROM query
EXECUTE cons_mov
DELETE FROM tempo_doc WHERE por_vencer = 0 AND vencido = 0
SELECT COUNT(*) INTO num_prov FROM tempo_doc
ERROR " "
IF num_prov = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
END IF
DROP TABLE t1
DROP TABLE t2

END FUNCTION



FUNCTION muestra_resumen_proveedores()
DEFINE orden		CHAR(40)
DEFINE query		CHAR(800)
DEFINE i, col		INTEGER

CALL mostrar_botones()
IF num_fav > 0 AND rm_par.ind_doc = 'T' THEN
	SELECT codprov, nomprov, NVL(SUM(por_vencer + vencido), 0) saldo_deu,
		NVL(SUM(por_vencer + vencido), 0) saldo_fav
		FROM tempo_doc
		GROUP BY 1, 2
		INTO TEMP tmp_sal_deu
	UPDATE tmp_sal_deu SET saldo_fav = 0
	INSERT INTO tmp_sal_deu
		SELECT p21_codprov, p01_nomprov, 0.00,
			NVL(SUM(saldo_fav), 0) saldo_fav
			FROM tmp_sal_fav
			GROUP BY 1, 2, 3
	SELECT codprov, nomprov, NVL(SUM(saldo_deu), 0) saldo_deu,
		NVL(SUM(saldo_fav), 0) saldo_fav
		FROM tmp_sal_deu
		GROUP BY 1, 2
		INTO TEMP tmp_prov_car
	DROP TABLE tmp_sal_deu
	DROP TABLE tmp_sal_fav
END IF
WHILE TRUE
	LET query = "SELECT codprov, nomprov, SUM(por_vencer),",
			" SUM(vencido), SUM(por_vencer + vencido) ",
			" FROM tempo_doc ",
			" GROUP BY 1, 2 "
	IF num_fav > 0 AND rm_par.ind_doc = 'T' THEN
		LET query = "SELECT codprov, nomprov, saldo_deu, ",
				"NVL(saldo_fav, 0), saldo_deu + ",
				"NVL(saldo_fav, 0) ",
			" FROM tmp_prov_car "
	END IF
	LET query = query CLIPPED,
			" ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
			        ", ", vm_columna_2, " ", rm_orden[vm_columna_2]
	PREPARE cons FROM query
	DECLARE q_cons CURSOR FOR cons
	LET i     = 1
	LET tot_1 = 0
	LET tot_2 = 0
	LET tot_3 = 0
	FOREACH q_cons INTO rm_prov[i].*
		LET tot_1 = tot_1 + rm_prov[i].tot_pven
		LET tot_2 = tot_2 + rm_prov[i].tot_venc
		LET tot_3 = tot_3 + rm_prov[i].tot_saldo
		LET i     = i + 1
		IF i > num_max_prov THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET num_prov = i - 1
	CALL set_count(num_prov)
	DISPLAY BY NAME tot_1, tot_2, tot_3
	LET int_flag = 0
	DISPLAY ARRAY rm_prov TO rm_prov.*
		BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY 
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			DISPLAY i        TO num_row
			DISPLAY num_prov TO max_row
		ON KEY(F5)
			LET i = arr_curr()
			CALL muestra_documentos(i)
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL muestra_estado_cuenta(i)
			LET int_flag = 0
		ON KEY(F7)
			CALL control_imprimir()
			LET int_flag = 0
		{--
		ON KEY(F8)
			CALL control_importar_archivo()
			LET int_flag = 0
		--}
		ON KEY(INTERRUPT)
			EXIT DISPLAY
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
IF num_fav > 0 AND rm_par.ind_doc = 'T' THEN
	DROP TABLE tmp_prov_car
END IF

END FUNCTION



FUNCTION mostrar_botones()

DISPLAY 'Código'		TO tit_col1
DISPLAY 'P r o v e e d o r'	TO tit_col2
DISPLAY 'Por Vencer'		TO tit_col3
DISPLAY 'Valor Vencido'		TO tit_col4
DISPLAY 'Val. a Pagar'		TO tit_col5
CASE rm_par.ind_venc
	WHEN 'P'
		DISPLAY '' TO tit_col4
	WHEN 'V'
		DISPLAY '' TO tit_col3
END CASE
IF num_fav > 0 AND rm_par.ind_doc = 'T' THEN
	DISPLAY 'Total Deudor'	TO tit_col3
	CASE rm_par.ind_venc
		WHEN 'P'
			DISPLAY 'Por Vencer'	TO tit_col3
		WHEN 'V'
			DISPLAY 'Total Vencido'	TO tit_col3
	END CASE
	DISPLAY 'Total A Favor'	TO tit_col4
	DISPLAY 'Cartera Total'	TO tit_col5
END IF

END FUNCTION



FUNCTION muestra_documentos(i)
DEFINE i		INTEGER
DEFINE comando		VARCHAR(150)

LET comando = 'fglrun cxpp315 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		vg_codloc, ' ', rm_par.moneda, ' ', rm_par.ind_venc, ' ',
		rm_par.ind_doc, ' "N" ', rm_par.fecha_cart, ' 0 0 ',
		rm_prov[i].codprov
RUN comando

END FUNCTION



FUNCTION muestra_estado_cuenta(i)
DEFINE i		INTEGER
DEFINE comando          VARCHAR(100)

LET comando = 'fglrun cxpp314 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		vg_codloc, ' ', rm_par.moneda, ' ', rm_par.fecha_cart, ' ',
		rm_par.ind_venc, ' ', 0.01, ' "N" ', rm_prov[i].codprov, ' 0 '
RUN comando

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		INTEGER
DEFINE aux_i		CHAR(1)

IF rm_par.ind_doc = 'D' THEN
	OPEN WINDOW w_cxpf310_2 AT 06, 26 WITH FORM "../forms/cxpf310_2" 
		ATTRIBUTE(BORDER, COMMENT LINE LAST, FORM LINE FIRST)
	LET aux_i    = vm_imprimir
	LET int_flag = 0
	INPUT BY NAME vm_imprimir
		WITHOUT DEFAULTS
		ON KEY(INTERRUPT)
			LET int_flag    = 1
			LET vm_imprimir = aux_i
			EXIT INPUT
	END INPUT
	CLOSE WINDOW w_cxpf310_2
	IF int_flag THEN
		RETURN
	END IF
ELSE
	LET vm_imprimir = 'R'
END IF
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT report_list_proveedor TO PIPE comando
FOR i = 1 TO num_prov
	OUTPUT TO REPORT report_list_proveedor(i)
END FOR
FINISH REPORT report_list_proveedor

END FUNCTION



REPORT report_list_proveedor(i)
DEFINE i		INTEGER
DEFINE query		VARCHAR(600)
DEFINE expr_fec		VARCHAR(100)
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE factura		VARCHAR(15)
DEFINE tit_imprimir	VARCHAR(10)
DEFINE tot_val		DECIMAL(14,2)
DEFINE tot_sal		DECIMAL(14,2)
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_p20		RECORD LIKE cxpt020.*

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo  = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CASE vm_imprimir
		WHEN 'R' LET tit_imprimir = 'RESUMIDO'
		WHEN 'D' LET tit_imprimir = 'DETALLADO'
	END CASE
	PRINT COLUMN 001, r_g01.g01_razonsocial,
  	      COLUMN 070, "PAGINA: ", PAGENO USING '&&&'
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 025, "ANALISIS CARTERA DE PROVEEDORES",
	      COLUMN 074, UPSHIFT(vg_proceso) 
	SKIP 1 LINES
	PRINT COLUMN 015, "** MONEDA         : ", rm_par.moneda,
		" ", rm_par.tit_mon
	IF rm_par.tipprov IS NOT NULL THEN
		PRINT COLUMN 015, "** TIPO PROVEEDOR : ",
			rm_par.tipprov USING '<<<&', " ", rm_par.tit_tipprov
	END IF
	PRINT COLUMN 015, "** TIPO DE VENCTO.: ", rm_par.ind_venc, " ",
		retorna_tipo_vencto(rm_par.ind_venc),
	      COLUMN 053, "** TIPO REPORTE: ", vm_imprimir, ' ',
			tit_imprimir CLIPPED
	PRINT COLUMN 015, "** POR PAGAR AL   : ",
		rm_par.fecha_cart USING 'dd-mm-yyyy';
	IF num_fav > 0 AND rm_par.ind_doc = 'T' THEN
		PRINT COLUMN 056, "INCLUIDO EL SALDO A FAVOR"
	ELSE
		PRINT " "
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 014, "P R O V E E D O R E S";
	IF rm_par.ind_doc <> 'T' THEN
		PRINT COLUMN 040, "V. POR VENCER",
		      COLUMN 054, "VALOR VENCIDO",
		      COLUMN 068, "  VALOR PAGAR"
	ELSE
		CASE rm_par.ind_venc
			WHEN 'P'
				PRINT COLUMN 040, "V. POR VENCER";
			WHEN 'V'
				PRINT COLUMN 040, "VALOR VENCIDO";
			WHEN 'T'
				PRINT COLUMN 040, " TOTAL DEUDOR";
		END CASE
		PRINT COLUMN 054, "TOTAL A FAVOR",
		      COLUMN 068, "CARTERA TOTAL"
	END IF
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_prov[i].codprov		USING "#&&&&&",
	      COLUMN 008, rm_prov[i].nomprov[1, 31] CLIPPED,
	      COLUMN 040, rm_prov[i].tot_pven		USING "--,---,--&.##",
	      COLUMN 054, rm_prov[i].tot_venc		USING "--,---,--&.##",
	      COLUMN 068, rm_prov[i].tot_saldo		USING "--,---,--&.##"
	IF vm_imprimir = 'D' THEN
		SKIP 1 LINES
		PRINT COLUMN 006, 'TD',
		      COLUMN 009, 'NUMERO DOC.',
		      COLUMN 029, 'FECHA VCTO',
		      COLUMN 040, '   VALOR DOC.',
		      COLUMN 054, '   SALDO DOC.'
		CASE rm_par.ind_venc
			WHEN 'V'
				LET expr_fec = '   AND p20_fecha_vcto  < "',
						rm_par.fecha_cart, '"'
			WHEN 'P'
				LET expr_fec = '   AND p20_fecha_vcto >= "',
						rm_par.fecha_cart, '"'
			OTHERWISE
				LET expr_fec = NULL
		END CASE
		LET query = 'SELECT p20_tipo_doc, p20_num_doc, p20_dividendo,',
				' p20_fecha_vcto, valor_doc, valor_mov ',
				' FROM tmp_mov ',
				' WHERE p20_codprov = ', rm_prov[i].codprov,
				expr_fec CLIPPED,
				' ORDER BY p20_fecha_vcto '
		PREPARE cons_docs FROM query
		DECLARE q_docs CURSOR FOR cons_docs
		LET tot_val = 0
		LET tot_sal = 0
		FOREACH q_docs INTO r_p20.p20_tipo_doc, r_p20.p20_num_doc,
				r_p20.p20_dividendo, r_p20.p20_fecha_vcto,
				r_p20.p20_valor_cap, r_p20.p20_saldo_cap
			LET tot_val = tot_val + r_p20.p20_valor_cap
			LET tot_sal = tot_sal + r_p20.p20_saldo_cap
			PRINT COLUMN 006, r_p20.p20_tipo_doc,
			      COLUMN 009, r_p20.p20_num_doc CLIPPED, '-',
				r_p20.p20_dividendo USING "<&&",
			      COLUMN 029, r_p20.p20_fecha_vcto
							USING "dd-mm-yyyy",
			      COLUMN 040, r_p20.p20_valor_cap
							USING "--,---,--&.##",
			      COLUMN 054, r_p20.p20_saldo_cap
							USING "--,---,--&.##"
		END FOREACH
		PRINT COLUMN 040, "-------------",
		      COLUMN 054, "-------------"
		PRINT COLUMN 024, "TOT. DOCS. ==>  ",
		      COLUMN 040, tot_val		USING "--,---,--&.##",
		      COLUMN 054, tot_sal		USING "--,---,--&.##"
		SKIP 1 LINES
	END IF
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 040, "-------------",
	      COLUMN 054, "-------------",
	      COLUMN 068, "-------------"
	PRINT COLUMN 027, "TOTALES ==>  ",
	      COLUMN 040, tot_1				USING "--,---,--&.##",
	      COLUMN 054, tot_2				USING "--,---,--&.##",
	      COLUMN 068, tot_3				USING "--,---,--&.##"

END REPORT



FUNCTION retorna_tipo_vencto(tipo)
DEFINE tipo		CHAR(1)
DEFINE tipo_nom		VARCHAR(10)

CASE tipo
	WHEN 'P'
		LET tipo_nom = 'POR VENCER'
	WHEN 'V'
		LET tipo_nom = 'VENCIDOS'
	WHEN 'T'
		LET tipo_nom = 'T O D O S'
END CASE
RETURN tipo_nom

END FUNCTION



FUNCTION control_importar_archivo()

UNLOAD TO "cartera_prov.unl"
	SELECT codprov, nomprov, SUM(por_vencer + vencido)
		FROM tempo_doc
		GROUP BY 1, 2
		ORDER BY 3 DESC, 1 DESC
CALL fl_mostrar_mensaje('Archivo Generado OK.', 'info')

END FUNCTION
