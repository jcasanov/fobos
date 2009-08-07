------------------------------------------------------------------------------
-- Titulo           : repp411.4gl - Impresión Ajuste de existencias
-- Elaboracion      : 07-Ene-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp411 base módulo compañía localidad 
--		      tipo_tran num_tran
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

DEFINE vm_tipo_tran	LIKE rept019.r19_cod_tran
DEFINE vm_num_tran	LIKE rept019.r19_num_tran

DEFINE vm_tipo_ajuste	VARCHAR(15)
DEFINE vm_ajuste_mas	LIKE rept019.r19_cod_tran
-- DEFINE vm_ajuste_menos	LIKE rept019.r19_cod_tran

DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_r02		RECORD LIKE rept002.*
DEFINE rm_r19		RECORD LIKE rept019.*

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 
			    'stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)

LET vm_tipo_tran = arg_val(5)
LET vm_num_tran  = arg_val(6)

LET vg_proceso = 'repp411'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

LET vm_ajuste_mas = 'A+'
-- LET vm_ajuste_menos = 'A-'

LET vm_top    = 1
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

DEFINE r_r20		RECORD LIKE rept020.*
DEFINE n_item		LIKE rept010.r10_nombre

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

CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, vm_tipo_tran, 
	vm_num_tran) RETURNING rm_r19.*
IF rm_r19.r19_num_tran IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe ajuste costo.',
		'stop')
	EXIT PROGRAM
END IF

IF rm_r19.r19_cod_tran = vm_ajuste_mas THEN
	LET vm_tipo_ajuste = 'INCREMENTO'
ELSE
	LET vm_tipo_ajuste = 'DECREMENTO'
END IF

CALL fl_lee_moneda(rm_r19.r19_moneda) RETURNING rm_g13.*
IF rm_g13.g13_moneda IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe moneda.',
		'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori) RETURNING rm_r02.*
IF rm_r02.r02_codigo IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe bodega.',
		'stop')
	EXIT PROGRAM
END IF

LET query = 'SELECT rept020.*, r10_nombre FROM rept020, rept010 ',
	    '	WHERE r20_compania  = ',  vg_codcia,
	    '  	  AND r20_localidad = ',  vg_codloc,
	    '	  AND r20_cod_tran  = "', vm_tipo_tran, '"',
	    '	  AND r20_num_tran  = ',  vm_num_tran,
	    '	  AND r10_compania  = r20_compania ',
	    '	  AND r10_codigo    = r20_item ',
	    '	ORDER BY r20_orden'

PREPARE deto FROM query
DECLARE q_deto CURSOR FOR deto
OPEN  q_deto
FETCH q_deto
IF STATUS = NOTFOUND THEN
	CLOSE q_deto
	CALL fl_mensaje_consulta_sin_registros()
	EXIT PROGRAM
END IF
CLOSE q_deto
START REPORT ajuste_existencia TO PIPE comando
FOREACH q_deto INTO r_r20.*, n_item
	OUTPUT TO REPORT ajuste_existencia(r_r20.r20_cant_ven,
				      r_r20.r20_item,
				      n_item,
				      r_r20.r20_costo)
END FOREACH
FINISH REPORT ajuste_existencia

END FUNCTION



REPORT ajuste_existencia(cant, item, descripcion, costo)

DEFINE documento	VARCHAR(30)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT

DEFINE cant		LIKE rept020.r20_cant_ven
DEFINE item		LIKE rept020.r20_item 
DEFINE descripcion	LIKE rept010.r10_nombre
DEFINE costo     	LIKE rept020.r20_costo

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page
FORMAT
PAGE HEADER
	print 'E';
	print '&l26A'		-- Indica que voy a trabajar con hojas A4
	LET modulo    = "Módulo: Repuestos"
	LET long      = LENGTH(modulo)
	LET documento = 'AJUSTE DE EXISTENCIA # ' || rm_r19.r19_num_tran
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', documento CLIPPED, 68)
		RETURNING titulo

	LET titulo = modulo, titulo
	PRINT COLUMN 1,  rm_cia.g01_razonsocial,
	      COLUMN 89, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1,  titulo CLIPPED,
	      COLUMN 89, UPSHIFT(vg_proceso)

	SKIP 1 LINES
	print '&k2S' 		-- Letra condensada
--	cabecera del ajuste_existencia
	PRINT COLUMN 1, fl_justifica_titulo('I', 'Tipo Ajuste', 15), ': ',
			vm_tipo_ajuste

	PRINT COLUMN 1, fl_justifica_titulo('I', 'Bodega', 15), ': ', 
			rm_r02.r02_codigo, ' ', rm_r02.r02_nombre,
	      COLUMN 68, fl_justifica_titulo('I', 'Fecha ', 19), 
	      		': ', DATE(rm_r19.r19_fecing) USING 'dd-mmm-yyyy'

	PRINT COLUMN 1, fl_justifica_titulo('I', 'Moneda', 15), ': ',
			rm_g13.g13_nombre
			
	PRINT COLUMN 1, fl_justifica_titulo('I', 'Referencia', 15), ': ',
	        	rm_r19.r19_referencia
--
	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha impresión: ", TODAY USING "dd-mmm-yyyy", 1 SPACES, TIME,
	      COLUMN 90, usuario
	SKIP 1 LINES
	PRINT COLUMN 1,  'Item',
	      COLUMN 18, 'Descripción',
	      COLUMN 55, fl_justifica_titulo('D', 'Cantidad', 10),
	      COLUMN 65, fl_justifica_titulo('D', 'Costo', 16),
	      COLUMN 83, fl_justifica_titulo('D', 'Total', 16)

	PRINT COLUMN 1,  '-----------------',
	      COLUMN 18, '-------------------------------------',
	      COLUMN 55, '------------',
	      COLUMN 65, '----------------',
	      COLUMN 83, '----------------'

ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 1,  item,
	      COLUMN 18, descripcion,
	      COLUMN 55, cant           USING "##,###,##&",
	      COLUMN 65, costo          USING "#,###,###,##&.##",
	      COLUMN 83, (cant * costo) USING "#,###,###,##&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 83, '----------------'
	PRINT COLUMN 71, 'Total Ajuste', 
		         SUM(cant * costo) 
		         USING '#,###,###,##&.##'

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
