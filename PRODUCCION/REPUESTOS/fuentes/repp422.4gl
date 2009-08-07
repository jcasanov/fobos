{*
 * Titulo           : repp422.4gl - Impresión despacho facturas
 * Elaboracion      : 05-nov-2008
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp422 base módulo compañía localidad 
 *		              tipo_tran num_tran
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_tipo_tran	LIKE rept019.r19_cod_tran
DEFINE vm_num_tran	LIKE rept019.r19_num_tran

DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_r01		RECORD LIKE rept001.*
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
CALL startlog('../logs/repp422.error')
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

LET vg_proceso = 'repp422'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

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

CALL fl_lee_cabecera_transaccion_rep(vg_codcia,    vg_codloc, 
		                     vm_tipo_tran, vm_num_tran)
	RETURNING rm_r19.*
IF rm_r19.r19_num_tran IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe compra local.',
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
	    '	WHERE r20_compania  = ', vg_codcia,
	    '  	  AND r20_localidad = ', vg_codloc,
	    '	  AND r20_cod_tran  = "', vm_tipo_tran, '"',
	    '	  AND r20_num_tran  = ', vm_num_tran,
	    '	  AND r10_compania  = r20_compania ',
	    '	  AND r10_codigo    = r20_item ',
	    '	ORDER BY r20_orden'

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
START REPORT egreso TO PIPE comando
FOREACH q_deto INTO r_r20.*, n_item
	OUTPUT TO REPORT egreso(r_r20.r20_cant_ven,
				     r_r20.r20_item,
				     n_item,
				     r_r20.r20_descuento,
				     r_r20.r20_precio,
				     r_r20.r20_val_impto)
END FOREACH
FINISH REPORT egreso

END FUNCTION



REPORT egreso(cant_ven, item, descripcion, descuento, precio, impto)

DEFINE documento	VARCHAR(40)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT

DEFINE impto		LIKE rept020.r20_val_impto

DEFINE fact			LIKE rept019.r19_cod_tran
DEFINE numfact		LIKE rept019.r19_num_tran

DEFINE cant_ven		LIKE rept020.r20_cant_ven
DEFINE item		LIKE rept020.r20_item 
DEFINE descripcion	LIKE rept010.r10_nombre
DEFINE descuento	LIKE rept020.r20_descuento
DEFINE precio		LIKE rept020.r20_precio

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page
FORMAT
PAGE HEADER
	print 'E'; print '&l26A'		-- Indica que voy a trabajar con hojas A4
	print '&k2S'	                	-- Letra  (12 cpi)
	LET modulo    = "Módulo: Repuestos"
	LET long      = LENGTH(modulo)
	LET documento = 'COMP. EGRESO POR DESPACHO # ' || rm_r19.r19_num_tran CLIPPED
		
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', documento CLIPPED, 78) RETURNING titulo

	LET titulo = modulo CLIPPED, titulo
	PRINT COLUMN 1,  rm_cia.g01_razonsocial,
	      COLUMN 92, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1,  titulo CLIPPED,
	      COLUMN 92, UPSHIFT(vg_proceso)
	      
	SKIP 1 LINES
--	cabecera de la compra local
	PRINT COLUMN 1, fl_justifica_titulo('I', rm_r19.r19_referencia, 22)
	      		
	PRINT COLUMN 1, fl_justifica_titulo('I', 'Bodega', 18), ': ', 
					rm_r02.r02_nombre,
	      COLUMN 72, "Fecha despacho: ", rm_r19.r19_fecing 
	PRINT COLUMN 1, fl_justifica_titulo('I', 'Cliente', 18), ': ', 
					rm_r19.r19_codcli, ' - ', rm_r19.r19_nomcli[1, 35]

	CALL obtener_factura(rm_r19.r19_compania, rm_r19.r19_localidad, 
						 rm_r19.r19_cod_tran, rm_r19.r19_num_tran)
		RETURNING fact, numfact
	PRINT COLUMN 1, fl_justifica_titulo('I', 'Factura interna', 18), ': ', 
					fact, ' - ', numfact USING '#####&'
--

	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha impresión: ", TODAY USING "dd-mmm-yyyy", 1 SPACES, TIME,
	      COLUMN 93, usuario
	SKIP 1 LINES
	PRINT COLUMN 1,  'Cant.',
	      COLUMN 8,  'Item',
	      COLUMN 25, 'Descripción'

	PRINT COLUMN 1,  '-------',
	      COLUMN 8,  '-----------------',
	      COLUMN 25, '-------------------------------------'

ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 1,  cant_ven USING "##&",
	      COLUMN 8,  item,
	      COLUMN 25, descripcion
	
END REPORT



FUNCTION obtener_factura(codcia, codloc, codtran, numtran)
DEFINE codcia		LIKE rept019.r19_compania
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE codtran		LIKE rept019.r19_cod_tran
DEFINE numtran		LIKE rept019.r19_num_tran
DEFINE r_r118		RECORD LIKE rept118.*

INITIALIZE r_r118.* TO NULL
SQL
	SELECT FIRST 1 * INTO $r_r118.*
	  FROM rept118
	 WHERE r118_compania  = $codcia 
	   AND r118_localidad = $codloc
	   AND r118_cod_desp  = $codtran
	   AND r118_num_desp  = $numtran
	 ORDER BY 1, 2, 3, 4
END SQL

RETURN r_r118.r118_cod_fact, r_r118.r118_num_fact

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
