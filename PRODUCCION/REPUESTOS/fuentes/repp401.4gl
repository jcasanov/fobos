------------------------------------------------------------------------------
-- Titulo           : repp401.4gl - Impresión Devolución/Anulación Factura
-- Elaboracion      : 19-jul-2002
-- Autor            : YEC
-- Formato Ejecucion: fglrun repp401 base módulo compañía localidad 
--		      tipo_tran num_tran
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
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
DEFINE vm_num_dev	INTEGER
DEFINE vm_num_lineas	INTEGER



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp401.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)
LET vm_tipo_tran = arg_val(5)
LET vm_num_tran  = arg_val(6)
LET vg_proceso   = 'repp401'
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
DEFINE tecla 		INTEGER

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 8
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rep FROM "../forms/repf401_1"
ELSE
	OPEN FORM f_rep FROM "../forms/repf401_1c"
END IF
DISPLAY FORM f_rep
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
	CALL fl_mostrar_mensaje('No existe Dev/Anul Factura.','stop')
	EXIT PROGRAM
END IF
DISPLAY BY NAME rm_r19.r19_cod_tran, rm_r19.r19_num_tran,
		rm_r19.r19_tipo_dev, rm_r19.r19_num_dev
MESSAGE "                                           Presione una tecla para continuar "
LET tecla = fgl_getkey()
MESSAGE "                                                                             "
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE r_g06		RECORD LIKE gent006.*
DEFINE r_g24		RECORD LIKE gent024.*
--DEFINE bodega		LIKE rept002.r02_codigo
DEFINE comando		VARCHAR(100)
--DEFINE cuantos		INTEGER
DEFINE flag		SMALLINT

--INITIALIZE r_g06.*, r_g24.*, bodega TO NULL
INITIALIZE r_g06.*, r_g24.* TO NULL
LET flag = 0
IF vg_codloc = 1 THEN
	LET r_g06.g06_impresora = FGL_GETENV('PRINTER_DESP')
	SELECT UNIQUE r36_bodega_real bod_imp, r20_item item
		FROM rept020, rept034, rept035, rept036
		WHERE r20_compania    = rm_r19.r19_compania
		  AND r20_localidad   = rm_r19.r19_localidad
		  AND r20_cod_tran    = rm_r19.r19_cod_tran
		  AND r20_num_tran    = rm_r19.r19_num_tran
		  AND r34_compania    = r20_compania
		  AND r34_localidad   = r20_localidad
		  AND r34_cod_tran    = rm_r19.r19_tipo_dev
		  AND r34_num_tran    = rm_r19.r19_num_dev
		  AND r35_compania    = r34_compania
		  AND r35_localidad   = r34_localidad
		  AND r35_bodega      = r20_bodega
		  AND r35_num_ord_des = r34_num_ord_des
		  AND r35_item        = r20_item
		  AND r36_compania    = r35_compania
		  AND r36_localidad   = r35_localidad
		  AND r36_bodega      = r35_bodega
		  AND r36_num_ord_des = r35_num_ord_des
		INTO TEMP t1
	--SELECT COUNT(*) INTO cuantos FROM t1 WHERE bod_imp = '60'
	--IF cuantos = 0 THEN
		SELECT UNIQUE r19_bodega_ori bod_ori, r20_item item
			FROM rept019, rept020, rept041
			WHERE r19_compania   = rm_r19.r19_compania
			  AND r19_localidad  = rm_r19.r19_localidad
			  AND r19_cod_tran   = "TR"
			  AND r19_tipo_dev   = rm_r19.r19_tipo_dev
			  AND r19_num_dev    = rm_r19.r19_num_dev
			  AND r20_compania   = r19_compania
			  AND r20_localidad  = r19_localidad
			  AND r20_cod_tran   = r19_cod_tran
			  AND r20_num_tran   = r19_num_tran
			  AND r20_item      IN
				(SELECT item
					FROM t1
					WHERE bod_imp = r20_bodega)
			  AND r41_compania   = r19_compania
			  AND r41_localidad  = r19_localidad
			  AND r41_cod_tr     = r19_cod_tran
			  AND r41_num_tr     = r19_num_tran
			INTO TEMP t2
		{--
		SQL
			SELECT UNIQUE bod_ori INTO $bodega
				FROM t2
				WHERE bod_ori = "60"
		END SQL
	ELSE
		SQL
			SELECT UNIQUE bod_imp INTO $bodega
				FROM t1
				WHERE bod_imp = "60"
		END SQL
	END IF
	IF bodega IS NOT NULL THEN
		IF bodega = '60' THEN
	--}
		SELECT UNIQUE r20_bodega bod_tal, r20_item item
			FROM rept020, rept002
			WHERE r20_compania   = rm_r19.r19_compania
			  AND r20_localidad  = rm_r19.r19_localidad
			  AND r20_cod_tran   = rm_r19.r19_cod_tran
			  AND r20_num_tran   = rm_r19.r19_num_tran
			  AND r20_bodega    IN
				(SELECT r02_codigo
					FROM rept002
					WHERE r02_compania  = r20_compania
					  AND r02_localidad = r20_localidad
					  AND r02_area      = 'T'
					  AND r02_estado    = 'A'
					  AND r02_factura   = 'S')
			INTO TEMP t3
			--
			SELECT UNIQUE bod_ori bodega FROM t2
			UNION
			SELECT UNIQUE bod_imp bodega FROM t1
			UNION
			SELECT UNIQUE bod_tal bodega FROM t3
			INTO TEMP t4
			--
			DROP TABLE t1
			DROP TABLE t2
			DROP TABLE t3
			DECLARE q_g24 CURSOR FOR
				SELECT * FROM gent024
					WHERE g24_compania = rm_r19.r19_compania
					  AND g24_bodega   IN
						(SELECT bodega FROM t4)
					ORDER BY g24_imprime DESC
			OPEN q_g24
			FETCH q_g24 INTO r_g24.*
			IF r_g24.g24_impresora IS NOT NULL THEN
				LET r_g06.g06_impresora = r_g24.g24_impresora
			END IF
			LET flag = 1
		{--
		ELSE
			LET r_g06.g06_impresora = 'DESPACHO'
		END IF
	ELSE
		LET r_g06.g06_impresora = 'DESPACHO'
	END IF
		--}
END IF
IF r_g06.g06_impresora IS NOT NULL THEN
	CALL fl_lee_impresora(r_g06.g06_impresora) RETURNING r_g06.*
	IF r_g06.g06_impresora IS NULL THEN
		CALL fl_control_reportes() RETURNING comando
		IF int_flag THEN
			RETURN
		END IF
	END IF
	LET comando = 'lpr -o raw -P ', r_g06.g06_impresora
ELSE
	IF vg_codloc <> 1 THEN
		CALL fl_control_reportes() RETURNING comando
		IF int_flag THEN
			RETURN
		END IF
	END IF
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
SELECT COUNT(*) INTO vm_num_dev FROM rept020
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
IF vg_codloc <> 1 THEN
	CALL imprimir_comprobante(comando)
ELSE
	FOREACH q_g24 INTO r_g24.*
		LET comando = 'lpr -o raw -P ', r_g24.g24_impresora
		CALL imprimir_comprobante(comando)
	END FOREACH
	IF flag = 1 OR rm_r19.r19_cod_tran = "AF" THEN
		LET comando = 'lpr -o raw -P DESPACHO'
		CALL imprimir_comprobante(comando)
	END IF
	DROP TABLE t4
END IF

END FUNCTION



FUNCTION imprimir_comprobante(comando)
DEFINE comando		VARCHAR(100)
DEFINE r_rep		RECORD
				bodega 		LIKE rept020.r20_bodega,
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
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*

START REPORT report_devolucion TO PIPE comando
LET vm_num_lineas = 0
FOREACH q_rept020 INTO r_r20.*
	CALL fl_lee_item(vg_codcia, r_r20.r20_item) RETURNING r_r10.*
	CALL fl_lee_marca_rep(vg_codcia, r_r10.r10_marca)
		RETURNING r_r73.*
	CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea,
			r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
			r_r10.r10_cod_clase)
		RETURNING r_r72.*
	LET r_rep.bodega	= r_r20.r20_bodega
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
	OUTPUT TO REPORT report_devolucion(r_rep.*)
END FOREACH
FINISH REPORT report_devolucion

END FUNCTION



REPORT report_devolucion(r_rep)
DEFINE r_rep		RECORD
				bodega 		LIKE rept020.r20_bodega,
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
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE documento	VARCHAR(60)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
DEFINE subtotal		DECIMAL(14,2)
DEFINE impuesto		DECIMAL(14,2)
DEFINE valor_pag	DECIMAL(14,2)
DEFINE factura		VARCHAR(15)
DEFINE nota_cred	VARCHAR(15)
DEFINE tipo_docum	VARCHAR(10)
DEFINE tipo_docum2	VARCHAR(10)
DEFINE sep_pun		VARCHAR(4)
DEFINE label_letras	VARCHAR(130)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_neg		SMALLINT
DEFINE des_neg		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	3
	PAGE LENGTH	44

FORMAT

PAGE HEADER
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET long        = LENGTH(modulo)
	LET tipo_docum  = "DEVOLUCION"
	LET tipo_docum2 = "DEVUELTA"
	LET sep_pun	= ": "
	IF rm_r19.r19_cod_tran = "AF" THEN
		LET tipo_docum  = "ANULACION"
		LET tipo_docum2 = "ANULADA"
		LET sep_pun	= " : "
	END IF
	LET documento = "COMPROBANTE ", tipo_docum CLIPPED, " FACTURA No. ",
			rm_r19.r19_cod_tran, "-",
			rm_r19.r19_num_tran USING "<<<<<<<&"
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', documento CLIPPED, 80) RETURNING titulo
	LET titulo 	= modulo, titulo
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET subtotal  	= rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto
	LET impuesto  	= rm_r19.r19_tot_neto - rm_r19.r19_tot_bruto +
			  rm_r19.r19_tot_dscto - rm_r19.r19_flete
	LET valor_pag	= rm_r19.r19_tot_neto
	LET factura	= rm_r19.r19_num_dev USING "&&&&&&&&&"
	INITIALIZE r_z21.* TO NULL
	SELECT * INTO r_z21.* FROM cxct021
		WHERE z21_compania  = vg_codcia
		  AND z21_localidad = vg_codloc
		  AND z21_cod_tran  = rm_r19.r19_cod_tran
		  AND z21_num_tran  = rm_r19.r19_num_tran
	LET nota_cred	= r_z21.z21_num_doc
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rm_cia.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, ASCII escape, ASCII act_neg, titulo CLIPPED,
	      COLUMN 128, UPSHIFT(vg_proceso),
		ASCII escape, ASCII des_neg,
		ASCII escape, ASCII act_comp
	SKIP 1 LINES
	PRINT COLUMN 001, ASCII escape, ASCII act_neg,
			"FACTURA ", tipo_docum2, sep_pun, rm_r19.r19_tipo_dev,
			' - ', rm_loc.g02_serie_cia USING "&&&", "-",
			rm_loc.g02_serie_loc USING "&&&", "-",
			factura, ASCII escape, ASCII des_neg,
	      COLUMN 074, "FECHA ", tipo_docum, sep_pun, DATE(rm_r19.r19_fecing)
						USING "dd-mm-yyyy"
	PRINT COLUMN 01,  "CLIENTE (", rm_r19.r19_codcli USING "&&&&&", ") : ",
					rm_r19.r19_nomcli[1, 100] CLIPPED
	PRINT COLUMN 01,  "VENDEDOR        : ",	rm_r01.r01_nombres,
	      COLUMN 70,  "MONEDA          : ",	rm_g13.g13_nombre
	PRINT COLUMN 01,  "REFERENCIA      : ", rm_r19.r19_referencia,
	      COLUMN 070, ASCII escape, ASCII act_neg,
			"No. DE N/C      : ", rm_loc.g02_serie_cia USING "&&&",
			"-", rm_loc.g02_serie_loc USING "&&&", "-",
			nota_cred USING "&&&&&&&&&",
			ASCII escape, ASCII des_neg,
			ASCII escape, ASCII act_comp
	SKIP 1 LINES
	PRINT COLUMN 01,  "FECHA IMPRESION : ", vg_fecha USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 123, usuario
	SKIP 1 LINES
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 02,  "BD",
	      COLUMN 05,  "CODIGO",
	      COLUMN 13,  "DESCRIPCION",
	      COLUMN 64,  "MEDIDA",
	      COLUMN 72,  "MARCA",
	      COLUMN 85,  "CANTIDAD",
	      COLUMN 96,  "PRECIO VENTA",
	      COLUMN 110, "%DSCTO",
	      COLUMN 121, "VALOR TOTAL"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES
	LET vm_num_lineas = vm_num_lineas + 1
	PRINT COLUMN 02,  r_rep.bodega,
	      COLUMN 05,  r_rep.r20_item[1,7],
	      COLUMN 13,  r_rep.desc_clase,
	      COLUMN 64,  r_rep.unidades,
	      COLUMN 72,  r_rep.desc_marca
	PRINT COLUMN 15,  r_rep.descripcion,
	      COLUMN 84,  r_rep.cant_ven	USING "####&.##",
	      COLUMN 94,  r_rep.precio		USING "###,###,##&.##",
	      COLUMN 110, r_rep.descuento	USING "##&.##",
	      COLUMN 118, r_rep.valor_tot	USING "###,###,##&.##"
	
PAGE TRAILER
	--NEED 4 LINES
	LET label_letras = fl_retorna_letras(rm_r19.r19_moneda, valor_pag)
	SKIP 2 LINES
	IF vm_num_lineas = vm_num_dev THEN
		--PRINT COLUMN 02,  "SOMOS CONTRIBUYENTES ESPECIALES D.G.R. # 39",
		PRINT COLUMN 95,  "TOTAL BRUTO",
		      COLUMN 116, rm_r19.r19_tot_bruto	USING "#,###,###,##&.##"
		--PRINT COLUMN 50,  "-------------------------",
		PRINT COLUMN 95,  "DESCUENTOS",
		      COLUMN 118, rm_r19.r19_tot_dscto	USING "###,###,##&.##"
		--PRINT COLUMN 50,  " RECIBI ", tipo_docum, " FACT. ",
		PRINT COLUMN 02, "AUTORIZADO POR ___________________",
		      COLUMN 45, "RECIBIDO POR ___________________",
		      COLUMN 95,  "SUBTOTAL",
		      COLUMN 118, subtotal		USING "###,###,##&.##"
		PRINT COLUMN 95,  "I. V. A. (", rm_r19.r19_porc_impto
							USING "#&", ") %",
		      COLUMN 118, impuesto		USING "###,###,##&.##"
		PRINT COLUMN 95,  "TRANSPORTE",
		      COLUMN 118, rm_r19.r19_flete	USING "###,###,##&.##"
		PRINT COLUMN 02,  "SON: ", label_letras[1,87],
		      COLUMN 95,  "VALOR A PAGAR",
		      COLUMN 116, valor_pag	USING "#,###,###,##&.##";
	ELSE
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
