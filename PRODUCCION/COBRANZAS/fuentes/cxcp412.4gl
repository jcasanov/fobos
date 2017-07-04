--------------------------------------------------------------------------------
-- Titulo           : cxcp412.4gl - Listado de Documentos Deudores 
-- Elaboración      : 22-Mar-2002
-- Autor            : RRM
-- Formato Ejecución: fglrun cxcp412 base modulo compañía localidad
-- Ultima Correción : 09-JUL-2002
-- Motivo Corrección: CORRECCIONES VARIAS (RCA) 

--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE d_documento      VARCHAR(20)
DEFINE d_area 		VARCHAR(20)
DEFINE d_cliente	VARCHAR(20)
DEFINE rm_par		RECORD
				localidad	LIKE gent002.g02_localidad,
				tit_localidad	LIKE gent002.g02_nombre,
				moneda		CHAR(2),
				documento	CHAR(2),
				area		SMALLINT,
				cliente		SMALLINT,
				inicial		DATE,
				final		DATE,
				saldo 		CHAR(1),
				origen_doc	CHAR(1)
			END RECORD
DEFINE rm_consulta	RECORD 
				localidad	LIKE cxct020.z20_localidad,
				fecha_doc	LIKE cxct020.z20_fecha_emi,
				cliente		LIKE cxct001.z01_nomcli,
				origen		LIKE cxct020.z20_origen,
				area		LIKE gent003.g03_abreviacion,
				tipo_documento	LIKE cxct020.z20_tipo_doc,
				num_documento	LIKE cxct020.z20_num_doc,
				sec_documento	LIKE cxct020.z20_dividendo,
				num_sri		LIKE cxct020.z20_num_sri,
				valor_capital	LIKE cxct020.z20_valor_cap,
				valor_interes	LIKE cxct020.z20_valor_int,
				saldo_capital 	LIKE cxct020.z20_saldo_cap,
				saldo_interes	LIKE cxct020.z20_saldo_int
			END RECORD



MAIN

DEFER QUIT
DEFER INTERRUPT
CALL startlog('../logs/cxcp412.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp412'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE query 		CHAR(1200)
DEFINE comando          VARCHAR(100)
DEFINE s_documento	VARCHAR(50)
DEFINE s_area		VARCHAR(50)
DEFINE s_cliente	VARCHAR(50)
DEFINE s_saldo		VARCHAR(50)
DEFINE s_origen_doc	VARCHAR(50)
DEFINE expr_loc		VARCHAR(50)
DEFINE base_suc		VARCHAR(10)
DEFINE r_rep		RECORD
				cod_tran	LIKE cxct020.z20_cod_tran,
				num_tran	LIKE cxct020.z20_num_tran,
				areaneg		LIKE cxct020.z20_areaneg
			END RECORD
DEFINE tipo_fuente	LIKE rept038.r38_tipo_fuente
DEFINE r_r38		RECORD LIKE rept038.*
DEFINE r_moneda		RECORD LIKE gent013.*
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 16
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW wf AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM frm_listado FROM '../forms/cxcf412_1'
ELSE
	OPEN FORM frm_listado FROM '../forms/cxcf412_1c'
END IF
DISPLAY FORM frm_listado
INITIALIZE rm_par.* TO NULL 
LET rm_par.moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_moneda.* 
DISPLAY r_moneda.g13_nombre TO desc_moneda
LET rm_par.inicial    = TODAY
LET rm_par.final      = TODAY
LET rm_par.saldo      = 'S'
LET rm_par.origen_doc = 'M'
WHILE (TRUE)
	CALL control_ingreso()
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	LET s_documento  = ' 1 = 1'
	LET s_area       = ' 1 = 1'
	LET s_cliente    = ' 1 = 1'
	LET s_saldo      = ' 1 = 1'
	LET s_origen_doc = ' 1 = 1'
	LET expr_loc     = ' 1 = 1'
	IF rm_par.documento IS NOT NULL THEN
		LET s_documento = ' z20_tipo_doc = "' || rm_par.documento || '"'
	END IF
	IF rm_par.area IS NOT NULL THEN
		LET s_area = ' z20_areaneg = ' || rm_par.area  
	END IF
	IF rm_par.cliente IS NOT NULL THEN
		LET s_cliente = ' z20_codcli = ' || rm_par.cliente  
	END IF
	IF rm_par.saldo IS NOT NULL THEN
		IF rm_par.saldo = 'S' THEN
		     LET s_saldo = ' z20_saldo_cap + z20_saldo_int > 0'
		ELSE
		     LET s_saldo = ' 1 = 1 '
		END IF
	ELSE
		LET s_saldo = ' z20_saldo > 0 '	
	END IF
        IF rm_par.origen_doc IS NOT NULL THEN
                IF rm_par.origen_doc = 'M' THEN
                        LET s_origen_doc = " z20_origen = 'M'"
                END IF
                IF rm_par.origen_doc = 'A' THEN
                        LET s_origen_doc = " z20_origen = 'A'"
                END IF
                IF rm_par.origen_doc = 'T' THEN
                        LET s_origen_doc = " 1 = 1 "
                END IF
        END IF
	IF rm_par.localidad IS NOT NULL THEN
		LET expr_loc = ' z20_localidad = ', rm_par.localidad  
	END IF
	LET query = 'SELECT z20_localidad, z20_fecha_emi, z01_nomcli, ' || 
		' z20_origen, g03_abreviacion, z20_tipo_doc,' ||
		' z20_num_doc, z20_dividendo, z20_num_sri, ' ||
		' z20_valor_cap, z20_valor_int,' ||
		' z20_saldo_cap, z20_saldo_int, ' ||
		' z20_cod_tran, z20_num_tran, z20_areaneg ' ||
		' FROM cxct020, cxct001, gent003' || 
		' WHERE z20_compania = ' || vg_codcia || 
		--' AND z20_localidad = '  || vg_codloc || 
		' AND ', expr_loc CLIPPED,
		' AND z20_moneda = "' || rm_par.moneda ||
		'" AND z20_fecha_emi BETWEEN "' || rm_par.inicial ||
		'" AND "' || rm_par.final || '"' ||
		' AND ' || s_documento || 
		' AND ' || s_area ||
	        ' AND ' || s_cliente ||
		' AND ' || s_saldo ||
		' AND ' || s_origen_doc ||
		' AND z01_codcli = z20_codcli' ||
		' AND g03_compania = z20_compania' ||
		' AND g03_areaneg = z20_areaneg' ||
		' ORDER BY 2, 7'
	PREPARE expresion FROM query
	DECLARE q_rep CURSOR FOR expresion
	OPEN q_rep
	FETCH q_rep INTO rm_consulta.*, r_rep.*
	IF STATUS = NOTFOUND THEN
		CLOSE q_rep
		FREE q_rep
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	START REPORT reporte_documento_deudor TO PIPE comando
	FOREACH q_rep INTO rm_consulta.*, r_rep.*
		IF rm_consulta.tipo_documento = 'FA' THEN
			LET tipo_fuente = NULL
			LET base_suc    = NULL
			IF r_rep.areaneg = 1 THEN
				LET tipo_fuente = 'PR'
			END IF
			IF r_rep.areaneg = 2 THEN
				LET tipo_fuente = 'OT'
			END IF
			IF rm_consulta.localidad = 2 THEN
				LET base_suc = 'acero_gc:'
			END IF
			IF rm_consulta.localidad = 4 THEN
				LET base_suc = 'acero_qs:'
			END IF
			INITIALIZE r_r38.* TO NULL
			IF r_rep.cod_tran IS NOT NULL THEN
			LET query = 'SELECT * FROM ',base_suc CLIPPED,'rept038',
				' WHERE r38_compania    = ', vg_codcia,
				'   AND r38_localidad = ',rm_consulta.localidad,
				'   AND r38_tipo_doc   IN ("FA", "NV") ',
				'   AND r38_tipo_fuente = "', tipo_fuente, '"',
				'   AND r38_cod_tran    = "',r_rep.cod_tran,'"',
				'   AND r38_num_tran    = ', r_rep.num_tran
			PREPARE cons_r38 FROM query
			DECLARE q_r38 CURSOR FOR cons_r38
			OPEN q_r38
			FETCH q_r38 INTO r_r38.*
			CLOSE q_r38
			FREE q_r38
			END IF
			LET rm_consulta.num_sri = r_r38.r38_num_sri
		END IF
		OUTPUT TO REPORT reporte_documento_deudor(rm_consulta.*)
	END FOREACH
	FINISH REPORT reporte_documento_deudor
END WHILE

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_moneda		RECORD LIKE gent013.*
DEFINE r_cliente	RECORD LIKE cxct001.*
DEFINE r_documento 	RECORD LIKE cxct004.*
DEFINE r_area		RECORD LIKE gent003.*
DEFINE codmon		LIKE gent013.g13_moneda
DEFINE descmon		LIKE gent013.g13_nombre
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE coddoc		LIKE cxct004.z04_tipo_doc
DEFINE descdoc		LIKE cxct004.z04_nombre
DEFINE codarea		LIKE gent003.g03_areaneg
DEFINE nomarea		LIKE gent003.g03_nombre 
DEFINE decimales	LIKE gent013.g13_decimales

DISPLAY BY NAME rm_par.*
IF vg_gui = 0 THEN
	CALL muestra_flagsaldo(rm_par.saldo)
	CALL muestra_origen(rm_par.origen_doc)
END IF
LET int_flag = 0
INPUT BY NAME rm_par.localidad, rm_par.moneda, rm_par.documento, rm_par.area,
	rm_par.cliente, rm_par.inicial, rm_par.final, rm_par.saldo,
	rm_par.origen_doc
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
				LET rm_par.localidad     = r_g02.g02_localidad
				LET rm_par.tit_localidad = r_g02.g02_nombre
				DISPLAY BY NAME rm_par.localidad
				DISPLAY r_g02.g02_nombre TO tit_localidad
			END IF
			LET int_flag = 0
		END IF
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas()
					RETURNING codmon, descmon, decimales
			LET int_flag = 0
			IF codmon IS NOT NULL THEN
				LET rm_par.moneda = codmon
				DISPLAY codmon TO moneda
				DISPLAY descmon TO desc_moneda
			ELSE
				NEXT FIELD moneda
			END IF
		END IF
		IF INFIELD(documento) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('D')
				RETURNING coddoc, descdoc
			IF coddoc IS NOT NULL THEN
				LET rm_par.documento = coddoc
				DISPLAY coddoc 	TO documento
				DISPLAY descdoc	TO desc_documento
			END IF
			LET int_flag = 0
		END IF
		IF INFIELD(area) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING codarea, nomarea
			IF codarea IS NOT NULL THEN
				LET rm_par.area = codarea
				DISPLAY codarea	TO area
				DISPLAY nomarea	TO desc_area
			END IF
			LET int_flag = 0
		END IF
		IF INFIELD(cliente) THEN
			CALL fl_ayuda_cliente_general()
				RETURNING codcli, nomcli
			IF codcli IS NOT NULL THEN
				LET rm_par.cliente = codcli
				DISPLAY codcli	TO cliente
				DISPLAY nomcli	TO desc_cliente
			END IF
			LET int_flag = 0
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD localidad
		IF rm_par.localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par.localidad)
				RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD localidad
			END IF
			IF r_g02.g02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD localidad
			END IF
			LET rm_par.tit_localidad = r_g02.g02_nombre
			DISPLAY r_g02.g02_nombre TO tit_localidad
		ELSE
			LET rm_par.tit_localidad = NULL
			CLEAR tit_localidad
		END IF
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda)
				RETURNING r_moneda.*
			IF r_moneda.g13_moneda IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe moneda.','exclamation')
				CALL fl_mostrar_mensaje('No existe moneda.','exclamation')
				NEXT FIELD moneda
			ELSE
				DISPLAY r_moneda.g13_nombre TO desc_moneda
			END IF
		ELSE
                        --CALL fgl_winmessage(vg_producto,'Debe especificar la moneda.','exclamation')
			CALL fl_mostrar_mensaje('Debe especificar la moneda.','exclamation')
                        NEXT FIELD moneda
		END IF
	AFTER FIELD documento
		IF rm_par.documento IS NOT NULL THEN
			CALL fl_lee_tipo_doc(rm_par.documento)
				RETURNING r_documento.*
			IF r_documento.z04_tipo_doc IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Documento no existe.','exclamation')
				CALL fl_mostrar_mensaje('Documento no existe.','exclamation')
				NEXT FIELD documento
			ELSE
				LET d_documento = r_documento.z04_nombre
				DISPLAY r_documento.z04_nombre 	
					TO desc_documento
			END IF
		ELSE
			CLEAR desc_documento
		END IF
	AFTER FIELD area
		 IF rm_par.area IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, rm_par.area)
				RETURNING r_area.*
			IF r_area.g03_areaneg IS NULL THEN

				--CALL fgl_winmessage(vg_producto,'Area de negocio no existe.','exclamation')
				CALL fl_mostrar_mensaje('Area de negocio no existe.','exclamation')
				NEXT FIELD area
			ELSE
				LET d_area = r_area.g03_nombre
				DISPLAY r_area.g03_nombre TO desc_area 	
			END IF
		ELSE
			CLEAR desc_area
		END IF
	AFTER FIELD cliente
		IF rm_par.cliente IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par.cliente)
				RETURNING r_cliente.*
			IF r_cliente.Z01_codcli IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Cliente no existe.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
				NEXT FIELD cliente
			ELSE
				LET d_cliente = r_cliente.z01_nomcli
				DISPLAY r_cliente.z01_nomcli 
					TO desc_cliente
			END IF
		ELSE
			CLEAR desc_cliente
		END IF
        AFTER FIELD inicial
                IF rm_par.inicial IS NULL THEN
                        --CALL fgl_winmessage(vg_producto,'Debe especificar la fecha inicial.','exclamation')
			CALL fl_mostrar_mensaje('Debe especificar la fecha inicial.','exclamation')
                        NEXT FIELD inicial
                END IF
        AFTER FIELD final
                IF rm_par.final IS NULL THEN
                        --CALL fgl_winmessage(vg_producto,'Debe especificar la fecha final.','exclamation')
			CALL fl_mostrar_mensaje('Debe especificar la fecha final.','exclamation')
                        NEXT FIELD final
                END IF
	AFTER FIELD saldo
		IF vg_gui = 0 THEN
			IF rm_par.saldo IS NOT NULL THEN
				CALL muestra_flagsaldo(rm_par.saldo)
			ELSE
				CLEAR tit_saldo
			END IF
		END IF
	AFTER FIELD origen_doc
		IF vg_gui = 0 THEN
			IF rm_par.origen_doc IS NOT NULL THEN
				CALL muestra_origen(rm_par.origen_doc)
			ELSE
				CLEAR tit_origen_doc
			END IF
		END IF
        AFTER INPUT
                IF rm_par.inicial > TODAY THEN
                        --CALL fgl_winmessage(vg_producto,'La fecha inicial debe ser menor a la de hoy.','exclamation')
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor a la de hoy.','exclamation')
                        NEXT FIELD inicial
                END IF
                IF rm_par.final > TODAY THEN
                        --CALL fgl_winmessage(vg_producto,'La fecha final debe ser menor a la de hoy.','exclamation')
			CALL fl_mostrar_mensaje('La fecha final debe ser menor a la de hoy.','exclamation')
                        NEXT FIELD final
                END IF
                IF rm_par.inicial > rm_par.final THEN
                        --CALL fgl_winmessage(vg_producto,'La fecha inicial debe ser menor o igual que la fecha final.','exclamation')
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual que la fecha final.','exclamation')
                        NEXT FIELD inicial
                END IF
END INPUT

END FUNCTION



REPORT reporte_documento_deudor(localidad, fecha_doc, cliente, origen, area, 
				tipo_documento, num_documento, sec_documento,
				num_sri, valor_capital, valor_interes,
				saldo_capital, saldo_interes)
DEFINE localidad	LIKE cxct021.z21_localidad
DEFINE fecha_doc	LIKE cxct020.z20_fecha_emi
DEFINE cliente		LIKE cxct001.z01_nomcli
DEFINE origen		LIKE cxct020.z20_origen
DEFINE area	    	LIKE gent003.g03_abreviacion
DEFINE tipo_documento	LIKE cxct020.z20_tipo_doc
DEFINE num_documento	LIKE cxct020.z20_num_doc
DEFINE sec_documento	LIKE cxct020.z20_dividendo
DEFINE num_sri		LIKE cxct020.z20_num_sri
DEFINE valor_capital	LIKE cxct020.z20_valor_cap
DEFINE valor_interes	LIKE cxct020.z20_valor_int
DEFINE saldo_capital	LIKE cxct020.z20_saldo_cap
DEFINE saldo_interes	LIKE cxct020.z20_saldo_int
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo           VARCHAR(80)
DEFINE modulo           VARCHAR(40)
DEFINE i,long           SMALLINT
DEFINE descr_estado	VARCHAR(9)		
DEFINE columna		SMALLINT
DEFINE desc_saldo       CHAR(25)
DEFINE desc_origen_doc  CHAR(25)
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
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET modulo	= 'MÓDULO: COBRANZAS'
	LET long	= LENGTH(modulo)
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DE DOCUMENTOS DEUDORES', 80)
		RETURNING titulo
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
       	PRINT COLUMN 001, rg_cia.g01_razonsocial,
      	      COLUMN 122, 'PAGINA: ', PAGENO USING "&&&"
       	PRINT COLUMN 001, modulo  CLIPPED,
	      COLUMN 044, titulo,
              COLUMN 109, UPSHIFT(vg_proceso)
      	SKIP 1 LINES
	--#IF rm_par.localidad IS NOT NULL THEN
		PRINT COLUMN 020, "*** LOCALIDAD:          ",
			rm_par.localidad USING '&&', " ", rm_par.tit_localidad
	--#END IF
	PRINT COLUMN 020, '*** MONEDA:             ', rm_par.moneda
	--#IF rm_par.documento IS NOT NULL THEN
		PRINT COLUMN 020, '*** DOCUMENTO A FAVOR:  ', d_documento 
	--#END IF
	--#IF rm_par.area IS NOT NULL THEN
		PRINT COLUMN 020, '*** AREA DE NEGOCIO:    ', d_area		
	--#END IF	
	--#IF rm_par.cliente IS NOT NULL THEN
		PRINT COLUMN 020, '*** CLIENTE:            ', d_cliente
	--#END IF
	PRINT COLUMN 020, '*** FECHA INICIAL:      ', rm_par.inicial USING 'dd-mm-yyyy'
	PRINT COLUMN 020, '*** FECHA FINAL:        ', rm_par.final USING 'dd-mm-yyyy'
	IF rm_par.saldo = 'S' THEN
                LET desc_saldo = 'SALDO > 0'
        	PRINT COLUMN 020, '*** SALDO:              ' , desc_saldo
        ELSE
                LET desc_saldo = 'TODOS'
                PRINT COLUMN 020, '*** SALDO:              ' , desc_saldo
        END IF
	IF rm_par.origen_doc  = 'M' THEN
		LET desc_origen_doc = 'MANUAL'
        	PRINT COLUMN 020, '*** ORIGEN:             ' , desc_origen_doc
	ELSE
		IF rm_par.origen_doc  = 'A' THEN
			LET desc_origen_doc = 'AUTOMATICO'
	        	PRINT COLUMN 020, '*** ORIGEN:             ' , desc_origen_doc
		ELSE
			--#IF rm_par.origen_doc  = 'T' THEN
				LET desc_origen_doc = 'TODOS'
        			PRINT COLUMN 020, '*** ORIGEN:             ' , desc_origen_doc
			--#END IF
		END IF
	END IF
        SKIP 1 LINES
	PRINT COLUMN 001, 'FECHA IMPRESION: ', TODAY USING 'dd-mm-yyyy', 
			 1 SPACES, TIME,
              COLUMN 123, usuario
      	SKIP 1 LINES
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 001, 'LC',
	      COLUMN 004, 'F. DCTO.',
	      COLUMN 015, 'CLIENTE',          
	      COLUMN 029, 'O',
	      COLUMN 031, 'A.NE',
	      COLUMN 036, 'TP',     
	      COLUMN 039, 'No. DCTO.',    		
	      COLUMN 055, ' SEC.',
	      COLUMN 061, 'No. SRI',    		
	      COLUMN 078, 'VALOR CAPITAL',
	      COLUMN 092, 'VALOR INTERES',
	      COLUMN 106, 'SALDO CAPITAL',
	      COLUMN 120, 'SALDO INTERES'
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------------------------------------------'

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, localidad	USING '&&', 
	      COLUMN 004, fecha_doc	USING 'dd-mm-yyyy',
	      COLUMN 015, cliente[1, 13],
	      COLUMN 029, origen,
	      COLUMN 031, area[1, 4],
	      COLUMN 036, tipo_documento,
	      COLUMN 039, num_documento,
	      COLUMN 055, sec_documento USING '###&&',
	      COLUMN 061, num_sri,
	      COLUMN 078, valor_capital USING '##,###,##&.##',
	      COLUMN 092, valor_interes USING '##,###,##&.##',
	      COLUMN 106, saldo_capital USING '##,###,##&.##',
	      COLUMN 120, saldo_interes USING '##,###,##&.##'

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 078, '-------------',
	      COLUMN 092, '-------------',
	      COLUMN 106, '-------------',
	      COLUMN 120, '-------------'
	PRINT COLUMN 078, SUM(valor_capital) USING '##,###,##&.##',
	      COLUMN 092, SUM(valor_interes) USING '##,###,##&.##', 
	      COLUMN 106, SUM(saldo_capital) USING '##,###,##&.##', 
	      COLUMN 120, SUM(saldo_interes) USING '##,###,##&.##';
	print ASCII escape;
	print ASCII desact_comp

END REPORT



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION muestra_flagsaldo(saldo)
DEFINE saldo		CHAR(1)

CASE saldo
	WHEN 'S'
		DISPLAY 'SALDO > 0' TO tit_saldo
	WHEN 'T'
		DISPLAY 'T O D O' TO tit_saldo
	OTHERWISE
		CLEAR saldo, tit_saldo
END CASE

END FUNCTION



FUNCTION muestra_origen(origen)
DEFINE origen		CHAR(1)

CASE origen
	WHEN 'M'
		DISPLAY 'MANUAL' TO tit_origen_doc
	WHEN 'A'
		DISPLAY 'AUTOMATICO' TO tit_origen_doc
	WHEN 'T'
		DISPLAY 'T O D O S' TO tit_origen_doc
	OTHERWISE
		CLEAR origen_doc, tit_origen_doc
END CASE

END FUNCTION
