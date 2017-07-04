------------------------------------------------------------------------------
-- Titulo           : ctbp407.4gl - Listado de saldos de bancos
-- Elaboracion      : 17-Ago-2002
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp407 base módulo compañía
--			[moneda] [fecha_inicial] [fecha_final] [columna1]
--			[columna2] [orden1] [orden2]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_b13		RECORD LIKE ctbt013.*
DEFINE rm_b12		RECORD LIKE ctbt012.*
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT
DEFINE vm_page		SMALLINT


MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp407.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 10 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base			= arg_val(1)
LET vg_modulo   		= arg_val(2)
LET vg_codcia   		= arg_val(3)
LET rm_b12.b12_moneda		= arg_val(4)
LET vm_fecha_ini		= arg_val(5)
LET vm_fecha_fin		= arg_val(6)
LET vm_columna_1		= arg_val(7)
LET vm_columna_2		= arg_val(8)
LET rm_orden[vm_columna_1]	= arg_val(9)
LET rm_orden[vm_columna_2]	= arg_val(10)
LET vg_proceso 			= 'ctbp407'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CREATE TEMP TABLE temp_saldos
	(cuenta		CHAR(12),
	 descripcion	VARCHAR(70),
	 tit_saldo_ini	DECIMAL(14,2),
	 tit_debito	DECIMAL(14,2),
	 tit_credito	DECIMAL(14,2),
	 tit_saldo	DECIMAL(14,2))
CREATE TEMP TABLE temp_mov
	(orden		SMALLINT,
	 cuenta		CHAR(12),
	 fecha		DATE,
	 tipo		CHAR(2),
	 numero		CHAR(8),
	 glosa		VARCHAR(35),
	 debito		DECIMAL(14,2),
	 credito	DECIMAL(14,2),
	 beneficiario	VARCHAR(40),
	 cheque		INTEGER,
	 banco		INTEGER,
	 tipo_cta	CHAR(1),
	 num_cta	CHAR(15))
CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 16 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
--OPEN FORM f_rep FROM "../forms/ctbf407_1"
--DISPLAY FORM f_rep
INITIALIZE rm_b13.* TO NULL
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		VARCHAR(1000)
DEFINE query2		VARCHAR(1000)
DEFINE comando 		VARCHAR(100)
DEFINE r_report 	RECORD
				cuenta		LIKE gent009.g09_aux_cont,
				descripcion	VARCHAR(70),
				tit_saldo_ini	DECIMAL(14,2),
				tit_debito	DECIMAL(14,2),
				tit_credito	DECIMAL(14,2),
				tit_saldo	DECIMAL(14,2)
			END RECORD
DEFINE r_report2 	RECORD
				orden		SMALLINT,
	 			cuenta		LIKE gent009.g09_aux_cont,
				fecha		LIKE ctbt013.b13_fec_proceso,
				tipo		LIKE ctbt013.b13_tipo_comp,
				numero		LIKE ctbt013.b13_num_comp,
				glosa		LIKE ctbt013.b13_glosa,
				debito		DECIMAL(14,2),
				credito		DECIMAL(14,2),
	 			beneficiario	VARCHAR(25),
	 			cheque		INTEGER,
				banco		LIKE gent009.g09_banco,
				tipo_cta	LIKE gent009.g09_tipo_cta,
				num_cta		LIKE gent009.g09_numero_cta
			END RECORD
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE fecha		DATE
DEFINE debito		DECIMAL(14,2)
DEFINE credito		DECIMAL(14,2)
DEFINE deb2		DECIMAL(14,2)
DEFINE cred2		DECIMAL(14,2)
DEFINE orden		SMALLINT

LET vm_top    = 0
LET vm_left   = 1
LET vm_right  = 220
LET vm_bottom = 0
LET vm_page   = 45

CALL fl_lee_moneda(rm_b12.b12_moneda) RETURNING rm_g13.*
WHILE TRUE
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		EXIT WHILE
	END IF
	LET query = 'SELECT * FROM gent009 ',
			'WHERE g09_compania = ', vg_codcia
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	OPEN q_deto
	FETCH q_deto
	IF STATUS = NOTFOUND THEN
		CLOSE q_deto
		FREE  q_deto
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	CLOSE q_deto
	FOREACH q_deto INTO r_g09.*
		LET query2 = 'SELECT * FROM ctbt013 ',
				'WHERE b13_compania = ', vg_codcia,
				'  AND b13_cuenta   = "',r_g09.g09_aux_cont,'"',
				'  AND b13_fec_proceso BETWEEN "', vm_fecha_ini,
				'" AND "', vm_fecha_fin, '"',
				' ORDER BY b13_fec_proceso, b13_tipo_comp,',
				' b13_num_comp'
		PREPARE deto2 FROM query2
		DECLARE q_deto2 CURSOR FOR deto2
		LET deb2  = 0
		LET cred2 = 0
		FOREACH q_deto2 INTO rm_b13.*
			CALL fl_lee_comprobante_contable(vg_codcia,
					rm_b13.b13_tipo_comp,
					rm_b13.b13_num_comp)
				RETURNING r_b12.*
			IF r_b12.b12_estado = "E"
			  OR r_b12.b12_moneda <> rm_b12.b12_moneda THEN
				CONTINUE FOREACH
			END IF
			CALL obtener_valores_deb_cre2(debito, credito)
				RETURNING debito, credito, orden
			INSERT INTO temp_mov
				VALUES (orden, r_g09.g09_aux_cont,
				rm_b13.b13_fec_proceso, rm_b13.b13_tipo_comp,
				rm_b13.b13_num_comp, rm_b13.b13_glosa, debito,
				credito, r_b12.b12_benef_che,
				r_b12.b12_num_cheque, r_g09.g09_banco,
				r_g09.g09_tipo_cta, r_g09.g09_numero_cta)
			CALL obtener_valores_deb_cre(deb2, cred2)
				RETURNING deb2, cred2
		END FOREACH
		LET r_report.cuenta = r_g09.g09_aux_cont
		CALL nombre_banco(r_g09.g09_banco, r_g09.g09_tipo_cta,
				r_g09.g09_numero_cta)
			RETURNING r_report.descripcion
		LET fecha                = vm_fecha_ini - 1 UNITS DAY
		CALL fl_obtiene_saldo_contable(vg_codcia, r_report.cuenta,
				rm_b12.b12_moneda, fecha, 'A')
			RETURNING r_report.tit_saldo_ini
		LET r_report.tit_debito  = deb2
		LET r_report.tit_credito = cred2
		LET r_report.tit_saldo   = r_report.tit_saldo_ini +
					   r_report.tit_debito +
					   r_report.tit_credito
		INSERT INTO temp_saldos	VALUES (r_report.*)
	END FOREACH
	LET query = 'SELECT * FROM temp_saldos ',
		     " ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
		    	     ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	START REPORT report_saldos_bancos TO PIPE comando
	PREPARE reposal FROM query
	DECLARE q_reposal CURSOR FOR reposal
	FOREACH q_reposal INTO r_report.*
		OUTPUT TO REPORT report_saldos_bancos(r_report.*)
	END FOREACH
	FINISH REPORT report_saldos_bancos
	LET query = 'SELECT * FROM temp_mov ',
			'ORDER BY cuenta, orden, fecha, tipo, numero'
	START REPORT report_saldos_bancos_mov TO PIPE comando
	PREPARE reporte FROM query
	DECLARE q_reporte CURSOR FOR reporte
	FOREACH q_reporte INTO r_report2.* 
		OUTPUT TO REPORT report_saldos_bancos_mov(r_report2.*)
	END FOREACH
	FINISH REPORT report_saldos_bancos_mov
	DELETE FROM temp_mov
	DELETE FROM temp_saldos
	EXIT WHILE
END WHILE 

END FUNCTION



REPORT report_saldos_bancos (r_report)
DEFINE r_report 	RECORD
				cuenta		LIKE gent009.g09_aux_cont,
				descripcion	VARCHAR(70),
				tit_saldo_ini	DECIMAL(14,2),
				tit_debito	DECIMAL(14,2),
				tit_credito	DECIMAL(14,2),
				tit_saldo	DECIMAL(14,2)
			END RECORD
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE tit_sist		VARCHAR(40)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

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

	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET modulo     = "Módulo: Contabilidad"
	LET long       = LENGTH(modulo)
	LET usuario    = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C','LISTADO DE SALDOS DE BANCOS',80)
		RETURNING titulo
	CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING r_g02.*
	LET tit_sist = r_g02.g02_nombre CLIPPED, " - ", vg_base CLIPPED, " (",
			vg_servidor CLIPPED, ")"
	CALL fl_justifica_titulo('C', tit_sist, 40) RETURNING tit_sist
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 1,   rg_cia.g01_razonsocial,
	      COLUMN 047, tit_sist CLIPPED,
	      COLUMN 122, 'Pagina: ', PAGENO USING '&&&'
	PRINT COLUMN 1,   modulo CLIPPED,
	      COLUMN 27,  titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso) 
	PRINT COLUMN 47,  '** Moneda        : ', rm_b12.b12_moneda, ' ',
					 	 rm_g13.g13_nombre
	PRINT COLUMN 47,  '** Fecha Inicial : ', vm_fecha_ini USING 'dd-mm-yyyy'
	PRINT COLUMN 47,  '** Fecha Final   : ', vm_fecha_fin USING 'dd-mm-yyyy'
	PRINT COLUMN 1, 'Fecha Impresión: ',
		TODAY USING 'dd-mm-yyyy', 1 SPACES, TIME,
	      COLUMN 113, usuario
	SKIP 1 LINES
	PRINT '-----------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 1,   'Cuenta',
	      COLUMN 15,  'Bancos',
	      COLUMN 74,  'Saldo Inicial',
	      COLUMN 89,  '       Débito',
	      COLUMN 104, '      Crédito',
	      COLUMN 119, '  Saldo Final'
	PRINT '-----------------------------------------------------------------------------------------------------------------------------------'

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 1,	  r_report.cuenta,
	      COLUMN 15,  r_report.descripcion,
	      COLUMN 74,  r_report.tit_saldo_ini	USING '--,---,--&.##',
	      COLUMN 89,  r_report.tit_debito		USING '##,###,##&.##',
	      COLUMN 104, r_report.tit_credito		USING '##,###,##&.##',
	      COLUMN 119, r_report.tit_saldo		USING '--,---,--&.##'

ON LAST ROW
	--print '&k4S'	        -- Letra (12 cpi)
	PRINT COLUMN 74,  '-------------',
	      COLUMN 89,  '-------------',
	      COLUMN 104, '-------------',
	      COLUMN 119, '-------------'
	PRINT COLUMN 61,  'TOTALES ==>  ',
	      COLUMN 74,  SUM(r_report.tit_saldo_ini)	USING '--,---,--&.##',
	      COLUMN 89,  SUM(r_report.tit_debito)	USING '##,###,##&.##',
	      COLUMN 104, SUM(r_report.tit_credito)	USING '##,###,##&.##',
	      COLUMN 119, SUM(r_report.tit_saldo)	USING '--,---,--&.##';
	print ASCII escape;
	print ASCII desact_comp 
	SKIP 2 LINES

END REPORT



REPORT report_saldos_bancos_mov(r_report2)
DEFINE r_report2 	RECORD
				orden		SMALLINT,
	 			cuenta		LIKE gent009.g09_aux_cont,
				fecha		LIKE ctbt013.b13_fec_proceso,
				tipo		LIKE ctbt013.b13_tipo_comp,
				numero		LIKE ctbt013.b13_num_comp,
				glosa		LIKE ctbt013.b13_glosa,
				debito		DECIMAL(14,2),
				credito		DECIMAL(14,2),
	 			beneficiario	VARCHAR(25),
	 			cheque		INTEGER,
				banco		LIKE gent009.g09_banco,
				tipo_cta	LIKE gent009.g09_tipo_cta,
				num_cta		LIKE gent009.g09_numero_cta
			END RECORD
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
DEFINE glosa		VARCHAR(70)
DEFINE fecha_ini	DATE
DEFINE saldo		DECIMAL(14,2)
DEFINE saldo_final	DECIMAL(14,2)
DEFINE descripcion	VARCHAR(70)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP MARGIN	vm_top
	LEFT MARGIN	vm_left
	RIGHT MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE LENGTH	vm_page
	ORDER EXTERNAL BY r_report2.cuenta, r_report2.orden, r_report2.fecha,
			r_report2.tipo, r_report2.numero
FORMAT

PAGE HEADER
	--print 'E'; 
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&l1O';		-- Modo landscape
	--print '&k2S'	                -- Letra condensada (16 cpi)
	--print '&k4S'	        -- Letra (12 cpi)

	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET modulo     = "Módulo: Contabilidad"
	LET long       = LENGTH(modulo)
	LET usuario    = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I','LISTADO MOVIMIENTOS SALDOS DE BANCOS',80)
		RETURNING titulo
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 1,   rg_cia.g01_razonsocial,
	      COLUMN 122, 'Página: ', PAGENO USING '&&&'
	PRINT COLUMN 1,   modulo CLIPPED,
	      COLUMN 49,  titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso) 
	PRINT COLUMN 47,  '** Moneda        : ', rm_b12.b12_moneda, ' ',
					 	 rm_g13.g13_nombre
	PRINT COLUMN 47,  '** Fecha Inicial : ', vm_fecha_ini USING 'dd-mm-yyyy'
	PRINT COLUMN 47,  '** Fecha Final   : ', vm_fecha_fin USING 'dd-mm-yyyy'
	PRINT COLUMN 1, 'Fecha Impresión: ',
		TODAY USING 'dd-mm-yyyy', 1 SPACES, TIME,
	      COLUMN 113, usuario
	SKIP 1 LINES
	PRINT '-----------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 1,   'Fecha',
	      COLUMN 13,  'TC',
	      COLUMN 17,  '  Número',
	      COLUMN 27,  'Glosa',
	      COLUMN 89,  '       Débito',
	      COLUMN 104, '      Crédito',
	      COLUMN 119, '        Saldo'
	PRINT '-----------------------------------------------------------------------------------------------------------------------------------'

ON EVERY ROW
	LET glosa = r_report2.glosa[1,25] CLIPPED
	IF r_report2.cheque IS NOT NULL THEN
		LET glosa = 'Ch. ', r_report2.cheque USING '&&&&#'
		IF r_report2.beneficiario IS NOT NULL THEN
			LET glosa = glosa CLIPPED, ' ', 
				    r_report2.beneficiario[1,20] CLIPPED
		ELSE
			LET glosa = glosa CLIPPED, ' ',
				    r_report2.glosa[1,25] CLIPPED
		END IF
	END IF
	LET saldo_final = r_report2.debito + r_report2.credito
	NEED 3 LINES
	PRINT COLUMN 1,	  r_report2.fecha		USING 'dd-mm-yyyy',
	      COLUMN 13,  r_report2.tipo,
	      COLUMN 17,  r_report2.numero		USING '#######&',
	      COLUMN 27,  glosa,
	      COLUMN 89,  r_report2.debito		USING '##,###,##&.##',
	      COLUMN 104, r_report2.credito		USING '##,###,##&.##',
	      COLUMN 119, saldo_final			USING '--,---,--&.##'

BEFORE GROUP OF r_report2.cuenta
	NEED 3 LINES 
	LET fecha_ini = vm_fecha_ini - 1 UNITS DAY
	CALL fl_obtiene_saldo_contable(vg_codcia, r_report2.cuenta, 
		       rm_b12.b12_moneda, fecha_ini, 'A')
		RETURNING saldo
	CALL nombre_banco(r_report2.banco, r_report2.tipo_cta, r_report2.numero)
		RETURNING descripcion
	PRINT COLUMN 1,  r_report2.cuenta, ': ', descripcion[1,50],
	      COLUMN 94, 'Saldo Al ==>  ',
	      COLUMN 108, fecha_ini USING 'dd-mm-yyyy',
	      COLUMN 119, saldo USING '--,---,--&.##'
	SKIP 1 LINES
	
AFTER GROUP OF r_report2.cuenta
	NEED 4 LINES
	PRINT COLUMN 89,  '-------------',
	      COLUMN 104, '-------------'
	PRINT COLUMN 89,  GROUP SUM(r_report2.debito)	USING '##,###,##&.##',
	      COLUMN 104, GROUP SUM(r_report2.credito)	USING '##,###,##&.##'
	SKIP 2 LINES

ON LAST ROW
	--print '&k4S'	        -- Letra (12 cpi)
	PRINT COLUMN 89,  '-------------',
	      COLUMN 104, '-------------'
	PRINT COLUMN 76,  'TOTALES ==>  ',
	      COLUMN 89,  SUM(r_report2.debito)		USING '##,###,##&.##',
	      COLUMN 104, SUM(r_report2.credito)	USING '##,###,##&.##';
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION obtener_valores_deb_cre(deb, cred)
DEFINE deb		DECIMAL(14,2)
DEFINE cred		DECIMAL(14,2)

IF rm_b12.b12_moneda = rg_gen.g00_moneda_base THEN
	IF rm_b13.b13_valor_base >= 0 THEN
		LET deb   = deb  + rm_b13.b13_valor_base
	ELSE
		LET cred  = cred + rm_b13.b13_valor_base
	END IF
ELSE
	IF rm_b13.b13_valor_aux >= 0 THEN
		LET deb   = deb  + rm_b13.b13_valor_aux
	ELSE
		LET cred  = cred + rm_b13.b13_valor_aux
	END IF
END IF
RETURN deb, cred

END FUNCTION



FUNCTION obtener_valores_deb_cre2(deb, cred)
DEFINE deb		DECIMAL(14,2)
DEFINE cred		DECIMAL(14,2)
DEFINE orden		SMALLINT

LET orden = 0
IF rm_b12.b12_moneda = rg_gen.g00_moneda_base THEN
	IF rm_b13.b13_valor_base >= 0 THEN
		LET deb   = rm_b13.b13_valor_base
		LET cred  = 0
	ELSE
		LET deb   = 0
		LET cred  = rm_b13.b13_valor_base
		LET orden = 1
	END IF
ELSE
	IF rm_b13.b13_valor_aux >= 0 THEN
		LET deb   = rm_b13.b13_valor_aux
		LET cred  = 0
	ELSE
		LET deb   = 0
		LET cred  = rm_b13.b13_valor_aux
		LET orden = 1
	END IF
END IF
RETURN deb, cred, orden

END FUNCTION



FUNCTION nombre_banco(banco, tipo_cta, numero)
DEFINE banco		LIKE gent009.g09_banco
DEFINE tipo_cta		LIKE gent009.g09_tipo_cta
DEFINE numero		LIKE gent009.g09_numero_cta
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE tipo_des		VARCHAR(10)
DEFINE descrip		VARCHAR(70)

CALL fl_lee_banco_general(banco) RETURNING r_g08.*
LET tipo_des = 'Cta. Aho. '
IF tipo_cta = 'C' THEN
	LET tipo_des = 'Cta. Cte. '
END IF
LET descrip = r_g08.g08_nombre CLIPPED, ' (', tipo_des CLIPPED, ' ',
		numero CLIPPED, ')' 
RETURN descrip

END FUNCTION



FUNCTION no_validar_parametros()

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
