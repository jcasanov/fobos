------------------------------------------------------------------------------
-- Titulo           : talp402.4gl - Impresión Devolución Factura
-- Elaboracion      : 19-feb-2004
-- Autor            : JCM
-- Formato Ejecucion: fglrun talp402 base módulo compañía localidad 
--		      num_dev
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_tran	LIKE talt028.t28_num_dev

DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_t03		RECORD LIKE talt003.*
DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t24		RECORD LIKE talt024.*
DEFINE rm_t28		RECORD LIKE talt028.*

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp402.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 
			    'stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)

LET vm_num_tran  = arg_val(5)

LET vg_proceso = 'talp402'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

LET vm_top    = 2
LET vm_left   =	2
LET vm_right  =	90
LET vm_bottom =	4
LET vm_page   = 66

CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()

DEFINE i,col		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE expr_sql         VARCHAR(600)
DEFINE comando		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	EXIT PROGRAM
END IF

CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe compañía.',
		'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_devolucion_factura_taller(vg_codcia, vg_codloc, vm_num_tran)
	RETURNING rm_t28.*
IF rm_t28.t28_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe devolucion # ' || 
                                         vm_num_tran || '.', 'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_factura_taller(vg_codcia, vg_codloc, rm_t28.t28_factura)
	RETURNING rm_t23.*
IF rm_t23.t23_num_factura IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe factura de taller.',
		'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_moneda(rm_t23.t23_moneda) RETURNING rm_g13.*
IF rm_g13.g13_moneda IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe moneda.',
		'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_mecanico(vg_codcia, rm_t23.t23_cod_asesor) RETURNING rm_t03.*
IF rm_t03.t03_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe asesor.', 'stop')
	EXIT PROGRAM
END IF

LET query = 'SELECT talt024.* FROM talt024 ',
	    '	WHERE t24_compania    = ', vg_codcia,
	    '  	  AND t24_localidad   = ', vg_codloc,
	    '	  AND t24_orden       = ', rm_t23.t23_orden,
	    '     AND t24_valor_tarea > 0 ',
	    '	ORDER BY t24_secuencia '

PREPARE deto FROM query
DECLARE q_deto CURSOR FOR deto
OPEN q_deto
FETCH q_deto
IF STATUS = NOTFOUND THEN
	CLOSE q_deto
	CALL fl_mensaje_consulta_sin_registros()
	EXIT PROGRAM
END IF
CLOSE q_deto
START REPORT report_devolucion TO PIPE comando
FOREACH q_deto INTO rm_t24.*
	OUTPUT TO REPORT report_devolucion()
END FOREACH
FINISH REPORT report_devolucion

END FUNCTION



REPORT report_devolucion()

DEFINE documento	VARCHAR(36)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page

FORMAT
PAGE HEADER
	LET modulo    = "Módulo: Taller"
	LET long      = LENGTH(modulo)
	LET documento = 'DEVOLUCION FACTURA # ' || rm_t28.t28_num_dev 
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', documento CLIPPED, 78)
		RETURNING titulo

	LET titulo = modulo, titulo
	SKIP 2 LINES
	print 'E';
	print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&k2S' 		-- Letra condensada
	SKIP 4 LINES
	LET modulo  = "Módulo: Taller "
	PRINT COLUMN 1,  rm_cia.g01_razonsocial,
	      COLUMN 92, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1,  titulo CLIPPED,
	      COLUMN 92, UPSHIFT(vg_proceso)
	      
	SKIP 1 LINES

--	cabecera de la devolucion  
	PRINT COLUMN 1, fl_justifica_titulo('I', 'Factura Devuelta', 16), ': ', 
			fl_justifica_titulo('I', rm_t28.t28_factura, 13),
	      COLUMN 72, fl_justifica_titulo('I', 'Fecha Devolución', 18), 
	      		': ', DATE(rm_t28.t28_fec_anula) USING 'dd-mmm-yyyy'
	      		
	PRINT COLUMN 1, fl_justifica_titulo('I', 'Cliente', 16), ': ',  
			fl_justifica_titulo('I', rm_t23.t23_cod_cliente, 5) CLIPPED,
			'  ', rm_t23.t23_nom_cliente,
	      COLUMN 72, fl_justifica_titulo('I', 'Moneda', 18), ': ',
	      		rm_g13.g13_nombre
	PRINT COLUMN 1, fl_justifica_titulo('I', 'Asesor', 16), ': ',
	      		rm_t03.t03_iniciales
	      
	PRINT COLUMN 1, fl_justifica_titulo('I', 'Referencia', 16), ': ',
	      		rm_t28.t28_motivo_dev
	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha impresión: ", TODAY USING "dd-mmm-yyyy", 1 SPACES, TIME,
	      COLUMN 93, usuario
	SKIP 1 LINES
	PRINT COLUMN 5,  'Descripcion ',
	      COLUMN 69, fl_justifica_titulo('D', 'Precio', 16),
	      COLUMN 87, fl_justifica_titulo('D', 'Total', 16)

	PRINT COLUMN 5,  '--------------------------------------------------------------------',
	      COLUMN 69, '------------------',
	      COLUMN 87, '----------------'

ON EVERY ROW
		PRINT COLUMN 05,  rm_t24.t24_descripcion CLIPPED,
		      COLUMN 69,  rm_t24.t24_valor_tarea USING "###,###,##&.##",
		      COLUMN 87, rm_t24.t24_valor_tarea USING "###,###,##&.##"
	
ON LAST ROW
  	IF rm_t23.t23_val_otros1 > 0 THEN
		PRINT COLUMN 05,  'VIATICOS:',
		      COLUMN 69, rm_t23.t23_val_otros1 USING "###,###,##&.##",
		      COLUMN 87, rm_t23.t23_val_otros1 USING "###,###,##&.##"
	END IF
  	IF rm_t23.t23_val_otros2 > 0 THEN
		PRINT COLUMN 05,  'SUMINISTROS:',
		      COLUMN 69, rm_t23.t23_val_otros2 USING "###,###,##&.##",
		      COLUMN 87, rm_t23.t23_val_otros2 USING "###,###,##&.##"
	END IF
	
	NEED 5 LINES

        PRINT COLUMN 87, '--------------'
	PRINT COLUMN 40, 'SUBTOTAL   : ',
              COLUMN 87, rm_t23.t23_tot_bruto USING '###,###,##&.##'
	PRINT COLUMN 40, 'DESCUENTOS : ',
	      COLUMN 87, rm_t23.t23_tot_dscto USING '###,###,##&.##'
	PRINT COLUMN 40, 'IMPUESTOS  : ',
	      COLUMN 87, rm_t23.t23_val_impto USING '###,###,##&.##'
	SKIP 1 LINES
	PRINT COLUMN 40, 'TOTAL NETO : ',
	      COLUMN 87, rm_t23.t23_tot_neto  USING '###,###,##&.##' 

	PRINT 'E'

END REPORT



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
                            vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
