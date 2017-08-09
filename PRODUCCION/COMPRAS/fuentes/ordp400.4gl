--------------------------------------------------------------------------------
-- Titulo           : ordp400.4gl - IMPRESION DE ORDEN DE COMPRA
-- Elaboracion      : 12-MAR-2002
-- Autor            : GVA
-- Formato Ejecucion: fglrun ordp400 base módulo compañía localidad [orden]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_c10		RECORD LIKE ordt010.*
DEFINE rm_p01		RECORD LIKE cxpt001.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE vm_num_item	INTEGER
DEFINE vm_num_lineas	INTEGER

DEFINE vm_impresion CHAR(1)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ordp400.err')
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN   -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.', 'stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso  = 'ordp400'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe compañía.','stop')
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe localidad.','stop')
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
IF num_args() = 5 THEN
	CALL control_reporte()
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 9
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rep FROM "../forms/ordf400_1"
ELSE
	OPEN FORM f_rep FROM "../forms/ordf400_1c"
END IF
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE comando		VARCHAR(100)
DEFINE r_rep		RECORD
				c11_codigo	LIKE ordt011.c11_codigo,
				desc_clase	LIKE rept072.r72_desc_clase,
				unidades	LIKE rept010.r10_uni_med,
				desc_marca	LIKE rept073.r73_desc_marca,
				descripcion	LIKE rept010.r10_nombre,
				cant_ped	LIKE ordt011.c11_cant_ped,
				precio		LIKE ordt011.c11_precio,
				descuento	LIKE ordt011.c11_descuento,
				valor_tot	DECIMAL(14,2)
			END RECORD
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c11		RECORD LIKE ordt011.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*

LET rm_c10.c10_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_c10.c10_moneda) RETURNING rm_g13.*
IF num_args() = 4 THEN
	DISPLAY rm_g13.g13_nombre TO tit_estado
END IF
WHILE TRUE
	IF num_args() = 4 THEN
		CALL lee_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	ELSE
		LET rm_c10.c10_numero_oc = arg_val(5)
		CALL fl_lee_orden_compra(vg_codcia, vg_codloc,
						rm_c10.c10_numero_oc)
			RETURNING rm_c10.*
	END IF
	CALL fl_control_reportes_extendido() RETURNING vm_impresion, comando
	IF int_flag THEN
		IF num_args() = 4 THEN
			CONTINUE WHILE
		ELSE
			EXIT WHILE
		END IF
	END IF
	CALL fl_lee_proveedor(rm_c10.c10_codprov) RETURNING rm_p01.*
	IF rm_p01.p01_codprov IS NULL THEN
		--CALL fgl_winmessage(vg_producto,'No existe proveedor.','stop')
		CALL fl_mostrar_mensaje('No existe proveedor.','stop')
		EXIT PROGRAM
	END IF
	SELECT COUNT(*) INTO vm_num_item FROM ordt011
		WHERE c11_compania  = vg_codcia
		  AND c11_localidad = vg_codloc
		  AND c11_numero_oc = rm_c10.c10_numero_oc
	DECLARE q_ordt011 CURSOR FOR
		SELECT ordt010.*, ordt011.* FROM ordt010, ordt011
			WHERE c10_compania  = vg_codcia
			  AND c10_localidad = vg_codloc
			  AND c10_numero_oc = rm_c10.c10_numero_oc
			  AND c10_moneda    = rm_c10.c10_moneda
			  AND c11_compania  = c10_compania
			  AND c11_localidad = c10_localidad
			  AND c11_numero_oc = c10_numero_oc
			ORDER BY c11_secuencia
	OPEN q_ordt011
	FETCH q_ordt011 INTO r_c10.*, r_c11.*
	IF STATUS = NOTFOUND THEN
		CLOSE q_ordt011
		CALL fl_mensaje_consulta_sin_registros()
		IF num_args() = 5 THEN
			EXIT WHILE
		END IF
		CONTINUE WHILE
	END IF
	START REPORT report_orden_compra TO PIPE comando
	LET vm_num_lineas = 0
	FOREACH q_ordt011 INTO r_c10.*, r_c11.*
		INITIALIZE r_rep.* TO NULL
		LET r_rep.c11_codigo  = r_c11.c11_codigo
		LET r_rep.descripcion = r_c11.c11_descrip
		CALL fl_lee_tipo_orden_compra(r_c10.c10_tipo_orden)
			RETURNING r_c01.*
		IF r_c01.c01_ing_bodega = 'S' THEN
			CALL fl_lee_item(vg_codcia, r_c11.c11_codigo)
				RETURNING r_r10.*
			CALL fl_lee_marca_rep(vg_codcia, r_r10.r10_marca)
				RETURNING r_r73.*
			CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea,
					r_r10.r10_sub_linea,r_r10.r10_cod_grupo,
					r_r10.r10_cod_clase)
				RETURNING r_r72.*
			LET r_rep.desc_clase	= r_r72.r72_desc_clase
			LET r_rep.unidades	= UPSHIFT(r_r10.r10_uni_med)
			LET r_rep.desc_marca	= r_r73.r73_desc_marca
			LET r_rep.descripcion	= r_r10.r10_nombre
		END IF
		LET r_rep.cant_ped	= r_c11.c11_cant_ped
		LET r_rep.precio	= r_c11.c11_precio
		LET r_rep.descuento	= r_c11.c11_descuento
		LET r_rep.valor_tot	= (r_c11.c11_cant_ped *
						r_c11.c11_precio) -
						r_c11.c11_val_descto
		OUTPUT TO REPORT report_orden_compra(r_rep.*, r_c01.*)
	END FOREACH
	FINISH REPORT report_orden_compra
	IF num_args() = 5 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_com		RECORD LIKE ordt010.*
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE r_mon		RECORD LIKE gent013.*

OPTIONS INPUT NO WRAP
INITIALIZE r_mon.*, r_prov.*, r_com.* TO NULL
LET int_flag = 0
INPUT BY NAME rm_c10.c10_numero_oc, rm_c10.c10_moneda
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(c10_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_c10.c10_moneda = r_mon.g13_moneda
				DISPLAY BY NAME rm_c10.c10_moneda
				DISPLAY r_mon.g13_nombre TO tit_estado
				LET rm_g13.* = r_mon.* 
			END IF
		END IF
		IF INFIELD(c10_numero_oc) THEN
			CALL fl_ayuda_ordenes_compra(vg_codcia, vg_codloc, 0,
						     0, 'T', '00', 'T')
				RETURNING r_com.c10_numero_oc
			IF r_com.c10_numero_oc IS NOT NULL THEN
				CALL fl_lee_orden_compra(vg_codcia, vg_codloc,
							 r_com.c10_numero_oc)
					RETURNING r_com.*
				LET rm_c10.* = r_com.*
				DISPLAY BY NAME rm_c10.c10_numero_oc,
						rm_c10.c10_moneda,
						rm_c10.c10_solicitado,
						rm_c10.c10_codprov
				CALL fl_lee_moneda(rm_c10.c10_moneda)
					RETURNING rm_g13.*
				DISPLAY rm_g13.g13_nombre TO tit_estado
				CALL fl_lee_proveedor(rm_c10.c10_codprov)
					RETURNING rm_p01.*
				DISPLAY rm_p01.p01_nomprov TO nom_prov
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD c10_numero_oc
		IF rm_c10.c10_numero_oc IS NOT NULL THEN
			CALL fl_lee_orden_compra(vg_codcia, vg_codloc,
						 rm_c10.c10_numero_oc)
				RETURNING r_com.*
			IF r_com.c10_numero_oc IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe la Orden de Compra en la Companía.','exclamation')
				CALL fl_mostrar_mensaje('No existe la Orden de Compra en la Companía.','exclamation')
				NEXT FIELD c10_numero_oc
			ELSE
				LET rm_c10.* = r_com.*
				DISPLAY BY NAME rm_c10.c10_numero_oc,
						rm_c10.c10_moneda,
						rm_c10.c10_solicitado,
						rm_c10.c10_codprov
				CALL fl_lee_moneda(rm_c10.c10_moneda)
					RETURNING rm_g13.*
				DISPLAY rm_g13.g13_nombre TO tit_estado
				CALL fl_lee_proveedor(rm_c10.c10_codprov)
					RETURNING rm_p01.*
				DISPLAY rm_p01.p01_nomprov TO nom_prov
			END IF
		END IF
	AFTER FIELD c10_moneda
		IF rm_c10.c10_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_c10.c10_moneda)
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe la moneda en la Compañía.','exclamation')
				CALL fl_mostrar_mensaje('No existe la moneda en la Compañía.','exclamation')
				NEXT FIELD c10_moneda
			ELSE
				LET rm_g13.* = r_mon.*
				LET rm_c10.c10_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME rm_c10.c10_moneda
				DISPLAY rm_g13.g13_nombre TO tit_estado
			END IF
		END IF
	AFTER INPUT 
		IF rm_c10.c10_numero_oc IS NULL THEN
			NEXT FIELD c10_numero_oc
		END IF
END INPUT

END FUNCTION



REPORT report_orden_compra(r_rep, r_tip_oc)
DEFINE r_rep		RECORD
				c11_codigo	LIKE ordt011.c11_codigo,
				desc_clase	LIKE rept072.r72_desc_clase,
				unidades	LIKE rept010.r10_uni_med,
				desc_marca	LIKE rept073.r73_desc_marca,
				descripcion	LIKE rept010.r10_nombre,
				cant_ped	LIKE ordt011.c11_cant_ped,
				precio		LIKE ordt011.c11_precio,
				descuento	LIKE ordt011.c11_descuento,
				valor_tot	DECIMAL(14,2)
			END RECORD
DEFINE r_tip_oc		RECORD LIKE ordt001.*
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE r_depto		RECORD LIKE gent034.*
DEFINE documento	VARCHAR(40)
DEFINE orden	 	CHAR(10)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
DEFINE subtotal		DECIMAL(14,2)
DEFINE impuesto		DECIMAL(14,2)
DEFINE valor_pag	DECIMAL(14,2)
DEFINE nom_estado 	CHAR(10)
DEFINE forma	 	CHAR(10)
DEFINE orden_trab 	CHAR(10)
DEFINE label_letras	VARCHAR(130)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	3
	PAGE LENGTH	44

FORMAT

PAGE HEADER
	--print 'E'; --print '&l26A';  -- Indica que voy a trabajar con hojas A4
	--print '&k4S'                -- Letra condensada (12 cpi)
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_lee_departamento(vg_codcia, rm_c10.c10_cod_depto)
		RETURNING r_depto.*
	LET modulo    = "MODULO: COMPRAS"
	LET long      = LENGTH(modulo)
	LET orden     = rm_c10.c10_numero_oc
	LET documento = 'COMPROBANTE DE ORDEN COMPRA No. ', orden
	CALL fl_justifica_titulo('C', documento, 80) RETURNING titulo
	LET titulo = modulo, titulo
	LET subtotal    = (rm_c10.c10_tot_repto + rm_c10.c10_tot_mano) -
			   rm_c10.c10_tot_dscto + rm_c10.c10_dif_cuadre +
			   rm_c10.c10_otros
	LET impuesto    = rm_c10.c10_tot_compra - (rm_c10.c10_tot_repto +
			  rm_c10.c10_tot_mano) + rm_c10.c10_tot_dscto -
			  rm_c10.c10_flete - rm_c10.c10_otros -
			  rm_c10.c10_dif_cuadre
	LET valor_pag   = rm_c10.c10_tot_compra
	LET orden_trab  = rm_c10.c10_ord_trabajo
	IF rm_c10.c10_tipo_pago = 'R' THEN
		LET forma = 'CREDITO'
	ELSE
		LET forma = 'CONTADO'
	END IF
	CASE rm_c10.c10_estado 
		WHEN 'A'
			LET nom_estado = 'ACTIVA'
		WHEN 'P'
			LET nom_estado = 'APROBADA'
		WHEN 'C'
			LET nom_estado = 'CERRADA'
	END CASE  
	IF vm_impresion = 'I' THEN
		print ASCII escape;
		print ASCII act_comp;
	ELSE
		print "";
		print "";
	END IF
	PRINT COLUMN 109, "PAG. ", PAGENO USING "&&&"
	PRINT COLUMN 01,  titulo
	SKIP 1 LINES
	PRINT COLUMN 01,  "PROVEEDOR (", rm_c10.c10_codprov
				USING "&&&&&", ") : ", rm_p01.p01_nomprov,
	      COLUMN 69,  "TIPO ORDEN COMPRA  : ", r_tip_oc.c01_nombre
	PRINT COLUMN 01,  "CEDULA/RUC        : ", rm_p01.p01_num_doc,
	      COLUMN 69,  "SOLICITADO POR     : ", rm_cia.g01_razonsocial
	PRINT COLUMN 01,  "DIRECCION         : ", rm_p01.p01_direccion1[1, 81],
	      COLUMN 103,  "FECHA ORDEN COMPRA: ", DATE(rm_c10.c10_fecing) 
			 			USING "dd-mm-yyyy"
	PRINT COLUMN 01,  "TELEFONO          : ", rm_p01.p01_telefono1, " ",
						  rm_p01.p01_telefono2,
	      COLUMN 69,  "FACTURA            : ", rm_c10.c10_factura
	PRINT COLUMN 01,  "FAX               : ", rm_p01.p01_fax1, " ",
						  rm_p01.p01_fax2,
	      COLUMN 69,  "ALMACEN            : ", rm_loc.g02_nombre
	PRINT COLUMN 01,  "REFERENCIA        : ", rm_c10.c10_referencia,
	      COLUMN 69,  "RUC                : ", rm_loc.g02_numruc
	PRINT COLUMN 01,  "FORMA DE PAGO     : ", forma,
	      COLUMN 69,  "DIRECCION          : ", rm_loc.g02_direccion
	PRINT COLUMN 01,  "DEPARTAMENTO      : ", r_depto.g34_nombre,
	      COLUMN 69,  "TELEFONO           : ", rm_loc.g02_telefono1, " ",
						   rm_loc.g02_telefono2
	PRINT COLUMN 01,  "ORDEN DE TRABAJO  : ", orden_trab,
	      COLUMN 69,  "FAX                : ", rm_loc.g02_fax1, " ",
						   rm_loc.g02_fax2
	PRINT COLUMN 01,  "FECHA IMPRESION   : ", DATE(TODAY)
			USING 'dd-mm-yyyy', 1 SPACES, TIME,
	      COLUMN 69,  "ESTADO ORDEN COMPRA: ", nom_estado

	--SKIP 1 LINES
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	IF r_tip_oc.c01_ing_bodega = 'S' THEN
		PRINT COLUMN 02,  "CODIGO",
		      COLUMN 11,  "DESCRIPCION",
		      COLUMN 56,  "MEDIDA",
		      COLUMN 64,  "MARCA",
		      COLUMN 82,  "CANTIDAD",
		      COLUMN 96,  "PRECIO VENTA",
		      COLUMN 110, "%DSCTO",
		      COLUMN 121, "VALOR TOTAL"
	ELSE
		PRINT COLUMN 02,  "CODIGO",
		      COLUMN 11,  "DESCRIPCION",
		      COLUMN 82,  "CANTIDAD",
		      COLUMN 96,  "PRECIO VENTA",
		      COLUMN 110, "%DSCTO",
		      COLUMN 121, "VALOR TOTAL"
	END IF
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	IF r_tip_oc.c01_ing_bodega = 'S' THEN
		NEED 2 LINES
		PRINT COLUMN 02,  r_rep.c11_codigo[1,7],
		      COLUMN 11,  r_rep.desc_clase,
		      COLUMN 56,  r_rep.unidades,
		      COLUMN 64,  r_rep.desc_marca
		PRINT COLUMN 13,  r_rep.descripcion[1,65],
		      COLUMN 82,  r_rep.cant_ped	USING '###,##&.##',
		      COLUMN 94,  r_rep.precio		USING '##,###,##&.###',
		      COLUMN 110, r_rep.descuento	USING '##&.##',
		      COLUMN 118, r_rep.valor_tot	USING '###,###,##&.##'
	ELSE
		NEED 1 LINES
		PRINT COLUMN 02,  r_rep.c11_codigo[1,7],
		      COLUMN 11,  r_rep.descripcion[1,65],
		      COLUMN 82,  r_rep.cant_ped	USING '###,##&.##',
		      COLUMN 94,  r_rep.precio		USING '##,###,##&.###',
		      COLUMN 110, r_rep.descuento	USING '##&.##',
		      COLUMN 118, r_rep.valor_tot	USING '###,###,##&.##'
	END IF
	LET vm_num_lineas = vm_num_lineas + 1
	
PAGE TRAILER
	--NEED 4 LINES
	LET label_letras = fl_retorna_letras(rm_c10.c10_moneda, valor_pag)
	SKIP 2 LINES
	IF vm_num_lineas = vm_num_item THEN
		PRINT --COLUMN 02,  "SOMOS CONTRIBUYENTES ESPECIALES D.G.R. # 39",
		      COLUMN 95,  "TOTAL BRUTO",
		      COLUMN 116, rm_c10.c10_tot_repto + rm_c10.c10_tot_mano
							USING "#,###,###,##&.##"
		PRINT --COLUMN 02,  "PRECIOS SUJETOS A CAMBIO SIN PREVIO AVISO",
		      COLUMN 95,  "DESCUENTOS",
		      COLUMN 118, rm_c10.c10_tot_dscto	USING "###,###,##&.##"
		PRINT COLUMN 95,  "SUBTOTAL",
		      COLUMN 118, subtotal		USING "###,###,##&.##"
		PRINT COLUMN 95,  "I. V. A. (", rm_c10.c10_porc_impto
							USING "#&", ") %",
		      COLUMN 118, impuesto		USING "###,###,##&.##"
		PRINT COLUMN 02,  "SON: ", label_letras[1,87],
		      COLUMN 95,  "VALOR A PAGAR",
		      COLUMN 116, valor_pag	USING "#,###,###,##&.##";
	ELSE
		PRINT COLUMN 02, 1 SPACES
		PRINT COLUMN 02, 1 SPACES
		PRINT COLUMN 02, 1 SPACES
		PRINT COLUMN 02, 1 SPACES
		PRINT COLUMN 02, 1 SPACES;
	END IF
	IF vm_impresion = 'I' THEN
		print ASCII escape;
		print ASCII desact_comp 
	ELSE
		print "";
		print ""
	END IF

END REPORT



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_c10.* TO NULL

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
