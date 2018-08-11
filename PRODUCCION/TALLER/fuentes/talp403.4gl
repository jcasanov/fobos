--------------------------------------------------------------------------------
-- Titulo           : talp403.4gl - Impresion Comprobante de Facturas Taller
-- Elaboracion      : 01-feb-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun talp403 BD MODULO COMPANIA LOCALIDAD FACTURA
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t03		RECORD LIKE talt003.*
DEFINE rm_t00		RECORD LIKE talt000.*
DEFINE rm_z01		RECORD LIKE cxct001.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE rm_r00		RECORD LIKE rept000.*
DEFINE vm_factura	LIKE talt023.t23_num_factura      
DEFINE vm_tarea_sem	LIKE talt024.t24_codtarea
DEFINE mensaje_fa_ant	VARCHAR(250)
DEFINE tot_lin_oc	INTEGER
DEFINE tot_lin_mo	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp403.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vm_factura  = arg_val(5)
LET vg_proceso  = 'talp403'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
INITIALIZE rm_t23.* TO NULL
SELECT * INTO rm_t23.* FROM talt023
	WHERE t23_compania    = vg_codcia
          AND t23_localidad   = vg_codloc
	  AND t23_num_factura = vm_factura
IF rm_t23.t23_orden IS NULL THEN	
	CALL fl_mostrar_mensaje('No existe Orden de Trabajo.','stop')
	EXIT PROGRAM
END IF
IF rm_t23.t23_num_factura IS NULL THEN	
	CALL fl_mostrar_mensaje('Orden no ha sido Facturada.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_cliente_general(rm_t23.t23_cod_cliente) RETURNING rm_z01.*
CALL fl_lee_mecanico(vg_codcia, rm_t23.t23_cod_asesor) RETURNING rm_t03.*
IF rm_t23.t23_cod_asesor IS NULL THEN	
	CALL fl_mostrar_mensaje('No existe codigo de asesor.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE r_g06		RECORD LIKE gent006.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_t60		RECORD LIKE talt060.*
DEFINE num_sri		LIKE rept038.r38_num_sri
DEFINE comando		VARCHAR(100)
DEFINE tope		INTEGER

INITIALIZE r_g06.* TO NULL
IF rm_t23.t23_cont_cred = 'C' THEN
	LET r_g06.g06_impresora = fgl_getenv('PRINTER_CONT')
ELSE
	LET r_g06.g06_impresora = fgl_getenv('PRINTER_CRED')
END IF
-- OJO PUESTO PARA LA NOTA DE VENTA
{--
IF vg_codloc = 3 THEN
	CALL fl_lee_cliente_general(rm_t23.t23_cod_cliente) RETURNING r_z01.*
	IF r_z01.z01_tipo_doc_id <> 'R' THEN
		LET r_g06.g06_impresora = fgl_getenv('PRINTER_NOTA')
	END IF
END IF
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
IF rm_loc.g02_localidad IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
INITIALIZE r_t60.* TO NULL
SELECT * INTO r_t60.*
	FROM talt060
	WHERE t60_compania  = vg_codcia
	  AND t60_localidad = vg_codloc
	  AND t60_fac_nue   = rm_t23.t23_num_factura
LET mensaje_fa_ant = NULL
IF r_t60.t60_compania IS NOT NULL THEN
	CALL fl_lee_factura_taller(r_t60.t60_compania, r_t60.t60_localidad,
					r_t60.t60_fac_ant) 
		RETURNING r_t23.*
	SELECT r38_num_sri INTO num_sri
		FROM rept038
		WHERE r38_compania    = r_t23.t23_compania
		  AND r38_localidad   = r_t23.t23_localidad
		  AND r38_tipo_fuente = 'OT'
		  AND r38_cod_tran    = 'FA'
		  AND r38_num_tran    = r_t23.t23_num_factura
	LET mensaje_fa_ant = 'FACTURA ORIGINAL # (FA-', r_t23.t23_num_factura
				USING "<<<<<<<<&", ')  ', num_sri CLIPPED,
				'  FECHA: ', DATE(r_t23.t23_fec_factura)
				USING "dd-mm-yyyy"
END IF
SELECT COUNT(c14_secuencia)
	INTO tot_lin_oc
	FROM ordt014, ordt013
	WHERE c14_compania   = vg_codcia
	  AND c14_localidad  = vg_codloc
	  AND c14_numero_oc IN
		(SELECT c10_numero_oc
			FROM ordt010
			WHERE c10_compania    = c14_compania
			  AND c10_localidad   = c14_localidad
			  AND c10_ord_trabajo = rm_t23.t23_orden
			  AND c10_estado      = "C")
	  AND c13_compania  = c14_compania
	  AND c13_localidad = c14_localidad
	  AND c13_numero_oc = c14_numero_oc
	  AND c13_num_recep = c14_num_recep
	  AND c13_estado    = "A"
SELECT COUNT(*) INTO tot_lin_mo
	FROM talt024
	WHERE t24_compania  = vg_codcia
	  AND t24_localidad = vg_codloc
	  AND t24_orden     = rm_t23.t23_orden
LET vm_tarea_sem = NULL
SELECT UNIQUE t24_codtarea
	INTO vm_tarea_sem
	FROM talt024
	WHERE t24_compania  = vg_codcia
	  AND t24_localidad = vg_codloc
	  AND t24_orden     = rm_t23.t23_orden
	  AND t24_codtarea  IN ("3", "4")
IF vm_tarea_sem IS NULL THEN
	LET tope = ((rm_r00.r00_numlin_fact * 2) - 6)
ELSE
	LET tope = ((rm_r00.r00_numlin_fact * 2) - 1)
END IF
IF tot_lin_oc + tot_lin_mo > tope THEN
	LET tot_lin_mo = tope - tot_lin_oc
	IF tot_lin_mo < 0 THEN
		LET tot_lin_mo = tot_lin_mo * (-1)
	END IF
	IF tot_lin_mo > (tope / 2) THEN
		LET tot_lin_mo = (tope / 2)
	END IF
	IF tot_lin_oc + tot_lin_mo > tope THEN
		LET tot_lin_oc = tot_lin_oc - tot_lin_mo
	END IF
	IF tot_lin_oc > (tope / 2) THEN
		LET tot_lin_oc = (tope / 2)
	END IF
END IF
START REPORT comprobante_factura TO PIPE comando
OUTPUT TO REPORT comprobante_factura()
FINISH REPORT comprobante_factura

END FUNCTION



REPORT comprobante_factura()
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE r_t20		RECORD LIKE talt020.*
DEFINE r_t24		RECORD LIKE talt024.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c14		RECORD LIKE ordt014.*
DEFINE query		CHAR(400)
DEFINE documento	VARCHAR(60)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE fecha_vcto	DATE
DEFINE long, i		SMALLINT
DEFINE tope_lin		SMALLINT
DEFINE valor_efec	DECIMAL(14,2)
DEFINE valor_cheq	DECIMAL(14,2)
DEFINE valor_tarj	DECIMAL(14,2)
DEFINE valor_rete	DECIMAL(14,2)
DEFINE valor_cred	DECIMAL(14,2)
DEFINE subtotal		DECIMAL(14,2)
DEFINE impuesto		DECIMAL(14,2)
DEFINE valor_pag	DECIMAL(14,2)
DEFINE precio, total	DECIMAL(14,2)
DEFINE factura		VARCHAR(15)
DEFINE label_letras	VARCHAR(130)
DEFINE num_lin		INTEGER
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_dob1		SMALLINT
DEFINE act_dob2		SMALLINT
DEFINE des_dob		SMALLINT
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
	--print 'E';
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET subtotal    = rm_t23.t23_tot_bruto - rm_t23.t23_tot_dscto
	LET impuesto    = rm_t23.t23_val_impto
	LET valor_pag   = rm_t23.t23_tot_neto
	CALL fl_justifica_titulo('I', vg_usuario, 10) RETURNING usuario
--	print '&k2S' 		-- Letra condensada
	LET fecha_vcto = NULL
	LET valor_cred = 0
	IF rm_t23.t23_cont_cred = 'R' THEN
		SELECT SUM(t26_valor_cap), MAX(t26_fec_vcto)
			INTO valor_cred, fecha_vcto FROM talt026
			WHERE t26_compania  = rm_t23.t23_compania
			  AND t26_localidad = rm_t23.t23_localidad
			  AND t26_orden     = rm_t23.t23_orden
		IF valor_cred IS NULL THEN
			LET valor_cred = 0
		END IF
	END IF
	SELECT * INTO r_j10.* FROM cajt010
		WHERE j10_compania     = rm_t23.t23_compania
		  AND j10_localidad    = rm_t23.t23_localidad
		  AND j10_tipo_fuente  = 'OT'
		  AND j10_tipo_destino = 'FA'
		  AND j10_num_destino  = rm_t23.t23_num_factura
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
	LET factura = rm_t23.t23_num_factura USING "&&&&&&&&&"
	CALL fl_lee_presupuesto_taller(vg_codcia, vg_codloc, rm_t23.t23_numpre)
		RETURNING r_t20.*
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	--20/05/2014
	--PRINT COLUMN 27,  "ALMACEN : ", rm_loc.g02_nombre,
	PRINT COLUMN 052, ASCII escape, ASCII act_12cpi, ASCII escape,
			ASCII act_dob1, ASCII act_dob2,
			ASCII escape, ASCII act_neg,
			"FACTURA No. ", rm_loc.g02_serie_cia USING "&&&", "-",
			rm_loc.g02_serie_loc USING "&&&", "-", factura;
	IF vm_tarea_sem IS NULL THEN
		PRINT " TALLER";
	ELSE
		PRINT " ";
	END IF
	PRINT ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_10cpi, ASCII escape, ASCII des_neg,
		ASCII escape, ASCII act_comp
	SKIP 2 LINES
	PRINT COLUMN 001, "CLIENTE (", rm_t23.t23_cod_cliente
					USING "&&&&&", ") : ",
					rm_t23.t23_nom_cliente[1, 100] CLIPPED
	PRINT COLUMN 001, "CEDULA/RUC      : ", rm_t23.t23_cedruc;
	IF vm_tarea_sem IS NULL THEN
		PRINT COLUMN 067, "No. ORDEN TRABAJO: ", rm_t23.t23_orden
						USING "&&&&&&&";
	ELSE
		PRINT COLUMN 067, " ";
	END IF
	PRINT COLUMN 106, "EFECTIVO  : ", valor_efec USING "###,###,##&.##"
	PRINT COLUMN 001, "DIRECCION       : ", rm_t23.t23_dir_cliente,
	      COLUMN 067, ASCII escape, ASCII act_neg,
		"FECHA FACTURA    : ", DATE(rm_t23.t23_fec_factura) 
			 			USING "dd-mm-yyyy",
		ASCII escape, ASCII des_neg,
	      COLUMN 110, "CHEQUES   : ", valor_cheq USING "###,###,##&.##"
	PRINT COLUMN 001, "TELEFONO        : ", rm_t23.t23_tel_cliente,
	      COLUMN 067, "FECHA VENCIMIENTO: ", DATE(fecha_vcto)
			 			USING "dd-mm-yyyy",
	      COLUMN 106, "TARJETAS  : ", valor_tarj USING "###,###,##&.##"
	PRINT COLUMN 001, "OBSER. PRESUP.  : ", r_t20.t20_observaciones;
	IF vm_tarea_sem IS NULL THEN
		PRINT COLUMN 067,"TECNICO(ASESOR)  : ",rm_t03.t03_nombres[1,19];
	ELSE
		PRINT COLUMN 067, " ";
	END IF
	PRINT COLUMN 106, "RETENCION : ", valor_rete USING "###,###,##&.##"
	PRINT COLUMN 067, "USUARIO          : ", usuario,
	      COLUMN 106, "CREDITO   : ", valor_cred USING "###,###,##&.##"
	--PRINT COLUMN 01,  "FECHA IMPRESION : ", DATE(TODAY) USING 'dd-mm-yyyy',
		--1 SPACES, TIME,
	      --COLUMN 125, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 011, "DESCRIPCION";
	IF vm_tarea_sem IS NOT NULL THEN
		PRINT COLUMN 096, "VALOR UNITARIO";
	ELSE
		PRINT COLUMN 096, " ";
	END IF
	PRINT COLUMN 121, "VALOR TOTAL"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	SKIP 1 LINES

ON EVERY ROW
	NEED 1 LINES
{--
	PRINT COLUMN 11,  "TOTAL REPUESTOS Y MATERIALES DE ALMACEN",
	      COLUMN 118, rm_t23.t23_val_rp_alm		USING '###,###,##&.##'
--}
	IF vm_tarea_sem IS NULL THEN
	PRINT COLUMN 11,  "TOTAL OTROS REPUESTOS Y MATERIALES",
	      COLUMN 118, rm_t23.t23_val_mo_ext + rm_t23.t23_val_mo_cti +
			  rm_t23.t23_val_rp_tal + rm_t23.t23_val_rp_ext +
			  rm_t23.t23_val_rp_cti + rm_t23.t23_val_otros2
			USING '###,###,##&.##'
	LET query ='SELECT * FROM ordt010 ',
			' WHERE c10_compania    = ', vg_codcia,
			'   AND c10_localidad   = ', vg_codloc,
			'   AND c10_ord_trabajo = ', rm_t23.t23_orden,
			'   AND c10_estado      = "C" ',
			' ORDER BY c10_fecing '
	PREPARE cons_c10 FROM query
	DECLARE q_ordt010 CURSOR FOR cons_c10
	LET i = 1
	FOREACH q_ordt010 INTO r_c10.*
		DECLARE q_ordt014 CURSOR FOR
			SELECT ordt014.*
				FROM ordt014, ordt013
				WHERE c14_compania  = vg_codcia
				  AND c14_localidad = vg_codloc
				  AND c14_numero_oc = r_c10.c10_numero_oc
				  AND c13_compania  = c14_compania
				  AND c13_localidad = c14_localidad
				  AND c13_numero_oc = c14_numero_oc
				  AND c13_num_recep = c14_num_recep
				  AND c13_estado    = "A"
				ORDER BY c14_numero_oc, c14_secuencia
		FOREACH q_ordt014 INTO r_c14.*
			LET total  = (r_c14.c14_cantidad * r_c14.c14_precio) -
				      r_c14.c14_val_descto
			LET total  = total + ((total * r_c10.c10_recargo) / 100)
			LET precio = total / r_c14.c14_cantidad
			--PRINT COLUMN 02,  DATE(r_c10.c10_fecing) USING "dd-mm-yyyy",
			      --COLUMN 17,  r_c14.c14_numero_oc USING "######",
		      	PRINT COLUMN 13,  r_c14.c14_descrip	--,
			{--
			      COLUMN 91,  r_c14.c14_cantidad  USING '###&.##',
			      COLUMN 100, precio USING '###,###,##&.##',
			      COLUMN 118, total	 USING '###,###,##&.##'
			--}
			--LET total_gen = total_gen + total
			IF i > tot_lin_oc THEN
				EXIT FOREACH
			END IF
			LET i = i + 1
		END FOREACH
		IF i > tot_lin_oc THEN
			EXIT FOREACH
		END IF
	END FOREACH
	SKIP 1 LINES
	PRINT COLUMN 011, "TOTAL DE MANO DE OBRA",
	      COLUMN 118, rm_t23.t23_val_mo_tal		USING '###,###,##&.##'
	ELSE
	IF vm_tarea_sem = "3" THEN
	PRINT COLUMN 011, "SEMINARIO: OPTIMIZACION ENERGETICA EN SISTEMAS CON VAPOR"
	ELSE
	PRINT COLUMN 011, "SEMINARIO: OPTIMIZACION SISTEMAS DE CONTROL EN CALDERAS ACUOTUBULARES"
	END IF
		SKIP 1 LINES
	END IF
	SELECT COUNT(*) INTO num_lin FROM talt024
		WHERE t24_compania  = vg_codcia
		  AND t24_localidad = vg_codloc
		  AND t24_orden     = rm_t23.t23_orden
	IF vm_tarea_sem IS NULL THEN
		LET tope_lin = ((rm_r00.r00_numlin_fact * 2) - 5)
	ELSE
		LET tope_lin = (rm_r00.r00_numlin_fact * 2)
	END IF
	IF num_lin <= tope_lin THEN
		DECLARE q_talt024 CURSOR FOR
			SELECT * FROM talt024
				WHERE t24_compania  = vg_codcia
				  AND t24_localidad = vg_codloc
				  AND t24_orden     = rm_t23.t23_orden
				ORDER BY t24_secuencia
		LET i = 1
		FOREACH q_talt024 INTO r_t24.*
			PRINT COLUMN 13,  r_t24.t24_descripcion;
			IF vm_tarea_sem IS NOT NULL THEN
				PRINT COLUMN 94,
				r_t24.t24_valor_tarea USING "#,###,###,##&.##",
				      COLUMN 116,
				r_t24.t24_valor_tarea USING "#,###,###,##&.##"
			ELSE
				PRINT COLUMN 94, ""
			END IF
			IF i > tot_lin_mo THEN
				EXIT FOREACH
			END IF
			LET i = i + 1
		END FOREACH
	END IF
	IF vm_tarea_sem IS NULL THEN
		SKIP 1 LINES
		PRINT COLUMN 011, "TOTAL MATERIAL Y REPUESTOS ",
			rm_cia.g01_razonsocial CLIPPED,
			" (VER FACTURAS ADJUNTAS)"
	END IF
	
PAGE TRAILER
	--NEED 4 LINES
	--LET label_letras = fl_retorna_letras(rm_t23.t23_moneda, valor_pag)
	CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
					rm_t23.t23_cod_cliente)
		RETURNING r_z02.*
	SKIP 2 LINES
	--PRINT COLUMN 02,  "SOMOS CONTRIBUYENTES ESPECIALES D.G.R. #39",
	--PRINT COLUMN 02, "SOMOS CONTRIBUYENTES ESPECIALES, RESOLUCION No. 5368",
	--PRINT COLUMN 50,  "-------------------------",
	PRINT COLUMN 002, ASCII escape, ASCII act_12cpi, ASCII escape,
			ASCII act_dob1, ASCII act_dob2,
			ASCII escape, ASCII act_neg,
	      COLUMN 008, "COPIA SIN DERECHO A CREDITO TRIBUTARIO",
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_10cpi, ASCII escape, ASCII des_neg,
		ASCII escape, ASCII act_comp,
	      COLUMN 085, "TOTAL BRUTO",
	      COLUMN 105, rm_t23.t23_tot_bruto	USING "#,###,###,##&.##"
	{--
	IF vg_codloc = 6 OR vg_codloc = 7 THEN
		PRINT COLUMN 006, "www.herramientasyanclajes.com";
	ELSE
		PRINT COLUMN 006, "w w w . a c e r o c o m e r c i a l . c o m";
	END IF
	PRINT COLUMN 50,  " RECIBI FACTURA ORIGINAL ",
	--}
	PRINT COLUMN 002, "Estimado cliente: Su comprobante electronico ",
			"usted lo recibira en su cuenta de correo:",
	      COLUMN 096, "DESCUENTOS",
	      COLUMN 118, rm_t23.t23_tot_dscto	USING "###,###,##&.##"
	PRINT COLUMN 002, ASCII escape, ASCII act_neg,
			r_z02.z02_email CLIPPED, '.',
			ASCII escape, ASCII des_neg,
	      COLUMN 100, "SUBTOTAL",
	      COLUMN 122, subtotal		USING "###,###,##&.##"
	{--
	IF mensaje_fa_ant IS NOT NULL THEN
		PRINT COLUMN 006, mensaje_fa_ant CLIPPED;
	END IF
	--}
	PRINT COLUMN 002, "Tambien podra consultar y descargar sus ",
			"comprobantes electronicos a traves del portal",
	      COLUMN 096, "I. V. A. (", rm_t23.t23_porc_impto USING "#&", ") %",
	      COLUMN 118, impuesto		USING "###,###,##&.##"
	PRINT COLUMN 002, "web ",
			ASCII escape, ASCII act_neg,
			"https://innobeefactura.com.",
			ASCII escape, ASCII des_neg,
			" Sus datos para el primer acceso son Usuario: ",
	      COLUMN 100, "GASTOS MOVILIZ. Y DIETAS",
	      COLUMN 126, rm_t23.t23_val_otros1	USING "###,##&.##"
	--PRINT COLUMN 02,  "SON: ", label_letras[1,87],
	PRINT COLUMN 002, ASCII escape, ASCII act_neg,
			rm_t23.t23_cedruc CLIPPED, "@innobeefactura.com",
			ASCII escape, ASCII des_neg,
			" y su Clave: ",
			ASCII escape, ASCII act_neg,
			rm_t23.t23_cedruc CLIPPED, ".",
			ASCII escape, ASCII des_neg,
	      COLUMN 104, "VALOR A PAGAR",
	      COLUMN 124, valor_pag		USING "#,###,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT
