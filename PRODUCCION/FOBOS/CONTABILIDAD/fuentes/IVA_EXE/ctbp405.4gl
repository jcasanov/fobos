------------------------------------------------------------------------------
-- Titulo           : ctbp405.4gl - Listado de Movimientos de Cuentas
-- Elaboracion      : 02-ABR-2002
-- Autor            : GVA
-- Formato Ejecucion: fglrun ctbp405 base módulo compañía localidad
--			[cuenta_ini] [cuenta_fin] [fecha_ini] [fecha_fin]
--			[moneda] [[tipo_comp]] [[subtipo]]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_b12		RECORD LIKE ctbt012.*
DEFINE rm_b13		RECORD LIKE ctbt013.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT
DEFINE vm_page		SMALLINT
DEFINE vm_tot_debito	DECIMAL(14,2)
DEFINE vm_tot_credito	DECIMAL(14,2)
DEFINE vm_tot_debito_g	DECIMAL(14,2)
DEFINE vm_tot_credito_g	DECIMAL(14,2)
DEFINE vm_cta_inicial	LIKE ctbt013.b13_cuenta
DEFINE nom_cta_ini	LIKE ctbt010.b10_descripcion
DEFINE nom_cta_fin	LIKE ctbt010.b10_descripcion
DEFINE vm_cta_final	LIKE ctbt013.b13_cuenta
DEFINE vm_tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE vm_subtipo	LIKE ctbt012.b12_subtipo
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_moneda	LIKE gent013.g13_moneda
DEFINE vm_nivel         SMALLINT
DEFINE vm_saldo 	DECIMAL (14,2)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp405.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 9 AND num_args() <> 10 AND num_args() <> 11
THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'ctbp405'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_top    = 1
LET vm_left   = 0
LET vm_right  = 132
LET vm_bottom = 4
LET vm_page   = 66
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Nivel no está configurado.','stop')
	EXIT PROGRAM
END IF
IF num_args() <> 4 THEN
	CALL llamada_otro_prog()
	EXIT PROGRAM
END IF
OPEN WINDOW w_mas AT 03, 02 WITH 15 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/ctbf405_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION llamada_otro_prog()

LET vm_cta_inicial = arg_val(5)
LET vm_cta_final   = arg_val(6)
LET vm_fecha_ini   = arg_val(7)
LET vm_fecha_fin   = arg_val(8)
LET vm_moneda      = arg_val(9)
LET vm_tipo_comp   = NULL
LET vm_subtipo     = NULL
IF num_args() > 9 THEN
	LET vm_tipo_comp = arg_val(10)
	IF vm_tipo_comp = 'XX' THEN
		LET vm_tipo_comp = NULL
	END IF
	IF num_args() = 11 THEN
		LET vm_subtipo = arg_val(11)
	END IF
END IF
CALL fl_lee_moneda(vm_moneda) RETURNING rm_g13.*
LET vm_tot_debito  = 0
LET vm_tot_credito = 0
LET vm_saldo       = 0
CALL imprimir_reporte()

END FUNCTION



FUNCTION control_reporte()

LET vm_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(vm_moneda) RETURNING rm_g13.*
DISPLAY rm_g13.g13_nombre TO nom_moneda
LET vm_fecha_ini = TODAY
LET vm_fecha_fin = TODAY
WHILE TRUE
	LET vm_tot_debito  = 0
	LET vm_tot_credito = 0
	LET vm_saldo       = 0
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL imprimir_reporte()
END WHILE 

END FUNCTION



FUNCTION imprimir_reporte()
DEFINE comando 		VARCHAR(100)
DEFINE query		VARCHAR(1200)
DEFINE expr_tipo	VARCHAR(100)
DEFINE expr_subtipo	VARCHAR(100)
DEFINE r_report 	RECORD LIKE ctbt013.*
DEFINE r_b12	 	RECORD LIKE ctbt012.*

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
LET expr_tipo = NULL
IF vm_tipo_comp IS NOT NULL THEN
	LET expr_tipo = '   AND b12_tipo_comp = "', vm_tipo_comp, '"'
END IF
LET expr_subtipo = NULL
IF vm_subtipo IS NOT NULL THEN
	LET expr_subtipo = '   AND b12_subtipo = ', vm_subtipo
END IF
LET query = 'SELECT ctbt013.*, ctbt012.*',
		' FROM ctbt012, ctbt013 ',
		'WHERE b12_compania  =',vg_codcia,
		expr_tipo CLIPPED,
		'  AND b12_moneda    ="',vm_moneda,'"',
		expr_subtipo CLIPPED,
		'  AND b12_fec_proceso ',
		'BETWEEN "',vm_fecha_ini,'" AND "',vm_fecha_fin, '"',
		'  AND b12_estado <> "E"',
		'  AND b12_compania  = b13_compania',
		'  AND b12_tipo_comp = b13_tipo_comp',
		'  AND b12_num_comp  = b13_num_comp',
		'  AND b13_cuenta BETWEEN "',vm_cta_inicial,'"',
		'  AND "',vm_cta_final,'"',
		' ORDER BY b13_cuenta, b13_fec_proceso, ',
		' b13_tipo_comp, b13_num_comp'
PREPARE reporte FROM query
DECLARE q_reporte CURSOR FOR reporte
OPEN q_reporte
FETCH q_reporte
IF STATUS = NOTFOUND THEN
	CLOSE q_reporte
	FREE  q_reporte
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
START REPORT report_movimientos_ctas TO PIPE comando
LET vm_tot_debito_g  = 0
LET vm_tot_credito_g = 0
FOREACH q_reporte INTO r_report.*, r_b12.* 
	OUTPUT TO REPORT report_movimientos_ctas(r_report.*, r_b12.*)
	IF int_flag THEN
		EXIT FOREACH
	END IF
END FOREACH
FINISH REPORT report_movimientos_ctas

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b03		RECORD LIKE ctbt003.*
DEFINE r_b04		RECORD LIKE ctbt004.*

INITIALIZE r_b10.* TO NULL
OPTIONS INPUT NO WRAP
LET int_flag = 0
INPUT BY NAME vm_cta_inicial, vm_cta_final, vm_fecha_ini,
	      vm_fecha_fin,   vm_moneda, vm_tipo_comp, vm_subtipo
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(vm_cta_inicial) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET vm_cta_inicial = r_b10.b10_cuenta	
				DISPLAY BY NAME vm_cta_inicial
				DISPLAY r_b10.b10_descripcion TO nom_cta_ini
			END IF
		END IF
		IF INFIELD(vm_cta_final) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET vm_cta_final   = r_b10.b10_cuenta	
				DISPLAY BY NAME vm_cta_final
				DISPLAY r_b10.b10_descripcion TO nom_cta_fin
			END IF
		END IF
		IF INFIELD(vm_moneda) THEN
        		CALL fl_ayuda_monedas()
	               		RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
			IF rm_g13.g13_moneda IS NOT NULL THEN
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		END IF
		IF INFIELD(vm_tipo_comp) THEN
			CALL fl_ayuda_tipos_comprobantes(vg_codcia)
				RETURNING r_b03.b03_tipo_comp,
					  r_b03.b03_nombre
			IF r_b03.b03_tipo_comp IS NOT NULL THEN
				LET vm_tipo_comp = r_b03.b03_tipo_comp
				DISPLAY r_b03.b03_tipo_comp TO vm_tipo_comp
				DISPLAY BY NAME r_b03.b03_nombre
			END IF
		END IF
		IF INFIELD(vm_subtipo) THEN
			CALL fl_ayuda_subtipos_comprobantes(vg_codcia)
				RETURNING r_b04.b04_subtipo,
					  r_b04.b04_nombre
			IF r_b04.b04_subtipo IS NOT NULL THEN
				LET vm_subtipo = r_b04.b04_subtipo
				DISPLAY r_b04.b04_subtipo TO vm_subtipo
				DISPLAY BY NAME r_b04.b04_nombre
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD vm_cta_inicial
		IF vm_cta_inicial IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, vm_cta_inicial) 
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la cuenta en la Compañía.','exclamation')
				CLEAR nom_cta_ini
				NEXT FIELD vm_cta_inicial
			END IF
			LET vm_cta_inicial = r_b10.b10_cuenta
			LET nom_cta_ini = r_b10.b10_descripcion
			DISPLAY BY NAME vm_cta_inicial, nom_cta_ini
			IF vm_cta_final IS NULL THEN
				LET vm_cta_final = r_b10.b10_cuenta
				LET nom_cta_fin  = r_b10.b10_descripcion
				DISPLAY BY NAME vm_cta_final, nom_cta_fin
				NEXT FIELD vm_cta_final
			END IF
		ELSE
			CLEAR nom_cta_ini
		END IF
	AFTER FIELD vm_cta_final
		IF vm_cta_final IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, vm_cta_final) 
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la cuenta en la Compañía.','exclamation')
				CLEAR nom_cta_fin
				NEXT FIELD vm_cta_final
			ELSE
				LET vm_cta_final   = r_b10.b10_cuenta
				DISPLAY r_b10.b10_descripcion TO nom_cta_fin
				LET nom_cta_fin = r_b10.b10_descripcion
			END IF
		ELSE
			CLEAR nom_cta_fin
		END IF
	AFTER FIELD vm_moneda
		IF vm_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(vm_moneda)
				RETURNING rm_g13.*
			IF rm_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la moneda en la Compañía.','exclamation')
				CLEAR nom_moneda
				NEXT FIELD vm_moneda
			ELSE
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		ELSE
			CLEAR nom_moneda
		END IF
	AFTER FIELD vm_tipo_comp
		IF vm_tipo_comp IS NOT NULL THEN
			CALL fl_lee_tipo_comprobante_contable(vg_codcia,
								vm_tipo_comp)
				RETURNING r_b03.*
			IF r_b03.b03_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este tipo de comprobante.', 'exclamation')
				NEXT FIELD vm_tipo_comp
			END IF
			DISPLAY BY NAME r_b03.b03_nombre
		ELSE
			CLEAR b03_nombre
		END IF
	AFTER FIELD vm_subtipo
		IF vm_subtipo IS NOT NULL THEN
			CALL fl_lee_subtipo_comprob_contable(vg_codcia,
								vm_subtipo)
				RETURNING r_b04.*
			IF r_b04.b04_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este subtipo de comprobante.', 'exclamation')
				NEXT FIELD vm_subtipo
			END IF
			DISPLAY BY NAME r_b04.b04_nombre
		ELSE
			CLEAR b04_nombre
		END IF
	AFTER INPUT 
		IF vm_cta_inicial IS NULL THEN
			NEXT FIELD vm_cta_inicial
		END IF
		IF vm_cta_final IS NULL THEN
			NEXT FIELD vm_cta_final
		END IF
		IF vm_fecha_ini IS NULL THEN
			NEXT FIELD vm_fecha_ini
		END IF
		IF vm_fecha_fin IS NULL THEN
			NEXT FIELD vm_fecha_fin
		END IF
		IF vm_moneda IS NULL THEN
			NEXT FIELD vm_moneda
		END IF
END INPUT

END FUNCTION



REPORT report_movimientos_ctas(r_b13, r_b12)
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_b03		RECORD LIKE ctbt003.*
DEFINE r_b04		RECORD LIKE ctbt004.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE titulo		VARCHAR(80)
DEFINE glosa		VARCHAR(230)
DEFINE fecha_ini	DATE
DEFINE val1		DECIMAL(14,2)
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
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_justifica_titulo('C','LISTADO DE MOVIMIENTOS DE CUENTAS',80)
		RETURNING titulo
	--SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rg_cia.g01_razonsocial
	PRINT COLUMN 026, titulo CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 122, 'PAGINA: ', 
	      COLUMN 130, PAGENO USING '&&&'
	PRINT COLUMN 001, 'CUENTA INICIAL: ', 
	      COLUMN 023, vm_cta_inicial, '  ', nom_cta_ini,
	      COLUMN 126, UPSHIFT(vg_proceso)
	PRINT COLUMN 001, 'CUENTA FINAL: ', 
	      COLUMN 023, vm_cta_final, '  ', nom_cta_fin
	PRINT COLUMN 001, 'FECHA INICIAL: ',
	      COLUMN 023, vm_fecha_ini USING 'dd-mm-yyyy',
	      COLUMN 067, 'FECHA FINAL: ',
	      COLUMN 081, vm_fecha_fin USING 'dd-mm-yyyy'
	PRINT COLUMN 001, 'MONEDA: ',
	      COLUMN 023, rm_g13.g13_nombre
	IF vm_tipo_comp IS NOT NULL THEN
		CALL fl_lee_tipo_comprobante_contable(vg_codcia, vm_tipo_comp)
			RETURNING r_b03.*
		PRINT COLUMN 001, 'TIPO COMPROBANTE: ',
		      COLUMN 023, r_b03.b03_nombre
	END IF
	IF vm_subtipo IS NOT NULL THEN
		CALL fl_lee_subtipo_comprob_contable(vg_codcia,	vm_subtipo)
			RETURNING r_b04.*
		PRINT COLUMN 001, 'SUBTIPO COMPROBANTE: ',
		      COLUMN 023, r_b04.b04_nombre
	END IF
	PRINT COLUMN 001, 'USUARIO: ',
	      COLUMN 023, vg_usuario
	PRINT COLUMN 001, 'FECHA DE IMPRESION: ',
	      COLUMN 023, TODAY USING 'dd-mm-yyyy', 1 SPACES, TIME
	PRINT '------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 001, 'TP',
	      COLUMN 004, 'NUMERO',
	      COLUMN 014, 'FECHA PRO.',
	      COLUMN 026, 'G L O S A',
	      COLUMN 087, '        DEBITO',
	      COLUMN 103, '       CREDITO',
	      COLUMN 119, '         SALDO'
	PRINT '------------------------------------------------------------------------------------------------------------------------------------'

BEFORE GROUP OF r_b13.b13_cuenta
	NEED 3 LINES 
	LET vm_tot_debito  = 0
	LET vm_tot_credito = 0
	CALL fl_lee_cuenta(vg_codcia, r_b13.b13_cuenta) RETURNING r_b10.*
	LET fecha_ini = vm_fecha_ini - 1 
	IF r_b10.b10_cuenta[1, 1] <> '3' THEN
		CALL fl_obtiene_saldo_contable(vg_codcia, r_b10.b10_cuenta, 
				  	     rm_g13.g13_moneda, fecha_ini, 'A')
			RETURNING vm_saldo
	ELSE
		CALL fl_obtener_saldo_cuentas_patrimonio(vg_codcia,
					r_b10.b10_cuenta, rm_g13.g13_moneda,
					fecha_ini, TODAY, 'A')
			RETURNING vm_saldo, val1
	END IF
	PRINT COLUMN 001, r_b10.b10_descripcion, ': ', r_b10.b10_cuenta,
	      COLUMN 070, 'SALDO AL ', fecha_ini USING 'dd-mm-yyyy', '  ==> ',
	      COLUMN 096, vm_saldo USING '---,---,--&.--'
	
ON EVERY ROW
	NEED 5 LINES 
	IF r_b12.b12_benef_che IS NOT NULL THEN
		LET glosa = r_b12.b12_benef_che[1,23] CLIPPED, ' ' 
		--LET glosa = NULL
		INITIALIZE r_g09.* TO NULL
		DECLARE q_bco CURSOR FOR
			SELECT * FROM gent009
				WHERE g09_compania = vg_codcia
				  AND g09_estado   = "A"
				  AND g09_aux_cont = r_b13.b13_cuenta
		OPEN q_bco
		FETCH q_bco INTO r_g09.*
		IF STATUS = NOTFOUND THEN
			LET glosa = r_b13.b13_glosa CLIPPED
		END IF
		CLOSE q_bco
		FREE q_bco
		LET glosa = 'Ch. ', r_b12.b12_num_cheque USING '&&&&#', ' ',
				glosa CLIPPED, ' ',
                            r_b12.b12_glosa CLIPPED
-- OJO
	ELSE
		LET glosa = r_b13.b13_glosa CLIPPED
		IF r_b12.b12_tipo_comp = 'DP' OR r_b12.b12_tipo_comp = 'EC'
			OR r_b12.b12_tipo_comp = 'DO' 
			OR r_b12.b12_tipo_comp = 'DC' THEN
			LET glosa = r_b12.b12_glosa CLIPPED, ' ',
				    r_b13.b13_glosa CLIPPED
		END IF
	END IF
	IF r_b13.b13_valor_base < 0 THEN
		LET vm_saldo = vm_saldo + r_b13.b13_valor_base
		PRINT COLUMN 001, r_b13.b13_tipo_comp,
	      	      COLUMN 004, r_b13.b13_num_comp,
	      	      COLUMN 014, r_b13.b13_fec_proceso USING 'dd-mm-yyyy',
	      	      COLUMN 026, glosa[1, 60],
	      	      COLUMN 087, '0.00'		USING '###,###,##&.##',
	      	      COLUMN 103, r_b13.b13_valor_base	USING '###,###,##&.##',
		      COLUMN 119, vm_saldo		USING '---,---,--&.--'
		IF glosa[61,120] IS NOT NULL OR glosa[61,120] <> ' ' THEN
			PRINT COLUMN 026, glosa[61,120] 
		END IF
		IF glosa[121,180] IS NOT NULL OR glosa[121,180] <> ' ' THEN
			PRINT COLUMN 026, glosa[121,180] 
		END IF
		IF glosa[181,230] IS NOT NULL OR glosa[181,230] <> ' ' THEN
			PRINT COLUMN 026, glosa[181,230] 
		END IF
		LET vm_tot_credito = vm_tot_credito + r_b13.b13_valor_base 
	ELSE
		LET vm_saldo = vm_saldo + r_b13.b13_valor_base
		PRINT COLUMN 001, r_b13.b13_tipo_comp,
	      	      COLUMN 004, r_b13.b13_num_comp,
	      	      COLUMN 014, r_b13.b13_fec_proceso USING 'dd-mm-yyyy',
	      	      COLUMN 026, glosa[1, 60],
	      	      COLUMN 087, r_b13.b13_valor_base	USING '###,###,##&.##',
		      COLUMN 103, '0.00'		USING '###,###,##&.##', 
		      COLUMN 119, vm_saldo		USING '---,---,--&.--'
		IF glosa[61,120] IS NOT NULL OR glosa[61,120] <> ' ' THEN
			PRINT COLUMN 026, glosa[61,120] 
		END IF
		IF glosa[121,180] IS NOT NULL OR glosa[121,180] <> ' ' THEN
			PRINT COLUMN 026, glosa[121,180] 
		END IF
		IF glosa[181,230] IS NOT NULL OR glosa[181,230] <> ' ' THEN
			PRINT COLUMN 026, glosa[181,230] 
		END IF
		LET vm_tot_debito = vm_tot_debito + r_b13.b13_valor_base
	END IF

AFTER GROUP OF r_b13.b13_cuenta
	NEED 4 LINES
	LET vm_tot_credito_g = vm_tot_credito_g + vm_tot_credito
	LET vm_tot_debito_g  = vm_tot_debito_g  + vm_tot_debito
	PRINT COLUMN 087, '--------------',
	      COLUMN 103, '--------------'
	PRINT COLUMN 087, vm_tot_debito  USING '###,###,##&.##',
	      COLUMN 103, vm_tot_credito USING '###,###,##&.##'
	SKIP 1 LINES

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 087, '--------------',
	      COLUMN 103, '--------------'
	PRINT COLUMN 064, 'TOTALES GENERALES ==>  ',
		vm_tot_debito_g USING '###,###,##&.##',
	      COLUMN 103, vm_tot_credito_g USING '###,###,##&.##';
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_b12.*, rm_b13.*, vm_fecha_ini, vm_fecha_fin, vm_tipo_comp,
		vm_subtipo TO NULL

END FUNCTION
