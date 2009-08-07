
--------------------------------------------------------------------------------
-- Titulo           : repp428.4gl - Impresion comprobante de importación      --
-- Elaboracion      : 23-ABR-2002					      --
-- Autor            : GVA						      --
-- Formato Ejecucion: fglrun repp428 base módulo cia loc cod_tran num_tran    --
-- Ultima Correccion: 							      --
-- Motivo Correccion: 							      --
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

DEFINE rm_r19		RECORD LIKE rept019.*		--CAB. TRANSACCION
DEFINE rm_r20		RECORD LIKE rept020.*		--DET. TRANSACCION
	
DEFINE rm_r28		RECORD LIKE rept028.*		--LIQUIDACION
DEFINE rm_p01		RECORD LIKE cxpt001.*		--PROVEEDOR

DEFINE rm_g13		RECORD LIKE gent013.*		--MONEDA

DEFINE vm_cod_tran	LIKE rept019.r19_cod_tran
DEFINE vm_num_tran	LIKE rept019.r19_num_tran

DEFINE vm_total_fob	DECIMAL(12,2)


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
IF num_args() <> 6 THEN   	-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.',
			    'stop')
	EXIT PROGRAM
END IF

LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)
LET vm_cod_tran  = arg_val(5)
LET vm_num_tran  = arg_val(6)

LET vg_proceso = 'repp428'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		VARCHAR(400)
DEFINE comando 		VARCHAR(100)
DEFINE r_report 	RECORD LIKE rept020.*

LET vm_top    = 0
LET vm_left   = 20
LET vm_right  = 90
LET vm_bottom = 4
LET vm_page   = 66

INITIALIZE rm_r19.*, rm_r20.*, rm_r28.*, rm_g13.*, rm_p01.* TO NULL

CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, 
				     vm_cod_tran, vm_num_tran)
	RETURNING rm_r19.*

IF rm_r19.r19_cod_tran IS NULL THEN
	CALL fgl_winmessage(vg_producto,
			    'No existe la transacción en la Compañía.',
			    'exclamation')
	EXIT PROGRAM
END IF

CALL fl_lee_moneda(rm_r19.r19_moneda)
	RETURNING rm_g13.*

CALL fl_lee_liquidacion_rep(vg_codcia, vg_codloc, rm_r19.r19_numliq)
	RETURNING rm_r28.*
IF rm_r28.r28_numliq IS NULL THEN
	CALL fgl_winmessage(vg_producto,
			    'No existe Liquidación en la Compañía.','stop')
	EXIT PROGRAM
END IF

CALL fl_lee_proveedor(rm_r28.r28_codprov)
	RETURNING rm_p01.*

LET vm_total_fob = 0

WHILE TRUE

	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		EXIT PROGRAM
	END IF

	LET query = 'SELECT * FROM rept020 ',
			'WHERE r20_compania  =',vg_codcia,
			'  AND r20_localidad =',vg_codloc,
			'  AND r20_cod_tran  ="',vm_cod_tran,'"',
			'  AND r20_num_tran  =',vm_num_tran,
			' ORDER BY r20_orden'

	PREPARE reporte FROM query
	DECLARE q_reporte CURSOR FOR reporte

	START REPORT report_transaccion_rep TO PIPE comando
	CLOSE q_reporte

	FOREACH q_reporte INTO r_report.* 
		OUTPUT TO REPORT report_transaccion_rep(r_report.*)
		IF int_flag THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FINISH REPORT report_transaccion_rep

	EXIT PROGRAM

END WHILE 

END FUNCTION



REPORT report_transaccion_rep(r_r20)
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r10		RECORD LIKE rept010.*

DEFINE fecha_aux 	DATE

OUTPUT
	TOP MARGIN	vm_top
	LEFT MARGIN	vm_left
	RIGHT MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE LENGTH	vm_page
FORMAT
PAGE HEADER

	print 'E'; print '&l26A';  -- Indica que voy a trabajar con hojas A4
	print '&k4S'	                -- Letra condensada (12 cpi)

	PRINT COLUMN 1, rg_cia.g01_razonsocial
	PRINT COLUMN 1, 'Fecha de Impresión: ', TODAY USING 'dd-mm-yyyy',
			 1 SPACES, TIME,
		COLUMN 48, 'Página: ', PAGENO USING '&&&'

	SKIP 1 LINES

	print '&k2S'	                -- Letra condensada (16 cpi)

	LET fecha_aux = DATE(rm_r19.r19_fecing) USING 'dd-mm-yyyy'

	PRINT COLUMN 01, 'No Importación:', 
	      COLUMN 20, rm_r19.r19_cod_tran, '  ',
			 fl_justifica_titulo('I',rm_r19.r19_num_tran,8),
	      COLUMN 60, 'Fecha Transacción:', 
	      COLUMN 80, fecha_aux

	PRINT COLUMN 01, 'Moneda:  ',
	      COLUMN 20,  rm_g13.g13_nombre,
	      COLUMN 60, 'Ingresado Por:',
	      COLUMN 80, fl_justifica_titulo('D',rm_r19.r19_usuario,10)

	PRINT COLUMN 01, 'Proveedor:',
	      COLUMN 20, fl_justifica_titulo('I',rm_p01.p01_codprov,8),'  ',
			 rm_p01.p01_nomprov

	PRINT COLUMN 01, 'No Liquidación:',
	      COLUMN 20, fl_justifica_titulo('I',rm_r28.r28_numliq,8)

	PRINT COLUMN 01, 'Factor Costo:',
	      COLUMN 20, fl_justifica_titulo('I',rm_r19.r19_fact_costo,12)
			 USING '#,###,##&.##',
	      COLUMN 60, 'Margen Utilidad:',
	      COLUMN 76, fl_justifica_titulo('I',rm_r19.r19_fact_venta,12)
			 USING '#,###,##&.##'
	
	PRINT COLUMN 01, 'Referencia:',
	      COLUMN 20, rm_r19.r19_referencia

	PRINT COLUMN 01, '========================================================================================='
	PRINT COLUMN 01, 'Item',
	      COLUMN 17, 'Descripción',
	      COLUMN 37, 'Cant',
	      COLUMN 46, 'FOB Unit.',
	      COLUMN 61, 'Costo Unit.',
	      COLUMN 79, 'Costo Total'
	PRINT COLUMN 01, '========================================================================================='

ON EVERY ROW
	CALL fl_lee_item(vg_codcia, r_r20.r20_item)
		RETURNING r_r10.*
	PRINT COLUMN 01, r_r20.r20_item,
	      COLUMN 17, r_r10.r10_nombre[1,16],
	      COLUMN 35, r_r20.r20_cant_ven,
	      COLUMN 41, r_r20.r20_fob	USING '###,###,##&.##',
	      COLUMN 58, r_r20.r20_costo USING '###,###,##&.##',
	      COLUMN 76, r_r20.r20_cant_ven * r_r20.r20_costo  	
			 USING '###,###,##&.##'

	LET vm_total_fob = vm_total_fob + r_r20.r20_cant_ven * r_r20.r20_fob

ON LAST ROW

	SKIP 1 LINES 
	print '&k4S'	                -- Letra condensada (12 cpi)
	PRINT COLUMN 10, 'Total FOB --> ',
	      COLUMN 44, vm_total_fob 	USING '#,###,###,##&.##' 
	PRINT COLUMN 10, 'Total Costo --> ',
	      COLUMN 44,rm_r19.r19_tot_costo 	USING '#,###,###,##&.##' 

END REPORT



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
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
