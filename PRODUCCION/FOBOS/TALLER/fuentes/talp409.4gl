--------------------------------------------------------------------------------
-- Titulo           : talp409.4gl - REPORTE DE N/C (DEV. FACT.)
-- Elaboracion      : 10-Feb-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp409 base modulo compania localidad [factura]
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_z21		RECORD LIKE cxct021.*
DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t03		RECORD LIKE talt003.*
DEFINE rm_t00		RECORD LIKE talt000.*
DEFINE rm_z01		RECORD LIKE cxct001.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp409.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 7 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base             = arg_val(1)
LET vg_modulo           = arg_val(2)
LET vg_codcia           = arg_val(3)
LET vg_codloc           = arg_val(4)
LET rm_z21.z21_codcli	= arg_val(5)
LET rm_z21.z21_tipo_doc	= arg_val(6)
LET rm_z21.z21_num_doc	= arg_val(7)
LET vg_proceso          = 'talp409'
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
CALL fl_lee_documento_favor_cxc(vg_codcia, vg_codloc, rm_z21.z21_codcli,
				rm_z21.z21_tipo_doc, rm_z21.z21_num_doc)
	RETURNING rm_z21.*
IF rm_z21.z21_compania IS NULL THEN	
	CALL fl_mostrar_mensaje('No existe el documento.','stop')
	EXIT PROGRAM
END IF
SELECT * INTO rm_t23.* FROM talt023
	WHERE t23_compania    = vg_codcia
          AND t23_localidad   = vg_codloc
	  AND t23_num_factura = rm_z21.z21_num_tran
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
CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE comando		VARCHAR(100)

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
IF rm_loc.g02_localidad IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
START REPORT report_nota_credito_tal TO PIPE comando
OUTPUT TO REPORT report_nota_credito_tal()
FINISH REPORT report_nota_credito_tal

END FUNCTION



REPORT report_nota_credito_tal()
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE r_t28		RECORD LIKE talt028.*
DEFINE r_r38		RECORD LIKE rept038.*
DEFINE documento	VARCHAR(60)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
DEFINE valor_oc		DECIMAL(16,2)
DEFINE subtotal		DECIMAL(14,2)
DEFINE impuesto		DECIMAL(14,2)
DEFINE valor_pag	DECIMAL(14,2)
DEFINE factura		VARCHAR(15)
DEFINE num_nc		VARCHAR(10)
DEFINE label_letras	VARCHAR(130)
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
	SELECT * INTO r_t28.* FROM talt028
		WHERE t28_compania  = vg_codcia
		  AND t28_localidad = vg_codloc
		  AND t28_factura   = rm_t23.t23_num_factura
	LET documento   = "COMPROBANTE DEVOLUCION DE FACTURA No. " ||
					r_t28.t28_num_dev CLIPPED
	LET subtotal  = rm_t23.t23_tot_bruto - rm_t23.t23_tot_dscto
	LET impuesto  = rm_t23.t23_val_impto
	LET valor_pag = rm_t23.t23_tot_neto
	CALL fl_justifica_titulo('I', vg_usuario, 10) RETURNING usuario
--	print '&k2S' 		-- Letra condensada
	LET factura = rm_t23.t23_num_factura USING "&&&&&&&&&"
	LET num_nc  = rm_z21.z21_num_doc USING "&&&&&&&&&"
	{--
	SELECT * INTO r_r38.* FROM rept038
		WHERE r38_compania    = vg_codcia
		  AND r38_localidad   = vg_codloc
		  AND r38_tipo_fuente = 'OT'
		  AND r38_cod_tran    = 'FA'
		  AND r38_num_tran    = rm_t23.t23_num_factura
	--}
	SKIP 3 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 102, ASCII escape, ASCII act_neg,
			"N/C No. ", rm_loc.g02_serie_cia USING "&&&", "-",
			rm_loc.g02_serie_loc USING "&&&", "-",
			num_nc, ASCII escape, ASCII des_neg
	PRINT COLUMN 027, ASCII escape, ASCII act_neg,
			documento, ASCII escape, ASCII des_neg,
	      COLUMN 104, "FECHA EMI. N/C : ", rm_z21.z21_fecha_emi
			 			USING "dd-mm-yyyy"
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 029, "ALMACEN : ", rm_loc.g02_nombre
	SKIP 2 LINES
	PRINT COLUMN 006, "CLIENTE (", rm_t23.t23_cod_cliente
					USING "&&&&&", ") : ",
					rm_z01.z01_nomcli[1, 77],
	      --COLUMN 072, "FACTURA SRI      : ", r_r38.r38_num_sri,
	      COLUMN 109, "ORDEN TRABAJO: ", rm_t23.t23_orden
						USING "&&&&&&&"
	PRINT COLUMN 006, "CEDULA/RUC      : ", rm_z01.z01_num_doc_id,
	      COLUMN 072, ASCII escape, ASCII act_neg,
		"No. FACTURA      : ", rm_z21.z21_cod_tran, " - ",
		rm_loc.g02_serie_cia USING "&&&", "-",
		rm_loc.g02_serie_loc USING "&&&", "-",
		factura, ASCII escape, ASCII des_neg
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 008, "DIRECCION       : ", rm_z01.z01_direccion1,
	      COLUMN 074, "FECHA FACTURA    : ", DATE(rm_t23.t23_fec_factura) 
			 			USING "dd-mm-yyyy"
	PRINT COLUMN 006, "TELEFONO        : ", rm_t23.t23_tel_cliente,
	      COLUMN 072, "TECNICO(ASESOR)  : ", rm_t03.t03_nombres[1,19]
	PRINT COLUMN 072, "USUARIO          : ", usuario
	--PRINT COLUMN 06,  "FECHA IMPRESION : ", DATE(TODAY) USING 'dd-mm-yyyy',
		--1 SPACES, TIME,
	      --COLUMN 125, UPSHIFT(vg_proceso)
	SKIP 2 LINES
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 011, "DESCRIPCION",
	      COLUMN 121, "VALOR TOTAL"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	SKIP 1 LINES

ON EVERY ROW
	NEED 1 LINES
{--
	PRINT COLUMN 11,  "TOTAL REPUESTOS Y MATERIALES DE ALMACEN",
	      COLUMN 118, rm_t23.t23_val_rp_alm		USING '###,###,##&.##'
--}
	LET valor_oc = 0
	IF rm_t23.t23_val_mo_ext + rm_t23.t23_val_mo_cti +
	   rm_t23.t23_val_rp_tal + rm_t23.t23_val_rp_ext = 0
	THEN
		CALL obtener_valor_oc() RETURNING valor_oc
	END IF
	PRINT COLUMN 11,  "TOTAL OTROS REPUESTOS Y MATERIALES",
	      COLUMN 118, rm_t23.t23_val_mo_ext + rm_t23.t23_val_mo_cti +
			  rm_t23.t23_val_rp_tal + rm_t23.t23_val_rp_ext +
			  rm_t23.t23_val_rp_cti + rm_t23.t23_val_otros2 +
			  valor_oc
			USING '###,###,##&.##'
	SKIP 1 LINES
	PRINT COLUMN 11,  "TOTAL DE MANO DE OBRA",
	      COLUMN 118, rm_t23.t23_val_mo_tal		USING '###,###,##&.##'
	SKIP 1 LINES
	PRINT COLUMN 11,  "TOTAL MATERIAL Y REPUESTOS ACERO COMERCIAL (VER FACTURAS ADJUNTAS)"
	
PAGE TRAILER
	--NEED 4 LINES
	LET subtotal     = subtotal + valor_oc
	LET impuesto     = impuesto + (valor_oc * rm_t23.t23_porc_impto / 100)
	LET valor_pag    = valor_pag + valor_oc
				+ (valor_oc * rm_t23.t23_porc_impto / 100)
	--LET label_letras = fl_retorna_letras(rm_t23.t23_moneda, valor_pag)
	CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
					rm_t23.t23_cod_cliente)
		RETURNING r_z02.*
	SKIP 2 LINES
	PRINT COLUMN 002, ASCII escape, ASCII act_12cpi, ASCII escape,
			ASCII act_dob1, ASCII act_dob2,
			ASCII escape, ASCII act_neg,
	      COLUMN 008, "COPIA SIN DERECHO A CREDITO TRIBUTARIO",
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_10cpi, ASCII escape, ASCII des_neg,
		ASCII escape, ASCII act_comp,
	      COLUMN 085, "TOTAL BRUTO (MO)",
	      COLUMN 105, rm_t23.t23_tot_bruto	USING "#,###,###,##&.##"
	PRINT COLUMN 002, "Estimado cliente: Su comprobante electronico ",
			"usted lo recibira en su cuenta de correo:",
	      COLUMN 096, "DESCUENTOS",
	      COLUMN 118, rm_t23.t23_tot_dscto	USING "###,###,##&.##"
	PRINT COLUMN 002, ASCII escape, ASCII act_neg,
			r_z02.z02_email CLIPPED, '.',
			ASCII escape, ASCII des_neg,
	      COLUMN 100, "SUBTOTAL",
	      COLUMN 122, subtotal		USING "###,###,##&.##"
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



FUNCTION obtener_valor_oc()
DEFINE valor_oc		DECIMAL(16,2)
DEFINE ot_nue		LIKE talt023.t23_orden

LET valor_oc = 0
INITIALIZE ot_nue TO NULL
SELECT t28_ot_nue INTO ot_nue
	FROM talt028
	WHERE t28_compania  = vg_codcia
	  AND t28_localidad = vg_codloc
	  AND t28_factura   = rm_t23.t23_num_factura
IF ot_nue IS NULL THEN
	RETURN valor_oc
END IF
SELECT NVL(((SELECT NVL(SUM((c11_precio - c11_val_descto) *
		(1 + c10_recargo / 100)), 0)
		FROM ordt010, ordt011
		WHERE c10_compania    = t23_compania
		  AND c10_localidad   = t23_localidad
		  AND c10_ord_trabajo = t23_orden
		  AND c10_estado      = 'C'
		  AND c11_compania    = c10_compania
		  AND c11_localidad   = c10_localidad
		  AND c11_numero_oc   = c10_numero_oc
		  AND c11_tipo        = 'S') +
		(SELECT NVL(SUM(((c11_cant_ped * c11_precio) - c11_val_descto)
			* (1 + c10_recargo / 100)), 0)
		 FROM ordt010, ordt011
		 WHERE c10_compania    = t23_compania
		   AND c10_localidad   = t23_localidad
		   AND c10_ord_trabajo = t23_orden
		   AND c10_estado      = 'C'
		   AND c11_compania    = c10_compania
		   AND c11_localidad   = c10_localidad
		   AND c11_numero_oc   = c10_numero_oc
		   AND c11_tipo        = 'B')), 0)
	INTO valor_oc
	FROM talt023
	WHERE t23_compania  = rm_t23.t23_compania
	  AND t23_localidad = rm_t23.t23_localidad
	  AND t23_orden     = ot_nue
RETURN valor_oc

END FUNCTION
