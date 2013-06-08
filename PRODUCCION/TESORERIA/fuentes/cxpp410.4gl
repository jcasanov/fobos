--------------------------------------------------------------------------------
-- Titulo              : cxpp410.4gl --  Listado de Retenciones Proveedores
-- Elaboración         : 01-Abr-2002
-- Autor               : NPC
-- Formato de Ejecución: fglrun cxcp410 base modulo compañía localidad
-- Ultima Correción    : 07-Abr-2006 (NPC)
-- Motivo Corrección   : Varias correcciones
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_par		RECORD
				moneda		LIKE gent013.g13_moneda,
				inicial		DATE,
				final		DATE,
				proveedor	LIKE cxpt001.p01_codprov,
				tipo_oc		LIKE ordt001.c01_tipo_orden,
				tipo_porc	LIKE ordt002.c02_tipo_ret,
				valor_porc	LIKE ordt002.c02_porcentaje,
				cod_sri		LIKE ordt003.c03_codigo_sri,
				fec_ini_por	LIKE ordt003.c03_fecha_ini_porc,
				des_sri		LIKE ordt003.c03_concepto_ret,
				agrup_p		CHAR(1),
				agrup_s		CHAR(1)
			END RECORD
DEFINE rm_consulta	RECORD 
				codigo_sri	LIKE cxpt028.p28_codigo_sri,
				proveedor	LIKE cxpt001.p01_nomprov,
				fecha_retencion	LIKE cxpt020.p20_fecha_emi,
				num_retencion	LIKE cxpt028.p28_num_ret,
				num_factura     LIKE cxpt028.p28_num_doc,
				fecha_factura	LIKE cxpt020.p20_fecha_emi,
				tipo_retencion	LIKE cxpt028.p28_tipo_ret,
				moneda		LIKE cxpt027.p27_moneda,
				valor_base	LIKE cxpt028.p28_valor_base,
				porc_retencion	LIKE cxpt028.p28_porcentaje,
				valor_retencion LIKE cxpt028.p28_valor_ret,
				codprov		LIKE cxpt001.p01_codprov,
				num_ret_sri	LIKE cxpt029.p29_num_sri
			END RECORD
DEFINE vm_tot_bas	DECIMAL(12,2)
DEFINE vm_tot_ret	DECIMAL(12,2)
DEFINE vm_page 		SMALLINT
DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CALL startlog('../logs/cxpp410.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxpp410'
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
DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_nivel_isolation()
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
OPEN WINDOW w_cxpf410_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf410_1 FROM '../forms/cxpf410_1'
ELSE
	OPEN FORM f_cxpf410_1 FROM '../forms/cxpf410_1c'
END IF
DISPLAY FORM f_cxpf410_1
LET vm_top	= 1
LET vm_left	= 2
LET vm_right	= 132
LET vm_bottom	= 4
LET vm_page	= 66
INITIALIZE rm_par.* TO NULL 
LET rm_par.moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO desc_moneda
LET rm_par.inicial  = MDY(MONTH(TODAY), 01, YEAR(TODAY))
LET rm_par.final    = TODAY
LET rm_par.agrup_p  = 'N'
LET rm_par.agrup_s  = 'N'
WHILE TRUE
	CALL control_ingreso()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_reporte()
END WHILE
CLOSE WINDOW w_cxpf410_1
EXIT PROGRAM

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_moneda		RECORD LIKE gent013.*
DEFINE r_proveedor	RECORD LIKE cxpt001.*
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_c03		RECORD LIKE ordt003.*
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE nombre_mon	LIKE gent013.g13_nombre
DEFINE decimales	LIKE gent013.g13_decimales
DEFINE proveedor	LIKE cxpt001.p01_codprov
DEFINE desc_proveedor	LIKE cxpt001.p01_nomprov
DEFINE cod_pago		LIKE cajt091.j91_codigo_pago
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE resp		CHAR(6)

LET int_flag = 0
INPUT BY NAME rm_par.moneda, rm_par.inicial, rm_par.final, rm_par.proveedor,
	rm_par.tipo_oc, rm_par.tipo_porc, rm_par.valor_porc, rm_par.cod_sri,
	rm_par.fec_ini_por, rm_par.agrup_p, rm_par.agrup_s
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.moneda, rm_par.inicial,
				rm_par.final, rm_par.proveedor,
				rm_par.tipo_oc, rm_par.tipo_porc,
				rm_par.valor_porc, rm_par.cod_sri,
				rm_par.fec_ini_por, rm_par.agrup_p,
				rm_par.agrup_s)
		THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING moneda, nombre_mon, decimales
			IF moneda IS NOT NULL THEN
				LET rm_par.moneda = moneda
				DISPLAY moneda TO moneda
				DISPLAY nombre_mon TO desc_moneda
			END IF
		END IF
		IF INFIELD(proveedor) THEN
			CALL fl_ayuda_proveedores()
				RETURNING proveedor, desc_proveedor
			IF proveedor IS NOT NULL THEN 
				LET rm_par.proveedor = proveedor
				DISPLAY proveedor TO proveedor
				DISPLAY desc_proveedor TO desc_prov
			END IF
		END IF
		IF INFIELD(tipo_oc) THEN
			CALL fl_ayuda_tipos_ordenes_compras('T')
				RETURNING r_c01.c01_tipo_orden,
					  r_c01.c01_nombre
			IF r_c01.c01_tipo_orden IS NOT NULL THEN
				LET rm_par.tipo_oc = r_c01.c01_tipo_orden
				DISPLAY BY NAME rm_par.tipo_oc
				DISPLAY r_c01.c01_nombre TO desc_tipo
			END IF 
		END IF
		IF INFIELD(tipo_porc) THEN
			IF vg_gui = 0 THEN
				CONTINUE INPUT
			END IF
			CALL ayuda_tipo_retencion() RETURNING r_c02.c02_tipo_ret
			IF r_c02.c02_tipo_ret IS NOT NULL THEN
				LET rm_par.tipo_porc = r_c02.c02_tipo_ret
				DISPLAY BY NAME rm_par.tipo_porc
			END IF
		END IF
		IF INFIELD(valor_porc) THEN
			LET cod_pago = NULL
			CALL fl_ayuda_retenciones(vg_codcia, cod_pago, 'A')
				RETURNING r_c02.c02_tipo_ret,
					  r_c02.c02_porcentaje,
					  r_c02.c02_nombre
			IF r_c02.c02_tipo_ret IS NOT NULL THEN
				LET rm_par.tipo_porc  = r_c02.c02_tipo_ret
				LET rm_par.valor_porc = r_c02.c02_porcentaje
				DISPLAY BY NAME rm_par.tipo_porc,
						rm_par.valor_porc
				DISPLAY r_c02.c02_nombre TO desc_porc
			END IF
		END IF
		IF INFIELD(cod_sri) THEN
			LET codprov = rm_par.proveedor
			IF rm_par.proveedor IS NULL THEN
				LET codprov = 1
			END IF
			CALL fl_ayuda_codigos_sri(vg_codcia,
					rm_par.tipo_porc,
					rm_par.valor_porc, 'A',
					codprov, 'P')
				RETURNING r_c03.c03_codigo_sri,
					  r_c03.c03_concepto_ret,
					  r_c03.c03_fecha_ini_porc
			IF r_c03.c03_codigo_sri IS NOT NULL THEN
				LET rm_par.cod_sri = r_c03.c03_codigo_sri
				LET rm_par.fec_ini_por =r_c03.c03_fecha_ini_porc
				LET rm_par.des_sri = r_c03.c03_concepto_ret
				DISPLAY BY NAME rm_par.cod_sri, rm_par.des_sri,
						rm_par.fec_ini_por
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) 
				RETURNING r_moneda.*
				
			IF r_moneda.g13_moneda IS NULL THEN
				CALL fl_mostrar_mensaje('No existe moneda.','exclamation')
				NEXT FIELD moneda
			ELSE
				DISPLAY r_moneda.g13_nombre TO desc_moneda
			END IF
		ELSE
			CLEAR desc_moneda
		END IF
	AFTER FIELD proveedor
		IF rm_par.proveedor IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_par.proveedor) 
				RETURNING r_proveedor.*
				
			IF r_proveedor.p01_codprov IS NULL THEN
				CALL fl_mostrar_mensaje('No existe proveedor.','exclamation')
				NEXT FIELD proveedor
			ELSE
				DISPLAY r_proveedor.p01_nomprov 
					TO desc_prov
			END IF
		ELSE
			CLEAR desc_prov
		END IF
	AFTER FIELD tipo_oc
		IF rm_par.tipo_oc IS NOT NULL THEN
			CALL fl_lee_tipo_orden_compra(rm_par.tipo_oc)
				RETURNING r_c01.*
			IF r_c01.c01_tipo_orden IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el tipo de orden en la Compañía.', 'exclamation')
				NEXT FIELD tipo_oc
			END IF
			DISPLAY r_c01.c01_nombre TO desc_tipo
		ELSE
			CLEAR desc_tipo
		END IF
	AFTER FIELD tipo_porc, valor_porc
		IF rm_par.tipo_porc IS NULL AND rm_par.valor_porc IS NULL THEN
			INITIALIZE rm_par.tipo_porc, rm_par.valor_porc TO NULL
			CLEAR tipo_porc, valor_porc, desc_porc
			CONTINUE INPUT
		END IF
		IF rm_par.tipo_porc IS NOT NULL AND
		   rm_par.valor_porc IS NOT NULL
		THEN
			CALL fl_lee_tipo_retencion(vg_codcia, rm_par.tipo_porc,
							rm_par.valor_porc)
				RETURNING r_c02.*
			DISPLAY r_c02.c02_nombre TO desc_porc
			IF r_c02.c02_tipo_ret IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el tipo de retención en la Compañía.', 'exclamation')
				NEXT FIELD valor_porc
			END IF
			LET rm_par.tipo_porc  = r_c02.c02_tipo_ret
			LET rm_par.valor_porc = r_c02.c02_porcentaje
			DISPLAY BY NAME rm_par.tipo_porc, rm_par.valor_porc
			DISPLAY r_c02.c02_nombre TO desc_porc
			CONTINUE INPUT
		END IF
	AFTER FIELD cod_sri
		IF rm_par.cod_sri IS NOT NULL THEN
			CALL fl_lee_codigos_sri(vg_codcia,
						rm_par.tipo_porc,
						rm_par.valor_porc,
						rm_par.cod_sri,
						rm_par.fec_ini_por)
				RETURNING r_c03.*
			IF r_c03.c03_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe configurado este codigo del SRI.', 'exclamation')
				NEXT FIELD cod_sri
			END IF
			LET rm_par.des_sri = r_c03.c03_concepto_ret
			DISPLAY BY NAME rm_par.des_sri
		ELSE
			CLEAR des_sri
		END IF
	AFTER INPUT  
		IF rm_par.inicial IS NULL OR rm_par.final IS NULL THEN
			NEXT FIELD inicial
		END IF
		IF rm_par.inicial > rm_par.final THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual que la fecha final.','exclamation')
			CONTINUE INPUT
		END IF
		{--
		IF rm_par.tipo_porc IS NOT NULL THEN
			IF rm_par.valor_porc IS NULL THEN
				NEXT FIELD valor_porc
			END IF
		END IF
		IF rm_par.valor_porc IS NOT NULL THEN
			IF rm_par.tipo_porc IS NULL THEN
				NEXT FIELD tipo_porc
			END IF
		END IF
		--}
END INPUT

END FUNCTION



FUNCTION control_reporte()

IF NOT prepapar_temporal() THEN
	RETURN
END IF
CALL generar_archivo()
IF rm_par.agrup_p = 'N' AND rm_par.agrup_s = 'N' THEN
	CALL imprimir_listado_simple()
END IF
IF rm_par.agrup_p = 'S' THEN
	CALL imprimir_listado_agrup_p()
END IF
IF rm_par.agrup_s = 'S' THEN
	CALL imprimir_listado_agrup_s()
END IF
DROP TABLE tmp_ret

END FUNCTION



FUNCTION prepapar_temporal()
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE cuantos	 	SMALLINT
DEFINE query 		CHAR(3500)
DEFINE comando          VARCHAR(100)
DEFINE estado		CHAR(1)
DEFINE tabla		VARCHAR(10)
DEFINE string		VARCHAR(100)
DEFINE expr_sri		VARCHAR(200)
DEFINE expr_ret		VARCHAR(200)
DEFINE expr_oc		CHAR(500)

LET string = NULL
IF rm_par.proveedor IS NOT NULL THEN
	LET string = ' AND p27_codprov = ', rm_par.proveedor
END IF
LET expr_ret = NULL
IF rm_par.tipo_porc IS NOT NULL AND rm_par.valor_porc IS NOT NULL THEN
	LET expr_ret = '   AND p28_tipo_ret     = "', rm_par.tipo_porc, '"',
			'   AND p28_porcentaje   = ', rm_par.valor_porc
END IF
IF rm_par.tipo_porc IS NOT NULL AND rm_par.valor_porc IS NULL THEN
	LET expr_ret = '   AND p28_tipo_ret     = "', rm_par.tipo_porc, '"'
END IF
IF rm_par.tipo_porc IS NULL AND rm_par.valor_porc IS NOT NULL THEN
	LET expr_ret = '   AND p28_porcentaje   = ', rm_par.valor_porc
END IF
LET expr_sri = NULL
IF rm_par.cod_sri IS NOT NULL THEN
	LET expr_sri = ' AND p28_codigo_sri = "', rm_par.cod_sri, '"',
			' AND p28_fecha_ini_porc = "', rm_par.fec_ini_por, '"'
END IF
LET tabla   = NULL
LET expr_oc = NULL
IF rm_par.tipo_oc IS NOT NULL THEN
	LET tabla   = ', ordt010'
	LET expr_oc = ' WHERE c10_compania     = p20_compania ',
			'   AND c10_localidad    = p20_localidad ',
			'   AND c10_numero_oc    = p20_numero_oc ',
			'   AND c10_codprov      = p20_codprov ',
			'   AND c10_tipo_orden   = ', rm_par.tipo_oc,
			'   AND c10_estado       = "C" ',
			'   AND c10_fecha_fact   = p20_fecha_emi '
END IF
LET query = 'SELECT p28_codigo_sri, p01_nomprov, p27_fecing, p28_num_ret,',
		' p28_num_doc, p20_fecha_emi, p28_tipo_ret,',
		' p27_moneda, p28_valor_base, p28_porcentaje,',
		' p28_valor_ret, p20_compania, p20_localidad, ',
		' p20_numero_oc, p20_codprov, p29_num_sri ',
		' FROM cxpt027, cxpt028, cxpt029, cxpt020, cxpt001',
		' WHERE p27_compania     = ', vg_codcia,
		'   AND p27_localidad    = ', vg_codloc,
		'   AND p27_estado       = "A" ',
		'   AND p27_moneda       = "', rm_par.moneda, '"',
		string CLIPPED,
		'   AND DATE(p27_fecing) BETWEEN "', rm_par.inicial,
					  '" AND "', rm_par.final, '"',
		'   AND p28_compania     = p27_compania ',
		'   AND p28_localidad    = p27_localidad ',
		'   AND p28_num_ret      = p27_num_ret ',
		'   AND p28_codprov      = p27_codprov ',
		expr_ret CLIPPED,
		expr_sri CLIPPED,
		'   AND p29_compania     = p27_compania ',
		'   AND p29_localidad    = p27_localidad ',
		'   AND p29_num_ret      = p27_num_ret ',
		'   AND p20_compania     = p28_compania ',
		'   AND p20_localidad    = p28_localidad ',
		'   AND p20_codprov      = p28_codprov ',
		'   AND p20_tipo_doc     = p28_tipo_doc ',
		'   AND p20_num_doc      = p28_num_doc ',
		'   AND p20_dividendo    = p28_dividendo ',
		'   AND p01_codprov      = p20_codprov ',
		' INTO TEMP tmp_ret '
PREPARE gen_tmp FROM query
EXECUTE gen_tmp
LET query = 'SELECT p28_codigo_sri, p01_nomprov, p27_fecing, p28_num_ret,',
		' p28_num_doc, p20_fecha_emi, p28_tipo_ret,',
		' p27_moneda, p28_valor_base, p28_porcentaje,',
		' p28_valor_ret, p20_codprov, p29_num_sri ',
		' FROM tmp_ret', tabla CLIPPED,
		expr_oc CLIPPED,
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DROP TABLE tmp_ret
SELECT COUNT(*) INTO cuantos FROM t1
IF cuantos = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE t1
	RETURN 0
END IF
SELECT * FROM t1 INTO TEMP tmp_ret
DROP TABLE t1
RETURN 1

END FUNCTION



FUNCTION generar_archivo()
DEFINE comando          VARCHAR(100)
DEFINE registro		CHAR(400)
DEFINE resp		CHAR(6)
DEFINE enter		SMALLINT

CALL fl_hacer_pregunta('Desea generar también un archivo de texto ?',
			'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
LET enter = 13
DECLARE q_rep1 CURSOR FOR SELECT * FROM tmp_ret ORDER BY 3, 4, 2, 7, 10
FOREACH q_rep1 INTO rm_consulta.*
	--LET registro = rm_consulta.codigo_sri CLIPPED, '|',
	LET registro = rm_consulta.proveedor CLIPPED, '|',
			DATE(rm_consulta.fecha_retencion) USING "dd-mm-yyyy",
			'|', rm_consulta.num_retencion CLIPPED, '|',
			rm_consulta.num_factura CLIPPED, '|',
			rm_consulta.fecha_factura USING "dd-mm-yyyy", '|',
			rm_consulta.tipo_retencion CLIPPED, '|',
			rm_consulta.moneda CLIPPED, '|',
			rm_consulta.porc_retencion USING '##&.##', '|',
			rm_consulta.valor_base USING '#,###,##&.##','|',
			rm_consulta.valor_retencion USING '#,###,##&.##'
	IF vg_gui = 1 THEN
		--#DISPLAY registro CLIPPED, ASCII(enter)
	ELSE
		DISPLAY registro CLIPPED
	END IF
END FOREACH
LET comando = 'mv ', vg_proceso CLIPPED, '.txt $HOME/tmp'
RUN comando
CALL fl_mostrar_mensaje('Se generó el Archivo ' || vg_proceso CLIPPED || '.txt', 'info')

END FUNCTION



FUNCTION imprimir_listado_simple()
DEFINE comando          VARCHAR(100)

LET int_flag = 0
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_retenciones01 TO PIPE comando
DECLARE q_rep CURSOR FOR SELECT * FROM tmp_ret ORDER BY 3, 4, 2, 7, 10
FOREACH q_rep INTO rm_consulta.*
	OUTPUT TO REPORT reporte_retenciones01(rm_consulta.*)
END FOREACH
FINISH REPORT reporte_retenciones01

END FUNCTION



FUNCTION imprimir_listado_agrup_p()
DEFINE r_ret		RECORD
				codprov		LIKE cxpt001.p01_codprov,
				nomprov		LIKE cxpt001.p01_nomprov
			END RECORD
DEFINE comando          VARCHAR(100)

LET int_flag = 0
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_retenciones03 TO PIPE comando
DECLARE q_rep3 CURSOR FOR
	SELECT UNIQUE p20_codprov, p01_nomprov
		FROM tmp_ret
		ORDER BY 2
FOREACH q_rep3 INTO r_ret.*
	DECLARE q_sri2 CURSOR FOR
		SELECT * FROM tmp_ret
			WHERE p20_codprov = r_ret.codprov
			ORDER BY 3, 4, 2
	FOREACH q_sri2 INTO rm_consulta.*
		OUTPUT TO REPORT reporte_retenciones03(r_ret.*, rm_consulta.*)
	END FOREACH
END FOREACH
FINISH REPORT reporte_retenciones03

END FUNCTION



FUNCTION imprimir_listado_agrup_s()
DEFINE r_ret		RECORD
				tipo		LIKE ordt003.c03_tipo_ret,
				porc		LIKE ordt003.c03_porcentaje,
				cod_sri		LIKE ordt003.c03_codigo_sri,
				fec_ini_p	LIKE ordt003.c03_fecha_ini_porc,
				des_sri		LIKE ordt003.c03_concepto_ret
			END RECORD
DEFINE comando          VARCHAR(100)

LET int_flag = 0
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_retenciones02 TO PIPE comando
DECLARE q_rep2 CURSOR FOR
	SELECT UNIQUE p28_tipo_ret, p28_porcentaje, p28_codigo_sri,
		c03_concepto_ret
		FROM tmp_ret, ordt003
		WHERE c03_compania   = vg_codcia
		  AND c03_tipo_ret   = p28_tipo_ret
		  AND c03_porcentaje = p28_porcentaje
		  AND c03_codigo_sri = p28_codigo_sri
		ORDER BY 1, 2, 3, 4
FOREACH q_rep2 INTO r_ret.*
	DECLARE q_sri CURSOR FOR
		SELECT * FROM tmp_ret
			WHERE p28_tipo_ret   = r_ret.tipo
			  AND p28_porcentaje = r_ret.porc
			  AND p28_codigo_sri = r_ret.cod_sri
			  AND p28_fecha_ini_porc = r_ret.fec_ini_p
			ORDER BY 3, 4, 2
	FOREACH q_sri INTO rm_consulta.*
		OUTPUT TO REPORT reporte_retenciones02(r_ret.*, rm_consulta.*)
	END FOREACH
END FOREACH
FINISH REPORT reporte_retenciones02

END FUNCTION



REPORT reporte_retenciones01(codigo_sri, proveedor, fecha_retencion,
				num_retencion, num_factura, fecha_factura,
				tipo_retencion, moneda, valor_base,
				porc_retencion, valor_retencion, codprov,
				num_ret_sri)
DEFINE codigo_sri	LIKE cxpt028.p28_codigo_sri
DEFINE proveedor	LIKE cxpt001.p01_nomprov
DEFINE fecha_retencion	LIKE cxpt027.p27_fecing
DEFINE num_retencion	LIKE cxpt028.p28_num_ret
DEFINE num_factura      LIKE cxpt028.p28_num_doc
DEFINE fecha_factura	LIKE cxpt020.p20_fecha_emi
DEFINE tipo_retencion	LIKE cxpt028.p28_tipo_ret
DEFINE moneda		LIKE cxpt027.p27_moneda
DEFINE valor_base	LIKE cxpt028.p28_valor_base
DEFINE porc_retencion	LIKE cxpt028.p28_porcentaje
DEFINE valor_retencion  LIKE cxpt028.p28_valor_ret
DEFINE codprov          LIKE cxpt001.p01_codprov
DEFINE num_ret_sri	LIKE cxpt029.p29_num_sri
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo           VARCHAR(80)
DEFINE modulo           VARCHAR(40)
DEFINE i, long          SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	2
	RIGHT  MARGIN	132
	BOTTOM MARGIN	4
	PAGE   LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET long        = LENGTH(modulo)
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DE RETENCIONES', 80)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rg_cia.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo  CLIPPED,
	      COLUMN 027, titulo,
	      COLUMN 122, UPSHIFT(vg_proceso) CLIPPED
      	SKIP 1 LINES
	PRINT COLUMN 040, '** Fecha Inicial    : ',
		rm_par.inicial USING "dd-mm-yyyy"
	PRINT COLUMN 040, '** Fecha Final      : ',
		rm_par.final USING "dd-mm-yyyy"
	IF rm_par.tipo_oc IS NOT NULL THEN
		CALL fl_lee_tipo_orden_compra(rm_par.tipo_oc) RETURNING r_c01.*
		PRINT COLUMN 040, '** Tipo Orden Compra: ',
			rm_par.tipo_oc USING "<<<&", ' ',
			r_c01.c01_nombre CLIPPED
	ELSE
		PRINT COLUMN 040, '** Tipo Orden Compra: T O D O S'
	END IF
	IF rm_par.tipo_porc IS NOT NULL THEN
		CALL fl_lee_tipo_retencion(vg_codcia, rm_par.tipo_porc,
						rm_par.valor_porc)
			RETURNING r_c02.*
		IF r_c02.c02_compania IS NOT NULL THEN
			PRINT COLUMN 040, '** Tipo Retencion   : ',
				rm_par.tipo_porc, ' ',
				rm_par.valor_porc USING "##&.##", ' ',
				r_c02.c02_nombre CLIPPED
		ELSE
			CASE rm_par.tipo_porc
				WHEN 'F' LET r_c02.c02_nombre = 'FUENTE'
				WHEN 'I' LET r_c02.c02_nombre = 'IVA'
			END CASE
			PRINT COLUMN 040, '** Tipo Retencion   : ',
				rm_par.tipo_porc, ' ',
				r_c02.c02_nombre CLIPPED
		END IF
	ELSE
		PRINT COLUMN 040, '** Tipo Retencion   : T O D O S'
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, 'Fecha impresión: ', TODAY USING 'dd-mmm-yyyy', 
			 1 SPACES, TIME,
              COLUMN 123, usuario
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 005, 'P r o v e e d o r',
	      COLUMN 028, 'Fecha Ret.',
	      COLUMN 039, 'No. Ret. SRI',
	      COLUMN 058, 'No. Ret.',
	      COLUMN 066, 'No. Factura',
	      COLUMN 085, 'Fecha Fac.',
	      COLUMN 096, 'Mo',
	      COLUMN 099, 'T',
	      COLUMN 101, '% Ret.',
	      COLUMN 108, '  Valor Base',
	      COLUMN 121, '  Valor Ret.'
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------------------------------------------'

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, proveedor[1, 26]	CLIPPED,
	      COLUMN 028, DATE(fecha_retencion)	USING "dd-mm-yyyy",
	      COLUMN 039, num_ret_sri		CLIPPED,
	      COLUMN 058, num_retencion		USING "<<<<<<&",
	      COLUMN 066, num_factura		CLIPPED,
	      COLUMN 085, fecha_factura		USING "dd-mm-yyyy",
	      COLUMN 096, moneda		CLIPPED, 
	      COLUMN 099, tipo_retencion	CLIPPED,
	      COLUMN 101, porc_retencion	USING '##&.##',
	      COLUMN 108, valor_base		USING '#,###,##&.##',
	      COLUMN 121, valor_retencion	USING '#,###,##&.##'

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 108, '------------',
	      COLUMN 121, '------------'
	PRINT COLUMN 085, 'Totales Generales ==>  ',
	      COLUMN 108, SUM(valor_base)	USING '#,###,##&.##',
	      COLUMN 121, SUM(valor_retencion)	USING '#,###,##&.##';
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



REPORT reporte_retenciones02(r_ret, codigo_sri, proveedor, fecha_retencion,
				num_retencion, num_factura, fecha_factura,
				tipo_retencion, moneda, valor_base,
				porc_retencion, valor_retencion, codprov,
				num_ret_sri)
DEFINE r_ret		RECORD
				tipo		LIKE ordt003.c03_tipo_ret,
				porc		LIKE ordt003.c03_porcentaje,
				cod_sri		LIKE ordt003.c03_codigo_sri,
				fec_ini_p	LIKE ordt003.c03_fecha_ini_porc,
				des_sri		LIKE ordt003.c03_concepto_ret
			END RECORD
DEFINE codigo_sri	LIKE cxpt028.p28_codigo_sri
DEFINE proveedor	LIKE cxpt001.p01_nomprov
DEFINE fecha_retencion	LIKE cxpt027.p27_fecing
DEFINE num_retencion	LIKE cxpt028.p28_num_ret
DEFINE num_factura      LIKE cxpt028.p28_num_doc
DEFINE fecha_factura	LIKE cxpt020.p20_fecha_emi
DEFINE tipo_retencion	LIKE cxpt028.p28_tipo_ret
DEFINE moneda		LIKE cxpt027.p27_moneda
DEFINE valor_base	LIKE cxpt028.p28_valor_base
DEFINE porc_retencion	LIKE cxpt028.p28_porcentaje
DEFINE valor_retencion  LIKE cxpt028.p28_valor_ret
DEFINE codprov          LIKE cxpt001.p01_codprov
DEFINE num_ret_sri	LIKE cxpt029.p29_num_sri
DEFINE concep		LIKE ordt003.c03_concepto_ret
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo           VARCHAR(80)
DEFINE modulo           VARCHAR(40)
DEFINE i,long           SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	2
	RIGHT  MARGIN	132
	BOTTOM MARGIN	4
	PAGE   LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET long        = LENGTH(modulo)
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C','LISTADO DE RETENCIONES POR CODIGO SRI',80)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rg_cia.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo  CLIPPED,
	      COLUMN 027, titulo,
	      COLUMN 122, UPSHIFT(vg_proceso) CLIPPED
      	SKIP 1 LINES
	PRINT COLUMN 040, '** Fecha Inicial    : ',
		rm_par.inicial USING "dd-mm-yyyy"
	PRINT COLUMN 040, '** Fecha Final      : ',
		rm_par.final USING "dd-mm-yyyy"
	IF rm_par.tipo_oc IS NOT NULL THEN
		CALL fl_lee_tipo_orden_compra(rm_par.tipo_oc) RETURNING r_c01.*
		PRINT COLUMN 040, '** Tipo Orden Compra: ',
			rm_par.tipo_oc USING "<<<&", ' ',
			r_c01.c01_nombre CLIPPED
	ELSE
		PRINT COLUMN 040, '** Tipo Orden Compra: T O D O S'
	END IF
	IF rm_par.tipo_porc IS NOT NULL THEN
		CALL fl_lee_tipo_retencion(vg_codcia, rm_par.tipo_porc,
						rm_par.valor_porc)
			RETURNING r_c02.*
		IF r_c02.c02_compania IS NOT NULL THEN
			PRINT COLUMN 040, '** Tipo Retencion   : ',
				rm_par.tipo_porc, ' ',
				rm_par.valor_porc USING "##&.##", ' ',
				r_c02.c02_nombre CLIPPED
		ELSE
			CASE rm_par.tipo_porc
				WHEN 'F' LET r_c02.c02_nombre = 'FUENTE'
				WHEN 'I' LET r_c02.c02_nombre = 'IVA'
			END CASE
			PRINT COLUMN 040, '** Tipo Retencion   : ',
				rm_par.tipo_porc, ' ',
				r_c02.c02_nombre CLIPPED
		END IF
	ELSE
		PRINT COLUMN 040, '** Tipo Retencion   : T O D O S'
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, 'Fecha impresión: ', TODAY USING 'dd-mmm-yyyy', 
			 1 SPACES, TIME,
              COLUMN 123, usuario
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 003, 'P r o v e e d o r e s',
	      COLUMN 037, 'Fecha Ret.',
	      COLUMN 048, 'No. Ret.',
	      COLUMN 075, 'No. Factura',
	      COLUMN 094, 'Fecha Fac.',
	      COLUMN 105, 'Mo',
	      COLUMN 108, '  Valor Base',
	      COLUMN 121, '  Valor Ret.'
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------------------------------------------'

BEFORE GROUP OF r_ret.cod_sri
	NEED 9 LINES
	PRINT COLUMN 001, 'COD. SRI: ',
	      COLUMN 011, r_ret.tipo, ' ', r_ret.porc USING "##&.##",
	      COLUMN 020, codigo_sri CLIPPED,
	      COLUMN 027, r_ret.des_sri[1, 106] CLIPPED
	LET long = LENGTH(r_ret.des_sri)
	IF long > 106 THEN
		PRINT COLUMN 017, r_ret.des_sri[106, 200] CLIPPED
		SKIP 1 LINES
	ELSE
		PRINT COLUMN 017, ' '
	END IF
	LET vm_tot_bas = 0
	LET vm_tot_ret = 0

ON EVERY ROW
	NEED 6 LINES
	PRINT COLUMN 003, codprov		USING "<<<&&&",
	      COLUMN 010, proveedor[1, 26]	CLIPPED,
	      COLUMN 037, DATE(fecha_retencion)	USING "dd-mm-yyyy",
	      COLUMN 048, num_ret_sri		CLIPPED,
	      COLUMN 067, num_retencion		USING "<<<<<<&",
	      COLUMN 075, num_factura		CLIPPED,
	      COLUMN 094, fecha_factura		USING "dd-mm-yyyy",
	      COLUMN 105, moneda		CLIPPED, 
	      COLUMN 108, valor_base		USING '#,###,##&.##',
	      COLUMN 121, valor_retencion	USING '#,###,##&.##'
	LET vm_tot_bas = vm_tot_bas + valor_base
	LET vm_tot_ret = vm_tot_ret + valor_retencion

AFTER GROUP OF r_ret.cod_sri
	NEED 5 LINES
	PRINT COLUMN 108, '------------',
	      COLUMN 121, '------------'
	PRINT COLUMN 062, 'Codigo SRI (', r_ret.cod_sri USING "<<<<<<", ')',
	      COLUMN 084, 'Totales del Grupo ==>  ',
	      COLUMN 108, vm_tot_bas		USING '#,###,##&.##',
	      COLUMN 121, vm_tot_ret		USING '#,###,##&.##'
	SKIP 1 LINES

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 108, '------------',
	      COLUMN 121, '------------'
	PRINT COLUMN 084, 'Totales Generales ==>  ',
	      COLUMN 108, SUM(valor_base)	USING '#,###,##&.##',
	      COLUMN 121, SUM(valor_retencion)	USING '#,###,##&.##';
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



REPORT reporte_retenciones03(r_ret, codigo_sri, proveedor, fecha_retencion,
				num_retencion, num_factura, fecha_factura,
				tipo_retencion, moneda, valor_base,
				porc_retencion, valor_retencion, codprov,
				num_ret_sri)
DEFINE r_ret		RECORD
				codprov		LIKE cxpt001.p01_codprov,
				nomprov		LIKE cxpt001.p01_nomprov
			END RECORD
DEFINE codigo_sri	LIKE cxpt028.p28_codigo_sri
DEFINE proveedor	LIKE cxpt001.p01_nomprov
DEFINE fecha_retencion	LIKE cxpt027.p27_fecing
DEFINE num_retencion	LIKE cxpt028.p28_num_ret
DEFINE num_factura      LIKE cxpt028.p28_num_doc
DEFINE fecha_factura	LIKE cxpt020.p20_fecha_emi
DEFINE tipo_retencion	LIKE cxpt028.p28_tipo_ret
DEFINE moneda		LIKE cxpt027.p27_moneda
DEFINE valor_base	LIKE cxpt028.p28_valor_base
DEFINE porc_retencion	LIKE cxpt028.p28_porcentaje
DEFINE valor_retencion  LIKE cxpt028.p28_valor_ret
DEFINE codprov          LIKE cxpt001.p01_codprov
DEFINE num_ret_sri	LIKE cxpt029.p29_num_sri
DEFINE concep		LIKE ordt003.c03_concepto_ret
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo           VARCHAR(80)
DEFINE modulo           VARCHAR(40)
DEFINE i,long           SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	2
	RIGHT  MARGIN	132
	BOTTOM MARGIN	4
	PAGE   LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET long        = LENGTH(modulo)
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C','LISTADO DE RETENCIONES POR PROVEEDOR',80)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rg_cia.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo  CLIPPED,
	      COLUMN 027, titulo,
	      COLUMN 122, UPSHIFT(vg_proceso) CLIPPED
      	SKIP 1 LINES
	PRINT COLUMN 040, '** Fecha Inicial    : ',
		rm_par.inicial USING "dd-mm-yyyy"
	PRINT COLUMN 040, '** Fecha Final      : ',
		rm_par.final USING "dd-mm-yyyy"
	IF rm_par.tipo_oc IS NOT NULL THEN
		CALL fl_lee_tipo_orden_compra(rm_par.tipo_oc) RETURNING r_c01.*
		PRINT COLUMN 040, '** Tipo Orden Compra: ',
			rm_par.tipo_oc USING "<<<&", ' ',
			r_c01.c01_nombre CLIPPED
	ELSE
		PRINT COLUMN 040, '** Tipo Orden Compra: T O D O S'
	END IF
	IF rm_par.tipo_porc IS NOT NULL THEN
		CALL fl_lee_tipo_retencion(vg_codcia, rm_par.tipo_porc,
						rm_par.valor_porc)
			RETURNING r_c02.*
		IF r_c02.c02_compania IS NOT NULL THEN
			PRINT COLUMN 040, '** Tipo Retencion   : ',
				rm_par.tipo_porc, ' ',
				rm_par.valor_porc USING "##&.##", ' ',
				r_c02.c02_nombre CLIPPED
		ELSE
			CASE rm_par.tipo_porc
				WHEN 'F' LET r_c02.c02_nombre = 'FUENTE'
				WHEN 'I' LET r_c02.c02_nombre = 'IVA'
			END CASE
			PRINT COLUMN 040, '** Tipo Retencion   : ',
				rm_par.tipo_porc, ' ',
				r_c02.c02_nombre CLIPPED
		END IF
	ELSE
		PRINT COLUMN 040, '** Tipo Retencion   : T O D O S'
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, 'Fecha impresión: ', TODAY USING 'dd-mmm-yyyy', 
			 1 SPACES, TIME,
              COLUMN 123, usuario
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 021, 'Fecha Ret.',
	      COLUMN 032, 'No. Ret. SRI',
	      COLUMN 051, 'No. Ret.',
	      COLUMN 059, 'No. Factura',
	      COLUMN 078, 'Fecha Fac.',
	      COLUMN 089, 'Mo',
	      COLUMN 092, 'T',
	      COLUMN 094, '% Ret.',
	      COLUMN 101, 'C. SRI',
	      COLUMN 108, '  Valor Base',
	      COLUMN 121, '  Valor Ret.'
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------------------------------------------'

BEFORE GROUP OF r_ret.codprov
	NEED 9 LINES
	PRINT COLUMN 001, 'PROVEEDOR: ',
	      COLUMN 012, r_ret.codprov		USING "<<<&&&",
	      COLUMN 019, r_ret.nomprov		CLIPPED
	SKIP 1 LINES
	LET vm_tot_bas = 0
	LET vm_tot_ret = 0

ON EVERY ROW
	NEED 6 LINES
	PRINT COLUMN 021, DATE(fecha_retencion)	USING "dd-mm-yyyy",
	      COLUMN 032, num_ret_sri		CLIPPED,
	      COLUMN 051, num_retencion		USING "<<<<<<&",
	      COLUMN 059, num_factura		CLIPPED,
	      COLUMN 078, fecha_factura		USING "dd-mm-yyyy",
	      COLUMN 089, moneda		CLIPPED, 
	      COLUMN 092, tipo_retencion	CLIPPED,
	      COLUMN 094, porc_retencion	USING '##&.##',
	      COLUMN 101, codigo_sri		USING "<<<<<<",
	      COLUMN 108, valor_base		USING '#,###,##&.##',
	      COLUMN 121, valor_retencion	USING '#,###,##&.##'
	LET vm_tot_bas = vm_tot_bas + valor_base
	LET vm_tot_ret = vm_tot_ret + valor_retencion

AFTER GROUP OF r_ret.codprov
	NEED 5 LINES
	PRINT COLUMN 108, '------------',
	      COLUMN 121, '------------'
	PRINT COLUMN 085, 'Totales del Grupo ==>  ',
	      COLUMN 108, vm_tot_bas		USING '#,###,##&.##',
	      COLUMN 121, vm_tot_ret		USING '#,###,##&.##'
	SKIP 1 LINES

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 108, '------------',
	      COLUMN 121, '------------'
	PRINT COLUMN 085, 'Totales Generales ==>  ',
	      COLUMN 108, SUM(valor_base)	USING '#,###,##&.##',
	      COLUMN 121, SUM(valor_retencion)	USING '#,###,##&.##';
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION ayuda_tipo_retencion()
DEFINE r_fue		ARRAY[3] OF RECORD
				tip_fue		LIKE ordt002.c02_tipo_ret,
				nom_fue		VARCHAR(10)
			END RECORD
DEFINE i, max_row	SMALLINT

LET max_row = 2
OPEN WINDOW w_cxpf410_2 AT 13, 22
	WITH FORM '../forms/cxpf410_2'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 0, BORDER)
--#DISPLAY "T"		TO tit_col1
--#DISPLAY "Nombre"	TO tit_col2
LET r_fue[1].tip_fue = 'F'
LET r_fue[1].nom_fue = 'FUENTE'
LET r_fue[2].tip_fue = 'I'
LET r_fue[2].nom_fue = 'IVA'
LET r_fue[3].tip_fue = NULL
LET r_fue[3].nom_fue = NULL
LET int_flag = 0
CALL set_count(max_row)
DISPLAY ARRAY r_fue TO r_fue.*
	ON KEY(RETURN)
		--#LET i = arr_curr()
		EXIT DISPLAY
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#MESSAGE i, ' de ', max_row
END DISPLAY
CLOSE WINDOW w_cxpf410_2
IF int_flag THEN
	INITIALIZE r_fue[1].* TO NULL
	RETURN r_fue[1].tip_fue
END IF
LET i = arr_curr()
RETURN r_fue[i].tip_fue

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
