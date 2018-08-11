------------------------------------------------------------------------------
-- Titulo           : cxpp407.4gl - Listado de Estado de cuenta de proveedores
-- Elaboracion      : 11-mar-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxpp407 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE codprov		INTEGER
DEFINE moneda 		CHAR(2)
DEFINE tipo 		CHAR(1)
DEFINE tit_mon 		CHAR(15)
DEFINE nomprov		CHAR(60)
DEFINE tot_favor        DECIMAL(14,2)
DEFINE tot_xven         DECIMAL(14,2)
DEFINE tot_vcdo         DECIMAL(14,2)
DEFINE tot_saldo        DECIMAL(14,2)

DEFINE r_report RECORD
	tipo_doc	LIKE cxpt020.p20_tipo_doc,
	num_doc		LIKE cxpt020.p20_num_doc,
	dividendo	LIKE cxpt020.p20_dividendo,
	fecha_emi	LIKE cxpt020.p20_fecha_emi,
	fecha_vcto	LIKE cxpt020.p20_fecha_vcto,
	fecha_pago	LIKE cxpt020.p20_fecha_vcto,
	val_ori		LIKE cxpt020.p20_valor_cap,
	saldo		LIKE cxpt020.p20_saldo_cap
	END RECORD


MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxpp407'
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
	OPEN FORM f_rep FROM "../forms/cxpf407_1"
ELSE
	OPEN FORM f_rep FROM "../forms/cxpf407_1c"
END IF
DISPLAY FORM f_rep

CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		CHAR(1000)
DEFINE comando		VARCHAR(100)
DEFINE data_found	SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*

INITIALIZE codprov TO NULL

CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING r_g13.*

LET tipo = 'R'
LET moneda = r_g13.g13_moneda
LET tit_mon = r_g13.g13_nombre
DISPLAY BY NAME tit_mon
IF vg_gui = 0 THEN
	CALL muestra_tipo(tipo)
END IF
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF

	LET query = "SELECT cxpt020.p20_tipo_doc, " ||
			" cxpt020.p20_num_doc, cxpt020.p20_dividendo, " ||
			" cxpt020.p20_fecha_emi, " ||
			" cxpt020.p20_fecha_vcto, cxpt020.p20_fecha_vcto, " ||
			" cxpt020.p20_valor_cap, cxpt020.p20_saldo_cap " ||
			" FROM cxpt020 " ||
			" WHERE p20_compania = " || vg_codcia ||
			" AND p20_localidad = " || vg_codloc || 
			" AND p20_codprov = " || codprov ||
			" AND p20_moneda = '", moneda ,"'"  

	IF tipo = 'R' THEN
		LET query = query CLIPPED || " AND p20_saldo_cap > 0 " 
	END IF

      SELECT  SUM(p30_saldo_favor), SUM(p30_saldo_xvenc), SUM(p30_saldo_venc)
                INTO tot_favor, tot_xven, tot_vcdo
                FROM cxpt030
                WHERE p30_compania  = vg_codcia AND
                      p30_localidad = vg_codloc AND
                      p30_codprov    = codprov AND
                      p30_moneda    = moneda
	
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

	START REPORT report_estado_cta_prov TO PIPE comando
	FOREACH	q_deto INTO r_report.*
		LET data_found = 1
		OUTPUT TO REPORT report_estado_cta_prov(r_report.*)
	END FOREACH
	FINISH REPORT report_estado_cta_prov

	IF NOT data_found THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE codprov_2	INTEGER
DEFINE r_p01		RECORD LIKE cxpt001.*

LET INT_FLAG   = 0
INPUT BY NAME codprov, moneda, tipo
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET INT_FLAG = 1 
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
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
		IF INFIELD(codprov) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia, vg_codloc)
				RETURNING r_p01.p01_codprov, 
					  r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET codprov = r_p01.p01_codprov
				LET nomprov = r_p01.p01_nomprov
				DISPLAY BY NAME codprov
				DISPLAY BY NAME nomprov
			END IF
		END IF 

	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD moneda
		IF moneda IS NOT NULL THEN
			CALL fl_lee_moneda(moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				CLEAR tit_mon
				NEXT FIELD moneda
			END IF
			LET tit_mon = r_g13.g13_nombre
			DISPLAY BY NAME tit_mon
		ELSE
			CLEAR tit_mon
		END IF

	AFTER FIELD codprov
		IF codprov IS NOT NULL THEN
			CALL fl_lee_proveedor(codprov)
				RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe el proveedor en la Companía.','exclamation')
				CALL fl_mostrar_mensaje('No existe el proveedor en la Companía.','exclamation')
				CLEAR nomprov
				NEXT FIELD codprov 
			END IF
			LET nomprov = r_p01.p01_nomprov
			DISPLAY BY NAME nomprov
		ELSE
			CLEAR nomprov
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
		IF codprov IS NULL THEN
			NEXT FIELD codprov
		END IF
		IF moneda IS NULL THEN
			NEXT FIELD moneda
		END IF

END INPUT

END FUNCTION



REPORT report_estado_cta_prov(tipo_doc, num_doc, dividendo,
				 fecha_emi, fecha_vcto, fecha_pago, 
				 val_ori, saldo)
DEFINE expr_sql 	CHAR(600)
DEFINE tipo_doc		LIKE cxpt020.p20_tipo_doc
DEFINE num_doc		LIKE cxpt020.p20_num_doc
DEFINE dividendo	LIKE cxpt020.p20_dividendo
DEFINE fecha_emi	LIKE cxpt020.p20_fecha_emi
DEFINE fecha_vcto	LIKE cxpt020.p20_fecha_vcto
DEFINE fecha_pago	LIKE cxpt020.p20_fecha_vcto
DEFINE val_ori		LIKE cxpt020.p20_saldo_cap
DEFINE saldo		LIKE cxpt020.p20_saldo_cap
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE num_trn 		LIKE cxpt022.p22_num_trn
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

	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET modulo  = "Módulo: Tesoreria"
	LET long    = LENGTH(modulo)
	--LET usuario = 'Usuario : ', vg_usuario
	--CALL fl_justifica_titulo('D', usuario, 20) RETURNING usuario
	CALL fl_justifica_titulo('C', 'ESTADO DE CUENTAS DE PROVEEDORES', 52)
		RETURNING titulo
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 1, rm_g01.g01_razonsocial

	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 30, fl_justifica_titulo('I', titulo CLIPPED, 60) CLIPPED,
	      COLUMN 86, UPSHIFT(vg_proceso)
--	print '&k2S'	                -- Letra condensada (16 cpi)

	SKIP 1 LINES

	PRINT COLUMN 01, "Fecha de Impresión: ", vg_fecha USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 74, "Usuario: ", fl_justifica_titulo('D', vg_usuario, 10) 

	PRINT COLUMN 74, "Página : ", fl_justifica_titulo('D',
						PAGENO USING "&&&",10)

	SKIP 1 LINES

	PRINT COLUMN 03,"** Cod. Proveedor : ", 
			fl_justifica_titulo('I', codprov, 38),
	      COLUMN 61,"Total Favor   : ",
		fl_justifica_titulo('D',tot_favor,16) USING "#,###,###,##&.##"  
		

	PRINT COLUMN 03,"** Nombre         : ",fl_justifica_titulo('I',nomprov,30),
	      COLUMN 61,"Total x Vencer: ",
		fl_justifica_titulo('D',tot_xven,16) USING "#,###,###,##&.##"  

	PRINT COLUMN 03,"** Moneda         : ",tit_mon,
	      COLUMN 61,"Total Vencido : ",
		fl_justifica_titulo('D',tot_vcdo,16) USING "#,###,###,##&.##"  

	IF tipo = 'D' THEN
		PRINT COLUMN 03, '** Listado Detallado';
	ELSE
		PRINT COLUMN 03, '** Listado Resumido';
	END IF
	PRINT COLUMN 61,"Saldo         : ",
		fl_justifica_titulo('D',tot_saldo,16) USING "#,###,###,##&.##"  
	
	SKIP 1 LINES
	
--	print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 1,  "=======================",
	      COLUMN 24,  "============",
	      COLUMN 36,  "=============",
	      COLUMN 48,  "=============",
	      COLUMN 60,  "================",
	      COLUMN 76,  "================"
	
	PRINT COLUMN 1,  "Documento",
	      COLUMN 24,  "Fecha Emi.",
	      COLUMN 36,  "Fecha Vct.",
	      COLUMN 48,  "Fecha Pago",
	      COLUMN 60,  fl_justifica_titulo('D', "Val. Ori.", 16),
	      COLUMN 76,  fl_justifica_titulo('D', "Saldo", 16)

	PRINT COLUMN 1,  "=======================",
	      COLUMN 24,  "============",
	      COLUMN 36,  "=============",
	      COLUMN 48,  "=============",
	      COLUMN 60,  "================",
	      COLUMN 76,  "================"

ON EVERY ROW
	--IF tipo = 'R' THEN
		LET fecha_pago = '  '
	--END IF

	PRINT COLUMN 1,  tipo_doc, '-', 
	      		  fl_justifica_titulo('I', num_doc, 16) CLIPPED, '-', 
	      		  fl_justifica_titulo('I', dividendo,3 ) USING "&&&",
	      COLUMN 24,  fecha_emi USING "dd-mm-yyyy",
	      COLUMN 36,  fecha_vcto USING "dd-mm-yyyy",
	      COLUMN 48,  fecha_pago USING "dd-mm-yyyy",
	      COLUMN 60,  val_ori USING "#,###,###,##&.##",
	      COLUMN 76,  saldo USING "#,###,###,##&.##"

	IF tipo = 'D' THEN
		LET expr_sql = "SELECT p23_tipo_trn, p23_num_trn, " ||
				" p23_div_doc, p22_fecha_emi, p22_fecing, " ||
				" p23_valor_cap " ||
				" FROM cxpt023, cxpt022 " ||
				" WHERE p23_compania  = " || vg_codcia ||
				"   AND p23_localidad = " || vg_codloc ||
				"   AND p23_codprov    = " || codprov    ||
				"   AND p23_tipo_doc  = '", tipo_doc ,"'" ||
				"   AND p23_num_doc   = '", num_doc ,"'" ||
				"   AND p23_compania  = p22_compania " ||
				"   AND p23_localidad = p22_localidad " ||
				"   AND p23_codprov    = p22_codprov " ||
				"   AND p23_tipo_trn  = p22_tipo_trn " ||
				"   AND p23_num_trn   = p22_num_trn" 	

		--DISPLAY expr_sql
		--sleep 2

		PREPARE det FROM expr_sql
		DECLARE q_det CURSOR FOR det 
		FOREACH	q_det INTO tipo_doc, num_trn, 
			           dividendo, fecha_emi,
				   fecha_pago, val_ori 
	      		PRINT COLUMN 1,  tipo_doc, '-', 
	      		      fl_justifica_titulo('I',num_trn,16) CLIPPED,      
	      			COLUMN 24,  fecha_emi USING "dd-mm-yyyy",
	      			COLUMN 48,  fecha_pago USING "dd-mm-yyyy",
	      			COLUMN 60,  val_ori USING "#,###,###,##&.##"
		END FOREACH
	END IF

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 78, "----------------"
	PRINT COLUMN 78, fl_justifica_titulo ('D',
			 SUM(saldo) USING "#,###,###,##&.##",16) CLIPPED;
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



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
DEFINE tipo		CHAR(1)

CASE tipo
	WHEN 'R'
		DISPLAY 'RESUMIDO' TO tit_tipo
	WHEN 'D'
		DISPLAY 'DETALLADO' TO tit_tipo
	OTHERWISE
		CLEAR tipo, tit_tipo
END CASE

END FUNCTION
