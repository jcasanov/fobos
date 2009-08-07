------------------------------------------------------------------------------
-- Titulo           : cxcp409.4gl - Listado de Estado de cuenta de clientes
-- Elaboracion      : 06-mar-2002
-- Autor            : GVA
-- Formato Ejecucion: fglrun cxcp409 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

DEFINE rm_g01		RECORD LIKE gent001.*

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN

DEFINE codcli 		INTEGER
DEFINE moneda 		CHAR(2)
DEFINE areaneg		LIKE gent003.g03_areaneg
DEFINE d_areaneg	LIKE gent003.g03_nombre
DEFINE tipo 		CHAR(1)
DEFINE tit_mon 		CHAR(15)
DEFINE nomcli 		CHAR(60)

DEFINE tot_favor        DECIMAL(14,2)
DEFINE tot_xven         DECIMAL(14,2)
DEFINE tot_vcdo         DECIMAL(14,2)
DEFINE tot_saldo        DECIMAL(14,2)

DEFINE r_report RECORD
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


MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 
		'Número de parámetros incorrecto', 
		'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxcp409'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE i		SMALLINT

CALL fl_nivel_isolation()

LET vm_top    = 1
LET vm_left   =	2
LET vm_right  =	132
LET vm_bottom =	2
LET vm_page   = 66

OPEN WINDOW w_mas AT 3,2 WITH 11 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE 0, 
		BORDER, MESSAGE LINE LAST - 2)

OPTIONS INPUT WRAP,
	ACCEPT KEY	F12

OPEN FORM f_rep FROM "../forms/cxcf409_1"
DISPLAY FORM f_rep

CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		VARCHAR(1000)
DEFINE comando		VARCHAR(100)
DEFINE data_found	SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*

DEFINE expr_areaneg	VARCHAR(100)

INITIALIZE codcli TO NULL

CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING r_g13.*

LET tipo = 'R'
LET moneda = r_g13.g13_moneda
LET tit_mon = r_g13.g13_nombre
DISPLAY BY NAME tit_mon
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF

	LET expr_areaneg = ' '
	IF areaneg IS NOT NULL THEN
		LET expr_areaneg = ' AND z20_areaneg = ' || areaneg 
	END IF

	LET query = "SELECT gent003.g03_nombre, cxct020.z20_tipo_doc, " ||
			" cxct020.z20_num_doc, cxct020.z20_dividendo, " ||
			" cxct020.z20_fecha_emi, " ||
			" cxct020.z20_fecha_vcto, cxct020.z20_fecha_vcto, " ||
			" cxct020.z20_valor_cap, cxct020.z20_saldo_cap " ||
			" FROM cxct020, gent003 " ||
			" WHERE z20_compania = " || vg_codcia ||
			" AND z20_localidad = " || vg_codloc || 
			" AND z20_codcli = " || codcli ||
			" AND z20_moneda = '", moneda ,"'" || 
			expr_areaneg CLIPPED ||
			" AND z20_compania = g03_compania " ||
			" AND z20_areaneg = g03_areaneg "

	IF tipo = 'R' THEN
		LET query = query || " AND z20_saldo_cap > 0 " 
	END IF

      SELECT  SUM(z30_saldo_favor), SUM(z30_saldo_xvenc), SUM(z30_saldo_venc)
                INTO tot_favor, tot_xven, tot_vcdo
                FROM cxct030
                WHERE z30_compania  = vg_codcia AND
                      z30_localidad = vg_codloc AND
                      z30_codcli    = codcli AND
                      z30_moneda    = moneda
	
	 IF tot_favor IS NULL THEN
                LET tot_favor = 0
                LET tot_xven  = 0
                LET tot_vcdo  = 0
                LET tot_saldo = 0
        END IF
        LET tot_saldo = tot_xven + tot_vcdo

	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET data_found = 0

	START REPORT report_estado_cta_cliente TO PIPE comando
	FOREACH	q_deto INTO r_report.*
		LET data_found = 1
		OUTPUT TO REPORT report_estado_cta_cliente(r_report.*)
	END FOREACH
	FINISH REPORT report_estado_cta_cliente

	IF NOT data_found THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE codcli_2		INTEGER
DEFINE r_cli		RECORD LIKE cxct001.*

INITIALIZE areaneg, d_areaneg TO NULL

LET INT_FLAG   = 0
INPUT BY NAME codcli, areaneg, d_areaneg, moneda, tipo WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(codcli, areaneg, d_areaneg, moneda, tipo) 
		THEN
			EXIT PROGRAM
		END IF
		LET INT_FLAG = 1 
		RETURN
	ON KEY(F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda, 
					  		  r_g13.g13_nombre,
					  		  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET moneda = r_g13.g13_moneda
				LET tit_mon = r_g13.g13_nombre
				DISPLAY BY NAME tit_mon
			END IF
		END IF
		IF INFIELD(codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING r_cli.z01_codcli, 
					  r_cli.z01_nomcli
			IF r_cli.z01_codcli IS NOT NULL THEN
				LET codcli = r_cli.z01_codcli
				LET nomcli = r_cli.z01_nomcli
				DISPLAY BY NAME codcli
				DISPLAY BY NAME nomcli
			END IF
		END IF 
		IF INFIELD(areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia) 
					RETURNING r_g03.g03_areaneg,
					  	  r_g03.g03_nombre
			IF r_g03.g03_areaneg IS NOT NULL THEN
				LET areaneg   = r_g03.g03_areaneg
				LET d_areaneg = r_g03.g03_nombre
				DISPLAY BY NAME areaneg, d_areaneg
			END IF 
		END IF

	AFTER FIELD moneda
		IF moneda IS NOT NULL THEN
			CALL fl_lee_moneda(moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Moneda no existe.', 
					'exclamation')
				CLEAR tit_mon
				NEXT FIELD moneda
			END IF
			LET tit_mon = r_g13.g13_nombre
			DISPLAY BY NAME tit_mon
		ELSE
			CLEAR tit_mon
		END IF

	AFTER FIELD codcli
		IF codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(codcli)
				RETURNING r_cli.*
			IF r_cli.z01_codcli IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el cliente en la Companía.','exclamation')
				CLEAR nomcli
				NEXT FIELD codcli 
			END IF
			LET nomcli = r_cli.z01_nomcli
			DISPLAY BY NAME nomcli
		ELSE
			CLEAR nomcli
		END IF
	AFTER FIELD areaneg
		IF areaneg IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, areaneg) 
				RETURNING r_g03.*
			IF r_g03.g03_areaneg IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Area de negocio no existe.', 
					'exclamation')
				NEXT FIELD areaneg
			END IF
			LET d_areaneg = r_g03.g03_nombre
			DISPLAY BY NAME d_areaneg
		ELSE
			LET d_areaneg = NULL
			CLEAR d_areaneg
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



REPORT report_estado_cta_cliente(areaneg, tipo_doc, num_doc, dividendo,
				 fecha_emi, fecha_vcto, fecha_pago, 
				 val_ori, saldo)
DEFINE expr_sql 	VARCHAR(600)

DEFINE areaneg		LIKE gent003.g03_nombre
DEFINE tipo_doc		LIKE cxct020.z20_tipo_doc
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE dividendo	LIKE cxct020.z20_dividendo
DEFINE fecha_emi	LIKE cxct020.z20_fecha_emi
DEFINE fecha_vcto	LIKE cxct020.z20_fecha_vcto
DEFINE fecha_pago	LIKE cxct020.z20_fecha_vcto
DEFINE val_ori		LIKE cxct020.z20_saldo_cap
DEFINE saldo		LIKE cxct020.z20_saldo_cap

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE num_trn 		LIKE cxct022.z22_num_trn

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page
FORMAT
PAGE HEADER

	print 'E'; print '&l26A';  -- Indica que voy a trabajar con hojas A4
	print '&k4S'	               -- Letra (12 cpi)

	LET modulo  = "Módulo: Cobranzas"
	LET long    = LENGTH(modulo)
	--LET usuario = 'Usuario : ', vg_usuario
	--CALL fl_justifica_titulo('D', usuario, 20) RETURNING usuario
	CALL fl_justifica_titulo('C', 'ESTADO DE CUENTAS DE CLIENTES', 52)
		RETURNING titulo
	PRINT COLUMN 1, rm_g01.g01_razonsocial

	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 30, fl_justifica_titulo('I', titulo CLIPPED, 60) CLIPPED,
	      COLUMN 103, UPSHIFT(vg_proceso)
	print '&k2S'	                -- Letra condensada (16 cpi)

	--SKIP 1 LINES

	PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 76, "Usuario         : ", fl_justifica_titulo('D',
						vg_usuario,16) 

	PRINT COLUMN 76, "Página          : ", fl_justifica_titulo('D',
						PAGENO USING "&&&",16)

	SKIP 1 LINES

	PRINT COLUMN 03,"** Cod. Cliente : ",fl_justifica_titulo('I',codcli,40),
	      COLUMN 76,"Total Favor     : ",
		fl_justifica_titulo('D',tot_favor,16) USING "#,###,###,##&.##"  
		

	PRINT COLUMN 03,"** Nombre       : ",fl_justifica_titulo('I',nomcli,40),
	      COLUMN 76,"Total x Vencer  : ",
		fl_justifica_titulo('D',tot_xven,16) USING "#,###,###,##&.##"  

	PRINT COLUMN 03,"** Moneda       : ",tit_mon,
	      COLUMN 76,"Total Vencido   : ",
		fl_justifica_titulo('D',tot_vcdo,16) USING "#,###,###,##&.##"  

	PRINT COLUMN 76,"Saldo           : ",
		fl_justifica_titulo('D',tot_saldo,16) USING "#,###,###,##&.##"  
	
	SKIP 1 LINES
	
--	print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 1,   "================",
	      COLUMN 17,  "=======================",
	      COLUMN 40,  "============",
	      COLUMN 52,  "=============",
	      COLUMN 65,  "=============",
	      COLUMN 78,  "================",
	      COLUMN 87,  "================"
	
	PRINT COLUMN 1,   "Area",
	      COLUMN 17,  "Documento",
	      COLUMN 40,  "Fecha Emi.",
	      COLUMN 52,  "Fecha Vcto.",
	      COLUMN 65,  "Fecha Pago",
	      COLUMN 81,  "Val. Original",
	      COLUMN 105,  "Saldo"

	PRINT COLUMN 1,   "==================",
	      COLUMN 17,  "=======================",
	      COLUMN 40,  "============",
	      COLUMN 52,  "=============",
	      COLUMN 65,  "=============",
	      COLUMN 78,  "================",
	      COLUMN 87,  "================"

ON EVERY ROW
	
	--IF tipo = 'R' THEN
		LET fecha_pago = '  '
	--END IF

	PRINT COLUMN 1,   fl_justifica_titulo('I', areaneg, 15),
	      COLUMN 19,  tipo_doc, '-', 
	      		  fl_justifica_titulo('I', num_doc, 16) CLIPPED, '-', 
	      		  fl_justifica_titulo('I', dividendo,3 ) USING "&&&",
	      COLUMN 40,  fecha_emi USING "dd-mm-yyyy",
	      COLUMN 52,  fecha_vcto USING "dd-mm-yyyy",
	      COLUMN 65,  fecha_pago USING "dd-mm-yyyy",
	      COLUMN 78,  val_ori USING "#,###,###,##&.##",
	      COLUMN 87,  saldo USING "#,###,###,##&.##"

	IF tipo = 'D' THEN
		LET expr_sql = "SELECT z23_tipo_trn, z23_num_trn, " ||
				" z23_div_doc, z22_fecha_emi, z22_fecing, " ||
				" z23_valor_cap " ||
				" FROM cxct023, cxct022 " ||
				" WHERE z23_compania  = " || vg_codcia ||
				"   AND z23_localidad = " || vg_codloc ||
				"   AND z23_codcli    = " || codcli    ||
				"   AND z23_tipo_doc  = '", tipo_doc ,"'" ||
				"   AND z23_num_doc   = '", num_doc ,"'" ||
				"   AND z23_compania  = z22_compania " ||
				"   AND z23_localidad = z22_localidad " ||
				"   AND z23_codcli    = z22_codcli " ||
				"   AND z23_tipo_trn  = z22_tipo_trn " ||
				"   AND z23_num_trn   = z22_num_trn" 	

		--display expr_sql
		--sleep 2

		PREPARE det FROM expr_sql
		DECLARE q_det CURSOR FOR det 
		FOREACH	q_det INTO tipo_doc, num_trn, 
			           dividendo, fecha_emi,
				   fecha_pago, val_ori 
	      		PRINT COLUMN 19,  tipo_doc, '-', 
	      		      fl_justifica_titulo('I',num_trn,16) CLIPPED, '-', 
	      	  	      fl_justifica_titulo('I',dividendo,3 ) USING "&&&",
	      			COLUMN 40,  fecha_emi USING "dd-mm-yyyy",
	      			COLUMN 65,  fecha_pago USING "dd-mm-yyyy",
	      			COLUMN 78,  val_ori USING "#,###,###,##&.##"
		END FOREACH
	END IF

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 94, "----------------"
	PRINT COLUMN 94, fl_justifica_titulo ('D',
			 SUM(saldo) USING "#,###,###,##&.##",16) CLIPPED, 'E' 

END REPORT



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
