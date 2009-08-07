------------------------------------------------------------------------------
-- Titulo           : ctbp408.4gl - Listado de saldos de bancos
-- Elaboracion      : 10-Sep-2002
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp408 base módulo compañía num_concil
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_b13		RECORD LIKE ctbt013.*
DEFINE rm_b12		RECORD LIKE ctbt012.*
DEFINE rm_b30		RECORD LIKE ctbt030.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_g09		RECORD LIKE gent009.*
DEFINE rm_g08		RECORD LIKE gent008.*
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE

DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT
DEFINE vm_page		SMALLINT


MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base		  = arg_val(1)
LET vg_modulo   	  = arg_val(2)
LET vg_codcia             = arg_val(3)
LET rm_b30.b30_num_concil = arg_val(4)
LET vg_proceso 		  = 'ctbp408'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 16 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
--OPEN FORM f_rep FROM "../forms/ctbf408_1"
--DISPLAY FORM f_rep
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		VARCHAR(1000)
DEFINE comando 		VARCHAR(100)
DEFINE r_report 	RECORD
				tipo		LIKE ctbt013.b13_tipo_comp,
				numero		LIKE ctbt013.b13_num_comp,
				fecha		LIKE ctbt013.b13_fec_proceso,
				cheque		LIKE ctbt012.b12_num_cheque,
				beneficiario	LIKE ctbt012.b12_benef_che,
				referencia	LIKE ctbt013.b13_glosa,
				valor		DECIMAL(14,2)
			END RECORD
DEFINE r_report_aux 	RECORD
				tipo		LIKE ctbt013.b13_tipo_comp,
				numero		LIKE ctbt013.b13_num_comp,
				fecha		LIKE ctbt013.b13_fec_proceso,
				cheque		LIKE ctbt012.b12_num_cheque,
				beneficiario	LIKE ctbt012.b12_benef_che,
				referencia	LIKE ctbt013.b13_glosa,
				valor_base	DECIMAL(14,2),
				valor_aux	DECIMAL(14,2)
			END RECORD
DEFINE num_concil	LIKE ctbt030.b30_num_concil
DEFINE tipo_comp	LIKE ctbt013.b13_tipo_comp
DEFINE tipo_doc		LIKE ctbt013.b13_tipo_doc
DEFINE tot_ch		SMALLINT
DEFINE tot_ch_gir	SMALLINT
DEFINE tot_dp		SMALLINT
DEFINE flag		SMALLINT

LET vm_top    = 0
LET vm_left   = 1
LET vm_right  = 220
LET vm_bottom = 0
LET vm_page   = 45

WHILE TRUE
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_lee_conciliacion(vg_codcia, rm_b30.b30_num_concil)
		RETURNING rm_b30.*
	CALL fl_lee_moneda(rm_b30.b30_moneda) RETURNING rm_g13.*
	CALL fl_lee_banco_compania(vg_codcia, rm_b30.b30_banco,
					rm_b30.b30_numero_cta)
		RETURNING rm_g09.*
	CALL fl_lee_banco_general(rm_g09.g09_banco) RETURNING rm_g08.*
	IF rm_b30.b30_compania IS NULL THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	LET query = 'SELECT b13_tipo_comp, b13_tipo_doc, b13_num_concil, 0 ',
			' FROM ctbt013 ',
			' WHERE b13_compania    = ', vg_codcia,
			'   AND b13_cuenta      = "', rm_b30.b30_aux_cont, '"',
			'   AND b13_num_concil IN (0, ',
						rm_b30.b30_num_concil, ')',
			'   AND b13_fec_proceso <= "',rm_b30.b30_fecha_fin, '"',
			' UNION ALL ',
			'SELECT b32_tipo_comp, b32_tipo_doc, b32_num_concil, 1',
			' FROM ctbt032 ',
			' WHERE b32_compania    = ', vg_codcia,
			'   AND b32_cuenta      = "', rm_b30.b30_aux_cont, '"',
			'   AND b32_num_concil  IN (0, ',
						rm_b30.b30_num_concil, ')',
			'   AND b32_fec_proceso <= "', rm_b30.b30_fecha_fin, '"'
	PREPARE contar FROM query
	DECLARE q_contar CURSOR FOR contar 
	LET tot_ch     = 0
	LET tot_ch_gir = 0
	LET tot_dp     = 0
	FOREACH q_contar INTO tipo_comp, tipo_doc, num_concil, flag
		IF (tipo_comp = 'EG' OR tipo_doc = 'CHE') THEN
			IF num_concil <> 0 THEN
				LET tot_ch = tot_ch + 1
			END IF
			LET tot_ch_gir = tot_ch_gir + 1
		END IF
		IF flag = 0 THEN
			IF tipo_comp = 'DP' OR tipo_doc = 'DEP' THEN
				LET tot_dp = tot_dp + 1
			END IF
		END IF
	END FOREACH
	START REPORT report_resumen_concil TO PIPE comando
	OUTPUT TO REPORT report_resumen_concil(tot_ch, tot_ch_gir, tot_dp)
	FINISH REPORT report_resumen_concil
	LET query = 'SELECT b13_tipo_comp, b13_num_comp, b13_fec_proceso,',
			' 0, "0", b13_glosa, b13_valor_base, b13_valor_aux,',
			' b13_num_concil ',
			' FROM ctbt013 ',
			' WHERE b13_compania     = ', vg_codcia,
			'   AND b13_cuenta       = "', rm_b30.b30_aux_cont, '"',
			'   AND b13_fec_proceso <= "',rm_b30.b30_fecha_fin, '"',
			' UNION ALL ',
			' SELECT b32_tipo_comp, b32_num_comp, b32_fec_proceso,',
			' b32_num_cheque, b32_benef_che, b32_glosa, ',
			' b32_valor_base, b32_valor_aux, b32_num_concil ',
			'	FROM ctbt032 ',
			'	WHERE b32_compania   = ', vg_codcia,
			'  	  AND b32_cuenta     = "',
						rm_b30.b30_aux_cont, '"',
			'         AND b32_fec_proceso <= "',
						rm_b30.b30_fecha_fin, '"',
			' ORDER BY 3, 1, 2 '
	START REPORT report_che_girados_ncob TO PIPE comando
	PREPARE reporte FROM query
	DECLARE q_reporte CURSOR FOR reporte
	FOREACH q_reporte INTO r_report_aux.*, num_concil
		IF r_report_aux.fecha > rm_b30.b30_fecha_fin THEN
			CONTINUE FOREACH
		END IF
	
		-- Parche por arranque de saldos que no debe ser conciliado.
		IF YEAR(r_report_aux.fecha) <= 2001 THEN
			CONTINUE FOREACH
		END IF
		--

		IF num_concil <> 0 THEN
			IF num_concil <= rm_b30.b30_num_concil THEN
				CONTINUE FOREACH
			END IF
		END IF
		CALL fl_lee_comprobante_contable(vg_codcia, r_report_aux.tipo,
					r_report_aux.numero)
			RETURNING rm_b12.*
		IF rm_b12.b12_moneda <> rm_g09.g09_moneda THEN
			CONTINUE FOREACH
		END IF
		IF rm_b12.b12_num_cheque IS NULL THEN
			CONTINUE FOREACH
		END IF
		LET r_report.tipo		= r_report_aux.tipo
		LET r_report.numero		= r_report_aux.numero
		LET r_report.fecha		= r_report_aux.fecha
		IF r_report_aux.cheque <> 0 THEN
			LET r_report.cheque	  = r_report_aux.cheque
			LET r_report.beneficiario = r_report_aux.beneficiario
		ELSE
			LET r_report.cheque	  = rm_b12.b12_num_cheque
			LET r_report.beneficiario = rm_b12.b12_benef_che
		END IF
		IF rm_b12.b12_estado <> 'E' THEN
			LET r_report.referencia	= r_report_aux.referencia
			CALL obtener_valores_deb_cre(r_report_aux.valor_base,
						     r_report_aux.valor_aux)
				RETURNING r_report.valor
		ELSE
			LET r_report.referencia	= '*** ELIMINADO ***'
			LET r_report.valor	= 0
		END IF
		OUTPUT TO REPORT report_che_girados_ncob(r_report.*)
	END FOREACH
	FINISH REPORT report_che_girados_ncob
	EXIT WHILE
END WHILE 

END FUNCTION



REPORT report_resumen_concil(tot_ch, tot_ch_gir, tot_dp)
DEFINE tot_ch		SMALLINT
DEFINE tot_ch_gir	SMALLINT
DEFINE tot_dp		SMALLINT
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
DEFINE num_concil	VARCHAR(10)
DEFINE estado		VARCHAR(20)
DEFINE tipo		VARCHAR(20)
DEFINE total_con	DECIMAL(12,2)
DEFINE chc		VARCHAR(5)
DEFINE chg		VARCHAR(5)
DEFINE dep		VARCHAR(5)

OUTPUT
	TOP MARGIN	vm_top
	LEFT MARGIN	vm_left
	RIGHT MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE LENGTH	vm_page
FORMAT

PAGE HEADER
	--print 'E'; 
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&l1O';		-- Modo landscape
	--print '&k2S'	                -- Letra condensada (16 cpi)
	--print '&k4S'	        -- Letra (12 cpi)

	LET modulo     = "Módulo: Contabilidad"
	LET long       = LENGTH(modulo)
	LET usuario    = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I','RESUMEN DE CONCILIACION BANCARIA',80)
		RETURNING titulo
	LET num_concil = rm_b30.b30_num_concil
	IF rm_b30.b30_estado = 'A' THEN
		LET estado = 'ACTIVA'
	END IF
	IF rm_b30.b30_estado = 'C' THEN
		LET estado = 'CONCILIADA'
	END IF
	IF rm_b30.b30_estado = 'E' THEN
		LET estado = 'ELIMINADA'
	END IF
	IF rm_g09.g09_tipo_cta = 'C' THEN
		LET tipo = 'CORRIENTE'
	END IF
	IF rm_g09.g09_tipo_cta = 'A' THEN
		LET tipo = 'AHORROS'
	END IF
	LET chc = tot_ch
	LET chg = tot_ch_gir
	LET dep = tot_dp
	LET total_con = rm_b30.b30_saldo_cont +
			rm_b30.b30_ch_nocob + rm_b30.b30_nd_banco + 
			rm_b30.b30_nc_banco + rm_b30.b30_dp_tran +
	      		rm_b30.b30_db_otros + rm_b30.b30_cr_otros
	PRINT COLUMN 1,   rg_cia.g01_razonsocial,
	      COLUMN 122, 'Página: ', PAGENO USING '&&&'
	PRINT COLUMN 1,   modulo CLIPPED,
	      COLUMN 51,  titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso) 
	SKIP 2 LINES
	PRINT COLUMN 1, 'Fecha Impresión: ',
		TODAY USING 'dd-mm-yyyy', 1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT '------------------------------------------------------------------------------------------------------------------------------------'
	SKIP 1 LINES
	PRINT COLUMN 1,   'Conciliación',
	      COLUMN 40,  ': ', '# ', num_concil,
	      COLUMN 114, 'Estado: ', estado
	PRINT COLUMN 1,   'Banco',
	      COLUMN 40,  ': ', rm_g08.g08_nombre
	PRINT COLUMN 1,   'Cuenta',
	      COLUMN 40,  ': ', rm_g09.g09_numero_cta
	PRINT COLUMN 1,   'Tipo',
	      COLUMN 40,  ': ', tipo
	PRINT COLUMN 1,   'Moneda',
	      COLUMN 40,  ': ', rm_g13.g13_nombre
	PRINT COLUMN 1,   'Período',
	      COLUMN 40,  ': ', rm_b30.b30_fecha_ini USING 'dd-mm-yyyy', ' AL ',
	                  rm_b30.b30_fecha_fin USING 'dd-mm-yyyy'
	SKIP 3 LINES
	PRINT COLUMN 1,   'Saldo Según E/C: ',
	      COLUMN 116, rm_b30.b30_saldo_ec USING '#,###,###,##&.##'
	SKIP 1 LINES
	PRINT COLUMN 1,   'Saldo Contable AL ',
	                  rm_b30.b30_fecha_fin USING 'dd-mm-yyyy', ':',
	      COLUMN 116, rm_b30.b30_saldo_cont USING '#,###,###,##&.##'
	SKIP 1 LINES
	PRINT COLUMN 1,   '(+) CHEQUES GIRADOS Y NO COBRADOS',
	      COLUMN 116, rm_b30.b30_ch_nocob USING '#,###,###,##&.##'
	PRINT COLUMN 1,   '(-) N/D BANCARIAS NO CONTABILIZADAS',
	      COLUMN 116, rm_b30.b30_nd_banco USING '#,###,###,##&.##'
	PRINT COLUMN 1,   '(+) N/C NO CONTABILIZADAS',
	      COLUMN 116, rm_b30.b30_nc_banco USING '#,###,###,##&.##'
	PRINT COLUMN 1,   '(-) DEPOSITOS EN TRANSITO',
	      COLUMN 116, rm_b30.b30_dp_tran USING '#,###,###,##&.##'
	PRINT COLUMN 1,   '(+) OTROS CREDITOS CONTAB. Y QUE NO ESTAN EN E/C',
	      COLUMN 116, rm_b30.b30_db_otros USING '#,###,###,##&.##'
	PRINT COLUMN 1,   '(-) OTROS DEBITOS CONTAB. Y QUE NO ESTAN EN E/C',
	      COLUMN 116, rm_b30.b30_cr_otros USING '#,###,###,##&.##'
	PRINT COLUMN 116, '----------------'
	PRINT COLUMN 1,   'Saldo Conciliado',
	      COLUMN 116, total_con USING '#,###,###,##&.##'
	SKIP 2 LINES
	PRINT COLUMN 1,   'Total Cheques Girados      (', chg, ')'
	SKIP 1 LINES
	PRINT COLUMN 1,   'Total Cheques Cobrados     (', chc, ')',
	      COLUMN 116, rm_b30.b30_ch_tarj USING '#,###,###,##&.##'
	PRINT COLUMN 1,   'Total Depósitos Realizados (', dep, ')',
	      COLUMN 116, rm_b30.b30_dp_tarj USING '#,###,###,##&.##'
	CALL fl_lee_comprobante_contable(vg_codcia, rm_b30.b30_tipcomp_gen,
					rm_b30.b30_numcomp_gen)
		RETURNING rm_b12.*
	IF rm_b12.b12_compania IS NOT NULL THEN
		SKIP 1 LINES
		PRINT COLUMN 1,  'Asciento Contable Generado',
		      COLUMN 40, ': ', rm_b12.b12_tipo_comp, ' ',
				       rm_b12.b12_num_comp
	END IF

END REPORT



REPORT report_che_girados_ncob(r_report)
DEFINE r_report 	RECORD
				tipo		LIKE ctbt013.b13_tipo_comp,
				numero		LIKE ctbt013.b13_num_comp,
				fecha		LIKE ctbt013.b13_fec_proceso,
				cheque		LIKE ctbt012.b12_num_cheque,
				beneficiario	LIKE ctbt012.b12_benef_che,
				referencia	LIKE ctbt013.b13_glosa,
				valor		DECIMAL(14,2)
			END RECORD
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT

OUTPUT
	TOP MARGIN	vm_top
	LEFT MARGIN	vm_left
	RIGHT MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE LENGTH	vm_page
FORMAT

PAGE HEADER
	--print 'E'; 
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&l1O';		-- Modo landscape
	--print '&k2S'	                -- Letra condensada (16 cpi)
	--print '&k4S'	        -- Letra (12 cpi)

	LET modulo     = "Módulo: Contabilidad"
	LET long       = LENGTH(modulo)
	LET usuario    = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I','DETALLE DE CHEQUES GIRADOS Y NO COBRADOS',
				80)
		RETURNING titulo
	PRINT COLUMN 1,   rg_cia.g01_razonsocial,
	      COLUMN 122, 'Página: ', PAGENO USING '&&&'
	PRINT COLUMN 1,   modulo CLIPPED,
	      COLUMN 47,  titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso) 
	SKIP 2 LINES
	PRINT COLUMN 1, 'Fecha Impresión: ',
		TODAY USING 'dd-mm-yyyy', 1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT '------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 1,   'Comprobante',
	      COLUMN 17,  'Fecha',
	      COLUMN 32,  'Ch.',
	      COLUMN 46,  'Beneficiario',
	      COLUMN 76,  'Referencia',
	      COLUMN 116, '            Valor'
	PRINT '------------------------------------------------------------------------------------------------------------------------------------'

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 1,   r_report.tipo,
	      COLUMN 3,   r_report.numero	USING '#######&',
	      COLUMN 17,  r_report.fecha	USING 'dd-mm-yyyy',
	      COLUMN 32,  r_report.cheque	USING '&&&&&&&&',
	      COLUMN 46,  r_report.beneficiario,
	      COLUMN 76,  r_report.referencia,
	      COLUMN 116, r_report.valor	USING '#,###,###,##&.##'

ON LAST ROW
	--print '&k4S'	        -- Letra (12 cpi)
	PRINT COLUMN 116, '----------------'
	PRINT COLUMN 105, 'TOTAL ==>  ',
	      COLUMN 116, SUM(r_report.valor)	USING '#,###,###,##&.##'

END REPORT



FUNCTION obtener_valores_deb_cre(valor_base, valor_aux)
DEFINE valor_base	DECIMAL(14,2)
DEFINE valor_aux	DECIMAL(14,2)
DEFINE valor		DECIMAL(14,2)

IF rm_b12.b12_moneda = rg_gen.g00_moneda_base THEN
	LET valor = valor_base
ELSE
	LET valor = valor_aux
END IF
RETURN valor

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo,
			    'stop')
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
