--------------------------------------------------------------------------------
-- Titulo           : talp406.4gl - Listado de Gastos de Viaje por Técnico   --
-- Elaboracion      : 12-ABR-2002					      --
-- Autor            : GVA						      --
-- Formato Ejecucion: fglrun talp406 base módulo cia loc [num_gasto]	      --
-- Ultima Correccion: 							      --
-- Motivo Correccion: 							      --
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_t30		RECORD LIKE talt030.*
DEFINE rm_t23		RECORD LIKE talt023.*

DEFINE rm_g13		RECORD LIKE gent013.*

DEFINE vm_num_gasto	LIKE talt030.t30_num_gasto

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
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN   	-- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF

LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)
LET vm_num_gasto = arg_val(5)

LET vg_proceso = 'talp406'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		CHAR(400)
DEFINE comando 		VARCHAR(100)
DEFINE r_report 	RECORD
	secuencia	LIKE talt031.t31_secuencia,
	descripcion	LIKE talt031.t31_descripcion,
	valor		LIKE talt031.t31_valor
	END RECORD

LET vm_top    = 0
LET vm_left   = 20
LET vm_right  = 90
LET vm_bottom = 4
LET vm_page   = 66

CALL fl_lee_gasto_viaje(vg_codcia, vg_codloc, vm_num_gasto)
	RETURNING rm_t30.*
IF rm_t30.t30_num_gasto IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe Gasto de Viaje en la Compañía.','exclamation')
	CALL fl_mostrar_mensaje('No existe Gasto de Viaje en la Compañía.','exclamation')
	EXIT PROGRAM
END IF
CALL fl_lee_moneda(rm_t30.t30_moneda)
	RETURNING rm_g13.*
CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_t30.t30_num_ot)
	RETURNING rm_t23.*

WHILE TRUE

	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		EXIT PROGRAM
	END IF

	LET query = 'SELECT t31_secuencia, t31_descripcion, t31_valor',
			'  FROM talt031 ',
			'WHERE t31_compania  =',vg_codcia,
			'  AND t31_localidad =',vg_codloc,
			'  AND t31_num_gasto =',vm_num_gasto,
			'  AND t31_moneda    ="',rm_t30.t30_moneda,'"',
			' ORDER BY t31_secuencia'

	PREPARE reporte FROM query
	DECLARE q_reporte CURSOR FOR reporte

	START REPORT report_gastos_viaje TO PIPE comando
	CLOSE q_reporte

	FOREACH q_reporte INTO r_report.* 
		OUTPUT TO REPORT report_gastos_viaje(r_report.*)
		IF int_flag THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FINISH REPORT report_gastos_viaje

	EXIT PROGRAM

END WHILE 

END FUNCTION



REPORT report_gastos_viaje(secuencia, descripcion, valor)
DEFINE secuencia	LIKE talt031.t31_secuencia
DEFINE descripcion	LIKE talt031.t31_descripcion
DEFINE valor		LIKE talt031.t31_valor
DEFINE nom_estado 	CHAR(10)
DEFINE fecha_aux 	DATE

DEFINE titulo		VARCHAR(80)

OUTPUT
	TOP MARGIN	0
	LEFT MARGIN	20
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT
PAGE HEADER

	--#print 'E'; --#print '&l26A';  -- Indica que voy a trabajar con hojas A4
	--#print '&k4S'	                -- Letra condensada (12 cpi)

	CALL fl_justifica_titulo('C',
	     'GASTO DE VIAJE No  ' || rm_t30.t30_num_gasto, 60)
		RETURNING titulo

	CASE rm_t30.t30_estado 
		WHEN 'A'
			LET nom_estado = 'ACTIVO'
		WHEN 'E'
			LET nom_estado = 'ELIMINADO'
	END CASE  

	PRINT COLUMN 1, rg_cia.g01_razonsocial
	PRINT COLUMN 1, titulo CLIPPED
	PRINT COLUMN 1, 'Fecha de Impresión: ', TODAY USING 'dd-mm-yyyy',
			 1 SPACES, TIME,
		COLUMN 48, 'Página: ', PAGENO USING '&&&'

	SKIP 1 LINES

	--#print '&k2S'	                -- Letra condensada (16 cpi)

	LET fecha_aux = DATE(rm_t30.t30_fecing) USING 'dd-mm-yyyy'

	PRINT COLUMN 01, 'No Gasto:', 
	      COLUMN 20, fl_justifica_titulo('I',rm_t30.t30_num_gasto,8),
	      COLUMN 30, 'Estado:  ',nom_estado,
	      COLUMN 60, 'Fecha de Gasto: ', 
	      COLUMN 80, fecha_aux

	PRINT COLUMN 01, 'Moneda:  ',
	      COLUMN 20,  rm_g13.g13_nombre,
	      COLUMN 60, 'Ingresado Por:',
	      COLUMN 80, fl_justifica_titulo('D',rm_t30.t30_usuario,10)

	PRINT COLUMN 01, 'Fecha de Inicio:',
	      COLUMN 20, rm_t30.t30_fec_ini_viaje USING 'dd-mm-yyyy',
	      COLUMN 60, 'Fecha final:',
	      COLUMN 80, rm_t30.t30_fec_fin_viaje USING 'dd-mm-yyyy'
	
	PRINT COLUMN 01, 'Origen:',
	      COLUMN 20, rm_t30.t30_origen,
	      COLUMN 60, 'Destino:',
	      COLUMN 75, fl_justifica_titulo('D',rm_t30.t30_destino[1,15],15)

	PRINT COLUMN 01, 'Orden de Trabajo:',
	      COLUMN 20, fl_justifica_titulo('I',rm_t30.t30_num_ot,8),
	      COLUMN 30, rm_t23.t23_nom_cliente[1,25],
	      COLUMN 75, fl_justifica_titulo('D',rm_t30.t30_destino[16,30],15)

	PRINT COLUMN 01, 'Descripcion:',
	      COLUMN 20, rm_t30.t30_desc_viaje[1,70]
	PRINT COLUMN 30, rm_t30.t30_desc_viaje[71,120]

	PRINT COLUMN 10, "================================================================"
	PRINT COLUMN 10, 'No',
	      COLUMN 18, 'Descripción',
	      COLUMN 69, 'Valor'
	PRINT COLUMN 10, "================================================================"

ON EVERY ROW
	PRINT COLUMN 10, fl_justifica_titulo('I',secuencia,6),
	      COLUMN 18, descripcion,
	      COLUMN 60, valor		USING '###,###,##&.##'

ON LAST ROW

	--#print '&k4S'	                -- Letra condensada (12 cpi)
	PRINT COLUMN 10, 'TOTAL ',
	      COLUMN 32,rm_t30.t30_tot_gasto 	USING '#,###,###,##&.##' 

END REPORT
