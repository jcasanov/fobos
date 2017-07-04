--------------------------------------------------------------------------------
-- Titulo           : cxpp315.4gl - Análisis Detalle Cartera Proveedor por Fecha
-- Elaboracion      : 26-Abr-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxpp315 base modulo compañía localidad
--			[moneda] [tipo_venc] [tipo_doc] [incluir_sal]
--			[fecha_cart] [tipprov o 0] [tipcar o 0] [proveedor o 0]
--			[[fecha_emi]] [[flag = F]]
--			[[fecha_vcto1]] [[fecha_vcto2]]
--			F = fecha_emi
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE rm_z60		RECORD LIKE cxct060.*
DEFINE rm_par 		RECORD
				moneda          LIKE gent013.g13_moneda,
				tit_mon         LIKE gent013.g13_nombre,
				ind_venc        CHAR(1),
				tipprov		LIKE gent012.g12_subtipo,
				tit_tipprov	LIKE gent012.g12_nombre,
				tipcar		LIKE gent012.g12_subtipo,
				tit_tipcar	LIKE gent012.g12_nombre,
				ind_doc		CHAR(1),
				codprov		LIKE cxpt001.p01_codprov,
				nom_prov	LIKE cxpt001.p01_nomprov,
				incluir_sal	CHAR(1),
				fecha_emi	DATE,
				fecha_cart	DATE,
				fecha_vcto1	DATE,
				fecha_vcto2	DATE
			END RECORD
DEFINE rm_doc		ARRAY[32766] OF RECORD
				cladoc		LIKE cxpt020.p20_tipo_doc,
				numdoc		VARCHAR(18),
				nomprov		LIKE cxpt001.p01_nomprov,
				fecha		DATE,
				valor		DECIMAL(12,2),
				saldo		DECIMAL(12,2)
			END RECORD
DEFINE num_doc, num_fav	INTEGER
DEFINE num_max_doc	INTEGER
DEFINE tot_val		DECIMAL(14,2)
DEFINE tot_sal		DECIMAL(14,2)
DEFINE vm_saldo_ant	DECIMAL(14,2)
DEFINE vm_fecha_ini	DATE
DEFINE vm_contab	CHAR(1)
DEFINE rm_cont		ARRAY[32766] OF RECORD
				b13_tipo_comp	LIKE ctbt013.b13_tipo_comp,
				b13_num_comp	LIKE ctbt013.b13_num_comp,
				b13_fec_proceso	LIKE ctbt013.b13_fec_proceso,
				b13_glosa	LIKE ctbt013.b13_glosa,
				val_db		LIKE ctbt013.b13_valor_base,
				val_cr		LIKE ctbt013.b13_valor_base,
				val_db_cr	DECIMAL(14,2)
			END RECORD
DEFINE rm_tes		ARRAY[32766] OF RECORD
				p23_tipo_trn	LIKE cxpt023.p23_tipo_trn,
				p23_num_trn	LIKE cxpt023.p23_num_trn,
				p22_fecha_emi	LIKE cxpt022.p22_fecha_emi,
				p22_referencia	LIKE cxpt022.p22_referencia,
				val_deu		DECIMAL(14,2),
				val_fav		DECIMAL(14,2),
				val_d_f		DECIMAL(14,2)
			END RECORD
DEFINE rm_aux		ARRAY[32766] OF RECORD
				loc		LIKE gent002.g02_localidad,
				tipo		LIKE cxpt023.p23_tipo_favor,
				codprov		LIKE cxpt023.p23_codprov
			END RECORD
DEFINE vm_num_tes	INTEGER
DEFINE vm_num_con	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp315.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 12 AND num_args() <> 14 THEN
	-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxpp315'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_lee_fecha_carga_cxc(vg_codcia, vg_codloc) RETURNING rm_z60.*
IF rm_z60.z60_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe una fecha de carga para este módulo.', 'stop')
	EXIT PROGRAM
END IF
CREATE TEMP TABLE tempo_doc 
	(cladoc		CHAR(2),
	 numdoc		VARCHAR(16),
	 secuencia	SMALLINT,
	 codprov	INTEGER,
	 nomprov	VARCHAR(100),
	 fecha_emi	DATE,
	 fecha		DATE,
	 valor_doc	DECIMAL(12,2),
	 saldo_doc	DECIMAL(12,2),
	 numero_oc	INTEGER,
	 tipo_doc	CHAR(1))
LET num_max_doc = 32766
OPEN WINDOW w_imp AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_par FROM "../forms/cxpf315_1"
DISPLAY FORM f_par
INITIALIZE rm_par.*, vm_fecha_ini TO NULL
LET rm_par.moneda      = rg_gen.g00_moneda_base
LET rm_par.ind_venc    = 'T'
LET rm_par.incluir_sal = 'N'
LET rm_par.ind_doc     = 'D'
LET rm_par.fecha_cart  = TODAY
LET vm_fecha_ini       = rm_z60.z60_fecha_carga
LET vm_contab          = 'C'
IF num_args() >= 5 THEN
	CALL llamada_de_otro_programa()
END IF
CALL control_consulta()
DROP TABLE tempo_doc

END FUNCTION



FUNCTION llamada_de_otro_programa()
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE r_p01		RECORD LIKE cxpt001.*

LET rm_par.moneda      = arg_val(5)
LET rm_par.ind_venc    = arg_val(6)
LET rm_par.ind_doc     = arg_val(7)
LET rm_par.incluir_sal = arg_val(8)
LET rm_par.fecha_cart  = arg_val(9)
LET rm_par.tipprov     = arg_val(10)
LET rm_par.tipcar      = arg_val(11)
LET rm_par.codprov     = arg_val(12)
IF num_args() > 12 THEN
	CASE arg_val(14)
		WHEN 'F'
			LET rm_par.fecha_emi = arg_val(13)
		OTHERWISE
			LET rm_par.fecha_vcto1 = arg_val(13)
			LET rm_par.fecha_vcto2 = arg_val(14)
	END CASE
END IF
IF rm_par.ind_doc = 'F' THEN
	LET rm_par.tipcar = NULL
END IF
IF rm_par.tipprov = 0 THEN
	LET rm_par.tipprov = NULL
END IF
IF rm_par.tipcar = 0 THEN
	LET rm_par.tipcar = NULL
END IF
IF rm_par.codprov = 0 THEN
	LET rm_par.codprov = NULL
END IF
IF rm_par.tipprov IS NOT NULL THEN
	CALL fl_lee_subtipo_entidad('TP', rm_par.tipprov) RETURNING r_g12.*
	IF r_g12.g12_tiporeg IS NULL THEN
		CALL fl_mostrar_mensaje('No existe tipo de proveedor.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_par.tit_tipprov = r_g12.g12_nombre 
END IF
IF rm_par.tipcar IS NOT NULL THEN
	CALL fl_lee_subtipo_entidad('CR', rm_par.tipcar) RETURNING r_g12.*
	IF r_g12.g12_tiporeg IS NULL THEN
		CALL fl_mostrar_mensaje('No existe tipo de cartera.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_par.tit_tipcar = r_g12.g12_nombre 
END IF
IF rm_par.codprov IS NOT NULL THEN
	CALL fl_lee_proveedor(rm_par.codprov) RETURNING r_p01.*
	IF r_p01.p01_codprov IS NULL THEN
		CALL fl_mostrar_mensaje('No existe codigo de proveedor.','stop')
		EXIT PROGRAM
	END IF
	LET rm_par.nom_prov = r_p01.p01_nomprov
END IF
DISPLAY BY NAME rm_par.*
IF rm_par.fecha_emi IS NOT NULL THEN
	IF rm_par.fecha_emi >= rm_par.fecha_cart THEN
		CALL fl_mostrar_mensaje('La fecha de emision debe ser menor que la fecha de cartera.', 'stop')
		EXIT PROGRAM
	END IF
END IF
IF rm_par.fecha_vcto1 IS NOT NULL THEN
	IF rm_par.fecha_vcto1 >= rm_par.fecha_vcto2 THEN
		CALL fl_mostrar_mensaje('La fecha de vencimiento inicial debe ser menor que la fecha de vencimiento final.', 'stop')
		EXIT PROGRAM
	END IF
END IF

END FUNCTION



FUNCTION control_consulta()
DEFINE i		SMALLINT

CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
LET rm_par.tit_mon = rm_mon.g13_nombre
DISPLAY BY NAME rm_par.tit_mon
DISPLAY 'TP'                TO tit_col1
DISPLAY 'Documento'         TO tit_col2
DISPLAY 'P r o v e e d o r' TO tit_col3
DISPLAY 'Fec. Vcto.'        TO tit_col4
DISPLAY 'Valor Doc.'        TO tit_col5
DISPLAY 'S a l d o'         TO tit_col6
WHILE TRUE
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	IF num_args() = 4 THEN
		CALL lee_parametros() 
		IF int_flag THEN
			EXIT WHILE
		END IF
	END IF
	CASE rm_par.ind_doc
		WHEN 'D'
			LET rm_orden[6]  = 'DESC'
			LET rm_orden[5]  = 'DESC'
			LET vm_columna_1 = 6
			LET vm_columna_2 = 5
		WHEN 'F'
			LET rm_orden[6]  = 'ASC'
			LET rm_orden[5]  = 'ASC'
			LET vm_columna_1 = 6
			LET vm_columna_2 = 5
		WHEN 'T'
			LET rm_orden[3]  = 'ASC'
			LET rm_orden[2]  = 'ASC'
			LET vm_columna_1 = 3
			LET vm_columna_2 = 2
	END CASE
	CALL genera_tabla_trabajo_detalle()
	IF num_doc > 0 THEN
		CALL muestra_detalle_documentos()
	END IF
	IF rm_par.fecha_emi IS NOT NULL THEN
		DROP TABLE tmp_sal_ini
	END IF
	DELETE FROM tempo_doc
	IF num_args() >= 5 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_mo		RECORD LIKE gent013.*
DEFINE r_se		RECORD LIKE gent012.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_p02		RECORD LIKE cxpt002.*
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
		LET int_flag = 1
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
		IF INFIELD(tipcar) THEN
			CALL fl_ayuda_subtipo_entidad('CR') 
				RETURNING tiporeg, subtipo, nomtipo, nombre
			IF nomtipo IS NOT NULL THEN
				LET rm_par.tipcar     = subtipo
				LET rm_par.tit_tipcar = nomtipo
				DISPLAY BY NAME rm_par.tipcar, rm_par.tit_tipcar
			END IF
		END IF
		IF INFIELD(codprov) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
					RETURNING r_p01.p01_codprov,
						  r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET rm_par.codprov  = r_p01.p01_codprov
				LET rm_par.nom_prov = r_p01.p01_nomprov
				DISPLAY BY NAME rm_par.codprov, rm_par.nom_prov
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
	AFTER FIELD tipcar
		IF rm_par.tipcar IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CR', rm_par.tipcar)
				RETURNING r_se.*
			IF r_se.g12_tiporeg IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe tipo cartera', 'exclamation')
				NEXT FIELD tipcar
			END IF
			LET rm_par.tit_tipcar = r_se.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipcar
		ELSE
			LET rm_par.tit_tipcar = NULL
			DISPLAY BY NAME rm_par.tit_tipcar
		END IF
	AFTER FIELD codprov
		IF rm_par.codprov IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_par.codprov) RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN
				CALL fl_mostrar_mensaje('Proveedor no existe.', 'exclamation')
				NEXT FIELD codprov
			END IF
			LET rm_par.nom_prov = r_p01.p01_nomprov
			DISPLAY BY NAME rm_par.nom_prov
			CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc,
							r_p01.p01_codprov)
				RETURNING r_p02.*
			IF r_p02.p02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Proveedor no está activado para la Localidad.', 'exclamation')
				NEXT FIELD codprov
			END IF
		END IF
	AFTER FIELD fecha_cart
		IF rm_par.fecha_cart IS NULL THEN
			LET rm_par.fecha_cart = fec
			DISPLAY BY NAME rm_par.fecha_cart
		END IF
		IF rm_par.fecha_cart <= vm_fecha_ini THEN
			CALL fl_mostrar_mensaje('La Fecha de Cartera AL, no puede ser menor a la Fecha de Inicio de las TESORERIA en el FOBOS.', 'exclamation')
			NEXT FIELD fecha_cart
		END IF
	AFTER FIELD fecha_emi
		IF rm_par.fecha_emi IS NOT NULL THEN
			IF rm_par.fecha_emi <= vm_fecha_ini THEN
				CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser menor a la Fecha de Inicio de las TESORERIA en el FOBOS.', 'exclamation')
				NEXT FIELD fecha_emi
			END IF
		END IF
	AFTER FIELD fecha_vcto1
		IF rm_par.fecha_vcto1 IS NOT NULL THEN
			IF rm_par.fecha_vcto1 <= vm_fecha_ini THEN
				CALL fl_mostrar_mensaje('La Fecha de Vencimiento Inicial no puede ser menor a la Fecha de Inicio de las TESORERIA en el FOBOS.', 'exclamation')
				NEXT FIELD fecha_vcto1
			END IF
		END IF
	AFTER FIELD fecha_vcto2
		IF rm_par.fecha_vcto2 IS NOT NULL THEN
			IF rm_par.fecha_vcto2 <= vm_fecha_ini THEN
				CALL fl_mostrar_mensaje('La Fecha de Vencimiento Final no puede ser menor a la Fecha de Inicio de las TESORERIA en el FOBOS.', 'exclamation')
				NEXT FIELD fecha_vcto2
			END IF
		END IF
	AFTER INPUT 
		IF rm_par.codprov IS NOT NULL THEN
			LET rm_par.tipprov     = NULL
			LET rm_par.tit_tipprov = NULL
			DISPLAY BY NAME rm_par.tipprov, rm_par.tit_tipprov
		END IF
		IF rm_par.fecha_emi IS NOT NULL THEN
			IF rm_par.fecha_emi > rm_par.fecha_cart THEN
				CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor que la Fecha Final.', 'exclamation')
				NEXT FIELD fecha_emi
			END IF
		END IF
		IF rm_par.fecha_vcto1 IS NULL AND rm_par.fecha_vcto2 IS NOT NULL
		THEN
			CALL fl_mostrar_mensaje('Digite fecha de vencimiento inicial.', 'exclamation')
			NEXT FIELD fecha_vcto1
		END IF
		IF rm_par.fecha_vcto1 IS NOT NULL AND rm_par.fecha_vcto2 IS NULL
		THEN
			CALL fl_mostrar_mensaje('Digite fecha de vencimiento final.', 'exclamation')
			NEXT FIELD fecha_vcto2
		END IF
		IF rm_par.fecha_vcto1 IS NOT NULL THEN
			IF rm_par.fecha_vcto1 >= rm_par.fecha_vcto2 THEN
				CALL fl_mostrar_mensaje('La fecha de vencimiento inicial debe ser menor que la fecha de vencimiento final.', 'exclamation')
				NEXT FIELD fecha_vcto1
			END IF
		END IF
		IF rm_par.fecha_emi IS NOT NULL THEN
			IF rm_par.fecha_emi >= rm_par.fecha_vcto1 THEN
				CALL fl_mostrar_mensaje('La fecha de emision debe ser menor que la fecha de vencimiento inicial.', 'exclamation')
				NEXT FIELD fecha_emi
			END IF
		END IF
		IF rm_par.ind_doc = 'F' THEN
			LET rm_par.tipcar     = NULL
			LET rm_par.tit_tipcar = NULL
			DISPLAY BY NAME rm_par.tipcar, rm_par.tit_tipcar
		END IF
END INPUT

END FUNCTION



FUNCTION genera_tabla_trabajo_detalle()

LET vm_saldo_ant = 0
LET num_doc      = 0
LET num_fav      = 0
IF rm_par.fecha_emi IS NOT NULL THEN
	SELECT p20_codprov cod_prov_s, p20_saldo_cap saldo_ini_tes,
		p20_origen tipo_s
		FROM cxpt020
		WHERE p20_compania = 17
		INTO TEMP tmp_sal_ini2
END IF
CASE rm_par.ind_doc
	WHEN 'D'
		CALL obtener_documentos_deudores()
		IF num_doc = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
		END IF
	WHEN 'F'
		CALL obtener_documentos_a_favor()
		IF num_fav = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
		END IF
		LET num_doc = num_fav
	WHEN 'T'
		CALL obtener_documentos_deudores()
		IF num_doc = 0 THEN
			CALL fl_mostrar_mensaje('No se ha encontrado documentos deudores con saldo.', 'info')
		END IF
		CALL obtener_documentos_a_favor()
		IF num_fav = 0 THEN
			CALL fl_mostrar_mensaje('No se ha encontrado documentos a favor con saldo.', 'info')
		END IF
		LET num_doc = num_doc + num_fav
END CASE
IF rm_par.fecha_emi IS NOT NULL THEN
	SELECT cod_prov_s, NVL(SUM(saldo_ini_tes), 0) saldo_ini_tes
		FROM tmp_sal_ini2
		GROUP BY 1
		INTO TEMP tmp_sal_ini
	DROP TABLE tmp_sal_ini2
END IF

END FUNCTION



FUNCTION obtener_documentos_deudores()
DEFINE fecha		LIKE cxpt022.p22_fecing
DEFINE query		CHAR(6000)
DEFINE subquery1	CHAR(3000)
DEFINE subquery2	CHAR(500)
DEFINE expr1, expr2	VARCHAR(100)
DEFINE expr3, expr4	VARCHAR(100)
DEFINE join_p22p23	CHAR(500)
DEFINE signo		CHAR(2)

ERROR "Procesando documentos deudores con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
INITIALIZE expr1, expr2, expr3, expr4 TO NULL
IF rm_par.tipprov IS NOT NULL THEN
	LET expr1 = '   AND p01_tipo_prov  = ', rm_par.tipprov
END IF
IF rm_par.tipcar IS NOT NULL THEN
	LET expr2 = '   AND p20_cartera    = ', rm_par.tipcar
END IF
IF rm_par.codprov IS NOT NULL THEN
	LET expr3 = '   AND p20_codprov    = ', rm_par.codprov
END IF
CASE rm_par.ind_venc
	WHEN 'V'
		LET expr4 = '   AND p20_fecha_emi  <= "', rm_par.fecha_cart,'"',
			    '   AND p20_fecha_vcto  < "', rm_par.fecha_cart, '"'
	WHEN 'P'
		LET expr4 = '   AND p20_fecha_emi  <= "', rm_par.fecha_cart,'"',
			    '   AND p20_fecha_vcto >= "', rm_par.fecha_cart, '"'
	WHEN 'T'
		LET expr4 = '   AND p20_fecha_emi  <= "', rm_par.fecha_cart, '"'
END CASE
LET query = 'SELECT cxpt020.*, p04_tipo ',
		' FROM cxpt020, cxpt004 ',
		' WHERE p20_compania   = ', vg_codcia,
		'   AND p20_localidad  = ', vg_codloc,
		'   AND p20_moneda     = "', rm_par.moneda, '"',
			expr2 CLIPPED,
			expr3 CLIPPED,
			expr4 CLIPPED,
		'   AND p04_tipo_doc   = p20_tipo_doc ',
		' INTO TEMP tmp_p20 '
PREPARE cons_p20 FROM query
EXECUTE cons_p20
LET fecha = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
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
LET query = 'INSERT INTO tempo_doc ',
		'SELECT p20_tipo_doc, p20_num_doc, p20_dividendo,',
			' p20_codprov, p01_nomprov, p20_fecha_emi,',
			' p20_fecha_vcto, p20_valor_cap + p20_valor_int, ',
			' NVL(', subquery1 CLIPPED, ', ',
			' CASE WHEN p20_fecha_emi <= "', vm_fecha_ini, '"',
				' THEN p20_saldo_cap + p20_saldo_int - ',
					subquery2 CLIPPED,
				' ELSE p20_valor_cap + p20_valor_int',
			' END) saldo_mov, ',
			' p20_numero_oc, p04_tipo ',
		' FROM tmp_p20, cxpt001 ',
		' WHERE p01_codprov    = p20_codprov ',
			expr1 CLIPPED
PREPARE stmnt1 FROM query
EXECUTE stmnt1
DROP TABLE tmp_p20
LET signo = '<='
IF rm_par.incluir_sal = 'S' THEN
	LET signo = '<'
END IF
LET expr1 = NULL
IF rm_par.incluir_sal = 'N' OR signo = '<' THEN
	LET expr1 = ' WHERE saldo_doc ', signo CLIPPED, ' 0 '
END IF
LET expr2 = NULL
IF rm_par.fecha_emi IS NOT NULL THEN
	LET expr2 = ' WHERE'
	IF expr1 IS NOT NULL THEN
		LET expr2 = '    OR'
	END IF
	LET expr2 = expr2 CLIPPED, ' fecha_emi  < "', rm_par.fecha_emi, '"'
	INSERT INTO tmp_sal_ini2
		SELECT codprov, NVL(SUM(saldo_doc), 0), 'D'
			FROM tempo_doc
			WHERE fecha_emi < rm_par.fecha_emi
			GROUP BY 1
	SELECT NVL(SUM(saldo_ini_tes), 0) INTO vm_saldo_ant FROM tmp_sal_ini2
END IF
IF expr1 IS NOT NULL OR expr2 IS NOT NULL THEN
	LET query = 'DELETE FROM tempo_doc ',
			expr1 CLIPPED,
			expr2 CLIPPED
	PREPARE borrar FROM query
	EXECUTE borrar
END IF
IF rm_par.fecha_vcto1 IS NOT NULL THEN
	LET query = 'SELECT * FROM tempo_doc ',
			' WHERE fecha  BETWEEN "', rm_par.fecha_vcto1,
					'" AND "', rm_par.fecha_vcto2, '"',
			' INTO TEMP t1'
	PREPARE cons_vcto FROM query
	EXECUTE cons_vcto
	DELETE FROM tempo_doc WHERE 1 = 1
	INSERT INTO tempo_doc SELECT * FROM t1
	DROP TABLE t1
END IF
SELECT COUNT(*) INTO num_doc FROM tempo_doc 
ERROR ' '

END FUNCTION



FUNCTION obtener_documentos_a_favor()
DEFINE fecha		LIKE cxpt022.p22_fecing
DEFINE query		CHAR(6000)
DEFINE subquery1	CHAR(1000)
DEFINE subquery2	CHAR(400)
DEFINE expr1, expr2	VARCHAR(100)
DEFINE sal_ant		DECIMAL(14,2)

ERROR "Procesando documentos a favor con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
INITIALIZE expr1, expr2 TO NULL
IF rm_par.tipprov IS NOT NULL THEN
	LET expr1 = '   AND p01_tipo_prov  = ', rm_par.tipprov
END IF
IF rm_par.codprov IS NOT NULL THEN
	LET expr2 = '   AND p21_codprov    = ', rm_par.codprov
END IF
LET query = 'SELECT cxpt021.*, p04_tipo ',
		' FROM cxpt021, cxpt004 ',
		' WHERE p21_compania   = ', vg_codcia,
		'   AND p21_localidad  = ', vg_codloc,
			expr2 CLIPPED,
		'   AND p21_moneda     = "', rm_par.moneda, '"',
		'   AND p21_fecha_emi <= "', rm_par.fecha_cart, '"',
		'   AND p04_tipo_doc   = p21_tipo_doc ',
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
LET query = 'INSERT INTO tempo_doc ',
		'SELECT p21_tipo_doc, p21_num_doc, 0,',
			' p21_codprov, p01_nomprov, DATE(p21_fecing),',
			' p21_fecha_emi, p21_valor * (-1), ',
			' NVL(CASE WHEN p21_fecha_emi > "', vm_fecha_ini, '"',
				' THEN p21_valor + ', subquery1 CLIPPED,
				' ELSE ', subquery2 CLIPPED, ' + p21_saldo - ',
					  subquery1 CLIPPED,
			' END, ',
			' CASE WHEN p21_fecha_emi <= "', vm_fecha_ini, '"',
				' THEN p21_saldo - ', subquery2 CLIPPED,
				' ELSE p21_valor',
			' END) * (-1) saldo_mov, ',
			' 0, p04_tipo ',
		' FROM tmp_p21, cxpt001 ',
		' WHERE p01_codprov    = p21_codprov ',
			expr1 CLIPPED
PREPARE stmnt2 FROM query
EXECUTE stmnt2
DROP TABLE tmp_p21
LET expr1 = NULL
IF rm_par.incluir_sal = 'N' THEN
	LET expr1 = '   AND saldo_doc = 0 '
END IF
LET expr2 = NULL
IF rm_par.fecha_emi IS NOT NULL THEN
	LET expr2 = '    OR'
	IF expr1 IS NULL THEN
		LET expr2 = '   AND'
	END IF
	LET expr2 = expr2 CLIPPED, ' fecha_emi < "', rm_par.fecha_emi, '"'
	INSERT INTO tmp_sal_ini2
		SELECT codprov, NVL(SUM(saldo_doc), 0) sal_f, 'F'
			FROM tempo_doc
			WHERE tipo_doc  = "F"
			  AND fecha_emi < rm_par.fecha_emi
			GROUP BY 1
	SELECT NVL(SUM(saldo_ini_tes), 0) INTO sal_ant
		FROM tmp_sal_ini2
		WHERE tipo_s = 'F'
	LET vm_saldo_ant = vm_saldo_ant + sal_ant
END IF
IF expr1 IS NOT NULL OR expr2 IS NOT NULL THEN
	LET query = 'DELETE FROM tempo_doc ',
			' WHERE tipo_doc   = "F" ',
			expr1 CLIPPED,
			expr2 CLIPPED
	PREPARE borrar2 FROM query
	EXECUTE borrar2
END IF
SELECT COUNT(*) INTO num_fav FROM tempo_doc WHERE tipo_doc = 'F'
ERROR ' '

END FUNCTION



FUNCTION muestra_detalle_documentos()
DEFINE r_aux		ARRAY[32766] OF RECORD
				codprov		LIKE cxpt001.p01_codprov,
				numdoc		LIKE cxpt020.p20_num_doc,
				dividendo	LIKE cxpt020.p20_dividendo,
				numero_oc	LIKE cxpt020.p20_numero_oc,
				tipo		LIKE cxpt004.p04_tipo,
				cod_tran	LIKE rept019.r19_cod_tran,
				num_tran	LIKE rept019.r19_num_tran,
				tipo_dev	LIKE rept019.r19_tipo_dev,
				num_dev		LIKE rept019.r19_num_dev
			END RECORD
DEFINE tit_venc		CHAR(20)
DEFINE query		CHAR(600)
DEFINE i, col		INTEGER
DEFINE dias		SMALLINT

WHILE TRUE
	LET query = 'SELECT cladoc, numdoc, nomprov, fecha, valor_doc, ',
			'saldo_doc, codprov, numdoc, secuencia, numero_oc, ',
			'tipo_doc ',
			' FROM tempo_doc ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE cond FROM query
	DECLARE q_cond CURSOR FOR cond
	LET i       = 1
	LET tot_val = 0
	LET tot_sal = 0
	FOREACH q_cond INTO rm_doc[i].*, r_aux[i].* 
		INITIALIZE r_aux[i].cod_tran, r_aux[i].num_tran,
				r_aux[i].tipo_dev, r_aux[i].num_dev TO NULL
		SELECT r19_cod_tran, r19_num_tran, r19_tipo_dev,
			r19_num_dev
			INTO r_aux[i].cod_tran, r_aux[i].num_tran,
				r_aux[i].tipo_dev, r_aux[i].num_dev
			FROM rept019
			WHERE r19_compania   = vg_codcia
			  AND r19_localidad  = vg_codloc
			  AND r19_cod_tran   = 'CL'
			  AND r19_oc_interna = r_aux[i].numero_oc
			  AND r19_oc_externa = rm_doc[i].numdoc
		IF r_aux[i].tipo = 'D' THEN
			LET rm_doc[i].numdoc = rm_doc[i].numdoc CLIPPED, '-',
						r_aux[i].dividendo USING '<<&&'
		END IF
		LET tot_val = tot_val + rm_doc[i].valor
		LET tot_sal = tot_sal + rm_doc[i].saldo
		LET i       = i + 1
		IF i > num_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i       = i - 1
	LET tot_sal = tot_sal + vm_saldo_ant
	DISPLAY BY NAME vm_saldo_ant, tot_val, tot_sal
	CALL mostrar_contadores_det(0, num_doc)
	CALL set_count(num_doc)
	LET int_flag = 0
	DISPLAY ARRAY rm_doc TO rm_doc.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			IF r_aux[i].numero_oc IS NULL THEN
				CONTINUE DISPLAY
			END IF	
			IF r_aux[i].numero_oc = 0 THEN
				CONTINUE DISPLAY
			END IF	
			IF r_aux[i].cod_tran IS NULL THEN
				CALL ver_orden_compra(r_aux[i].numero_oc)
			ELSE
				IF r_aux[i].tipo_dev IS NULL THEN
					CALL fl_ver_transaccion_rep(vg_codcia,
							vg_codloc,
							r_aux[i].cod_tran,
							r_aux[i].num_tran)
				ELSE
					CALL fl_ver_transaccion_rep(vg_codcia,
							vg_codloc,
							r_aux[i].tipo_dev,
							r_aux[i].num_dev)
				END IF
			END IF
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL muestra_movimientos_documento_cxp(vg_codcia,
					r_aux[i].codprov, rm_doc[i].cladoc,
					r_aux[i].numdoc, r_aux[i].dividendo)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_estado_cuenta(r_aux[i].codprov)
			LET int_flag = 0
		ON KEY(F8)
			LET i = arr_curr()
			CALL ver_documento(r_aux[i].codprov, r_aux[i].numdoc,
					r_aux[i].dividendo, r_aux[i].tipo, i)
			LET int_flag = 0
		ON KEY(F9)
			IF rm_par.ind_doc <> 'T' THEN
				CONTINUE DISPLAY
			END IF
			LET i = arr_curr()
			CALL control_contabilizacion(r_aux[i].codprov)
			LET int_flag = 0
		ON KEY(F10)
			CALL control_imprimir()
			LET int_flag = 0
		ON KEY(F11)
			CALL control_archivo()
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
		BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT","")
			IF rm_par.ind_doc = 'T' THEN
				CALL dialog.keysetlabel("F9","Contabilización")
			ELSE
				CALL dialog.keysetlabel("F9", "")
			END IF
		AFTER DISPLAY 
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			IF rm_doc[i].fecha < rm_par.fecha_cart THEN
				LET dias = rm_par.fecha_cart - rm_doc[i].fecha
				LET tit_venc = 'VENCIDO ', dias USING "<<<<&",
					       ' DIAS'
			ELSE
				LET dias = rm_doc[i].fecha - rm_par.fecha_cart
				LET tit_venc = 'HOY SE VENCE'
				IF dias > 0 THEN
					LET tit_venc = 'POR VENCER ',
							dias USING "<<<&",
							' DIAS'
				END IF
			END IF
			IF r_aux[i].tipo = 'D' AND rm_doc[i].saldo = 0 THEN
				LET dias = rm_doc[i].fecha - rm_par.fecha_cart
				LET tit_venc = 'PAGADO ', dias USING "<<<<&",
					       ' DIAS'
			END IF
			IF r_aux[i].tipo = 'F' THEN
				LET dias = rm_par.fecha_cart - rm_doc[i].fecha
				LET tit_venc = 'EMITIDO ', dias USING "<<<<&",
					       ' DIAS'
				DISPLAY 'Fecha Emi.' TO tit_col4
				IF r_aux[i].numero_oc = 0 THEN
					CALL dialog.keysetlabel("F5", "")
				END IF
			ELSE
				DISPLAY 'Fec. Vcto.' TO tit_col4
				IF r_aux[i].numero_oc IS NOT NULL AND
				   r_aux[i].numero_oc > 0 THEN
					CALL dialog.keysetlabel("F5",
							"Orden Compra")
				ELSE
					CALL dialog.keysetlabel("F5", "")
				END IF
				IF r_aux[i].cod_tran IS NOT NULL THEN
					CALL dialog.keysetlabel("F5",
								"Compra Local")
				END IF
				IF r_aux[i].tipo_dev IS NOT NULL THEN
					CALL dialog.keysetlabel("F5",
							"Dev. Compra Local")
				END IF
			END IF
			DISPLAY BY NAME tit_venc
			CALL mostrar_contadores_det(i, num_doc)
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
CALL mostrar_contadores_det(0, num_doc)
	
END FUNCTION



FUNCTION mostrar_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION muestra_movimientos_documento_cxp(codcia, codprov, tipo_doc, num_doc,
						dividendo)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE tipo_doc		LIKE cxpt020.p20_tipo_doc
DEFINE num_doc		LIKE cxpt020.p20_num_doc
DEFINE dividendo	LIKE cxpt020.p20_dividendo
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
				loc		LIKE gent002.g02_localidad,
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
DEFINE expr_loc		VARCHAR(50)
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
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf315_2 FROM "../forms/cxpf315_2"
ELSE
	OPEN FORM f_cxpf315_2 FROM "../forms/cxpf315_2c"
END IF
DISPLAY FORM f_cxpf315_2
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
CLEAR p23_tipo_doc, p23_num_doc, p23_div_doc
IF dividendo <> 0 THEN
	DISPLAY tipo_doc, num_doc, dividendo
	     TO p23_tipo_doc, p23_num_doc, p23_div_doc
ELSE
	DISPLAY tipo_doc, num_doc TO p23_tipo_doc, p23_num_doc
END IF
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'ASC'
LET columna_1  = 3
LET columna_2  = 1
LET fecha2     = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET expr_fec   = '   AND p22_fecing    <= "', fecha2, '"'
IF rm_par.fecha_emi IS NOT NULL THEN
	LET fecha1   = EXTEND(rm_par.fecha_emi, YEAR TO SECOND)
	LET expr_fec = '   AND p22_fecing    BETWEEN "', fecha1,
					      '" AND "', fecha2, '"'
END IF
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
			'   p23_localidad, p23_tipo_favor ',
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
	PREPARE dpgc FROM query
	DECLARE q_dpgc CURSOR FOR dpgc
	LET i        = 1
	LET tot_pago = 0
	IF dividendo <> 0 THEN
		OPEN q_dpgc USING codcia, codprov, tipo_doc, num_doc, dividendo
	ELSE
		OPEN q_dpgc USING codcia, codprov, tipo_doc, num_doc
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
			CALL muestra_cheque_emitido(codcia, codprov,
							r_pdoc[i].p23_tipo_trn,
							r_pdoc[i].p23_num_trn) 
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_documento_tran(codcia, codprov,
				r_pdoc[i].p23_tipo_trn, r_pdoc[i].p23_num_trn,
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
			--#CALL mostrar_contadores_det(i, num_rows)
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



FUNCTION control_contabilizacion(cod_prov)
DEFINE cod_prov		LIKE cxpt001.p01_codprov

IF num_args() <> 4 THEN
	LET vm_contab = 'C'
	CALL tesoreria_vs_contabilidad(cod_prov)
	RETURN
END IF
OPEN WINDOW w_ran AT 07, 19 WITH FORM "../forms/cxpf315_3" 
	ATTRIBUTE(BORDER, COMMENT LINE LAST, FORM LINE FIRST)
LET int_flag = 0
INPUT BY NAME vm_contab
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	AFTER INPUT
		IF vm_contab = 'M' THEN
			IF rm_par.codprov IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Solo puede escojer esta opcion si es que se han seleccionado todos los documentos.', 'info')
				LET vm_contab = 'C'
				DISPLAY BY NAME vm_contab
				NEXT FIELD vm_contab
			END IF
		END IF
END INPUT
CLOSE WINDOW w_ran
IF int_flag THEN
	RETURN
END IF
CASE vm_contab
	WHEN 'B'
		CALL ver_contabilizacion(cod_prov)
	OTHERWISE
		CALL tesoreria_vs_contabilidad(cod_prov)
END CASE

END FUNCTION



FUNCTION ver_contabilizacion(cod_prov)
DEFINE cod_prov		LIKE cxpt001.p01_codprov
DEFINE r_p00		RECORD LIKE cxpt000.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_cont		ARRAY[32766] OF RECORD
				b13_tipo_comp	LIKE ctbt013.b13_tipo_comp,
				b13_num_comp	LIKE ctbt013.b13_num_comp,
				b13_fec_proceso	LIKE ctbt013.b13_fec_proceso,
				b13_glosa	LIKE ctbt013.b13_glosa,
				val_db		LIKE ctbt013.b13_valor_base,
				val_cr		LIKE ctbt013.b13_valor_base
			END RECORD
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE max_rows, i, col	INTEGER
DEFINE num_rows		INTEGER
DEFINE tot_val_db	DECIMAL(14,2)
DEFINE tot_val_cr	DECIMAL(14,2)
DEFINE sal_ini_tes	DECIMAL(14,2)
DEFINE sal_ini_con	DECIMAL(14,2)
DEFINE saldo_cont	DECIMAL(14,2)
DEFINE saldo_tes	DECIMAL(14,2)
DEFINE v_saldo_cont	DECIMAL(14,2)
DEFINE v_saldo_tes	DECIMAL(14,2)
DEFINE val_des		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE fecha_antes	DATE

LET max_rows  = num_max_doc
LET num_rows2 = 21
LET num_cols  = 80
IF vg_gui = 0 THEN
	LET num_rows2 = 20
	LET num_cols  = 77
END IF
OPEN WINDOW w_cont AT 03, 02 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf315_4 FROM "../forms/cxpf315_4"
ELSE
	OPEN FORM f_cxpf315_4 FROM "../forms/cxpf315_4c"
END IF
DISPLAY FORM f_cxpf315_4
--#DISPLAY 'TP'		TO tit_col1 
--#DISPLAY 'Número'	TO tit_col2 
--#DISPLAY 'Fecha'	TO tit_col3
--#DISPLAY 'G l o s a'	TO tit_col4 
--#DISPLAY 'Débito'	TO tit_col5
--#DISPLAY 'Crédito'	TO tit_col6
CALL fl_lee_proveedor(cod_prov) RETURNING r_p01.*
IF r_p01.p01_codprov IS NULL THEN
	CALL fl_mostrar_mensaje('No existe proveedor: ' || cod_prov, 'exclamation')
	CLOSE WINDOW w_cont
	RETURN
END IF
CALL fl_lee_compania_tesoreria(vg_codcia) RETURNING r_p00.*
LET fecha_ini = rm_par.fecha_emi
LET fecha_fin = rm_par.fecha_cart
IF fecha_ini IS NULL THEN
	LET fecha_ini = vm_fecha_ini + 1 UNITS DAY
END IF
LET fecha_antes = fecha_ini - 1 UNITS DAY
DISPLAY BY NAME r_p01.p01_codprov, r_p01.p01_nomprov, fecha_ini, fecha_fin,
		rm_par.moneda, rm_par.tit_mon
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'ASC'
LET columna_1  = 3
LET columna_2  = 4
ERROR "Procesando Movimientos en Contabilidad . . . espere por favor." ATTRIBUTE(NORMAL)
SELECT UNIQUE p02_aux_prov_mb cuenta FROM cxpt002 INTO TEMP tmp_cta
SELECT * FROM tmp_cta WHERE cuenta = r_p00.p00_aux_prov_mb
IF STATUS = NOTFOUND THEN
	INSERT INTO tmp_cta VALUES (r_p00.p00_aux_prov_mb)
END IF
INSERT INTO tmp_cta SELECT UNIQUE p02_aux_ant_mb FROM cxpt002
SELECT * FROM tmp_cta WHERE cuenta = r_p00.p00_aux_ant_mb
IF STATUS = NOTFOUND THEN
	INSERT INTO tmp_cta VALUES (r_p00.p00_aux_ant_mb)
END IF
LET query = 'SELECT * FROM ctbt013 ',
		' WHERE b13_compania    = ', vg_codcia,
		'   AND b13_cuenta     IN (SELECT UNIQUE cuenta FROM tmp_cta) ',
		'   AND b13_fec_proceso BETWEEN "', vm_fecha_ini,
					 '" AND "', fecha_fin, '"',
		'   AND b13_codprov     = ', r_p01.p01_codprov,
		' INTO TEMP tmp_b13'
PREPARE exec_b13_2 FROM query
EXECUTE exec_b13_2
DROP TABLE tmp_cta
LET query = 'SELECT NVL(SUM(b13_valor_base), 0) saldo_ini ',
		' FROM ctbt012, tmp_b13 ',
		' WHERE b12_compania    = ', vg_codcia,
		'   AND b12_estado      = "M" ',
		'   AND b12_moneda      = "', rm_par.moneda, '"',
		'   AND b13_compania    = b12_compania ',
		'   AND b13_tipo_comp   = b12_tipo_comp ',
		'   AND b13_num_comp    = b12_num_comp ',
		'   AND b13_fec_proceso <= "', fecha_antes, '"',
		' INTO TEMP t_sum'
PREPARE cons_sum FROM query
EXECUTE cons_sum
SELECT * INTO sal_ini_con FROM t_sum
DROP TABLE t_sum
LET sal_ini_tes = 0
IF rm_par.fecha_emi IS NOT NULL THEN
	SELECT NVL(saldo_ini_tes, 0) INTO sal_ini_tes
		FROM tmp_sal_ini
		WHERE cod_prov_s = r_p01.p01_codprov
END IF
DISPLAY BY NAME sal_ini_tes, sal_ini_con
WHILE TRUE
	LET query = 'SELECT b13_tipo_comp, b13_num_comp, b13_fec_proceso, ',
			' b13_glosa, NVL(CASE WHEN b13_valor_base >= 0 THEN ',
			' b13_valor_base END, 0), ',
			' NVL(CASE WHEN b13_valor_base < 0 THEN ',
			' b13_valor_base END, 0) ',
			' FROM ctbt012, tmp_b13 ',
			' WHERE b12_compania    = ', vg_codcia,
			'   AND b12_estado      = "M" ',
			'   AND b12_moneda      = "', rm_par.moneda, '"',
			'   AND b13_compania    = b12_compania ',
			'   AND b13_tipo_comp   = b12_tipo_comp ',
			'   AND b13_num_comp    = b12_num_comp ',
			'   AND b13_fec_proceso > "', fecha_antes, '"',
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE mov_con FROM query
	DECLARE q_mov_con CURSOR FOR mov_con
	ERROR ' '
	LET i          = 1
	LET tot_val_db = 0
	LET tot_val_cr = 0
	FOREACH q_mov_con INTO r_cont[i].*
		LET tot_val_db = tot_val_db + r_cont[i].val_db 
		LET tot_val_cr = tot_val_cr + r_cont[i].val_cr 
		LET i          = i + 1
		IF i > max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	IF i = max_rows THEN
		CALL fl_mostrar_mensaje('Solo se mostraran un maximo de ' || i || ' líneas de detalle ya que la aplicación solo soporta esta cantidad.', 'info')
		LET query = 'SELECT b13_glosa, NVL(CASE WHEN b13_valor_base ',
				'>= 0 THEN ',
				' b13_valor_base END, 0), ',
				' NVL(CASE WHEN b13_valor_base < 0 THEN ',
				' b13_valor_base END, 0) ',
				' INTO tot_val_db, tot_val_cr ',
				' FROM ctbt012, tmp_b13 ',
				' WHERE b12_compania    = ', vg_codcia,
				'   AND b12_estado      = "M" ',
				'   AND b12_moneda      = "', rm_par.moneda,'"',
				'   AND b13_compania    = b12_compania ',
				'   AND b13_tipo_comp   = b12_tipo_comp ',
				'   AND b13_num_comp    = b12_num_comp ',
				'   AND b13_fec_proceso > "', fecha_antes, '"'
		PREPARE cons_sum_tot FROM query
		EXECUTE cons_sum_tot
	END IF
	LET saldo_cont = sal_ini_con + tot_val_db + tot_val_cr
	LET num_rows   = i - 1
	IF num_rows = 0 THEN
		CALL fl_mostrar_mensaje('Proveedor no tiene movimientos en contabiliadad.','exclamation')
		CLOSE WINDOW w_cont
		RETURN
	END IF
	LET saldo_tes = tot_sal
	IF rm_par.codprov IS NULL THEN
		SELECT NVL(SUM(saldo_doc), 0) INTO saldo_tes
			FROM tempo_doc
			WHERE codprov = r_p01.p01_codprov
		LET saldo_tes = saldo_tes + sal_ini_tes
	END IF
	LET v_saldo_cont = saldo_cont
	IF v_saldo_cont < 0 THEN
		LET v_saldo_cont = v_saldo_cont * (-1)
	END IF
	LET v_saldo_tes = saldo_tes
	IF v_saldo_tes < 0 THEN
		LET v_saldo_tes = v_saldo_tes * (-1)
	END IF
	IF saldo_cont > saldo_tes THEN
		LET val_des = v_saldo_cont - v_saldo_tes
	ELSE
		LET val_des = v_saldo_tes - v_saldo_cont
	END IF
	DISPLAY BY NAME tot_val_db, tot_val_cr, saldo_cont, saldo_tes, val_des
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY ARRAY r_cont TO r_cont.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_diario_contable(r_cont[i].b13_tipo_comp,
						 r_cont[i].b13_num_comp)
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
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_det(i, num_rows)
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
DROP TABLE tmp_b13
CLOSE WINDOW w_cont

END FUNCTION



FUNCTION tesoreria_vs_contabilidad(cod_prov)
DEFINE cod_prov		LIKE cxpt001.p01_codprov
DEFINE r_p00		RECORD LIKE cxpt000.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE fecha1, fecha2	LIKE cxpt022.p22_fecing
DEFINE max_rows, i, col	INTEGER
DEFINE lim		INTEGER
DEFINE tot_val_deu	DECIMAL(14,2)
DEFINE tot_val_fav	DECIMAL(14,2)
DEFINE tot_val_db	DECIMAL(14,2)
DEFINE tot_val_cr	DECIMAL(14,2)
DEFINE sal_ini_tes	DECIMAL(14,2)
DEFINE sal_ini_con	DECIMAL(14,2)
DEFINE saldo_cont	DECIMAL(14,2)
DEFINE saldo_tes	DECIMAL(14,2)
DEFINE v_saldo_cont	DECIMAL(14,2)
DEFINE v_saldo_tes	DECIMAL(14,2)
DEFINE val_des		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE expr_fec		VARCHAR(200)
DEFINE expr_prov1	VARCHAR(100)
DEFINE expr_prov2	VARCHAR(100)
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE fecha_antes	DATE
DEFINE sig_tes, sig_con	SMALLINT
DEFINE p1, p2, p3, p4	INTEGER

LET num_rows2 = 22
LET num_cols  = 80
IF vg_gui = 0 THEN
	LET num_rows2 = 20
	LET num_cols  = 77
END IF
OPEN WINDOW w_tes_cont AT 03, 02 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf315_5 FROM "../forms/cxpf315_5"
ELSE
	OPEN FORM f_cxpf315_5 FROM "../forms/cxpf315_5c"
END IF
DISPLAY FORM f_cxpf315_5
--#DISPLAY 'TP'		TO tit_col1 
--#DISPLAY 'Número'	TO tit_col2 
--#DISPLAY 'Fecha Pago'	TO tit_col3
--#DISPLAY 'Referencia'	TO tit_col4
--#DISPLAY 'Deudor'	TO tit_col5
--#DISPLAY 'Acreedor'	TO tit_col6
--#DISPLAY 'Saldo Tes.'	TO tit_col7
--#DISPLAY 'TP'		TO tit_col8 
--#DISPLAY 'Número'	TO tit_col9 
--#DISPLAY 'Fecha'	TO tit_col10
--#DISPLAY 'G l o s a'	TO tit_col11 
--#DISPLAY 'Débito'	TO tit_col12
--#DISPLAY 'Crédito'	TO tit_col13
--#DISPLAY 'Saldo Con.'	TO tit_col14
CALL fl_lee_proveedor(cod_prov) RETURNING r_p01.*
IF r_p01.p01_codprov IS NULL THEN
	CALL fl_mostrar_mensaje('No existe proveedor: ' || cod_prov, 'exclamation')
	CLOSE WINDOW w_tes_cont
	RETURN
END IF
CALL fl_lee_compania_tesoreria(vg_codcia) RETURNING r_p00.*
LET fecha_ini = rm_par.fecha_emi
LET fecha_fin = rm_par.fecha_cart
IF fecha_ini IS NULL THEN
	LET fecha_ini = vm_fecha_ini + 1 UNITS DAY
END IF
LET fecha_antes = fecha_ini - 1 UNITS DAY
SELECT UNIQUE p02_aux_prov_mb cuenta FROM cxpt002 INTO TEMP tmp_cta
SELECT * FROM tmp_cta WHERE cuenta = r_p00.p00_aux_prov_mb
IF STATUS = NOTFOUND THEN
	INSERT INTO tmp_cta VALUES (r_p00.p00_aux_prov_mb)
END IF
INSERT INTO tmp_cta SELECT UNIQUE p02_aux_ant_mb FROM cxpt002
SELECT * FROM tmp_cta WHERE cuenta = r_p00.p00_aux_ant_mb
IF STATUS = NOTFOUND THEN
	INSERT INTO tmp_cta VALUES (r_p00.p00_aux_ant_mb)
END IF
IF vm_contab <> 'M' THEN
	DISPLAY BY NAME r_p01.p01_codprov, r_p01.p01_nomprov
	LET expr_prov1 = '   AND p23_codprov     = ', r_p01.p01_codprov
	LET expr_prov2 = '   AND b13_codprov     = ', r_p01.p01_codprov
ELSE
	DISPLAY "*** TODOS LOS PROVEEDORES ***" TO p01_nomprov
	LET expr_prov1 = NULL
	LET expr_prov2 = NULL
END IF
DISPLAY BY NAME fecha_ini, fecha_fin, rm_par.moneda, rm_par.tit_mon
LET fecha2   = EXTEND(rm_par.fecha_cart, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET expr_fec = '   AND p22_fecing    <= "', fecha2, '"'
IF rm_par.fecha_emi IS NOT NULL THEN
	LET fecha1   = EXTEND(rm_par.fecha_emi, YEAR TO SECOND)
	LET expr_fec = '   AND p22_fecing    BETWEEN "', fecha1,
					      '" AND "', fecha2, '"'
END IF
ERROR "Procesando Movimientos en Tesorería . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT p23_tipo_trn, p23_num_trn, p22_fecha_emi, p22_referencia, ',
			' CASE WHEN p23_valor_cap + p23_valor_int > 0 ',
				' THEN p23_valor_cap + p23_valor_int ',
				' ELSE 0 ',
			' END valor_d, ',
			' CASE WHEN p23_valor_cap + p23_valor_int < 0 ',
				' THEN p23_valor_cap + p23_valor_int ',
				' ELSE 0 ',
			' END valor_f, ',
			' p23_valor_cap + p23_valor_int valor_m, ',
			' p23_localidad, p23_tipo_favor, p23_codprov ',
	       	' FROM cxpt023, cxpt022 ',
		' WHERE p23_compania   = ', vg_codcia,
		expr_prov1 CLIPPED,
		'   AND p22_compania   = p23_compania ',
		'   AND p22_localidad  = p23_localidad ',
		'   AND p22_codprov    = p23_codprov ',
		'   AND p22_tipo_trn   = p23_tipo_trn  ',
		'   AND p22_num_trn    = p23_num_trn ',
		expr_fec CLIPPED,
		' INTO TEMP tmp_mov_tes '
PREPARE exec_p23 FROM query
EXECUTE exec_p23
SELECT COUNT(*) INTO vm_num_tes FROM tmp_mov_tes
LET sal_ini_tes = 0
LET saldo_tes   = tot_sal
IF rm_par.fecha_emi IS NOT NULL THEN
	IF vm_contab <> 'M' THEN
		SELECT NVL(saldo_ini_tes, 0) INTO sal_ini_tes
			FROM tmp_sal_ini
			WHERE cod_prov_s = r_p01.p01_codprov
	END IF
END IF
IF rm_par.codprov IS NULL THEN
	IF vm_contab <> 'M' THEN
		SELECT NVL(SUM(saldo_doc), 0) INTO saldo_tes
			FROM tempo_doc
			WHERE codprov = r_p01.p01_codprov
		LET saldo_tes = saldo_tes + sal_ini_tes
	END IF
END IF
LET sig_tes = 0
IF vm_num_tes > 0 THEN
	DISPLAY BY NAME saldo_tes, sal_ini_tes
	LET query = 'SELECT * FROM tmp_mov_tes ORDER BY 3 DESC, 1'
	PREPARE mov_tes2 FROM query
	DECLARE q_mov_tes2 CURSOR FOR mov_tes2
	LET i           = 1
	LET tot_val_deu = 0
	LET tot_val_fav = 0
	FOREACH q_mov_tes2 INTO rm_tes[i].*, rm_aux[i].*
		LET tot_val_deu = tot_val_deu + rm_tes[i].val_deu 
		LET tot_val_fav = tot_val_fav + rm_tes[i].val_fav 
		LET i           = i + 1
		IF i > num_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
	IF vm_contab <> 'B' THEN
		LET sal_ini_tes = (saldo_tes * (-1) + tot_val_deu +
					tot_val_fav) * (-1)
	END IF
	DISPLAY BY NAME sal_ini_tes, tot_val_deu, tot_val_fav
	LET lim = vm_num_tes
	IF lim > fgl_scr_size('rm_tes') THEN
		LET lim = fgl_scr_size('rm_tes')
	END IF
	FOR i = 1 TO lim
		DISPLAY rm_tes[i].* TO rm_tes[i].*
	END FOR
	DISPLAY rm_tes[1].p22_referencia TO tit_referencia
	LET sig_tes = 1
END IF
ERROR "Procesando Movimientos en Contabilidad . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT * FROM ctbt013 ',
		' WHERE b13_compania    = ', vg_codcia,
		'   AND b13_fec_proceso BETWEEN "', vm_fecha_ini,
					 '" AND "', fecha_fin, '"',
		'   AND b13_cuenta     IN (SELECT UNIQUE cuenta FROM tmp_cta) ',
		expr_prov2 CLIPPED,
		' INTO TEMP tmp_b13'
PREPARE exec_b13 FROM query
EXECUTE exec_b13
DROP TABLE tmp_cta
LET query = 'SELECT NVL(SUM(b13_valor_base), 0) saldo_ini ',
		' FROM ctbt012, tmp_b13 ',
		' WHERE b12_compania    = ', vg_codcia,
		'   AND b12_estado      = "M" ',
		'   AND b12_moneda      = "', rm_par.moneda, '"',
		'   AND b13_compania    = b12_compania ',
		'   AND b13_tipo_comp   = b12_tipo_comp ',
		'   AND b13_num_comp    = b12_num_comp ',
		'   AND b13_fec_proceso <= "', fecha_antes, '"',
		' INTO TEMP t_sum'
PREPARE cons_sum2 FROM query
EXECUTE cons_sum2
SELECT * INTO sal_ini_con FROM t_sum
DISPLAY BY NAME sal_ini_con
DROP TABLE t_sum
LET query = 'SELECT b13_tipo_comp, b13_num_comp, b13_fec_proceso, ',
			' b13_glosa, NVL(CASE WHEN b13_valor_base >= 0 THEN ',
			' b13_valor_base END, 0) val_db, ',
			' NVL(CASE WHEN b13_valor_base < 0 THEN ',
			' b13_valor_base END, 0)  val_cr, ',
			' b13_valor_base val_db_cr ',
		' FROM ctbt012, tmp_b13 ',
		' WHERE b12_compania    = ', vg_codcia,
		'   AND b12_estado      = "M" ',
		'   AND b12_moneda      = "', rm_par.moneda, '"',
		'   AND b13_compania    = b12_compania ',
		'   AND b13_tipo_comp   = b12_tipo_comp ',
		'   AND b13_num_comp    = b12_num_comp ',
		'   AND b13_fec_proceso > "', fecha_antes, '"',
		' INTO TEMP tmp_mov_con '
PREPARE exec_b13_1 FROM query
EXECUTE exec_b13_1
SELECT COUNT(*) INTO vm_num_con FROM tmp_mov_con
DROP TABLE tmp_b13
IF vm_num_tes = 0 AND vm_num_con = 0 THEN
	DROP TABLE tmp_mov_tes
	DROP TABLE tmp_mov_con
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_tes_cont
	RETURN
END IF
IF vm_num_tes > num_max_doc THEN
	LET vm_num_tes = num_max_doc
END IF
IF vm_num_con > num_max_doc THEN
	LET vm_num_con = num_max_doc
END IF
IF vm_num_tes = num_max_doc OR vm_num_con > num_max_doc THEN
	CALL fl_mostrar_mensaje('Solo se mostraran un maximo de ' || num_max_doc || ' líneas de detalle ya que la aplicación solo soporta esta cantidad.', 'info')
END IF
LET sig_con = 0
IF vm_num_con > 0 THEN
	LET query = 'SELECT * FROM tmp_mov_con ORDER BY 3 DESC, 4'
	PREPARE mov_con2 FROM query
	DECLARE q_mov_con2 CURSOR FOR mov_con2
	LET i          = 1
	LET tot_val_db = 0
	LET tot_val_cr = 0
	FOREACH q_mov_con2 INTO rm_cont[i].*
		LET tot_val_db = tot_val_db + rm_cont[i].val_db 
		LET tot_val_cr = tot_val_cr + rm_cont[i].val_cr 
		LET i          = i + 1
		IF i > num_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
	IF vm_num_con = num_max_doc THEN
		SELECT NVL(SUM(val_db), 1), NVL(SUM(val_cr), 0)
			INTO tot_val_db, tot_val_cr
			FROM tmp_mov_con
			WHERE b13_fec_proceso > fecha_antes
	END IF
	LET saldo_cont   = sal_ini_con + tot_val_db + tot_val_cr
	LET v_saldo_cont = saldo_cont
	IF v_saldo_cont < 0 THEN
		LET v_saldo_cont = v_saldo_cont * (-1)
	END IF
	LET v_saldo_tes = saldo_tes
	IF v_saldo_tes < 0 THEN
		LET v_saldo_tes = v_saldo_tes * (-1)
	END IF
	IF saldo_cont > saldo_tes THEN
		LET val_des = v_saldo_cont - v_saldo_tes
	ELSE
		LET val_des = v_saldo_tes - v_saldo_cont
	END IF
	DISPLAY BY NAME tot_val_db, tot_val_cr, saldo_cont, val_des
	LET lim = vm_num_con
	IF lim > fgl_scr_size('rm_cont') THEN
		LET lim = fgl_scr_size('rm_cont')
	END IF
	FOR i = 1 TO lim
		DISPLAY rm_cont[i].* TO rm_cont[i].*
	END FOR
	IF sig_tes = 0 THEN
		LET sig_con = 1
	END IF
	DISPLAY rm_cont[1].b13_glosa TO tit_glosa
END IF
ERROR ' '
CALL mostrar_contadores_tes_con(0, vm_num_tes, 0, vm_num_con)
LET p1 = 1
LET p2 = 1
LET p3 = 1
LET p4 = 1
WHILE TRUE
	IF sig_tes = 1 THEN
		CALL detalle_tesoreria(p1,p2) RETURNING sig_con, p1, p2
	END IF
	IF sig_con = 1 THEN
		CALL detalle_contabilidad(p3, p4) RETURNING sig_tes, p3, p4
	END IF
	IF sig_tes = 0 THEN
		EXIT WHILE
	END IF
	IF sig_con = 0 THEN
		EXIT WHILE
	END IF
END WHILE
DROP TABLE tmp_mov_tes
DROP TABLE tmp_mov_con
CLOSE WINDOW w_tes_cont

END FUNCTION



FUNCTION detalle_tesoreria(pos_pan, pos_arr)
DEFINE pos_pan, pos_arr	INTEGER
DEFINE query		VARCHAR(200)
DEFINE i, col		INTEGER
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE sig_tes		SMALLINT

FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'DESC'
LET columna_1  = 3
LET columna_2  = 1
WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_num_tes)
	DISPLAY ARRAY rm_tes TO rm_tes.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			LET sig_tes  = 0
			EXIT DISPLAY
		ON KEY(F5)
			IF vm_num_con = 0 THEN
				CONTINUE DISPLAY
			END IF
			LET int_flag = 1
			LET sig_tes  = 1
			LET pos_pan  = scr_line()
			LET pos_arr  = arr_curr()
			EXIT DISPLAY
		ON KEY(F6)
			LET i = arr_curr()
			CALL muestra_cheque_emitido(vg_codcia,rm_aux[i].codprov,
							rm_tes[i].p23_tipo_trn,
							rm_tes[i].p23_num_trn) 
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_documento_tran(vg_codcia, rm_aux[i].codprov,
				rm_tes[i].p23_tipo_trn, rm_tes[i].p23_num_trn,
				rm_aux[i].loc, rm_aux[i].tipo)
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
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_tes_con(i, vm_num_tes,
							--#0, vm_num_con)
			--#DISPLAY rm_tes[i].p22_referencia TO tit_referencia
		--#BEFORE DISPLAY
			--#CALL dialog.setcurrline(pos_pan, pos_arr)
			--#CALL mostrar_contadores_tes_con(pos_arr, vm_num_tes,
							--#0, vm_num_con)
			--#DISPLAY rm_tes[pos_arr].p22_referencia TO
				--#tit_referencia
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("F5","Detalle Contabi.")
			--#IF vm_num_con = 0 THEN
				--#CALL dialog.keysetlabel("F5","")
			--#END IF
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
	LET query = 'SELECT * FROM tmp_mov_tes ',
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE mov_tes3 FROM query
	DECLARE q_mov_tes3 CURSOR FOR mov_tes3
	LET i = 1
	FOREACH q_mov_tes3 INTO rm_tes[i].*, rm_aux[i].*
		LET i = i + 1
		IF i > num_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
END WHILE
CALL mostrar_contadores_tes_con(0, vm_num_tes, 0, vm_num_con)
RETURN sig_tes, pos_pan, pos_arr

END FUNCTION



FUNCTION detalle_contabilidad(pos_pan, pos_arr)
DEFINE pos_pan, pos_arr	INTEGER
DEFINE query		VARCHAR(200)
DEFINE i, col		INTEGER
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE sig_con		SMALLINT

FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'DESC'
LET columna_1  = 3
LET columna_2  = 4
WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_num_con)
	DISPLAY ARRAY rm_cont TO rm_cont.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			LET sig_con  = 0
			EXIT DISPLAY
		ON KEY(F5)
			IF vm_num_tes = 0 THEN
				CONTINUE DISPLAY
			END IF
			LET int_flag = 1
			LET sig_con  = 1
			LET pos_pan  = scr_line()
			LET pos_arr  = arr_curr()
			EXIT DISPLAY
		ON KEY(F8)
			LET i = arr_curr()
			CALL ver_diario_contable(rm_cont[i].b13_tipo_comp,
						 rm_cont[i].b13_num_comp)
			LET int_flag = 0
		ON KEY(F22)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F23)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F24)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F25)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F26)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F27)
			LET col      = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F28)
			LET col      = 7
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_tes_con(0, vm_num_tes,
							--#i, vm_num_con)
			--#DISPLAY rm_cont[i].b13_glosa TO tit_glosa
		--#BEFORE DISPLAY
			--#CALL dialog.setcurrline(pos_pan, pos_arr)
			--#CALL mostrar_contadores_tes_con(0, vm_num_tes,
							--#pos_arr, vm_num_con)
			--#DISPLAY rm_cont[pos_arr].b13_glosa TO tit_glosa
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("F5","Detalle Tesorería")
			--#IF vm_num_tes = 0 THEN
				--#CALL dialog.keysetlabel("F5","")
			--#END IF
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
	LET query = 'SELECT * FROM tmp_mov_con ',
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE mov_con3 FROM query
	DECLARE q_mov_con3 CURSOR FOR mov_con3
	LET i = 1
	FOREACH q_mov_con3 INTO rm_cont[i].*
		LET i = i + 1
		IF i > num_max_doc THEN
			EXIT FOREACH
		END IF
	END FOREACH
END WHILE
CALL mostrar_contadores_tes_con(0, vm_num_tes, 0, vm_num_con)
RETURN sig_con, pos_pan, pos_arr

END FUNCTION



FUNCTION mostrar_contadores_tes_con(num_row_tes, max_row_tes, num_row_con,
					max_row_con)
DEFINE num_row_tes	INTEGER
DEFINE max_row_tes	INTEGER
DEFINE num_row_con	INTEGER
DEFINE max_row_con	INTEGER

DISPLAY BY NAME num_row_tes, max_row_tes, num_row_con, max_row_con

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
OPEN FORM f_cxpf315_6 FROM "../forms/cxpf315_6"
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
		CALL ver_diario_contable(r_p24.p24_tip_contable,
					 r_p24.p24_num_contable)
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU
LET int_flag = 0
CLOSE WINDOW w_pch

END FUNCTION



FUNCTION ver_orden_compra(numero_oc)
DEFINE numero_oc	LIKE cxpt020.p20_numero_oc
DEFINE comando          VARCHAR(200)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COMPRAS',
		vg_separador, 'fuentes', vg_separador, '; fglrun ordp200 ',
		vg_base, ' OC ', vg_codcia, ' ', vg_codloc, ' ', numero_oc
RUN comando

END FUNCTION



FUNCTION ver_estado_cuenta(codprov)
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE comando		VARCHAR(200)
DEFINE param		VARCHAR(15)

LET param = ' 0 '
IF rm_par.fecha_emi IS NOT NULL THEN
	LET param = rm_par.fecha_emi
END IF
LET comando = 'fglrun cxpp314 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		vg_codloc, ' ', rm_par.moneda, ' ', rm_par.fecha_cart, ' ',
		rm_par.ind_venc, ' ', 0.01, ' ', rm_par.incluir_sal,
		' ', codprov, ' ', param CLIPPED, ' ', rm_par.fecha_vcto1, ' ',
		rm_par.fecha_vcto2
RUN comando

END FUNCTION



FUNCTION ver_documento(codprov, numdoc, dividendo, tipo, i)
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE numdoc		LIKE cxpt020.p20_num_doc
DEFINE dividendo	LIKE cxpt020.p20_dividendo
DEFINE tipo		LIKE cxpt004.p04_tipo
DEFINE i		INTEGER
DEFINE prog		VARCHAR(10)
DEFINE expr		VARCHAR(40)
DEFINE comando          VARCHAR(200)

LET prog = 'cxpp200 '
LET expr = dividendo, ' ', rm_par.fecha_cart
IF tipo = 'F' THEN
	LET prog = 'cxpp201 '
	LET expr = ' ', rm_par.fecha_cart
END IF
LET comando = 'fglrun ', prog CLIPPED, ' ', vg_base, ' ', vg_modulo, ' ',
		vg_codcia, ' ',	vg_codloc, ' ', codprov, ' ',
		rm_doc[i].cladoc, ' ', numdoc, ' ', expr CLIPPED
RUN comando

END FUNCTION



FUNCTION ver_documento_tran(codcia, codprov, tipo_trn, num_trn, loc, tipo)
DEFINE codcia		LIKE cxpt022.p22_compania
DEFINE codprov		LIKE cxpt022.p22_codprov
DEFINE tipo_trn		LIKE cxpt022.p22_tipo_trn
DEFINE num_trn		LIKE cxpt022.p22_num_trn
DEFINE loc		LIKE cxpt022.p22_localidad
DEFINE tipo		LIKE cxpt023.p23_tipo_favor
DEFINE comando		VARCHAR(200)
DEFINE run_prog		CHAR(10)
DEFINE prog		CHAR(10)

{- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE -}
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
{--- ---}
LET prog = 'cxpp202 '
IF tipo IS NOT NULL THEN
	LET prog = 'cxpp203 '
END IF
LET comando = run_prog, prog, vg_base, ' ', vg_modulo, ' ', codcia, ' ', loc,
		' ', codprov, ' ', tipo_trn, ' ', num_trn
RUN comando

END FUNCTION



FUNCTION ver_diario_contable(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt013.b13_tipo_comp
DEFINE num_comp		LIKE ctbt013.b13_num_comp
DEFINE comando		VARCHAR(200)
DEFINE run_prog		CHAR(10)

{- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE -}
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
		vg_separador, 'fuentes', vg_separador, '; ', run_prog,
		'ctbp201 ', vg_base, ' "CB" ', vg_codcia, ' ', tipo_comp, ' ',
		num_comp
RUN comando

END FUNCTION



FUNCTION control_archivo()

ERROR 'Generando Archivo cxpp315.unl ... por favor espere'
UNLOAD TO "cxpp315.unl"
	SELECT cladoc, numdoc, localidad, codprov, nomprov, fecha,
		valor_doc, saldo_doc
		FROM tempo_doc
		ORDER BY 4 ASC, 2 ASC
RUN 'mv cxpp315.unl $HOME/tmp/cxpp315.unl'
CALL fl_mostrar_mensaje('Archivo Generado cxpp315.unl', 'info')
ERROR ' '

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		INTEGER

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT report_list_proveedor TO PIPE comando
FOR i = 1 TO num_doc
	OUTPUT TO REPORT report_list_proveedor(i)
END FOR
FINISH REPORT report_list_proveedor

END FUNCTION



REPORT report_list_proveedor(i)
DEFINE i		INTEGER
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE factura		VARCHAR(15)
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*

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
	PRINT COLUMN 001, r_g01.g01_razonsocial,
  	      COLUMN 070, "PAGINA: ", PAGENO USING '&&&'
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 024, "ANALISIS CARTERA DETALLE POR FECHA",
	      COLUMN 074, UPSHIFT(vg_proceso) 
	SKIP 1 LINES
	PRINT COLUMN 015, "** MONEDA            : ", rm_par.moneda,
		" ", rm_par.tit_mon
	IF rm_par.tipprov IS NOT NULL THEN
		PRINT COLUMN 015, "** TIPO PROVEEDOR      : ",
			rm_par.tipprov USING '<<<&', " ", rm_par.tit_tipprov
	END IF
	IF rm_par.tipcar IS NOT NULL THEN
		PRINT COLUMN 015, "** TIPO CARTERA      : ",
			rm_par.tipcar USING '<<<&', " ", rm_par.tit_tipcar
	END IF
	IF rm_par.codprov IS NOT NULL THEN
		PRINT COLUMN 015, "** PROVEEDOR         : ",
			rm_par.codprov USING '<<<<<&', " ",
			rm_par.nom_prov[1, 40] CLIPPED
	END IF
	IF rm_par.ind_doc <> 'F' THEN
		PRINT COLUMN 015, "** TIPO DE VENCTO.   : ", rm_par.ind_venc,
			" ", retorna_tipo_vencto(rm_par.ind_venc)
	END IF
	PRINT COLUMN 015, "** TIPO DE DOCUMENTO : ", rm_par.ind_doc, " ",
		retorna_tipo_doc(rm_par.ind_doc)
	PRINT COLUMN 015, "** CARTERA DETALLE AL: ",
		rm_par.fecha_cart USING 'dd-mm-yyyy'
	IF rm_par.fecha_vcto1 IS NOT NULL THEN
		PRINT COLUMN 015, "** RANGO VENCIMIENTOS: ",
			rm_par.fecha_vcto1 USING 'dd-mm-yyyy', ' - ',
			rm_par.fecha_vcto2 USING 'dd-mm-yyyy'
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "TP",
	      COLUMN 008, "DOCUMENTOS",
	      COLUMN 023, "P R O V E E D O R E S",
	      COLUMN 045, "FEC. VCTO.",
	      COLUMN 056, "VALOR DOCUM.",
	      COLUMN 069, "SALDO DOCUM."
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_doc[i].cladoc,
	      COLUMN 004, rm_doc[i].numdoc		CLIPPED,
	      COLUMN 023, rm_doc[i].nomprov[1, 21]	CLIPPED,
	      COLUMN 045, rm_doc[i].fecha		USING "dd-mm-yyyy",
	      COLUMN 056, rm_doc[i].valor		USING "-,---,--&.##",
	      COLUMN 069, rm_doc[i].saldo		USING "-,---,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 056, "------------",
	      COLUMN 069, "------------"
	PRINT COLUMN 043, "TOTALES ==>  ",
	      COLUMN 056, tot_val			USING "-,---,--&.##",
	      COLUMN 069, tot_sal			USING "-,---,--&.##"

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



FUNCTION retorna_tipo_doc(tipo)
DEFINE tipo		CHAR(1)
DEFINE tipo_nom		VARCHAR(10)

CASE tipo
	WHEN 'D'
		LET tipo_nom = 'DEUDOR'
	WHEN 'F'
		LET tipo_nom = 'A FAVOR'
	WHEN 'T'
		LET tipo_nom = 'T O D O S'
END CASE
RETURN tipo_nom

END FUNCTION
