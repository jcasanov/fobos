------------------------------------------------------------------------------
-- Titulo           : repp416.4gl - Impresión Devolucion Compra Local
-- Elaboracion      : 28-dic-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp416 base módulo compañía localidad 
--		      tipo_tran num_tran
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

DEFINE vm_tipo_tran	LIKE rept019.r19_cod_tran
DEFINE vm_num_tran	LIKE rept019.r19_num_tran

DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_r19		RECORD LIKE rept019.*
DEFINE rm_c10		RECORD LIKE ordt010.*
DEFINE rm_p01		RECORD LIKE cxpt001.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_r01		RECORD LIKE rept001.*
DEFINE rm_r02		RECORD LIKE rept002.*

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
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN   -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)

LET vm_tipo_tran = arg_val(5)
LET vm_num_tran  = arg_val(6)

LET vg_proceso = 'repp416'

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
LET vm_left   =	2
LET vm_right  =	90
LET vm_bottom =	4
LET vm_page   = 66

CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()

DEFINE i,col		SMALLINT
DEFINE query		CHAR(1000)
DEFINE comando		VARCHAR(100)

DEFINE r_r20		RECORD LIKE rept020.*
DEFINE n_item		LIKE rept010.r10_nombre

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	EXIT PROGRAM
END IF

CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe compañía.','stop')
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF

CALL fl_lee_cabecera_transaccion_rep(vg_codcia,    vg_codloc, 
		                     vm_tipo_tran, vm_num_tran)
	RETURNING rm_r19.*
IF rm_r19.r19_num_tran IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe devolución de compra local.','stop')
	CALL fl_mostrar_mensaje('No existe devolución de compra local.','stop')
	EXIT PROGRAM
END IF

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_r19.r19_oc_interna)
	RETURNING rm_c10.*
IF rm_c10.c10_numero_oc IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe orden de compra.','stop')
	CALL fl_mostrar_mensaje('No existe orden de compra.','stop')
	EXIT PROGRAM
END IF
	
CALL fl_lee_proveedor(rm_c10.c10_codprov) RETURNING rm_p01.*
IF rm_p01.p01_codprov IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe proveedor.','stop')
	CALL fl_mostrar_mensaje('No existe proveedor.','stop')
	EXIT PROGRAM
END IF

CALL fl_lee_moneda(rm_r19.r19_moneda) RETURNING rm_g13.*
IF rm_g13.g13_moneda IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe moneda.','stop')
	CALL fl_mostrar_mensaje('No existe moneda.','stop')
	EXIT PROGRAM
END IF

CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor) RETURNING rm_r01.*
IF rm_r01.r01_codigo IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe vendedor.','stop')
	CALL fl_mostrar_mensaje('No existe vendedor.','stop')
	EXIT PROGRAM
END IF

CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori) RETURNING rm_r02.*
IF rm_r02.r02_codigo IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe bodega.','stop')
	EXIT PROGRAM
END IF

LET query = 'SELECT rept020.*, r10_nombre FROM rept020, rept010 ',
	    '	WHERE r20_compania  = ', vg_codcia,
	    '  	  AND r20_localidad = ', vg_codloc,
	    '	  AND r20_cod_tran  = "', vm_tipo_tran, '"',
	    '	  AND r20_num_tran  = ', vm_num_tran,
	    '	  AND r10_compania  = r20_compania ',
	    '	  AND r10_codigo    = r20_item ',
	    '	ORDER BY 1'
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
START REPORT compra_local TO PIPE comando
FOREACH q_deto INTO r_r20.*, n_item
	OUTPUT TO REPORT compra_local(r_r20.r20_cant_ven,
				     r_r20.r20_item,
				     n_item,
				     r_r20.r20_descuento,
				     r_r20.r20_precio,
				     r_r20.r20_val_impto)
END FOREACH
FINISH REPORT compra_local

END FUNCTION



REPORT compra_local(cant_ven, item, descripcion, descuento, precio, impto)

DEFINE documento	VARCHAR(30)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT

DEFINE impto		LIKE rept020.r20_val_impto

DEFINE cant_ven		LIKE rept020.r20_cant_ven
DEFINE item		LIKE rept020.r20_item 
DEFINE descripcion	LIKE rept010.r10_nombre
DEFINE descuento	LIKE rept020.r20_descuento
DEFINE precio		LIKE rept020.r20_precio

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	2
	RIGHT  MARGIN	90
	BOTTOM MARGIN	4
	PAGE   LENGTH	66
FORMAT
PAGE HEADER
	LET modulo    = "Módulo: Inventario"
	LET long      = LENGTH(modulo)
	LET documento = 'DEVOLUCION COMPRA LOCAL # ' || rm_r19.r19_num_tran
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', documento CLIPPED, 78)
		RETURNING titulo

	LET titulo = modulo, titulo
	PRINT COLUMN 1,  rm_cia.g01_razonsocial,
	      COLUMN 92, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1,  titulo CLIPPED,
	      COLUMN 92, UPSHIFT(vg_proceso)
	      
	SKIP 1 LINES
--	cabecera de la devolucion compra local
	PRINT COLUMN 1, fl_justifica_titulo('I', 'Compra Local', 15), ': ', 
			fl_justifica_titulo('I', rm_r19.r19_num_dev, 5),
	      COLUMN 72, fl_justifica_titulo('I', 'Fecha Devolución', 18), 
	      		': ', DATE(rm_r19.r19_fecing) USING 'dd-mmm-yyyy'
	      		
	PRINT COLUMN 1, fl_justifica_titulo('I', 'Orden De Compra', 15), ': ', 
			fl_justifica_titulo('I', rm_r19.r19_oc_interna, 5),
	      COLUMN 72, fl_justifica_titulo('I', 'Moneda', 18), ': ', 
	      		rm_g13.g13_nombre
	      		
	PRINT COLUMN 1, fl_justifica_titulo('I', 'Proveedor', 15), ': ',  
			fl_justifica_titulo('I', rm_c10.c10_codprov, 5) CLIPPED,
			'  ', rm_p01.p01_nomprov,
	      COLUMN 72, fl_justifica_titulo('I', 'Vendedor', 18), ': ', 
	      		rm_r01.r01_iniciales
	      		
	PRINT COLUMN 1, fl_justifica_titulo('I', 'Factura', 15), ': ',
	        	rm_r19.r19_oc_externa,
	      COLUMN 72, fl_justifica_titulo('I', 'Bodega', 18), ': ', 
	      		rm_r02.r02_nombre
	IF rm_r19.r19_cont_cred = 'R' THEN
		PRINT COLUMN 1, fl_justifica_titulo('I', 'Forma Pago', 15), 
				': Crédito'
	ELSE
		PRINT COLUMN 1, fl_justifica_titulo('I', 'Forma Pago', 15), 
				': Contado'
	END IF
--

	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha impresión: ", TODAY USING "dd-mmm-yyyy", 1 SPACES, TIME,
	      COLUMN 93, usuario
	SKIP 1 LINES
	PRINT COLUMN 01, 'Cantidad',
	      COLUMN 12, 'Item',
	      COLUMN 25, 'Descripción',
	      COLUMN 62, 'Desc.',
	      COLUMN 69, fl_justifica_titulo('D', 'Precio', 16),
	      COLUMN 87, fl_justifica_titulo('D', 'Total', 16)

	PRINT COLUMN 1,  '-------',
	      COLUMN 8,  '-----------------',
	      COLUMN 25, '-------------------------------------',
	      COLUMN 62, '-------',
	      COLUMN 69, '------------------',
	      COLUMN 87, '----------------'

ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 01, cant_ven USING "###,##&.##",
	      COLUMN 12, item[1,7],
	      COLUMN 25, descripcion[1,35],
	      COLUMN 62, descuento USING "#&.##",
	      COLUMN 69, precio USING "#,###,###,##&.##",
	      COLUMN 87, (cant_ven * precio) USING "#,###,###,##&.##"
	
ON LAST ROW
	NEED 6 LINES
	PRINT COLUMN 87, '----------------'
	PRINT COLUMN 74, '    Subtotal ',
			 rm_r19.r19_tot_bruto USING '#,###,###,##&.##'
	PRINT COLUMN 74, '(-)Descuento ',
			 rm_r19.r19_tot_dscto USING '#,###,###,##&.##'
	PRINT COLUMN 65, '(+) Impuesto (', rm_r19.r19_porc_impto USING '#&.##', 
			 '%) ', SUM(impto) USING '#,###,###,##&.##'
	PRINT COLUMN 87, '----------------'
	PRINT COLUMN 74, '       Total ', 
		         rm_r19.r19_tot_neto USING '#,###,###,##&.##'

END REPORT
