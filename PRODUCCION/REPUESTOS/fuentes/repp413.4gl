--------------------------------------------------------------------------------
-- Titulo           : repp413.4gl - Impresión Compra local
-- Elaboracion      : 27-dic-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp413 base módulo compañía localidad 
--		      tipo_tran num_tran
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_tipo_tran	LIKE rept019.r19_cod_tran
DEFINE vm_num_tran	LIKE rept019.r19_num_tran
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_c10		RECORD LIKE ordt010.*
DEFINE rm_p01		RECORD LIKE cxpt001.*
DEFINE rm_r01		RECORD LIKE rept001.*
DEFINE rm_r02		RECORD LIKE rept002.*
DEFINE rm_r19		RECORD LIKE rept019.*
DEFINE vm_num_item	INTEGER
DEFINE vm_num_lineas	INTEGER



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp413.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN   -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)
LET vm_tipo_tran = arg_val(5)
LET vm_num_tran  = arg_val(6)
LET vg_proceso   = 'repp413'
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
DEFINE comando		VARCHAR(100)
DEFINE r_rep		RECORD
				r20_item	LIKE rept020.r20_item,
				desc_clase	LIKE rept072.r72_desc_clase,
				unidades	LIKE rept010.r10_uni_med,
				desc_marca	LIKE rept073.r73_desc_marca,
				descripcion	LIKE rept010.r10_nombre,
				cant_ven	LIKE rept020.r20_cant_ven,
				precio		LIKE rept020.r20_precio,
				descuento	LIKE rept020.r20_descuento,
				valor_tot	DECIMAL(14,2)
			END RECORD
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, vm_tipo_tran,
					vm_num_tran)
	RETURNING rm_r19.*
IF rm_r19.r19_num_tran IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compra local.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_r19.r19_oc_interna)
	RETURNING rm_c10.*
IF rm_c10.c10_numero_oc IS NULL THEN
	CALL fl_mostrar_mensaje('No existe orden de compra.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_proveedor(rm_c10.c10_codprov) RETURNING rm_p01.*
IF rm_p01.p01_codprov IS NULL THEN
	CALL fl_mostrar_mensaje('No existe proveedor.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_moneda(rm_r19.r19_moneda) RETURNING rm_g13.*
IF rm_g13.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('No existe moneda.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor) RETURNING rm_r01.*
IF rm_r01.r01_codigo IS NULL THEN
	CALL fl_mostrar_mensaje('No existe vendedor.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori) RETURNING rm_r02.*
IF rm_r02.r02_codigo IS NULL THEN
	CALL fl_mostrar_mensaje('No existe bodega.','stop')
	EXIT PROGRAM
END IF
SELECT COUNT(*) INTO vm_num_item FROM rept020
	WHERE r20_compania  = vg_codcia
	  AND r20_localidad = vg_codloc
	  AND r20_cod_tran  = rm_r19.r19_cod_tran
	  AND r20_num_tran  = rm_r19.r19_num_tran
DECLARE q_rept020 CURSOR FOR
	SELECT rept020.* FROM rept020
		WHERE r20_compania  = vg_codcia
		  AND r20_localidad = vg_codloc
		  AND r20_cod_tran  = rm_r19.r19_cod_tran
		  AND r20_num_tran  = rm_r19.r19_num_tran
	    	ORDER BY r20_orden
START REPORT report_compra_local TO PIPE comando
LET vm_num_lineas = 0
FOREACH q_rept020 INTO r_r20.*
	CALL fl_lee_item(vg_codcia, r_r20.r20_item) RETURNING r_r10.*
	CALL fl_lee_marca_rep(vg_codcia, r_r10.r10_marca)
		RETURNING r_r73.*
	CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea, r_r10.r10_sub_linea,					r_r10.r10_cod_grupo, r_r10.r10_cod_clase)
		RETURNING r_r72.*
	LET r_rep.r20_item	= r_r20.r20_item
	LET r_rep.desc_clase	= r_r72.r72_desc_clase
	LET r_rep.unidades	= UPSHIFT(r_r10.r10_uni_med)
	LET r_rep.desc_marca	= r_r73.r73_desc_marca
	LET r_rep.descripcion	= r_r10.r10_nombre
	LET r_rep.cant_ven	= r_r20.r20_cant_ven
	LET r_rep.precio	= r_r20.r20_precio
	LET r_rep.descuento	= r_r20.r20_descuento
	LET r_rep.valor_tot	= (r_r20.r20_cant_ven * r_r20.r20_precio) -
				   r_r20.r20_val_descto
	OUTPUT TO REPORT report_compra_local(r_rep.*)
END FOREACH
FINISH REPORT report_compra_local

END FUNCTION



REPORT report_compra_local(r_rep)
DEFINE r_rep		RECORD
				r20_item	LIKE rept020.r20_item,
				desc_clase	LIKE rept072.r72_desc_clase,
				unidades	LIKE rept010.r10_uni_med,
				desc_marca	LIKE rept073.r73_desc_marca,
				descripcion	LIKE rept010.r10_nombre,
				cant_ven	LIKE rept020.r20_cant_ven,
				precio		LIKE rept020.r20_precio,
				descuento	LIKE rept020.r20_descuento,
				valor_tot	DECIMAL(14,2)
			END RECORD
DEFINE documento	VARCHAR(50)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
DEFINE subtotal		DECIMAL(14,2)
DEFINE impuesto		DECIMAL(14,2)
DEFINE valor_pag	DECIMAL(14,2)
DEFINE orden		VARCHAR(10)
DEFINE forma		VARCHAR(8)
DEFINE label_letras	VARCHAR(130)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	0
	RIGHT  MARGIN	132
	BOTTOM MARGIN	3
	PAGE   LENGTH	44

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET modulo    = "MODULO: INVENTARIO"
	LET long      = LENGTH(modulo)
	LET documento = 'COMPROBANTE COMPRA LOCAL No. ',
			rm_r19.r19_num_tran USING "<<<<<<<&"
	CALL fl_justifica_titulo('C', documento CLIPPED, 80) RETURNING titulo
	LET titulo = modulo, titulo
	LET subtotal    = rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto +
			  rm_c10.c10_otros + rm_c10.c10_dif_cuadre
	LET impuesto    = rm_r19.r19_tot_neto - rm_r19.r19_tot_bruto +
			  rm_r19.r19_tot_dscto - rm_c10.c10_flete -
			  rm_c10.c10_otros - rm_c10.c10_dif_cuadre
	LET valor_pag   = rm_r19.r19_tot_neto
	LET orden	= rm_r19.r19_oc_interna
	IF rm_r19.r19_cont_cred = 'R' THEN
		LET forma = 'CREDITO'
	ELSE
		LET forma = 'CONTADO'
	END IF
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 107, "PAG. ", PAGENO USING "&&&"
	PRINT COLUMN 01,  titulo
	SKIP 1 LINES
	PRINT COLUMN 01,  "PROVEEDOR (", rm_c10.c10_codprov
				USING "&&&&&", ") : ", rm_p01.p01_nomprov,
	      COLUMN 69,  "FECHA COMPRA LOCAL : ", DATE(rm_r19.r19_fecing) 
			 			USING "dd-mm-yyyy"
	PRINT COLUMN 01,  "CEDULA/RUC        : ", rm_p01.p01_num_doc,
	      COLUMN 69,  "ORDEN DE COMPRA    : ", orden
	PRINT COLUMN 01,  "DIRECCION         : ", rm_p01.p01_direccion1,
	      COLUMN 69,  "FACTURA            : ", rm_r19.r19_oc_externa
	PRINT COLUMN 01,  "TELEFONO          : ", rm_p01.p01_telefono1, " ",
						  rm_p01.p01_telefono2,
	      COLUMN 69,  "ALMACEN            : ", rm_loc.g02_nombre
	PRINT COLUMN 01,  "FAX               : ", rm_p01.p01_fax1, " ",
						  rm_p01.p01_fax2,
	      COLUMN 69,  "RUC                : ", rm_loc.g02_numruc
	PRINT COLUMN 01,  "REFERENCIA        : ", rm_c10.c10_referencia,
	      COLUMN 69,  "DIRECCION          : ", rm_loc.g02_direccion
	PRINT COLUMN 01,  "FORMA DE PAGO     : ", forma,
	      COLUMN 69,  "TELEFONO           : ", rm_loc.g02_telefono1, " ",
						   rm_loc.g02_telefono2
	PRINT COLUMN 01,  "BODEGA            : [", rm_r02.r02_codigo, "] ",
						  rm_r02.r02_nombre,
	      COLUMN 69,  "FAX                : ", rm_loc.g02_fax1, " ",
						   rm_loc.g02_fax2
	PRINT COLUMN 01,  "FECHA IMPRESION   : ", DATE(TODAY)
			USING 'dd-mm-yyyy', 1 SPACES, TIME,
	      COLUMN 69,  "USUARIO            : ", rm_r01.r01_nombres
	SKIP 1 LINES
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 02,  "CODIGO",
	      COLUMN 11,  "DESCRIPCION",
	      COLUMN 56,  "MEDIDA",
	      COLUMN 64,  "MARCA",
	      COLUMN 82,  "CANTIDAD",
	      COLUMN 96,  "PRECIO VENTA",
	      COLUMN 110, "%DSCTO",
	      COLUMN 121, "VALOR TOTAL"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES
	LET vm_num_lineas = vm_num_lineas + 1
	PRINT COLUMN 02,  r_rep.r20_item[1,7],
	      COLUMN 11,  r_rep.desc_clase,
	      COLUMN 56,  r_rep.unidades,
	      COLUMN 64,  r_rep.desc_marca
	PRINT COLUMN 13,  r_rep.descripcion[1,65],
	      COLUMN 82,  r_rep.cant_ven	USING '###,##&.##',
	      COLUMN 94,  r_rep.precio		USING '##,###,##&.###',
	      COLUMN 110, r_rep.descuento	USING '##&.##',
	      COLUMN 118, r_rep.valor_tot	USING '###,###,##&.##'
	
PAGE TRAILER
	LET label_letras = fl_retorna_letras(rm_r19.r19_moneda, valor_pag)
	SKIP 2 LINES
	IF vm_num_lineas = vm_num_item THEN
		PRINT COLUMN 02,  "SOMOS CONTRIBUYENTES ESPECIALES D.G.R. # 39",
		      COLUMN 95,  "TOTAL BRUTO",
		      COLUMN 116, rm_r19.r19_tot_bruto	USING "#,###,###,##&.##"
		PRINT COLUMN 02,  "PRECIOS SUJETOS A CAMBIO SIN PREVIO AVISO",
		      COLUMN 95,  "DESCUENTOS",
		      COLUMN 118, rm_r19.r19_tot_dscto	USING "###,###,##&.##"
		PRINT COLUMN 95,  "SEGURO",
	      	      COLUMN 118, rm_c10.c10_otros	USING "###,###,##&.##"
		PRINT COLUMN 95,  "SUBTOTAL",
		      COLUMN 118, subtotal		USING "###,###,##&.##"
		PRINT COLUMN 95,  "I. V. A. (", rm_r19.r19_porc_impto
							USING "#&", ") %",
		      COLUMN 118, impuesto		USING "###,###,##&.##"
		PRINT COLUMN 95,  "TRANSPORTE",
	      	      COLUMN 118, rm_c10.c10_flete	USING "###,###,##&.##"
		PRINT COLUMN 02,  "SON: ", label_letras[1,87],
		      COLUMN 95,  "VALOR A PAGAR",
		      COLUMN 116, valor_pag	USING "#,###,###,##&.##";
	ELSE
		PRINT COLUMN 02, 1 SPACES
		PRINT COLUMN 02, 1 SPACES
		PRINT COLUMN 02, 1 SPACES
		PRINT COLUMN 02, 1 SPACES
		PRINT COLUMN 02, 1 SPACES
		PRINT COLUMN 02, 1 SPACES
		PRINT COLUMN 02, 1 SPACES;
	END IF
	print ASCII escape;
	print ASCII desact_comp 

END REPORT
