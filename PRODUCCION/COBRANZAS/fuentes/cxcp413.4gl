--------------------------------------------------------------------------------
-- Titulo           : cxcp413.4gl - Listado de Transacciones
-- Elaboración      : 18-Mar-2002
-- Autor            : RRM
-- Formato Ejecución: fglrun cxcp413 base modulo compañía localidad
-- Ultima Correción : 
-- Motivo Corrección: 
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par		RECORD
				localidad	LIKE gent002.g02_localidad,
				tit_localidad	LIKE gent002.g02_nombre,
				moneda		CHAR(2),
				transaccion	LIKE cxct023.z23_tipo_trn,
				doc_deudor	LIKE cxct020.z20_tipo_doc,
				doc_favor	LIKE cxct021.z21_tipo_doc,
				area		SMALLINT,
				cliente		LIKE cxct001.z01_codcli,
				inicial		DATE,
				final		DATE,
				origen_doc	CHAR(1)
			END RECORD
DEFINE rm_consulta	RECORD 
				fecha_doc	LIKE cxct022.z22_fecha_emi,
				cliente		LIKE cxct001.z01_nomcli,
				origen		LIKE cxct020.z20_origen,
				area		LIKE gent003.g03_abreviacion,
				tipo_transac	LIKE cxct022.z22_tipo_trn,
				numero_transac	LIKE cxct022.z22_num_trn,
				dcto_aplico	LIKE cxct023.z23_tipo_doc,
				num_dcto_aplico	LIKE cxct023.z23_num_doc,
				sec_dcto_aplico	LIKE cxct023.z23_div_doc,
				dcto_aplicado	LIKE cxct023.z23_tipo_favor,
				num_dcto_aplicado LIKE cxct023.z23_doc_favor,
				valor_capital	LIKE cxct023.z23_valor_cap,
				valor_interes	LIKE cxct023.z23_valor_int
			END RECORD
DEFINE d_transaccion    VARCHAR(20)
DEFINE d_doc_deu	VARCHAR(20)
DEFINE d_doc_fav	VARCHAR(20)
DEFINE d_area 		VARCHAR(20)
DEFINE d_cliente	VARCHAR(20)
DEFINE vm_page 		SMALLINT
DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CALL startlog('../logs/cxcp413.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp413'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE query 		CHAR(1500)
DEFINE comando          VARCHAR(100)
DEFINE estado		CHAR(1)
DEFINE s_transaccion	VARCHAR(100)
DEFINE s_documento	VARCHAR(100)
DEFINE s_doc_fav	VARCHAR(100)
DEFINE s_area		VARCHAR(100)
DEFINE s_cliente	VARCHAR(100)
DEFINE s_origen_doc	VARCHAR(100)
DEFINE expr_loc		VARCHAR(100)
DEFINE registro		CHAR(400)
DEFINE enter		SMALLINT
DEFINE resp		CHAR(6)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_nivel_isolation()
LET enter     = 13
LET vm_top    = 1
LET vm_left   = 2
LET vm_right  = 90
LET vm_bottom = 4
LET vm_page   = 66
LET lin_menu  = 0
LET row_ini   = 3
LET num_rows  = 17
LET num_cols  = 80
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
	OPEN FORM frm_listado FROM '../forms/cxcf413_1'
ELSE
	OPEN FORM frm_listado FROM '../forms/cxcf413_1c'
END IF
DISPLAY FORM frm_listado
INITIALIZE rm_par.* TO NULL 
LET rm_par.moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO desc_moneda
LET rm_par.inicial = vg_fecha
LET rm_par.final   = vg_fecha
WHILE (TRUE)
	CALL control_ingreso()
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	CALL fl_hacer_pregunta('Desea generar también un archivo de texto ?', 'No')
		RETURNING resp
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	LET s_transaccion = ' 1 = 1'
	LET s_documento   = ' 1 = 1'
	LET s_doc_fav     = ' 1 = 1'
	LET s_area        = ' 1 = 1'
	LET s_cliente     = ' 1 = 1'
	LET s_origen_doc  = ' 1 = 1'
	LET expr_loc      = ' 1 = 1'
	IF rm_par.transaccion IS NOT NULL THEN
		LET s_transaccion = ' z22_tipo_trn = "', rm_par.transaccion, '"'
	END IF
	IF rm_par.doc_deudor IS NOT NULL THEN
		LET s_documento = ' z23_tipo_doc = "', rm_par.doc_deudor, '"'
	END IF
	IF rm_par.doc_favor IS NOT NULL THEN
		LET s_doc_fav = ' z23_tipo_favor = "', rm_par.doc_favor, '"'
	END IF
	IF rm_par.area IS NOT NULL THEN
		LET s_area = ' z22_areaneg = ', rm_par.area
	END IF
	IF rm_par.cliente IS NOT NULL THEN
		LET s_cliente = ' z22_codcli = ' || rm_par.cliente  
	END IF
        IF rm_par.origen_doc IS NOT NULL THEN
                IF rm_par.origen_doc = 'M' THEN
                        LET s_origen_doc = " z22_origen = 'M'"
                END IF
                IF rm_par.origen_doc = 'A' THEN
                        LET s_origen_doc = " z22_origen = 'A'"
                END IF
        END IF
	IF rm_par.localidad IS NOT NULL THEN
		LET expr_loc = ' z22_localidad = ', rm_par.localidad  
	END IF
	LET query = 'SELECT z22_fecha_emi, z01_nomcli, ' || 
		' z22_origen, g03_abreviacion, z22_tipo_trn, z22_num_trn,' ||
		' z23_tipo_doc, z23_num_doc, z23_div_doc, ' ||
		' z23_tipo_favor, z23_doc_favor, ' ||
		' z23_valor_cap, z23_valor_int ' || 
		' FROM cxct022, cxct023, cxct001, gent003' || 
		' WHERE z22_compania = ' || vg_codcia || 
		--' AND z22_localidad = '  || vg_codloc || 
		' AND ', expr_loc CLIPPED,
		' AND z22_moneda = "' || rm_par.moneda ||
		'" AND z22_fecha_emi BETWEEN "' || rm_par.inicial ||
		'" AND "' || rm_par.final || '"' ||
		' AND ' || s_transaccion || 
		' AND ' || s_documento || 
		' AND ' || s_doc_fav || 
		' AND ' || s_area ||
	        ' AND ' || s_cliente ||
	        ' AND ' || s_origen_doc ||
		' AND z23_compania = z22_compania' ||
		' AND z23_localidad = z22_localidad' ||
		' AND z23_codcli = z22_codcli' ||
		' AND z23_tipo_trn = z22_tipo_trn' ||
		' AND z23_num_trn = z22_num_trn' ||
		' AND z01_codcli = z22_codcli' ||
		' AND g03_compania = z22_compania' ||
		' AND g03_areaneg = z22_areaneg' ||
		' ORDER BY 1'
	PREPARE expresion FROM query
	DECLARE q_rep CURSOR FOR expresion
	OPEN q_rep
	FETCH q_rep INTO rm_consulta.*
	IF STATUS = NOTFOUND THEN
		CLOSE q_rep
		CALL fl_mensaje_consulta_sin_registros()
	ELSE
		START REPORT reporte_transaccion_documentos TO PIPE comando
		FOREACH q_rep INTO rm_consulta.*
			IF resp = 'Yes' THEN
				LET registro = rm_consulta.fecha_doc
					USING "mm/dd/yyyy", '|',
					rm_consulta.cliente CLIPPED,
					'|', rm_consulta.origen CLIPPED,
					'|', rm_consulta.area CLIPPED,
					'|', rm_consulta.tipo_transac,
					'|', rm_consulta.numero_transac,
					'|', rm_consulta.dcto_aplico,
					'|', rm_consulta.num_dcto_aplico,
					'|', rm_consulta.sec_dcto_aplico,
					'|', rm_consulta.dcto_aplicado,
					'|', rm_consulta.num_dcto_aplicado,
					'|', rm_consulta.valor_capital,
					'|', rm_consulta.valor_interes
				IF vg_gui = 1 THEN
					--#DISPLAY registro CLIPPED,ASCII(enter)
				ELSE
					DISPLAY registro CLIPPED
				END IF
			END IF
			OUTPUT TO REPORT 
				reporte_transaccion_documentos(rm_consulta.*)
		END FOREACH
		FINISH REPORT reporte_transaccion_documentos
	END IF
	FREE q_rep
END WHILE

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_moneda		RECORD LIKE gent013.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_cliente	RECORD LIKE cxct001.*
DEFINE r_z04	 	RECORD LIKE cxct004.*
DEFINE r_transaccion 	RECORD LIKE cxct004.*
DEFINE r_area		RECORD LIKE gent003.*
DEFINE codmon		LIKE gent013.g13_moneda
DEFINE descmon		LIKE gent013.g13_nombre
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE codtrn		LIKE gent021.g21_cod_tran
DEFINE desctrn		LIKE gent021.g21_nombre
DEFINE codarea		LIKE gent003.g03_areaneg
DEFINE nomarea		LIKE gent003.g03_nombre 
DEFINE decimales	LIKE gent013.g13_decimales

LET rm_par.origen_doc = 'M'
DISPLAY BY NAME rm_par.*
IF vg_gui = 0 THEN
	CALL muestra_origen(rm_par.origen_doc)
END IF
LET int_flag = 0
INPUT BY NAME rm_par.localidad, rm_par.moneda, rm_par.transaccion,
	rm_par.doc_deudor, rm_par.doc_favor, rm_par.area, rm_par.cliente,
	rm_par.inicial, rm_par.final, rm_par.origen_doc
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		LET int_flag = 1
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY (F2)
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
			END IF
			NEXT FIELD moneda
		END IF
		IF INFIELD(transaccion) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('T')
				RETURNING codtrn, desctrn
			IF codtrn IS NOT NULL THEN
				LET rm_par.transaccion = codtrn
				DISPLAY codtrn 	TO transaccion
				DISPLAY desctrn	TO desc_transaccion
			END IF
			LET int_flag = 0
		END IF
		IF INFIELD(doc_deudor) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('D')
				RETURNING r_z04.z04_tipo_doc, r_z04.z04_nombre
			IF r_z04.z04_tipo_doc IS NOT NULL THEN
				LET rm_par.doc_deudor = r_z04.z04_tipo_doc
				DISPLAY r_z04.z04_tipo_doc TO doc_deudor
				DISPLAY r_z04.z04_nombre   TO desc_doc_deu
			END IF
			LET int_flag = 0
		END IF
		IF INFIELD(doc_favor) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('F')
				RETURNING r_z04.z04_tipo_doc, r_z04.z04_nombre
			IF r_z04.z04_tipo_doc IS NOT NULL THEN
				LET rm_par.doc_favor = r_z04.z04_tipo_doc
				DISPLAY r_z04.z04_tipo_doc TO doc_favor
				DISPLAY r_z04.z04_nombre   TO desc_doc_fav
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
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda)
				RETURNING r_moneda.*
			IF r_moneda.g13_moneda IS NULL THEN
				CALL fl_mostrar_mensaje('No existe moneda.','exclamation')
				NEXT FIELD moneda
			ELSE
				DISPLAY r_moneda.g13_nombre TO desc_moneda
			END IF
		ELSE
			CALL fl_mostrar_mensaje('Debe especificar la moneda.','exclamation')
                        NEXT FIELD moneda
		END IF
	AFTER FIELD transaccion
		IF rm_par.transaccion IS NOT NULL THEN
			CALL fl_lee_tipo_doc(rm_par.transaccion)
				RETURNING r_transaccion.*
			IF r_transaccion.z04_tipo_doc IS NULL THEN
				CALL fl_mostrar_mensaje('Tipo de Transacción no existe.','exclamation')
				NEXT FIELD transaccion
			ELSE
				LET d_transaccion = r_transaccion.z04_nombre
				DISPLAY r_transaccion.z04_nombre 	
					TO desc_transaccion
			END IF
		ELSE
			CLEAR desc_transaccion
		END IF
	AFTER FIELD doc_deudor
		IF rm_par.doc_deudor IS NOT NULL THEN
			CALL fl_lee_tipo_doc(rm_par.doc_deudor) RETURNING r_z04.*
			IF r_z04.z04_tipo_doc IS NULL THEN
				CALL fl_mostrar_mensaje('Tipo de Documento no existe.','exclamation')
				NEXT FIELD doc_deudor
			ELSE
				LET d_doc_deu = r_z04.z04_nombre
				DISPLAY r_z04.z04_nombre 	
					TO desc_doc_deu
			END IF
		ELSE
			CLEAR desc_doc_deu
		END IF
	AFTER FIELD doc_favor
		IF rm_par.doc_favor IS NOT NULL THEN
			CALL fl_lee_tipo_doc(rm_par.doc_favor) RETURNING r_z04.*
			IF r_z04.z04_tipo_doc IS NULL THEN
				CALL fl_mostrar_mensaje('Tipo de Documento no existe.','exclamation')
				NEXT FIELD doc_favor
			ELSE
				LET d_doc_fav = r_z04.z04_nombre
				DISPLAY r_z04.z04_nombre TO desc_doc_fav
			END IF
		ELSE
			CLEAR desc_doc_fav
		END IF
		
	AFTER FIELD area
		 IF rm_par.area IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, rm_par.area)
				RETURNING r_area.*
			IF r_area.g03_areaneg IS NULL THEN
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
			CALL fl_mostrar_mensaje('Debe especificar la fecha inicial.','exclamation')
                        NEXT FIELD inicial
                END IF
	AFTER FIELD origen_doc
		IF vg_gui = 0 THEN
			IF rm_par.origen_doc IS NOT NULL THEN
				CALL muestra_origen(rm_par.origen_doc)
			ELSE
				CLEAR tit_origen_doc
			END IF
		END IF
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
        AFTER INPUT
                IF rm_par.inicial > rm_par.final THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual que la fecha final.','exclamation')
                        NEXT FIELD inicial
                END IF
END INPUT

END FUNCTION



REPORT reporte_transaccion_documentos(fecha_doc, cliente, origen, area,
			tipo_transac, numero_transac, dcto_aplico,
			num_dcto_aplico, sec_dcto_aplico, dcto_aplicado,
			num_dcto_aplicado, valor_capital, valor_interes)
DEFINE fecha_doc		LIKE cxct022.z22_fecha_emi
DEFINE cliente			LIKE cxct001.z01_nomcli
DEFINE origen			LIKE cxct020.z20_origen
DEFINE area			LIKE gent003.g03_abreviacion
DEFINE tipo_transac		LIKE cxct022.z22_tipo_trn
DEFINE numero_transac		LIKE cxct022.z22_num_trn
DEFINE dcto_aplico		LIKE cxct023.z23_tipo_doc
DEFINE num_dcto_aplico		LIKE cxct023.z23_num_doc
DEFINE sec_dcto_aplico		LIKE cxct023.z23_div_doc
DEFINE dcto_aplicado		LIKE cxct023.z23_tipo_favor
DEFINE num_dcto_aplicado 	LIKE cxct023.z23_doc_favor
DEFINE valor_capital		LIKE cxct023.z23_valor_cap
DEFINE valor_interes		LIKE cxct023.z23_valor_int
DEFINE titulo  	        	VARCHAR(80)
DEFINE modulo           	VARCHAR(40)
DEFINE i,long           	SMALLINT
DEFINE descr_estado		VARCHAR(9)		
DEFINE columna			SMALLINT
DEFINE usuario			VARCHAR(15)
DEFINE desc_tipo		VARCHAR(30)
DEFINE desc_origen_doc		VARCHAR(30)

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	2
	RIGHT  MARGIN	90
	BOTTOM MARGIN	4
	PAGE   LENGTH	66

FORMAT
	PAGE HEADER
	LET modulo = 'Módulo: Cobranzas'
	LET long   = LENGTH(modulo)
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DE TRANSACCIONES', '52')
		RETURNING titulo
       	PRINT COLUMN 001, rg_cia.g01_razonsocial,
       	      COLUMN 122, 'Pagina: ', PAGENO USING "&&&"
       	PRINT COLUMN 001, modulo  CLIPPED,
	      COLUMN 044, titulo,
              COLUMN 126, UPSHIFT(vg_proceso)
      	SKIP 1 LINES
	--#IF rm_par.localidad IS NOT NULL THEN
		PRINT COLUMN 030, "*** Localidad:           ",
			rm_par.localidad USING '&&', " ", rm_par.tit_localidad
	--#END IF
	PRINT COLUMN 030, '*** Moneda:              ', rm_par.moneda
	--#IF rm_par.transaccion IS NOT NULL THEN
		PRINT COLUMN 030, '*** Tipo de Transacción: ', d_transaccion 
	--#END IF
	--#IF rm_par.area IS NOT NULL THEN
		PRINT COLUMN 030, '*** Area de Negocio:     ', d_area		
	--#END IF	
	--#IF rm_par.cliente IS NOT NULL THEN
		PRINT COLUMN 030, '*** Cliente:             ', d_cliente
	--#END IF
	PRINT COLUMN 030, '*** Fecha Inicial:       ', rm_par.inicial USING 'dd-mm-yyyy'
	PRINT COLUMN 030, '*** Fecha Final:         ', rm_par.final USING 'dd-mm-yyyy'
	IF rm_par.transaccion IS NULL THEN
		LET desc_tipo = 'Todos'   	
		PRINT COLUMN 030, '*** Tipo:                ', desc_tipo
	ELSE
		LET desc_tipo = rm_par.transaccion
		PRINT COLUMN 030, '*** Tipo:                ', desc_tipo	
	END IF
	IF rm_par.doc_deudor IS NULL THEN
		PRINT COLUMN 030, '*** Tipo Documento:      ', "TODOS"
	ELSE
		PRINT COLUMN 030, '*** Tipo Documento:      ', d_doc_deu	
	END IF
	IF rm_par.doc_favor IS NULL THEN
		PRINT COLUMN 030, '*** Tipo A Favor:        ', "TODOS"
	ELSE
		PRINT COLUMN 030, '*** Tipo A Favor:        ', d_doc_fav	
	END IF
        IF rm_par.origen_doc  = 'M' THEN
                LET desc_origen_doc = 'Manual'
                PRINT COLUMN 030, '*** Origen:              ' , desc_origen_doc
	ELSE
	        IF rm_par.origen_doc  = 'A' THEN
        	        LET desc_origen_doc = 'Automatico'
                	PRINT COLUMN 030, '*** Origen:              ' , desc_origen_doc
		ELSE
		        --#IF rm_par.origen_doc  = 'T' THEN
        		        LET desc_origen_doc = 'Todos'
		                PRINT COLUMN 030, '*** Origen:              ' , desc_origen_doc
		        --#END IF
	        END IF
        END IF
	SKIP 1 LINES
	PRINT COLUMN 001, 'Fecha impresión: ', vg_fecha USING 'dd-mm-yyyy', 
			 1 SPACES, TIME,
              COLUMN 120, usuario
      	SKIP 1 LINES
	PRINT COLUMN 001, 'F. Doc.  ',
	      COLUMN 012, 'Cliente',
	      COLUMN 029, 'O.',
	      COLUMN 032, 'Area',
	      COLUMN 044, 'Dcto',
	      COLUMN 050, 'No.Tran.',
	      COLUMN 059, 'Aplicó',
	      COLUMN 066, 'No. Doc.',
	      COLUMN 078, 'Sec.',
	      COLUMN 090, 'Aplicado',
	      COLUMN 099, 'No. Doc.',
	      COLUMN 111, 'Valor Cap.',
	      COLUMN 123, 'Valor Int.'
	PRINT COLUMN 001, '-----------',
	      COLUMN 012, '-----------------',
	      COLUMN 029, '---',
	      COLUMN 032, '------------',
	      COLUMN 044, '---',
	      COLUMN 047, '------------',
	      COLUMN 059, '-------',
	      COLUMN 066, '------------',
	      COLUMN 078, '------------',
	      COLUMN 090, '---------',
	      COLUMN 099, '------------',
	      COLUMN 111, '------------',
	      COLUMN 123, '----------'

ON EVERY ROW
	PRINT COLUMN 001, fecha_doc,
	      COLUMN 012, cliente[1,15],
	      COLUMN 029, origen,
	      COLUMN 032, area,
	      COLUMN 044, tipo_transac,
	      COLUMN 047, numero_transac,
	      COLUMN 059, dcto_aplico,
              COLUMN 066, num_dcto_aplico,
	      COLUMN 078, sec_dcto_aplico,
	      COLUMN 090, dcto_aplicado,
	      COLUMN 099, num_dcto_aplicado,
	      COLUMN 111, valor_capital USING '-,---,--&.##', 
	      COLUMN 123, valor_interes	USING '---,--&.##'  

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 111, '------------',
	      COLUMN 123, '----------'
	PRINT COLUMN 111, SUM(valor_capital) USING '-,---,--&.##',
	      COLUMN 123, SUM(valor_interes) USING '---,--&.##' 

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
