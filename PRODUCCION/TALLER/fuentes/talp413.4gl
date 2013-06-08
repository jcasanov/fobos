--------------------------------------------------------------------------------
-- Titulo           : talp413.4gl - Impresión Comprobante Devolución Taller
-- Elaboracion      : 27-Abr-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp413 base modulo compañía localidad devolución
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_devolucion	LIKE talt023.t23_num_factura      
DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_dev		RECORD LIKE talt023.*
DEFINE rm_t28		RECORD LIKE talt028.*
DEFINE rm_t03		RECORD LIKE talt003.*
DEFINE rm_t00		RECORD LIKE talt000.*
DEFINE rm_z01		RECORD LIKE cxct001.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp413.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base       = arg_val(1)
LET vg_modulo     = arg_val(2)
LET vg_codcia     = arg_val(3)
LET vg_codloc     = arg_val(4)
LET vm_devolucion = arg_val(5)
LET vg_proceso    = 'talp413'
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
INITIALIZE rm_t28.* TO NULL
SELECT * INTO rm_t28.*
	FROM talt028
	WHERE t28_compania  = vg_codcia
          AND t28_localidad = vg_codloc
	  AND t28_num_dev   = vm_devolucion
IF rm_t28.t28_num_dev IS NULL THEN	
	CALL fl_mostrar_mensaje('No existe Devolución.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_factura_taller(rm_t28.t28_compania, rm_t28.t28_localidad,
				rm_t28.t28_factura)
	RETURNING rm_dev.*
IF rm_dev.t23_num_factura IS NULL THEN	
	CALL fl_mostrar_mensaje('Devolución no tiene Factura.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_orden_trabajo(rm_t28.t28_compania, rm_t28.t28_localidad,
				rm_t28.t28_ot_nue)
	RETURNING rm_t23.*
IF rm_t23.t23_orden IS NULL THEN	
	CALL fl_mostrar_mensaje('No existe Orden de Trabajo.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_cliente_general(rm_t23.t23_cod_cliente) RETURNING rm_z01.*
CALL fl_lee_mecanico(vg_codcia, rm_t23.t23_cod_asesor) RETURNING rm_t03.*
IF rm_t23.t23_cod_asesor IS NULL THEN	
	CALL fl_mostrar_mensaje('No existe codigo de asesor.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 10
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
	OPEN FORM f_tal FROM "../forms/talf413_1"
ELSE
	OPEN FORM f_tal FROM "../forms/talf413_1c"
END IF
DISPLAY FORM f_tal
DISPLAY BY NAME rm_t28.t28_num_dev, rm_t28.t28_factura, rm_t28.t28_ot_ant
MESSAGE "                                           Presione una tecla para continuar "
LET tecla = fgl_getkey()
MESSAGE "                                                                             "
CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE orden		LIKE talt023.t23_orden
DEFINE comando		VARCHAR(100)
DEFINE comando2		CHAR(250)
DEFINE run_prog		CHAR(10)

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
START REPORT report_devolucion TO PIPE comando
OUTPUT TO REPORT report_devolucion()
FINISH REPORT report_devolucion
IF rm_dev.t23_val_mo_ext + rm_dev.t23_val_mo_cti = 0 THEN
	RETURN
END IF
LET orden = rm_t28.t28_ot_ant
IF NOT tiene_oc(rm_t28.t28_ot_ant) THEN
	IF NOT tiene_oc(rm_t28.t28_ot_nue) THEN
		RETURN
	END IF
	LET orden = rm_t28.t28_ot_nue
END IF
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando2 = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
		vg_separador, 'fuentes', vg_separador, run_prog, 'talp408 ',
		vg_base, ' TA ', vg_codcia, ' ', vg_codloc, ' ', orden, ' ',
		rm_dev.t23_num_factura, ' ', rm_t28.t28_ot_ant
RUN comando2

END FUNCTION



FUNCTION tiene_oc(orden)
DEFINE orden		LIKE talt023.t23_orden
DEFINE r_c10		RECORD LIKE ordt010.*

DECLARE q_c10 CURSOR FOR
	SELECT * FROM ordt010
		WHERE c10_compania    = vg_codcia
		  AND c10_localidad   = vg_codloc
		  AND c10_ord_trabajo = orden
OPEN q_c10
FETCH q_c10 INTO r_c10.*
IF STATUS = NOTFOUND THEN
	CLOSE q_c10
	FREE q_c10
	RETURN 0
END IF
CLOSE q_c10
FREE q_c10
RETURN 1

END FUNCTION



REPORT report_devolucion()
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_r00		RECORD LIKE rept000.*
DEFINE r_t20		RECORD LIKE talt020.*
DEFINE r_t24		RECORD LIKE talt024.*
DEFINE documento	VARCHAR(60)
DEFINE fecha_vcto	DATE
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
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
DEFINE tipo_docum	VARCHAR(10)
DEFINE tipo_docum2	VARCHAR(10)
DEFINE tipo_docum3	VARCHAR(12)
DEFINE sep_pun		VARCHAR(4)
DEFINE label_letras	VARCHAR(130)
DEFINE num_lin		INTEGER
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
	LET subtotal  = rm_dev.t23_tot_bruto - rm_dev.t23_tot_dscto
	LET impuesto  = rm_dev.t23_val_impto
	LET valor_pag = rm_dev.t23_tot_neto
	CALL fl_justifica_titulo('I', vg_usuario, 10) RETURNING usuario
--	print '&k2S' 		-- Letra condensada
	LET fecha_vcto = NULL
	LET valor_cred = 0
	IF rm_dev.t23_cont_cred = 'R' THEN
		SELECT SUM(t26_valor_cap), MAX(t26_fec_vcto)
			INTO valor_cred, fecha_vcto FROM talt026
			WHERE t26_compania  = rm_dev.t23_compania
			  AND t26_localidad = rm_dev.t23_localidad
			  AND t26_orden     = rm_dev.t23_orden
		IF valor_cred IS NULL THEN
			LET valor_cred = 0
		END IF
	END IF
	SELECT * INTO r_j10.* FROM cajt010
		WHERE j10_compania     = rm_dev.t23_compania
		  AND j10_localidad    = rm_dev.t23_localidad
		  AND j10_tipo_fuente  = 'OT'
		  AND j10_tipo_destino = 'FA'
		  AND j10_num_destino  = rm_dev.t23_num_factura
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
			WHEN 'TJ'
				LET valor_tarj = valor_tarj + r_j11.j11_valor
			WHEN 'RT'
				LET valor_rete = valor_rete + r_j11.j11_valor
		END CASE
	END FOREACH
	LET factura  = rm_dev.t23_num_factura
	CALL fl_lee_presupuesto_taller(vg_codcia, vg_codloc, rm_dev.t23_numpre)
		RETURNING r_t20.*
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET long        = LENGTH(modulo)
	LET tipo_docum  = "DEVOLUCION"
	LET tipo_docum2 = "DEVUELTA"
	LET tipo_docum3 = "DEVOLUCIONES"
	LET sep_pun	= ": "
	IF DATE(rm_dev.t23_fec_factura) = DATE(rm_t28.t28_fec_anula) THEN
		LET tipo_docum  = "ANULACION"
		LET tipo_docum2 = "ANULADA"
		LET tipo_docum3 = "ANULACIONES"
		LET sep_pun	= " : "
	END IF
	LET documento = "COMPROBANTE ", tipo_docum CLIPPED, " FACTURA No. ",
			rm_t28.t28_num_dev USING "<<<<<<<&"
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', documento CLIPPED, 80) RETURNING titulo
	LET titulo    = modulo, titulo
	INITIALIZE r_z21.* TO NULL
	SELECT * INTO r_z21.* FROM cxct021
		WHERE z21_compania  = vg_codcia
		  AND z21_localidad = vg_codloc
		  AND z21_cod_tran  = 'FA'
		  AND z21_num_tran  = rm_dev.t23_num_factura
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 01,  rm_cia.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 01,  titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso)
	SKIP 2 LINES
	PRINT COLUMN 01,  "FACTURA ", tipo_docum2, sep_pun, factura, " TALLER",
	      COLUMN 67,  "FECHA ", tipo_docum, " ", sep_pun,
			DATE(rm_t28.t28_fec_anula) USING "dd-mm-yyyy"
	PRINT COLUMN 01,  "CLIENTE (", rm_dev.t23_cod_cliente
					USING "&&&&&", ") : ",
					rm_dev.t23_nom_cliente[1, 100] CLIPPED
	PRINT COLUMN 01,  "CEDULA/RUC      : ", rm_dev.t23_cedruc,
	      COLUMN 67,  "No. ORDEN TRABAJO: ", rm_dev.t23_orden
						USING "<<<&&",
	      COLUMN 106, "EFECTIVO  : ", valor_efec USING "###,###,##&.##"
	PRINT COLUMN 01,  "DIRECCION       : ", rm_dev.t23_dir_cliente,
	      COLUMN 67,  "FECHA FACTURA    : ", DATE(rm_dev.t23_fec_factura) 
			 			USING "dd-mm-yyyy",
	      COLUMN 106, "CHEQUES   : ", valor_cheq USING "###,###,##&.##"
	PRINT COLUMN 01,  "TELEFONO        : ", rm_dev.t23_tel_cliente,
	      COLUMN 67,  "FECHA VENCIMIENTO: ", DATE(fecha_vcto)
			 			USING "dd-mm-yyyy",
	      COLUMN 106, "TARJETAS  : ", valor_tarj USING "###,###,##&.##"
	PRINT COLUMN 01,  "OBSER. PRESUP.  : ", r_t20.t20_observaciones,
	      COLUMN 67,  "TECNICO(ASESOR)  : ", rm_t03.t03_nombres[1,19],
	      COLUMN 106, "RETENCION : ", valor_rete USING "###,###,##&.##"
	PRINT COLUMN 67,  "NOTA CREDITO No. : ",
		r_z21.z21_num_doc USING "<<<<<<<&",
	      COLUMN 106, "CREDITO   : ", valor_cred USING "###,###,##&.##"
	SKIP 1 LINES
	PRINT COLUMN 01,  "FECHA IMPRESION : ", DATE(TODAY) USING 'dd-mm-yyyy',
		1 SPACES, TIME,
	      COLUMN 123, usuario CLIPPED
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 11,  "DESCRIPCION",
	      COLUMN 121, "VALOR TOTAL"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 1 LINES
	PRINT COLUMN 11,  "TOTAL OTROS REPUESTOS Y MATERIALES",
	      COLUMN 118, rm_dev.t23_val_mo_ext + rm_dev.t23_val_mo_cti +
			  rm_dev.t23_val_rp_tal + rm_dev.t23_val_rp_ext +
			  rm_dev.t23_val_rp_cti + rm_dev.t23_val_otros2
			USING '###,###,##&.##'
	SKIP 1 LINES
	PRINT COLUMN 11,  "TOTAL DE MANO DE OBRA",
	      COLUMN 118, rm_dev.t23_val_mo_tal		USING '###,###,##&.##'
	SELECT COUNT(*) INTO num_lin FROM talt024
		WHERE t24_compania  = vg_codcia
		  AND t24_localidad = vg_codloc
		  AND t24_orden     = rm_dev.t23_orden
	CALL fl_lee_compania_repuestos(vg_codcia) RETURNING r_r00.*
	IF num_lin <= ((r_r00.r00_numlin_fact * 2) - 5) THEN
		DECLARE q_talt024 CURSOR FOR
			SELECT * FROM talt024
				WHERE t24_compania  = vg_codcia
				  AND t24_localidad = vg_codloc
				  AND t24_orden     = rm_dev.t23_orden
				ORDER BY t24_secuencia
		FOREACH q_talt024 INTO r_t24.*
			PRINT COLUMN 13,  r_t24.t24_descripcion
		END FOREACH
	END IF
	SKIP 1 LINES
	PRINT COLUMN 11,  "TOTAL MATERIAL Y REPUESTOS ",
			rm_cia.g01_razonsocial CLIPPED,
			" (VER ", tipo_docum3 CLIPPED, " ADJUNTAS)"
	
PAGE TRAILER
	LET label_letras = fl_retorna_letras(rm_dev.t23_moneda, valor_pag)
	SKIP 2 LINES
	--PRINT COLUMN 02, "SOMOS CONTRIBUYENTES ESPECIALES, RESOLUCION No. 5368",
	PRINT COLUMN 99,  "TOTAL BRUTO",
	      COLUMN 116, rm_dev.t23_tot_bruto	USING "#,###,###,##&.##"
	PRINT COLUMN 100, "DESCUENTOS",
	      COLUMN 118, rm_dev.t23_tot_dscto	USING "###,###,##&.##"
	PRINT COLUMN 02, "AUTORIZADO POR ___________________",
	      COLUMN 45, "RECIBIDO POR ___________________",
	      COLUMN 102, "SUBTOTAL",
	      COLUMN 118, subtotal		USING "###,###,##&.##"
	PRINT COLUMN 95,  "I. V. A. (", rm_dev.t23_porc_impto USING "#&", ") %",
	      COLUMN 118, impuesto		USING "###,###,##&.##"
	PRINT COLUMN 82,  "GASTOS MOVILIZACION Y DIETAS",
	      COLUMN 118, rm_dev.t23_val_otros1	USING "###,###,##&.##"
	PRINT COLUMN 02,  "SON: ", label_letras[1,87],
	      COLUMN 97,  "VALOR A PAGAR",
	      COLUMN 116, valor_pag		USING "#,###,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT
