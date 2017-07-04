--------------------------------------------------------------------------------
-- Titulo           : cxcp415.4gl - Comprobante Nota de Debito / Documentos
-- Elaboracion      : 28-Dic-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp415 base módulo compañía localidad
-- 			[cliente] [nota debito] [número] [dividendo]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE rm_r19		RECORD LIKE rept019.*
DEFINE rm_z20		RECORD LIKE cxct020.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp415.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 8 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base		 = arg_val(1)
LET vg_modulo		 = arg_val(2)
LET vg_codcia		 = arg_val(3)
LET vg_codloc		 = arg_val(4)
LET rm_z20.z20_codcli	 = arg_val(5)
LET rm_z20.z20_tipo_doc	 = arg_val(6)
LET rm_z20.z20_num_doc	 = arg_val(7)
LET rm_z20.z20_dividendo = arg_val(8)
LET vg_proceso 		 = 'cxcp415'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
IF rm_z20.z20_tipo_doc <> 'ND' AND rm_z20.z20_tipo_doc <> 'DO' THEN
	CALL fl_mostrar_mensaje('El documento debe ser una Nota de Debito ó un Documento (DO).','stop')
	EXIT PROGRAM
END IF
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE comando		VARCHAR(100)
DEFINE r_z01		RECORD LIKE cxct001.*

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc,rm_z20.z20_codcli,
				rm_z20.z20_tipo_doc, rm_z20.z20_num_doc,
				rm_z20.z20_dividendo)
	RETURNING rm_z20.*
CALL fl_lee_cliente_general(rm_z20.z20_codcli) RETURNING r_z01.*
IF r_z01.z01_codcli IS NULL THEN
	CALL fl_mostrar_mensaje('No existe el Cliente.','stop')
	EXIT PROGRAM
END IF 
LET rm_r19.r19_codcli = r_z01.z01_codcli
LET rm_r19.r19_cedruc = r_z01.z01_num_doc_id
LET rm_r19.r19_nomcli = r_z01.z01_nomcli
LET rm_r19.r19_dircli = r_z01.z01_direccion1
LET rm_r19.r19_telcli = r_z01.z01_telefono1
CASE rm_z20.z20_tipo_doc
	WHEN 'ND'
		START REPORT report_nota_deb TO PIPE comando
		OUTPUT TO REPORT report_nota_deb()
		FINISH REPORT report_nota_deb
	WHEN 'DO'
		START REPORT report_documentos TO PIPE comando
		OUTPUT TO REPORT report_documentos()
		FINISH REPORT report_documentos
END CASE

END FUNCTION



REPORT report_nota_deb()
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE valor_pag	DECIMAL(14,2)
DEFINE num_db		VARCHAR(10)
DEFINE label_letras	VARCHAR(100)
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
	--print 'E'; --print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&k4S'	                -- Letra (12 cpi)
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
	--LET db 	    	= "\033W1"      # Activar doble ancho.
	--LET db_c    	= "\033W0"      # Cancelar doble ancho.
	LET valor_pag = rm_z20.z20_valor_cap + rm_z20.z20_valor_int
	LET num_db    = rm_z20.z20_num_doc USING "&&&&&&&&&"
	SKIP 4 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 110, ASCII escape, ASCII act_neg,
			"No. ", rm_loc.g02_serie_cia USING "&&&", "-",
			rm_loc.g02_serie_loc USING "&&&", "-",
			num_db, ASCII escape, ASCII des_neg
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 106, "FECHA EMI. N/D : ", rm_z20.z20_fecha_emi
			 			USING "dd-mm-yyyy"
	PRINT COLUMN 27,  "ALMACEN : ", rm_loc.g02_nombre
	SKIP 1 LINES
	PRINT COLUMN 06,  "CLIENTE (", rm_r19.r19_codcli USING "&&&&&", ") : ",
					rm_r19.r19_nomcli[1, 100] CLIPPED
	PRINT COLUMN 06,  "CEDULA/RUC      : ", rm_r19.r19_cedruc
	PRINT COLUMN 06,  "DIRECCION       : ", rm_r19.r19_dircli
	PRINT COLUMN 06,  "TELEFONO        : ", rm_r19.r19_telcli
	PRINT COLUMN 06,  "OBSERVACION     : ", rm_z20.z20_referencia

	SKIP 2 LINES
	--print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 14,  "DESCRIPCION",
	      COLUMN 121, " VALOR TOTAL"
	SKIP 2 LINES

ON EVERY ROW
	--OJO
	NEED 5 LINES
	PRINT COLUMN 002, ASCII escape, ASCII act_12cpi, ASCII escape,
			ASCII act_dob1, ASCII act_dob2,
			ASCII escape, ASCII act_neg,
	      COLUMN 008, "COPIA SIN DERECHO A CREDITO TRIBUTARIO",
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_10cpi, ASCII escape, ASCII des_neg,
		ASCII escape, ASCII act_comp
	SKIP 2 LINES
	PRINT COLUMN 13,  "VALOR BRUTO DE N/D",
	      COLUMN 118, valor_pag - rm_z20.z20_val_impto
				USING '###,###,##&.##'
	IF rm_z20.z20_val_impto > 0 THEN
		PRINT COLUMN 13,  "VALOR IMPUESTO DE N/D",
		      COLUMN 118, rm_z20.z20_val_impto	USING '###,###,##&.##'
	END IF
	
PAGE TRAILER
	--NEED 4 LINES
	CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, rm_r19.r19_codcli)
		RETURNING r_z02.*
	--LET label_letras = fl_retorna_letras(rm_z20.z20_moneda, valor_pag)
	--PRINT COLUMN 06,  "SON: ", label_letras[1,90],
	PRINT COLUMN 002, "Estimado cliente: Su comprobante electronico ",
			"usted lo recibira en su cuenta de correo:"
	PRINT COLUMN 002, ASCII escape, ASCII act_neg,
			r_z02.z02_email CLIPPED, '.',
			ASCII escape, ASCII des_neg,
	      COLUMN 100, "VALOR A PAGAR",
	      COLUMN 120, valor_pag		USING "#,###,###,##&.##"
	PRINT COLUMN 002, "Tambien podra consultar y descargar sus ",
			"comprobantes electronicos a traves del portal"
	PRINT COLUMN 002, "web ",
			ASCII escape, ASCII act_neg,
			"https://innobeefactura.com.",
			ASCII escape, ASCII des_neg,
			" Sus datos para el primer acceso son Usuario: "
	PRINT COLUMN 002, ASCII escape, ASCII act_neg,
			rm_r19.r19_cedruc CLIPPED, "@innobeefactura.com",
			ASCII escape, ASCII des_neg,
			" y su Clave: ",
			ASCII escape, ASCII act_neg,
			rm_r19.r19_cedruc CLIPPED, ".",
			ASCII escape, ASCII des_neg;
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



REPORT report_documentos()
DEFINE valor_pag	DECIMAL(14,2)
DEFINE num_db		VARCHAR(10)
DEFINE label_letras	VARCHAR(100)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	3
	PAGE LENGTH	44

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET valor_pag   = rm_z20.z20_valor_cap + rm_z20.z20_valor_int
	LET num_db      = rm_z20.z20_num_doc
	SKIP 4 LINES
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 117, "No. ", num_db
	PRINT COLUMN 104, "FECHA EMI. DOC.: ", rm_z20.z20_fecha_emi
			 			USING "dd-mm-yyyy"
	PRINT COLUMN 27,  "ALMACEN : ", rm_loc.g02_nombre
	SKIP 1 LINES
	PRINT COLUMN 06,  "CLIENTE (", rm_r19.r19_codcli USING "&&&&&", ") : ",
					rm_r19.r19_nomcli[1, 100] CLIPPED
	PRINT COLUMN 06,  "CEDULA/RUC      : ", rm_r19.r19_cedruc
	PRINT COLUMN 06,  "DIRECCION       : ", rm_r19.r19_dircli
	PRINT COLUMN 06,  "TELEFONO        : ", rm_r19.r19_telcli
	PRINT COLUMN 06,  "OBSERVACION     : ", rm_z20.z20_referencia

	SKIP 2 LINES
	PRINT COLUMN 14,  "DESCRIPCION",
	      COLUMN 121, " VALOR TOTAL"
	SKIP 2 LINES

ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 13,  "VALOR BRUTO DEL DOC.",
	      COLUMN 118, valor_pag - rm_z20.z20_val_impto
				USING '###,###,##&.##'
	IF rm_z20.z20_val_impto > 0 THEN
		PRINT COLUMN 13,  "VALOR IMPUESTO DEL DOC.",
		      COLUMN 118, rm_z20.z20_val_impto	USING '###,###,##&.##'
	END IF
	
PAGE TRAILER
	LET label_letras = fl_retorna_letras(rm_z20.z20_moneda, valor_pag)
	PRINT COLUMN 06,  "SON: ", label_letras[1,90],
	      COLUMN 96,  "VALOR A PAGAR",
	      COLUMN 116, valor_pag		USING "#,###,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT
