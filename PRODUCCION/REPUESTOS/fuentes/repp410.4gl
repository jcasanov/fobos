--------------------------------------------------------------------------------
-- Titulo           : repp410.4gl - REPORTE DE FACTURA 
-- Elaboracion      : 28-dic-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp410 BD MODULO COMPANIA LOCALIDAD FACTURA
-- Ultima Correccion: 28-dic-2001 
-- Motivo Correccion: 1
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_cod_tran 	LIKE rept019.r19_cod_tran
DEFINE vm_factura	LIKE rept019.r19_num_tran
DEFINE rm_r00		RECORD LIKE rept000.*
DEFINE rm_r19		RECORD LIKE rept019.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE mensaje_fa_ant	VARCHAR(250)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp410.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vm_cod_tran = arg_val(5)
LET vm_factura  = arg_val(6)
LET vg_proceso  = 'repp410'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE num_lineas	SMALLINT

CALL fl_nivel_isolation()
INITIALIZE rm_r19.* TO NULL
-- Para probar en una impresora matricial
CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, vm_cod_tran,
					vm_factura) 
	RETURNING rm_r19.*
IF rm_r19.r19_num_tran IS NULL THEN	
	CALL fl_mostrar_mensaje('No existe factura.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
SELECT COUNT(*) INTO num_lineas FROM rept020 
	WHERE r20_compania  = vg_codcia
	  AND r20_localidad = vg_codloc
	  AND r20_cod_tran  = vm_cod_tran
	  AND r20_num_tran  = rm_r19.r19_num_tran
IF num_lineas > rm_r00.r00_numlin_fact THEN
	CALL fl_mostrar_mensaje('La factura tiene demasiadas lineas.','stop')
	EXIT PROGRAM
END IF
CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
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
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE r_r88		RECORD LIKE rept088.*
DEFINE r_g06		RECORD LIKE gent006.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE num_sri		LIKE rept038.r38_num_sri

INITIALIZE r_g06.*, r_r88.* TO NULL
IF rm_r19.r19_cont_cred = 'C' THEN
	LET r_g06.g06_impresora = FGL_GETENV('PRINTER_CONT')
ELSE
	LET r_g06.g06_impresora = FGL_GETENV('PRINTER_CRED')
END IF
-- OJO PUESTO PARA LA NOTA DE VENTA
{--
IF vg_codloc = 3 THEN
	CALL fl_lee_cliente_general(rm_r19.r19_codcli) RETURNING r_z01.*
	IF r_z01.z01_tipo_doc_id <> 'R' THEN
		LET r_g06.g06_impresora = FGL_GETENV('PRINTER_NOTA')
	END IF
END IF
--
--}
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
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		RETURN
	END IF
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
SELECT * INTO r_r88.*
	FROM rept088
	WHERE r88_compania     = vg_codcia
	  AND r88_localidad    = vg_codloc
	  AND r88_cod_fact_nue = rm_r19.r19_cod_tran
	  AND r88_num_fact_nue = rm_r19.r19_num_tran
LET mensaje_fa_ant = NULL
IF r_r88.r88_compania IS NOT NULL THEN
	CALL fl_lee_cabecera_transaccion_rep(r_r88.r88_compania,
					r_r88.r88_localidad, r_r88.r88_cod_fact,
					r_r88.r88_num_fact) 
		RETURNING r_r19.*
	SELECT r38_num_sri INTO num_sri
		FROM rept038
		WHERE r38_compania    = r_r19.r19_compania
		  AND r38_localidad   = r_r19.r19_localidad
		  AND r38_tipo_fuente = 'PR'
		  AND r38_cod_tran    = r_r19.r19_cod_tran
		  AND r38_num_tran    = r_r19.r19_num_tran
	LET mensaje_fa_ant = 'FACTURA ORIGINAL # (', r_r19.r19_cod_tran, '-',
				r_r19.r19_num_tran USING "<<<<<<<<&", ')  ',
				num_sri CLIPPED, '  FECHA: ',
				DATE(r_r19.r19_fecing) USING "dd-mm-yyyy"
END IF
DECLARE q_rept020 CURSOR FOR
	SELECT rept020.* FROM rept020
		WHERE r20_compania  = vg_codcia
		  AND r20_localidad = vg_codloc
		  AND r20_cod_tran  = rm_r19.r19_cod_tran
		  AND r20_num_tran  = rm_r19.r19_num_tran
	    	ORDER BY r20_orden
--QUITAR ESTA HUEVADA, PARA OTRA INSTALACION
IF vg_codloc <> 3 AND vg_codloc <> 4 AND vg_codloc <> 5 THEN
	IF vg_codcia = 1 THEN
		START REPORT report_factura TO PIPE comando
	ELSE
		START REPORT report_factura3 TO PIPE comando
	END IF
ELSE
	--QUITAR ESTA HUEVADA, PARA OTRA INSTALACION
	START REPORT report_factura2 TO PIPE comando
END IF
FOREACH q_rept020 INTO r_r20.*
	CALL fl_lee_item(vg_codcia, r_r20.r20_item) RETURNING r_r10.*
	CALL fl_lee_marca_rep(vg_codcia, r_r10.r10_marca)
		RETURNING r_r73.*
	CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea,
			r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
			r_r10.r10_cod_clase)
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
	--QUITAR ESTA HUEVADA, PARA OTRA INSTALACION
	IF vg_codloc <> 3 AND vg_codloc <> 4 AND vg_codloc <> 5 THEN
		IF vg_codcia = 1 THEN
			OUTPUT TO REPORT report_factura(r_rep.*)
		ELSE
			OUTPUT TO REPORT report_factura3(r_rep.*)
		END IF
	ELSE
		--QUITAR ESTA HUEVADA, PARA OTRA INSTALACION
		OUTPUT TO REPORT report_factura2(r_rep.*)
	END IF
END FOREACH
--QUITAR ESTA HUEVADA, PARA OTRA INSTALACION
IF vg_codloc <> 3 AND vg_codloc <> 4 AND vg_codloc <> 5 THEN
	IF vg_codcia = 1 THEN
		FINISH REPORT report_factura
	ELSE
		FINISH REPORT report_factura3
	END IF
ELSE
	--QUITAR ESTA HUEVADA, PARA OTRA INSTALACION
	FINISH REPORT report_factura2
END IF

END FUNCTION



REPORT report_factura(r_rep)
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
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE documento	VARCHAR(60)
DEFINE titulo		VARCHAR(80)
DEFINE fecha_vcto	DATE
DEFINE long		SMALLINT
DEFINE valor_efec	DECIMAL(14,2)
DEFINE valor_cheq	DECIMAL(14,2)
DEFINE valor_tarj	DECIMAL(14,2)
DEFINE valor_rete	DECIMAL(14,2)
DEFINE valor_cred	DECIMAL(14,2)
DEFINE subtotal		DECIMAL(14,2)
DEFINE impuesto		DECIMAL(14,2)
DEFINE valor_pag	DECIMAL(14,2)
DEFINE factura		VARCHAR(15)
DEFINE proforma		VARCHAR(10)
DEFINE v_e		VARCHAR(15)
DEFINE v_ch		VARCHAR(15)
DEFINE v_t		VARCHAR(15)
DEFINE v_r		VARCHAR(15)
DEFINE v_c		VARCHAR(15)
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
	--print 'E';
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET subtotal  = rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto
	LET impuesto  = rm_r19.r19_tot_neto - rm_r19.r19_tot_bruto +
			rm_r19.r19_tot_dscto - rm_r19.r19_flete
	LET valor_pag = rm_r19.r19_tot_neto
	CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
		RETURNING r_r01.*
--	print '&k2S' 		-- Letra condensada
	SELECT * INTO r_r21.* FROM rept021
		WHERE r21_compania  = rm_r19.r19_compania
		  AND r21_localidad = rm_r19.r19_localidad
		  AND r21_cod_tran  = rm_r19.r19_cod_tran
		  AND r21_num_tran  = rm_r19.r19_num_tran
	LET fecha_vcto = NULL
	LET valor_cred = 0
	IF rm_r19.r19_cont_cred = 'R' THEN
		SELECT * INTO r_r23.* FROM rept023
			WHERE r23_compania  = rm_r19.r19_compania
			  AND r23_localidad = rm_r19.r19_localidad
			  AND r23_cod_tran  = r_r21.r21_cod_tran
			  AND r23_num_tran  = r_r21.r21_num_tran
		SELECT SUM(r26_valor_cap), MAX(r26_fec_vcto)
			INTO valor_cred, fecha_vcto FROM rept026
			WHERE r26_compania  = r_r23.r23_compania
			  AND r26_localidad = r_r23.r23_localidad
			  AND r26_numprev   = r_r23.r23_numprev
		IF valor_cred IS NULL THEN
			LET valor_cred = 0
		END IF
	END IF
	SELECT * INTO r_j10.* FROM cajt010
		WHERE j10_compania     = rm_r19.r19_compania
		  AND j10_localidad    = rm_r19.r19_localidad
		  AND j10_tipo_fuente  = 'PR'
		  AND j10_tipo_destino = rm_r19.r19_cod_tran
		  AND j10_num_destino  = rm_r19.r19_num_tran
	DECLARE q_forpag CURSOR FOR
		SELECT * FROM cajt011
			WHERE j11_compania    = r_j10.j10_compania
			  AND j11_localidad   = r_j10.j10_localidad
			  AND j11_tipo_fuente = r_j10.j10_tipo_fuente
			  AND j11_num_fuente  = r_j10.j10_num_fuente
	LET valor_efec = 0
	LET valor_cheq = 0
	LET valor_tarj = 0
	LET valor_rete = 0
	FOREACH q_forpag INTO r_j11.*
		CASE r_j11.j11_codigo_pago
			WHEN 'EF'
				LET valor_efec = valor_efec + r_j11.j11_valor
			WHEN 'CH'
				LET valor_cheq = valor_cheq + r_j11.j11_valor
			WHEN 'RT'
				LET valor_rete = valor_rete + r_j11.j11_valor
		END CASE
		IF r_j11.j11_codigo_pago[1, 1] = 'T' THEN
			LET valor_tarj = valor_tarj + r_j11.j11_valor
		END IF
	END FOREACH
	LET factura  = rm_r19.r19_num_tran
	LET proforma = r_r21.r21_numprof
	LET v_e      = valor_efec USING "###,###,##&.##"
	LET v_ch     = valor_cheq USING "###,###,##&.##"
	LET v_t      = valor_tarj USING "###,###,##&.##"
	LET v_r      = valor_rete USING "###,###,##&.##"
	LET v_c      = valor_cred USING "###,###,##&.##"
	CALL fl_lee_cliente_general(rm_r19.r19_codcli) RETURNING r_z01.*
	print ASCII escape;
	print ASCII act_comp
	SKIP 1 LINES
	PRINT COLUMN 70,  "No. ", rm_r19.r19_cod_tran, " ", factura
	PRINT COLUMN 27,  "ALMACEN : ", rm_loc.g02_nombre,
	      COLUMN 70,  "FECHA FACTURA : ", DATE(rm_r19.r19_fecing) 
			 			USING "dd-mm-yyyy"
	SKIP 2 LINES
	{--
	IF r_z01.z01_tipo_doc_id = 'R' THEN
		SKIP 1 LINES
		PRINT COLUMN 27,  "ALMACEN : ", rm_loc.g02_nombre CLIPPED,
		      COLUMN 57,  "No. ", rm_r19.r19_cod_tran, " ", factura,
		      COLUMN 103, "FECHA FACTURA : ", DATE(rm_r19.r19_fecing) 
			 			USING "dd-mm-yyyy"
		SKIP 3 LINES
	ELSE
		SKIP 2 LINES
		PRINT COLUMN 27,  "ALMACEN : ", rm_loc.g02_nombre CLIPPED,
		      COLUMN 57,  "No. ", rm_r19.r19_cod_tran, " ", factura,
		      COLUMN 103, "FECHA FACTURA : ", DATE(rm_r19.r19_fecing) 
			 			USING "dd-mm-yyyy"
		SKIP 2 LINES
	END IF
	--}
	PRINT COLUMN 01,  "CLIENTE (", rm_r19.r19_codcli USING "&&&&&", ") : ",
					rm_r19.r19_nomcli[1, 100] CLIPPED
	PRINT COLUMN 01,  "CEDULA/RUC      : ", rm_r19.r19_cedruc,
	      COLUMN 69,  "EFECTIVO   : ", fl_justifica_titulo('I', v_e, 15),
	      COLUMN 106, "No. PROFORMA : ", proforma
	PRINT COLUMN 01,  "DIRECCION       : ", rm_r19.r19_dircli,
	      COLUMN 69,  "CHEQUES    : ", fl_justifica_titulo('I', v_ch, 15),
	      COLUMN 106, "FECHA DE VENCIMIENTO"
	PRINT COLUMN 01,  "TELEFONO        : ", rm_r19.r19_telcli,
	      COLUMN 69,  "TARJETAS   : ", fl_justifica_titulo('I', v_t, 15),
	      COLUMN 111, DATE(fecha_vcto) USING "dd-mm-yyyy"
	PRINT COLUMN 01,  "OBSERVACION     : ", r_r21.r21_atencion,
	      COLUMN 69,  "RETENCION  : ", fl_justifica_titulo('I', v_r, 15)
	PRINT COLUMN 01,  "VENDEDOR(A)     : ", r_r01.r01_nombres,
	      COLUMN 69,  "CREDITO    : ", fl_justifica_titulo('I', v_c, 15)
	SKIP 2 LINES
	--PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 02,  "CODIGO",
	      COLUMN 11,  "DESCRIPCION",
	      COLUMN 56,  "MEDIDA",
	      COLUMN 64,  "MARCA",
	      COLUMN 84,  "CANTIDAD",
	      COLUMN 96,  "PRECIO VENTA",
	      COLUMN 110, "%DSCTO",
	      COLUMN 121, "VALOR TOTAL"
	--PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	--SKIP 1 LINES

ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 02,  r_rep.r20_item[1,7],
	      COLUMN 11,  r_rep.desc_clase,
	      COLUMN 56,  r_rep.unidades,
	      COLUMN 64,  r_rep.desc_marca
	PRINT COLUMN 13,  r_rep.descripcion,
	      COLUMN 84,  r_rep.cant_ven	USING '####&.##',
	      COLUMN 94,  r_rep.precio		USING '###,###,##&.##',
	      COLUMN 110, r_rep.descuento	USING '##&.##',
	      COLUMN 118, r_rep.valor_tot	USING '###,###,##&.##'
	
PAGE TRAILER
	--NEED 4 LINES
	LET label_letras = fl_retorna_letras(rm_r19.r19_moneda, valor_pag)
	SKIP 2 LINES
	--PRINT COLUMN 02,  "SOMOS CONTRIBUYENTES ESPECIALES D.G.R. # 39",
	--PRINT COLUMN 02, "SOMOS CONTRIBUYENTES ESPECIALES, RESOLUCION No. 5368",
	PRINT COLUMN 60,  "-------------------------",
	      COLUMN 95,  "TOTAL BRUTO",
	      COLUMN 116, rm_r19.r19_tot_bruto	USING "#,###,###,##&.##"
	PRINT COLUMN 60,  " RECIBI FACTURA ORIGINAL ",
	      COLUMN 95,  "DESCUENTOS",
	      COLUMN 118, rm_r19.r19_tot_dscto	USING "###,###,##&.##"
	IF vg_codloc = 6 OR vg_codloc = 7 THEN
		PRINT COLUMN 008, "www.herramientasyanclajes.com";
	ELSE
		PRINT COLUMN 008, "w w w . a c e r o c o m e r c i a l . c o m";
	END IF
	PRINT COLUMN 95,  "SUBTOTAL",
	      COLUMN 118, subtotal		USING "###,###,##&.##"
	PRINT COLUMN 95,  "I. V. A. (", rm_r19.r19_porc_impto USING "#&", ") %",
	      COLUMN 118, impuesto		USING "###,###,##&.##"
	IF mensaje_fa_ant IS NOT NULL THEN
		PRINT COLUMN 006, mensaje_fa_ant CLIPPED;
	END IF
	PRINT COLUMN 95,  "TRANSPORTE",
	      COLUMN 118, rm_r19.r19_flete	USING "###,###,##&.##"
	PRINT COLUMN 02,  "SON: ", label_letras[1,87],
	      COLUMN 95,  "VALOR A PAGAR",
	      COLUMN 116, valor_pag		USING "#,###,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



REPORT report_factura2(r_rep)	--QUITAR ESTA HUEVADA, PARA OTRA INSTALACION
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
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE documento	VARCHAR(60)
DEFINE titulo		VARCHAR(80)
DEFINE fecha_vcto	DATE
DEFINE long		SMALLINT
DEFINE valor_efec	DECIMAL(14,2)
DEFINE valor_cheq	DECIMAL(14,2)
DEFINE valor_tarj	DECIMAL(14,2)
DEFINE valor_rete	DECIMAL(14,2)
DEFINE valor_cred	DECIMAL(14,2)
DEFINE subtotal		DECIMAL(14,2)
DEFINE impuesto		DECIMAL(14,2)
DEFINE valor_pag	DECIMAL(14,2)
DEFINE factura		VARCHAR(15)
DEFINE proforma		VARCHAR(10)
DEFINE v_e		VARCHAR(15)
DEFINE v_ch		VARCHAR(15)
DEFINE v_t		VARCHAR(15)
DEFINE v_r		VARCHAR(15)
DEFINE v_c		VARCHAR(15)
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
	--print 'E';
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET subtotal  = rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto
	LET impuesto  = rm_r19.r19_tot_neto - rm_r19.r19_tot_bruto +
			rm_r19.r19_tot_dscto - rm_r19.r19_flete
	LET valor_pag = rm_r19.r19_tot_neto
	CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
		RETURNING r_r01.*
--	print '&k2S' 		-- Letra condensada
	SELECT * INTO r_r21.* FROM rept021
		WHERE r21_compania  = rm_r19.r19_compania
		  AND r21_localidad = rm_r19.r19_localidad
		  AND r21_cod_tran  = rm_r19.r19_cod_tran
		  AND r21_num_tran  = rm_r19.r19_num_tran
	LET fecha_vcto = NULL
	LET valor_cred = 0
	IF rm_r19.r19_cont_cred = 'R' THEN
		SELECT * INTO r_r23.* FROM rept023
			WHERE r23_compania  = rm_r19.r19_compania
			  AND r23_localidad = rm_r19.r19_localidad
			  AND r23_cod_tran  = r_r21.r21_cod_tran
			  AND r23_num_tran  = r_r21.r21_num_tran
		SELECT SUM(r26_valor_cap), MAX(r26_fec_vcto)
			INTO valor_cred, fecha_vcto FROM rept026
			WHERE r26_compania  = r_r23.r23_compania
			  AND r26_localidad = r_r23.r23_localidad
			  AND r26_numprev   = r_r23.r23_numprev
		IF valor_cred IS NULL THEN
			LET valor_cred = 0
		END IF
	END IF
	SELECT * INTO r_j10.* FROM cajt010
		WHERE j10_compania     = rm_r19.r19_compania
		  AND j10_localidad    = rm_r19.r19_localidad
		  AND j10_tipo_fuente  = 'PR'
		  AND j10_tipo_destino = rm_r19.r19_cod_tran
		  AND j10_num_destino  = rm_r19.r19_num_tran
	DECLARE q_forpag2 CURSOR FOR
		SELECT * FROM cajt011
			WHERE j11_compania    = r_j10.j10_compania
			  AND j11_localidad   = r_j10.j10_localidad
			  AND j11_tipo_fuente = r_j10.j10_tipo_fuente
			  AND j11_num_fuente  = r_j10.j10_num_fuente
	LET valor_efec = 0
	LET valor_cheq = 0
	LET valor_tarj = 0
	LET valor_rete = 0
	FOREACH q_forpag2 INTO r_j11.*
		CASE r_j11.j11_codigo_pago
			WHEN 'EF'
				LET valor_efec = valor_efec + r_j11.j11_valor
			WHEN 'CH'
				LET valor_cheq = valor_cheq + r_j11.j11_valor
			WHEN 'RT'
				LET valor_rete = valor_rete + r_j11.j11_valor
		END CASE
		IF r_j11.j11_codigo_pago[1, 1] = 'T' THEN
			LET valor_tarj = valor_tarj + r_j11.j11_valor
		END IF
	END FOREACH
	LET factura  = rm_r19.r19_num_tran
	LET proforma = r_r21.r21_numprof
	LET v_e      = valor_efec USING "###,###,##&.##"
	LET v_ch     = valor_cheq USING "###,###,##&.##"
	LET v_t      = valor_tarj USING "###,###,##&.##"
	LET v_r      = valor_rete USING "###,###,##&.##"
	LET v_c      = valor_cred USING "###,###,##&.##"
	SKIP 1 LINES
	print ASCII escape;
	print ASCII act_comp
	--IF vg_codloc = 3 THEN
	PRINT COLUMN 70,  "No. ", rm_r19.r19_cod_tran, " ", factura
	PRINT COLUMN 27,  "ALMACEN : ", rm_loc.g02_nombre,
	      COLUMN 70,  "FECHA FACTURA : ", DATE(rm_r19.r19_fecing) 
			 			USING "dd-mm-yyyy"
	{--
	ELSE
	PRINT COLUMN 27,  "ALMACEN : ", rm_loc.g02_nombre,
	      COLUMN 94,  "No. ", rm_r19.r19_cod_tran, " ", factura
	PRINT COLUMN 94,  "FECHA FACTURA : ", DATE(rm_r19.r19_fecing) 
			 			USING "dd-mm-yyyy"
	END IF
	--}
	SKIP 2 LINES
	PRINT COLUMN 01,  "CLIENTE (", rm_r19.r19_codcli USING "&&&&&", ") : ",
					rm_r19.r19_nomcli[1, 100] CLIPPED
	PRINT COLUMN 01,  "CEDULA/RUC      : ", rm_r19.r19_cedruc,
	      COLUMN 69,  "EFECTIVO   : ", fl_justifica_titulo('I', v_e, 15),
	      COLUMN 106, "No. PROFORMA : ", proforma
	PRINT COLUMN 01,  "DIRECCION       : ", rm_r19.r19_dircli,
	      COLUMN 69,  "CHEQUES    : ", fl_justifica_titulo('I', v_ch, 15),
	      COLUMN 106, "FECHA DE VENCIMIENTO"
	PRINT COLUMN 01,  "TELEFONO        : ", rm_r19.r19_telcli,
	      COLUMN 69,  "TARJETAS   : ", fl_justifica_titulo('I', v_t, 15),
	      COLUMN 111, DATE(fecha_vcto) USING "dd-mm-yyyy"
	PRINT COLUMN 01,  "OBSERVACION     : ", r_r21.r21_atencion,
	      COLUMN 69,  "RETENCION  : ", fl_justifica_titulo('I', v_r, 15)
	PRINT COLUMN 01,  "VENDEDOR(A)     : ", r_r01.r01_nombres,
	      COLUMN 69,  "CREDITO    : ", fl_justifica_titulo('I', v_c, 15)
	SKIP 2 LINES
	--PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 02,  "CODIGO",
	      COLUMN 11,  "DESCRIPCION",
	      COLUMN 56,  "MEDIDA",
	      COLUMN 64,  "MARCA",
	      COLUMN 84,  "CANTIDAD",
	      COLUMN 96,  "PRECIO VENTA",
	      COLUMN 110, "%DSCTO",
	      COLUMN 121, "VALOR TOTAL"
	--PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	SKIP 1 LINES

ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 02,  r_rep.r20_item[1,7],
	      COLUMN 11,  r_rep.desc_clase,
	      COLUMN 56,  r_rep.unidades,
	      COLUMN 64,  r_rep.desc_marca
	PRINT COLUMN 13,  r_rep.descripcion,
	      COLUMN 84,  r_rep.cant_ven	USING '####&.##',
	      COLUMN 94,  r_rep.precio		USING '###,###,##&.##',
	      COLUMN 110, r_rep.descuento	USING '##&.##',
	      COLUMN 118, r_rep.valor_tot	USING '###,###,##&.##'
	
PAGE TRAILER
	--NEED 4 LINES
	LET label_letras = fl_retorna_letras(rm_r19.r19_moneda, valor_pag)
	SKIP 2 LINES
	--PRINT COLUMN 02, "SOMOS CONTRIBUYENTES ESPECIALES, RESOLUCION No. 5368",
	PRINT COLUMN 60,  "-------------------------",
	      COLUMN 95,  "TOTAL BRUTO",
	      COLUMN 116, rm_r19.r19_tot_bruto	USING "#,###,###,##&.##"
	PRINT COLUMN 60,  " RECIBI FACTURA ORIGINAL ",
	      COLUMN 95,  "DESCUENTOS",
	      COLUMN 118, rm_r19.r19_tot_dscto	USING "###,###,##&.##"
	IF vg_codloc = 6 OR vg_codloc = 7 THEN
		PRINT COLUMN 008, "www.herramientasyanclajes.com";
	ELSE
		PRINT COLUMN 008, "w w w . a c e r o c o m e r c i a l . c o m";
	END IF
	PRINT COLUMN 95,  "SUBTOTAL",
	      COLUMN 118, subtotal		USING "###,###,##&.##"
	PRINT COLUMN 95,  "I. V. A. (", rm_r19.r19_porc_impto USING "#&", ") %",
	      COLUMN 118, impuesto		USING "###,###,##&.##"
	IF mensaje_fa_ant IS NOT NULL THEN
		PRINT COLUMN 006, mensaje_fa_ant CLIPPED;
	END IF
	PRINT COLUMN 95,  "TRANSPORTE",
	      COLUMN 118, rm_r19.r19_flete	USING "###,###,##&.##"
	PRINT COLUMN 02,  "SON: ", label_letras[1,87],
	      COLUMN 95,  "VALOR A PAGAR",
	      COLUMN 116, valor_pag		USING "#,###,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



REPORT report_factura3(r_rep)		-- PARA SERMACO
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
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE documento	VARCHAR(60)
DEFINE titulo		VARCHAR(80)
DEFINE fecha_vcto	DATE
DEFINE long, i		SMALLINT
DEFINE valor_efec	DECIMAL(14,2)
DEFINE valor_cheq	DECIMAL(14,2)
DEFINE valor_tarj	DECIMAL(14,2)
DEFINE valor_rete	DECIMAL(14,2)
DEFINE valor_cred	DECIMAL(14,2)
DEFINE subtotal		DECIMAL(14,2)
DEFINE impuesto		DECIMAL(14,2)
DEFINE valor_pag	DECIMAL(14,2)
DEFINE factura		VARCHAR(15)
DEFINE proforma		VARCHAR(10)
DEFINE v_e		VARCHAR(15)
DEFINE v_ch		VARCHAR(15)
DEFINE v_t		VARCHAR(15)
DEFINE v_r		VARCHAR(15)
DEFINE v_c		VARCHAR(15)
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
	--print 'E';
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET subtotal  = rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto
	LET impuesto  = rm_r19.r19_tot_neto - rm_r19.r19_tot_bruto +
			rm_r19.r19_tot_dscto - rm_r19.r19_flete
	LET valor_pag = rm_r19.r19_tot_neto
	CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
		RETURNING r_r01.*
--	print '&k2S' 		-- Letra condensada
	SELECT * INTO r_r21.* FROM rept021
		WHERE r21_compania  = rm_r19.r19_compania
		  AND r21_localidad = rm_r19.r19_localidad
		  AND r21_cod_tran  = rm_r19.r19_cod_tran
		  AND r21_num_tran  = rm_r19.r19_num_tran
	LET fecha_vcto = NULL
	LET valor_cred = 0
	IF rm_r19.r19_cont_cred = 'R' THEN
		SELECT * INTO r_r23.* FROM rept023
			WHERE r23_compania  = rm_r19.r19_compania
			  AND r23_localidad = rm_r19.r19_localidad
			  AND r23_cod_tran  = r_r21.r21_cod_tran
			  AND r23_num_tran  = r_r21.r21_num_tran
		SELECT SUM(r26_valor_cap), MAX(r26_fec_vcto)
			INTO valor_cred, fecha_vcto FROM rept026
			WHERE r26_compania  = r_r23.r23_compania
			  AND r26_localidad = r_r23.r23_localidad
			  AND r26_numprev   = r_r23.r23_numprev
		IF valor_cred IS NULL THEN
			LET valor_cred = 0
		END IF
	END IF
	SELECT * INTO r_j10.* FROM cajt010
		WHERE j10_compania     = rm_r19.r19_compania
		  AND j10_localidad    = rm_r19.r19_localidad
		  AND j10_tipo_fuente  = 'PR'
		  AND j10_tipo_destino = rm_r19.r19_cod_tran
		  AND j10_num_destino  = rm_r19.r19_num_tran
	DECLARE q_forpag3 CURSOR FOR
		SELECT * FROM cajt011
			WHERE j11_compania    = r_j10.j10_compania
			  AND j11_localidad   = r_j10.j10_localidad
			  AND j11_tipo_fuente = r_j10.j10_tipo_fuente
			  AND j11_num_fuente  = r_j10.j10_num_fuente
	LET valor_efec = 0
	LET valor_cheq = 0
	LET valor_tarj = 0
	LET valor_rete = 0
	FOREACH q_forpag3 INTO r_j11.*
		CASE r_j11.j11_codigo_pago
			WHEN 'EF'
				LET valor_efec = valor_efec + r_j11.j11_valor
			WHEN 'CH'
				LET valor_cheq = valor_cheq + r_j11.j11_valor
			WHEN 'RT'
				LET valor_rete = valor_rete + r_j11.j11_valor
		END CASE
		IF r_j11.j11_codigo_pago[1, 1] = 'T' THEN
			LET valor_tarj = valor_tarj + r_j11.j11_valor
		END IF
	END FOREACH
	LET factura  = rm_r19.r19_num_tran
	LET proforma = r_r21.r21_numprof
	LET v_e      = valor_efec USING "###,###,##&.##"
	LET v_ch     = valor_cheq USING "###,###,##&.##"
	LET v_t      = valor_tarj USING "###,###,##&.##"
	LET v_r      = valor_rete USING "###,###,##&.##"
	LET v_c      = valor_cred USING "###,###,##&.##"
	CALL fl_lee_cliente_general(rm_r19.r19_codcli) RETURNING r_z01.*
	print ASCII escape;
	print ASCII act_comp
	SKIP 2 LINES
	IF vg_codloc = 6 THEN
		PRINT COLUMN 72,  "No. ", rm_r19.r19_cod_tran, " ",
				factura CLIPPED,
		      COLUMN 103, "FECHA FACTURA : ", DATE(rm_r19.r19_fecing) 
		 			USING "dd-mm-yyyy"
		PRINT COLUMN 27,  "ALMACEN : ", rm_loc.g02_nombre CLIPPED
		SKIP 1 LINES
	ELSE
		PRINT COLUMN 27,  "ALMACEN : ", rm_loc.g02_nombre CLIPPED,
		      COLUMN 57,  "No. ", rm_r19.r19_cod_tran, " ", factura,
		      COLUMN 103, "FECHA FACTURA : ", DATE(rm_r19.r19_fecing) 
		 			USING "dd-mm-yyyy"
		SKIP 2 LINES
	END IF
	PRINT COLUMN 01,  "CLIENTE (", rm_r19.r19_codcli USING "&&&&&", ") : ",
					rm_r19.r19_nomcli[1, 100] CLIPPED
	PRINT COLUMN 01,  "CEDULA/RUC      : ", rm_r19.r19_cedruc,
	      COLUMN 69,  "EFECTIVO   : ", fl_justifica_titulo('I', v_e, 15),
	      COLUMN 106, "No. PROFORMA : ", proforma
	PRINT COLUMN 01,  "DIRECCION       : ", rm_r19.r19_dircli,
	      COLUMN 69,  "CHEQUES    : ", fl_justifica_titulo('I', v_ch, 15),
	      COLUMN 106, "FECHA DE VENCIMIENTO"
	PRINT COLUMN 01,  "TELEFONO        : ", rm_r19.r19_telcli,
	      COLUMN 69,  "TARJETAS   : ", fl_justifica_titulo('I', v_t, 15),
	      COLUMN 111, DATE(fecha_vcto) USING "dd-mm-yyyy"
	PRINT COLUMN 01,  "OBSERVACION     : ", r_r21.r21_atencion,
	      COLUMN 69,  "RETENCION  : ", fl_justifica_titulo('I', v_r, 15)
	PRINT COLUMN 01,  "VENDEDOR(A)     : ", r_r01.r01_nombres,
	      COLUMN 69,  "CREDITO    : ", fl_justifica_titulo('I', v_c, 15)
	SKIP 2 LINES
	--#IF vg_codloc = 6 THEN
		--#SKIP 1 LINES
	--#END IF
	--PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 02,  "CODIGO",
	      COLUMN 11,  "DESCRIPCION",
	      COLUMN 56,  "MEDIDA",
	      COLUMN 64,  "MARCA",
	      COLUMN 84,  "CANTIDAD",
	      COLUMN 96,  "PRECIO VENTA",
	      COLUMN 110, "%DSCTO",
	      COLUMN 121, "VALOR TOTAL"
	--PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	--SKIP 1 LINES

ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 02,  r_rep.r20_item[1,7],
	      COLUMN 11,  r_rep.desc_clase,
	      COLUMN 56,  r_rep.unidades,
	      COLUMN 64,  r_rep.desc_marca
	PRINT COLUMN 13,  r_rep.descripcion,
	      COLUMN 84,  r_rep.cant_ven	USING '####&.##',
	      COLUMN 94,  r_rep.precio		USING '###,###,##&.##',
	      COLUMN 110, r_rep.descuento	USING '##&.##',
	      COLUMN 118, r_rep.valor_tot	USING '###,###,##&.##'
	
PAGE TRAILER
	--NEED 4 LINES
	LET label_letras = fl_retorna_letras(rm_r19.r19_moneda, valor_pag)
	SKIP 1 LINES
	--PRINT COLUMN 02,  "SOMOS CONTRIBUYENTES ESPECIALES D.G.R. # 39",
	--PRINT COLUMN 02, "SOMOS CONTRIBUYENTES ESPECIALES, RESOLUCION No. 5368",
	PRINT COLUMN 60,  "-------------------------",
	      COLUMN 95,  "TOTAL BRUTO",
	      COLUMN 116, rm_r19.r19_tot_bruto	USING "#,###,###,##&.##"
	PRINT COLUMN 60,  " RECIBI FACTURA ORIGINAL ",
	      COLUMN 95,  "DESCUENTOS",
	      COLUMN 118, rm_r19.r19_tot_dscto	USING "###,###,##&.##"
	IF vg_codloc = 6 OR vg_codloc = 7 THEN
		PRINT COLUMN 008, "www.herramientasyanclajes.com";
	ELSE
		PRINT COLUMN 008, "w w w . a c e r o c o m e r c i a l . c o m";
	END IF
	PRINT COLUMN 95,  "SUBTOTAL",
	      COLUMN 118, subtotal		USING "###,###,##&.##"
	PRINT COLUMN 95,  "I. V. A. (", rm_r19.r19_porc_impto USING "#&", ") %",
	      COLUMN 118, impuesto		USING "###,###,##&.##"
	IF mensaje_fa_ant IS NOT NULL THEN
		PRINT COLUMN 006, mensaje_fa_ant CLIPPED;
	END IF
	PRINT COLUMN 95,  "TRANSPORTE",
	      COLUMN 118, rm_r19.r19_flete	USING "###,###,##&.##"
	PRINT COLUMN 02,  "SON: ", label_letras[1,87],
	      COLUMN 95,  "VALOR A PAGAR",
	      COLUMN 116, valor_pag		USING "#,###,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT
