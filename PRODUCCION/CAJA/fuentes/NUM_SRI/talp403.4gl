--------------------------------------------------------------------------------
-- Titulo           : talp403.4gl - REPORTE DE FACTURA 
-- Elaboracion      : 01-feb-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun talp403 BD MODULO COMPANIA LOCALIDAD FACTURA
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_factura	LIKE talt023.t23_num_factura      
DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t03		RECORD LIKE talt003.*
DEFINE rm_t00		RECORD LIKE talt000.*
DEFINE rm_z01		RECORD LIKE cxct001.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE mensaje_fa_ant	VARCHAR(250)



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
CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE comando		VARCHAR(100)
DEFINE r_g06		RECORD LIKE gent006.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_t60		RECORD LIKE talt060.*
DEFINE num_sri		LIKE rept038.r38_num_sri

INITIALIZE r_g06.* TO NULL
IF rm_t23.t23_cont_cred = 'C' THEN
	LET r_g06.g06_impresora = fgl_getenv('PRINTER_CONT')
ELSE
	LET r_g06.g06_impresora = fgl_getenv('PRINTER_CRED')
END IF
-- OJO PUESTO PARA LA NOTA DE VENTA
--IF vg_codloc = 3 THEN
	CALL fl_lee_cliente_general(rm_t23.t23_cod_cliente) RETURNING r_z01.*
	IF r_z01.z01_tipo_doc_id <> 'R' THEN
		LET r_g06.g06_impresora = fgl_getenv('PRINTER_NOTA')
	END IF
--END IF
--
IF r_g06.g06_impresora IS NOT NULL THEN
	CALL fl_lee_impresora(r_g06.g06_impresora) RETURNING r_g06.*
	IF r_g06.g06_impresora IS NULL THEN
		CALL fl_control_reportes() RETURNING comando
		IF int_flag THEN
			RETURN
		END IF
	END IF
	LET comando = 'lpr -P ', r_g06.g06_impresora
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
START REPORT report_factura TO PIPE comando
OUTPUT TO REPORT report_factura()
FINISH REPORT report_factura

END FUNCTION



REPORT report_factura()
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE r_r00		RECORD LIKE rept000.*
DEFINE r_t20		RECORD LIKE talt020.*
DEFINE r_t24		RECORD LIKE talt024.*
DEFINE documento	VARCHAR(60)
DEFINE usuario		VARCHAR(10,5)
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
	LET subtotal  = rm_t23.t23_tot_bruto - rm_t23.t23_tot_dscto
	LET impuesto  = rm_t23.t23_val_impto
	LET valor_pag = rm_t23.t23_tot_neto
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
			WHEN 'TJ'
				LET valor_tarj = valor_tarj + r_j11.j11_valor
			WHEN 'RT'
				LET valor_rete = valor_rete + r_j11.j11_valor
		END CASE
	END FOREACH
	LET factura  = rm_t23.t23_num_factura
	CALL fl_lee_presupuesto_taller(vg_codcia, vg_codloc, rm_t23.t23_numpre)
		RETURNING r_t20.*
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 27,  "ALMACEN : ", rm_loc.g02_nombre,
	      COLUMN 99,  "No. FA ", factura, " TALLER"
	SKIP 2 LINES
	PRINT COLUMN 01,  "CLIENTE (", rm_t23.t23_cod_cliente
					USING "&&&&&", ") : ",
					rm_z01.z01_nomcli[1, 100] CLIPPED
	PRINT COLUMN 01,  "CEDULA/RUC      : ", rm_z01.z01_num_doc_id,
	      COLUMN 67,  "No. ORDEN TRABAJO: ", rm_t23.t23_orden
						USING "&&&&&&&",
	      COLUMN 106, "EFECTIVO  : ", valor_efec USING "###,###,##&.##"
	PRINT COLUMN 01,  "DIRECCION       : ", rm_z01.z01_direccion1,
	      COLUMN 67,  "FECHA FACTURA    : ", DATE(rm_t23.t23_fec_factura) 
			 			USING "dd-mm-yyyy",
	      COLUMN 106, "CHEQUES   : ", valor_cheq USING "###,###,##&.##"
	PRINT COLUMN 01,  "TELEFONO        : ", rm_t23.t23_tel_cliente,
	      COLUMN 67,  "FECHA VENCIMIENTO: ", DATE(fecha_vcto)
			 			USING "dd-mm-yyyy",
	      COLUMN 106, "TARJETAS  : ", valor_tarj USING "###,###,##&.##"
	PRINT COLUMN 01,  "OBSER. PRESUP.  : ", r_t20.t20_observaciones,
	      COLUMN 67,  "TECNICO(ASESOR)  : ", rm_t03.t03_nombres[1,19],
	      COLUMN 106, "RETENCION : ", valor_rete USING "###,###,##&.##"
	PRINT COLUMN 67,  "USUARIO          : ", usuario,
	      COLUMN 106, "CREDITO   : ", valor_cred USING "###,###,##&.##"
	--PRINT COLUMN 01,  "FECHA IMPRESION : ", DATE(TODAY) USING 'dd-mm-yyyy',
		--1 SPACES, TIME,
	      --COLUMN 125, UPSHIFT(vg_proceso)
	SKIP 2 LINES
	--PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 11,  "DESCRIPCION",
	      COLUMN 121, "VALOR TOTAL"
	--PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	SKIP 1 LINES

ON EVERY ROW
	NEED 1 LINES
{--
	PRINT COLUMN 11,  "TOTAL REPUESTOS Y MATERIALES DE ALMACEN",
	      COLUMN 118, rm_t23.t23_val_rp_alm		USING '###,###,##&.##'
--}
	PRINT COLUMN 11,  "TOTAL OTROS REPUESTOS Y MATERIALES",
	      COLUMN 118, rm_t23.t23_val_mo_ext + rm_t23.t23_val_mo_cti +
			  rm_t23.t23_val_rp_tal + rm_t23.t23_val_rp_ext +
			  rm_t23.t23_val_rp_cti + rm_t23.t23_val_otros2
			USING '###,###,##&.##'
	SKIP 1 LINES
	PRINT COLUMN 11,  "TOTAL DE MANO DE OBRA",
	      COLUMN 118, rm_t23.t23_val_mo_tal		USING '###,###,##&.##'
	SELECT COUNT(*) INTO num_lin FROM talt024
		WHERE t24_compania  = vg_codcia
		  AND t24_localidad = vg_codloc
		  AND t24_orden     = rm_t23.t23_orden
	CALL fl_lee_compania_repuestos(vg_codcia) RETURNING r_r00.*
	IF num_lin <= ((r_r00.r00_numlin_fact * 2) - 5) THEN
		DECLARE q_talt024 CURSOR FOR
			SELECT * FROM talt024
				WHERE t24_compania  = vg_codcia
				  AND t24_localidad = vg_codloc
				  AND t24_orden     = rm_t23.t23_orden
				ORDER BY t24_secuencia
		FOREACH q_talt024 INTO r_t24.*
			PRINT COLUMN 13,  r_t24.t24_descripcion
		END FOREACH
	END IF
	SKIP 1 LINES
	PRINT COLUMN 11,  "TOTAL MATERIAL Y REPUESTOS ",
			rm_cia.g01_razonsocial CLIPPED,
			" (VER FACTURAS ADJUNTAS)"
	
PAGE TRAILER
	--NEED 4 LINES
	LET label_letras = fl_retorna_letras(rm_t23.t23_moneda, valor_pag)
	SKIP 2 LINES
	--PRINT COLUMN 02,  "SOMOS CONTRIBUYENTES ESPECIALES D.G.R. #39",
	PRINT COLUMN 02, "SOMOS CONTRIBUYENTES ESPECIALES, RESOLUCION No. 5368",
	      COLUMN 50,  "-------------------------",
	      COLUMN 99,  "TOTAL BRUTO",
	      COLUMN 116, rm_t23.t23_tot_bruto	USING "#,###,###,##&.##"
	PRINT COLUMN 50,  " RECIBI FACTURA ORIGINAL ",
	      COLUMN 100, "DESCUENTOS",
	      COLUMN 118, rm_t23.t23_tot_dscto	USING "###,###,##&.##"
	PRINT COLUMN 006, "w w w . a c e r o c o m e r c i a l . c o m",
	      COLUMN 102, "SUBTOTAL",
	      COLUMN 118, subtotal		USING "###,###,##&.##"
	IF mensaje_fa_ant IS NOT NULL THEN
		PRINT COLUMN 006, mensaje_fa_ant CLIPPED;
	END IF
	PRINT COLUMN 95,  "I. V. A. (", rm_t23.t23_porc_impto USING "#&", ") %",
	      COLUMN 118, impuesto		USING "###,###,##&.##"
	PRINT COLUMN 82,  "GASTOS MOVILIZACION Y DIETAS",
	      COLUMN 118, rm_t23.t23_val_otros1	USING "###,###,##&.##"
	PRINT COLUMN 02,  "SON: ", label_letras[1,87],
	      COLUMN 97,  "VALOR A PAGAR",
	      COLUMN 116, valor_pag		USING "#,###,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT
