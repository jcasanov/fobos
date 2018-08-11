------------------------------------------------------------------------------
-- Titulo           : cxcp409.4gl - Listado de Estado de cuenta de clientes
-- Elaboracion      : 06-mar-2002
-- Autor            : GVA
-- Formato Ejecucion: fglrun cxcp409 base módulo compañía localidad
--			[cliente] [moneda]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE codcli 		LIKE cxct001.z01_codcli
DEFINE moneda 		LIKE gent013.g13_moneda
DEFINE localidad	LIKE gent002.g02_localidad
DEFINE tit_mon 		LIKE gent013.g13_nombre
DEFINE tit_localidad	LIKE gent002.g02_nombre
DEFINE nomcli 		LIKE cxct001.z01_nomcli
DEFINE tipo 		CHAR(1)
DEFINE tot_favor        DECIMAL(14,2)
DEFINE tot_xven         DECIMAL(14,2)
DEFINE tot_vcdo         DECIMAL(14,2)
DEFINE tot_saldo        DECIMAL(14,2)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
IF arg_val(4) <> '0' THEN
	LET vg_codloc  = arg_val(4)
END IF
LET vg_proceso = 'cxcp409'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 11
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
	OPEN FORM f_rep FROM "../forms/cxcf409_1"
ELSE
	OPEN FORM f_rep FROM "../forms/cxcf409_1c"
END IF
DISPLAY FORM f_rep
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
IF rm_g01.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE r_report		RECORD
				tit_local	LIKE cxct020.z20_localidad,
				tit_loc		LIKE gent002.g02_nombre,
				areaneg 	LIKE gent003.g03_nombre,
				tipo_doc	LIKE cxct020.z20_tipo_doc,
				num_doc		LIKE cxct020.z20_num_doc,
				dividendo	LIKE cxct020.z20_dividendo,
				fecha_emi	LIKE cxct020.z20_fecha_emi,
				fecha_vcto	LIKE cxct020.z20_fecha_vcto,
				fecha_pago	LIKE cxct020.z20_fecha_vcto,
				val_ori		LIKE cxct020.z20_valor_cap,
				saldo		LIKE cxct020.z20_saldo_cap
			END RECORD
DEFINE query		CHAR(1000)
DEFINE expr_loc		VARCHAR(50)
DEFINE comando		VARCHAR(100)
DEFINE data_found	SMALLINT
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z01		RECORD LIKE cxct001.*

INITIALIZE localidad, codcli, moneda, tipo TO NULL
LET moneda = rg_gen.g00_moneda_base
IF num_args() = 6 THEN
	IF arg_val(4) <> '0' THEN
		LET localidad = vg_codloc
	END IF
	LET codcli    = arg_val(5)
	LET moneda    = arg_val(6)
	CALL fl_lee_localidad(vg_codcia, localidad) RETURNING r_g02.*
	CALL fl_lee_cliente_general(codcli) RETURNING r_z01.*
	LET nomcli    = r_z01.z01_nomcli
	DISPLAY BY NAME localidad, codcli, nomcli
	DISPLAY r_g02.g02_nombre TO tit_localidad
END IF
CALL fl_lee_moneda(moneda) RETURNING r_g13.*
LET tit_mon = r_g13.g13_nombre
DISPLAY BY NAME moneda, tit_mon
LET tipo    = 'R'
IF vg_gui = 0 THEN
	CALL muestra_tipo(tipo)
END IF
WHILE TRUE
	IF num_args() = 4 THEN
		CALL lee_parametros()
	ELSE
		CALL lee_parametros2()
	END IF
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		IF num_args() <> 4 THEN
			EXIT WHILE
		END IF
		CONTINUE WHILE
	END IF
	LET expr_loc = ' '
	IF localidad IS NOT NULL THEN
		LET expr_loc = "   AND z20_localidad = ", localidad
	END IF
	LET query = "SELECT z20_localidad, g02_nombre, g03_nombre, ",
			" z20_tipo_doc, z20_num_doc,",
			" z20_dividendo, z20_fecha_emi, z20_fecha_vcto, ",
			" z20_fecha_vcto, z20_valor_cap, z20_saldo_cap ",
			" FROM cxct020, gent003, gent002 ",
			" WHERE z20_compania  = ", vg_codcia,
			expr_loc CLIPPED,
			"   AND z20_codcli    = ", codcli,
			"   AND z20_moneda    = '", moneda, "'", 
			"   AND z20_compania  = g03_compania ",
			"   AND z20_areaneg   = g03_areaneg ",
			"   AND z20_compania  = g02_compania ",
			"   AND z20_localidad = g02_localidad "
	IF tipo = 'R' THEN
		LET query = query CLIPPED, " AND z20_saldo_cap > 0 " 
	END IF
	LET query = query CLIPPED, " ORDER BY g02_nombre, z20_fecha_emi"
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET data_found = 0
	LET expr_loc = ' '
	IF localidad IS NOT NULL THEN
		LET expr_loc = "   AND z30_localidad = ", localidad
	END IF
	LET query = 'SELECT SUM(z30_saldo_favor), SUM(z30_saldo_xvenc), ',
			' SUM(z30_saldo_venc) ',
                	' FROM cxct030 ',
                	' WHERE z30_compania  = ', vg_codcia,
			expr_loc CLIPPED,
			'   AND z30_codcli    = ', codcli,
			'   AND z30_moneda    = "', moneda, '"'
	PREPARE suma FROM query
	DECLARE q_suma CURSOR FOR suma
	OPEN q_suma
	FETCH q_suma INTO tot_favor, tot_xven, tot_vcdo
	IF STATUS = NOTFOUND THEN
                LET tot_favor = 0
                LET tot_xven  = 0
                LET tot_vcdo  = 0
                LET tot_saldo = 0
        END IF
	CLOSE q_suma
	FREE q_suma
        LET tot_saldo = (tot_xven + tot_vcdo) - tot_favor
	START REPORT report_estado_cta_cliente TO PIPE comando
	FOREACH	q_deto INTO r_report.*
		LET data_found = 1
		OUTPUT TO REPORT report_estado_cta_cliente(r_report.*)
	END FOREACH
	FINISH REPORT report_estado_cta_cliente
	IF NOT data_found THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF
	IF num_args() <> 4 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE codcli_2		LIKE cxct001.z01_codcli

LET int_flag = 0
INPUT BY NAME localidad, codcli, moneda, tipo
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1 
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET localidad = r_g02.g02_localidad
				DISPLAY BY NAME localidad
				DISPLAY r_g02.g02_nombre TO tit_localidad
			END IF
		END IF
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda, 
					  		  r_g13.g13_nombre,
					  		  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET moneda = r_g13.g13_moneda
				LET tit_mon = r_g13.g13_nombre
				DISPLAY BY NAME moneda, tit_mon
			END IF
		END IF
		IF INFIELD(codcli) THEN
			IF localidad IS NULL THEN
				CALL fl_ayuda_cliente_general()
					RETURNING r_z01.z01_codcli, 
						  r_z01.z01_nomcli
			ELSE
				CALL fl_ayuda_cliente_localidad(vg_codcia,
								localidad)
					RETURNING r_z01.z01_codcli, 
						  r_z01.z01_nomcli
			END IF
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET codcli = r_z01.z01_codcli
				LET nomcli = r_z01.z01_nomcli
				DISPLAY BY NAME codcli
				DISPLAY BY NAME nomcli
			END IF
		END IF 
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD localidad
		IF localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, localidad)
				RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD localidad
			END IF
			DISPLAY r_g02.g02_nombre TO tit_localidad
		ELSE
			CLEAR tit_localidad
		END IF
	AFTER FIELD moneda
		IF moneda IS NOT NULL THEN
			CALL fl_lee_moneda(moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD moneda
			END IF
			LET tit_mon = r_g13.g13_nombre
			DISPLAY BY NAME tit_mon
		ELSE
			CLEAR tit_mon
		END IF
	AFTER FIELD codcli
		IF codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(codcli) RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el cliente en la Compañía.','exclamation')
				NEXT FIELD codcli 
			END IF
			LET nomcli = r_z01.z01_nomcli
			DISPLAY BY NAME nomcli
		ELSE
			CLEAR nomcli
		END IF
	AFTER FIELD tipo
		IF vg_gui = 0 THEN
			IF tipo IS NOT NULL THEN
				CALL muestra_tipo(tipo)
			ELSE
				CLEAR tit_tipo
			END IF
		END IF
	AFTER INPUT
		IF codcli IS NULL THEN
			NEXT FIELD codcli
		END IF
		IF moneda IS NULL THEN
			NEXT FIELD moneda
		END IF
END INPUT

END FUNCTION



FUNCTION lee_parametros2()

LET int_flag = 0
INPUT BY NAME tipo WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1 
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD tipo
		IF vg_gui = 0 THEN
			IF tipo IS NOT NULL THEN
				CALL muestra_tipo(tipo)
			ELSE
				CLEAR tit_tipo
			END IF
		END IF
END INPUT

END FUNCTION



REPORT report_estado_cta_cliente(r_report)
DEFINE r_report		RECORD
				tit_local	LIKE cxct020.z20_localidad,
				tit_loc		LIKE gent002.g02_nombre,
				areaneg 	LIKE gent003.g03_nombre,
				tipo_doc	LIKE cxct020.z20_tipo_doc,
				num_doc		LIKE cxct020.z20_num_doc,
				dividendo	LIKE cxct020.z20_dividendo,
				fecha_emi	LIKE cxct020.z20_fecha_emi,
				fecha_vcto	LIKE cxct020.z20_fecha_vcto,
				fecha_pago	LIKE cxct020.z20_fecha_vcto,
				val_ori		LIKE cxct020.z20_valor_cap,
				saldo		LIKE cxct020.z20_saldo_cap
			END RECORD
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE num_trn 		VARCHAR(15)
DEFINE num_nc 		VARCHAR(10)
DEFINE expr_sql 	CHAR(1200)
DEFINE expr_loc		VARCHAR(50)
DEFINE expr_doc		VARCHAR(100)
DEFINE total		DECIMAL(14,2)
DEFINE entro		SMALLINT
DEFINE cont		INTEGER
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	0
	RIGHT  MARGIN	132
	BOTTOM MARGIN	4
	PAGE   LENGTH	66

FORMAT

PAGE HEADER
	--print 'E'; --print '&l26A';  -- Indica que voy a trabajar con hojas A4
	--print '&k4S'	               -- Letra (12 cpi)
	LET modulo      = "MODULO: COBRANZAS"
	LET long        = LENGTH(modulo)
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET usuario     = 'USUARIO : ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'ESTADO DE CUENTAS DE CLIENTES', 80)
		RETURNING titulo
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rm_g01.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 040, titulo,
	      COLUMN 126, UPSHIFT(vg_proceso)
	SKIP 2 LINES
	IF localidad IS NOT NULL THEN
		CALL fl_lee_localidad(vg_codcia, localidad) RETURNING r_g02.*
		PRINT COLUMN 001, "LOCALIDAD     : ", localidad	USING "&&",
				" ", r_g02.g02_nombre,
		      COLUMN 099, "TOTAL A FAVOR   : ", tot_favor
						USING "-,---,---,--&.##"
	ELSE
		PRINT COLUMN 001, "LOCALIDAD     : T O D A S", 
		      COLUMN 099, "TOTAL A FAVOR   : ", tot_favor
						USING "-,---,---,--&.##"
	END IF
	PRINT COLUMN 001, "CODIGO        : ", codcli	USING "&&&&&",
	      COLUMN 099, "TOTAL POR VENCER: ", tot_xven
						USING "-,---,---,--&.##"
	PRINT COLUMN 001, "NOMBRE        : ", nomcli,
	      COLUMN 099, "TOTAL VENCIDO   : ", tot_vcdo
						USING "-,---,---,--&.##"
	PRINT COLUMN 001, "MONEDA        : ", tit_mon,
	      COLUMN 099, "S A L D O       : ", tot_saldo
						USING "-,---,---,--&.##"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "LOCALIDAD",
	      COLUMN 023, "AREA",
	      COLUMN 040, "DOCUMENTO",
	      COLUMN 064, "FECHA EMI.",
	      COLUMN 076, "FECHA VCTO",
	      COLUMN 088, "FECHA PAGO",
	      COLUMN 100, "  VALOR ORIGINAL",
	      COLUMN 117, " SALDO DOCUMENTO"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	IF tipo = 'R' THEN
		LET r_report.fecha_pago = NULL
	END IF
	PRINT COLUMN 001, r_report.tit_loc,
	      COLUMN 023, r_report.areaneg,
	      COLUMN 040, r_report.tipo_doc, "-", r_report.num_doc CLIPPED, "-",
	      		  r_report.dividendo	USING "&&&",
	      COLUMN 064, r_report.fecha_emi	USING "dd-mm-yyyy",
	      COLUMN 076, r_report.fecha_vcto	USING "dd-mm-yyyy",
	      COLUMN 088, r_report.fecha_pago	USING "dd-mm-yyyy",
	      COLUMN 100, r_report.val_ori	USING "-,---,---,--&.##",
	      COLUMN 117, r_report.saldo	USING "-,---,---,--&.##"
	IF tipo = 'D' THEN
		LET expr_doc = "   AND z23_tipo_doc = '", r_report.tipo_doc,"'",
				"   AND z23_num_doc  = '", r_report.num_doc, "'"
		CALL query_mov(r_report.tit_local, expr_doc, 0)
			RETURNING expr_sql
		PREPARE det FROM expr_sql
		DECLARE q_det CURSOR FOR det 
		FOREACH	q_det INTO r_report.tipo_doc, num_trn,
				r_report.fecha_emi, r_report.fecha_pago,
				r_report.val_ori
			PRINT COLUMN 040, r_report.tipo_doc, "-",
				num_trn CLIPPED,
	      		      COLUMN 064, r_report.fecha_emi
					USING "dd-mm-yyyy",
	      		      COLUMN 088, r_report.fecha_pago
					USING "dd-mm-yyyy",
	      		      COLUMN 100, r_report.val_ori
					USING "-,---,---,--&.##"
		END FOREACH
	END IF

ON LAST ROW
	PRINT COLUMN 117, "----------------"
	PRINT COLUMN 102, "S A L D O  ==> ",
	      COLUMN 117, SUM(r_report.saldo) - tot_favor
			USING "-,---,---,--&.##"
	SELECT COUNT(*) INTO cont FROM cxct021
		WHERE z21_compania = vg_codcia
		  AND z21_codcli   = codcli
		  AND z21_tipo_doc = "NC"
		  AND z21_moneda   = moneda
	IF cont > 0 THEN
		SKIP 2 LINES
		CASE tipo
			WHEN 'R'
				PRINT COLUMN 001, "RESUMEN VALORES A FAVOR"
			WHEN 'D'
				PRINT COLUMN 001, "DETALLE VALORES A FAVOR"
		END CASE
		PRINT COLUMN 001, "-----------------------"
		SKIP 1 LINES
	END IF
	LET expr_loc = ' '
	IF localidad IS NOT NULL THEN
		LET expr_loc = "   AND z21_localidad = ", localidad
	END IF
	LET expr_sql = 'SELECT * FROM cxct021 ',
			' WHERE z21_compania  = ', vg_codcia,
			expr_loc CLIPPED,
			'   AND z21_codcli    = ', codcli,
			--'   AND z21_tipo_doc  = "NC" ',
			'   AND z21_moneda    = "', moneda, '"'
	--IF tipo = 'R' THEN
		--LET expr_sql = expr_sql CLIPPED, ' AND z21_saldo > 0 ' 
	--END IF
	LET expr_sql = expr_sql CLIPPED,' ORDER BY z21_localidad, z21_fecha_emi'
	PREPARE det_nc FROM expr_sql
	DECLARE q_nc CURSOR FOR det_nc
	LET total = 0
	LET entro = 0
	FOREACH q_nc INTO r_z21.*
		LET total  = total + r_z21.z21_saldo
		LET num_nc = r_z21.z21_num_doc
		CALL fl_lee_area_negocio(vg_codcia, r_z21.z21_areaneg)
			RETURNING r_g03.*
		PRINT COLUMN 001, r_z21.z21_referencia[1,21],
		      COLUMN 023, r_g03.g03_nombre,
		      COLUMN 040, r_z21.z21_tipo_doc, "-", num_nc,
		      COLUMN 064, r_z21.z21_fecha_emi  USING "dd-mm-yyyy",
		      COLUMN 100, r_z21.z21_valor      USING "-,---,---,--&.##",
		      COLUMN 117, r_z21.z21_saldo      USING "-,---,---,--&.##"
		IF tipo = 'D' THEN
			LET expr_doc = "   AND z23_tipo_favor = '",
						r_z21.z21_tipo_doc, "'",
					"   AND z23_doc_favor = ",
						r_z21.z21_num_doc
			CALL query_mov(r_z21.z21_localidad, expr_doc, 1)
				RETURNING expr_sql
			PREPARE det2 FROM expr_sql
			DECLARE q_det2 CURSOR FOR det2
			FOREACH	q_det2 INTO r_report.tipo_doc, num_trn,
					r_z20.z20_tipo_doc, r_z20.z20_num_doc,
					r_z20.z20_dividendo, r_report.fecha_emi,
					r_report.fecha_pago, r_report.val_ori
				PRINT COLUMN 005, "APLICADO A: ",							r_z20.z20_tipo_doc, "-",
					r_z20.z20_num_doc CLIPPED, "-",
					r_z20.z20_dividendo USING "&&&",
				      COLUMN 040, r_report.tipo_doc, "-",
					num_trn CLIPPED,
		      		      COLUMN 064, r_report.fecha_emi
						USING "dd-mm-yyyy",
	      			      COLUMN 088, r_report.fecha_pago
						USING "dd-mm-yyyy",
		      		      COLUMN 100, r_report.val_ori
						USING "#,###,###,##&.##"
			END FOREACH
		END IF
		LET entro = 1
	END FOREACH
	IF entro THEN
		PRINT COLUMN 117, "----------------"
		PRINT COLUMN 096, "S A L D O  (N/C) ==> ",
		      COLUMN 117, total		USING "-,---,---,--&.##"
	END IF
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION query_mov(loc, expr_doc, flag)
DEFINE loc		LIKE gent002.g02_localidad
DEFINE expr_doc		VARCHAR(100)
DEFINE flag		SMALLINT
DEFINE doc_deu		VARCHAR(50)
DEFINE expr_loc		VARCHAR(50)
DEFINE expr_sql 	CHAR(1200)

LET doc_deu = ' ' 
IF flag THEN
	LET doc_deu = "z23_tipo_doc, z23_num_doc, z23_div_doc, "
END IF
LET expr_loc = ' '
IF loc IS NOT NULL THEN
	LET expr_loc = "   AND z23_localidad = ", loc
END IF
LET expr_sql = "SELECT z23_tipo_trn, z23_num_trn, ", doc_deu CLIPPED,
			" z22_fecha_emi, z22_fecing, z23_valor_cap ",
			" FROM cxct023, cxct022 ",
			" WHERE z23_compania  = ", vg_codcia,
			expr_loc CLIPPED,
			"   AND z23_codcli    = ", codcli,
			expr_doc CLIPPED,
			"   AND z23_compania  = z22_compania ",
			"   AND z23_localidad = z22_localidad ",
			"   AND z23_codcli    = z22_codcli ",
			"   AND z23_tipo_trn  = z22_tipo_trn ",
			"   AND z23_num_trn   = z22_num_trn ",
			" ORDER BY 1, 2, 3, 4"
RETURN expr_sql CLIPPED

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



FUNCTION muestra_tipo(tipo)
DEFINE tipo		SMALLINT

CASE tipo
	WHEN 'R'
		DISPLAY 'RESUMIDO' TO tit_tipo
	WHEN 'D'
		DISPLAY 'DETALLADO' TO tit_tipo
	OTHERWISE
		CLEAR tipo, tit_tipo
END CASE

END FUNCTION
