------------------------------------------------------------------------------
-- Titulo               : cxcp411.4gl --  Listado de Documentos a Favor
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  cxcp411 base modulo compañía localidad
-- Ultima Correción     : 15-JUL-2002
-- Motivo Corrección    : CORECCIONES VARIAS (RCA) 

--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                DEFINE vm_demonios      VARCHAR(12)
DEFINE d_documento      LIKE cxct004.z04_nombre
DEFINE d_area 		LIKE gent003.g03_nombre
DEFINE d_cliente	VARCHAR(20)
DEFINE rm_par 		RECORD
				moneda		CHAR(2),
				documento	CHAR(2),
				origen_nc	CHAR(1),
				area		SMALLINT,
				cliente		SMALLINT,
				inicial		DATE,
				final		DATE,
				saldo 		CHAR(1),
			--	origen 		CHAR(15)
				origen_doc	CHAR(1)
			END RECORD
DEFINE rm_consulta	RECORD 
				fecha_doc	LIKE cxct021.z21_fecha_emi,
				cliente		LIKE cxct001.z01_nomcli,
				referencia	LIKE cxct021.z21_referencia,
				origen		LIKE cxct021.z21_origen,
				area		LIKE gent003.g03_abreviacion,
				tipo_documento	LIKE cxct021.z21_tipo_doc,
				num_documento	LIKE cxct021.z21_num_doc,
				cod_tran	LIKE cxct021.z21_cod_tran,
				num_tran	LIKE cxct021.z21_num_tran,
				num_sri		LIKE cxct021.z21_num_sri,
				valor_original	LIKE cxct021.z21_valor,
				saldo_actual 	LIKE cxct021.z21_saldo
			END RECORD



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   
     --CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp411'
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
DEFINE estado		CHAR(1)
DEFINE s_documento	VARCHAR(50)
DEFINE s_area		VARCHAR(50)
DEFINE s_cliente	VARCHAR(50)
DEFINE s_saldo		VARCHAR(50)
DEFINE s_origen		VARCHAR(50)
DEFINE s_origen_nc	VARCHAR(60)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE r_g03		RECORD LIKE gent003.*

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
	OPEN FORM frm_listado FROM '../forms/cxcf411_1'
ELSE
	OPEN FORM frm_listado FROM '../forms/cxcf411_1c'
END IF
DISPLAY FORM frm_listado
LET int_flag = 0
INITIALIZE rm_par.* TO NULL 
LET rm_par.inicial    = TODAY
LET rm_par.final      = TODAY
LET rm_par.saldo      = 'S'
LET rm_par.origen_doc = 'M'
LET rm_par.origen_nc  = 'T'
WHILE (TRUE)
	CALL control_ingreso()
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	LET s_documento = ' 1 = 1'
	LET s_area      = ' 1 = 1'
	LET s_cliente   = ' 1 = 1'
	LET s_saldo     = ' 1 = 1'
	LET s_origen    = ' 1 = 1'
	LET s_origen_nc = ' 1 = 1'
	IF rm_par.documento IS NOT NULL THEN
		LET s_documento = ' z21_tipo_doc = "' || rm_par.documento || '"'
	END IF
	IF rm_par.area IS NOT NULL THEN
		LET s_area = ' z21_areaneg = ' || rm_par.area  
	END IF
	IF rm_par.cliente IS NOT NULL THEN
		LET s_cliente = ' z21_codcli = ' || rm_par.cliente  
	END IF
	IF rm_par.documento = 'NC' THEN
		IF rm_par.origen_nc = 'A' THEN
			LET s_origen_nc = ' z21_cod_tran = "AF"'
		END IF
		IF rm_par.origen_nc = 'D' THEN
			LET s_origen_nc = ' z21_cod_tran = "DF"'
		END IF
		IF rm_par.origen_nc = 'T' THEN
			LET s_origen_nc = ' (z21_cod_tran IN ("AF","DF") ',
					   ' OR z21_cod_tran IS NULL) '
			IF rm_par.origen_doc = 'A' THEN
				LET s_origen_nc = ' z21_cod_tran IN ("AF","DF")'
			END IF
		END IF
		CALL fl_lee_area_negocio(vg_codcia, rm_par.area)
				RETURNING r_g03.*
		IF r_g03.g03_modulo = 'TA' THEN
			LET s_origen_nc = ' z21_cod_tran = "FA"'
			LET rm_par.origen_nc = 'T'
			DISPLAY BY NAME rm_par.origen_nc
		END IF
	END IF
	IF rm_par.saldo IS NOT NULL THEN
		IF rm_par.saldo = 'S' THEN
			LET s_saldo = ' z21_saldo > 0 '
	        ELSE	
			LET s_saldo = ' z21_saldo >= 0 '
		END IF
	ELSE
		LET s_saldo = ' z21_saldo > 0 '
	END IF
	IF rm_par.origen_doc IS NOT NULL THEN
		IF rm_par.origen_doc = 'M' THEN
			LET s_origen = " z21_origen = 'M'"
		END IF
		IF rm_par.origen_doc = 'A' THEN
			LET s_origen = " z21_origen = 'A'"
		END IF
		IF rm_par.origen_doc = 'T' THEN
			LET s_origen = " z21_origen IN ('A','M') "
		END IF
	END IF
	LET query = 'SELECT z21_fecha_emi, z01_nomcli, z21_referencia, ', 
		' z21_origen, g03_abreviacion, z21_tipo_doc, z21_num_doc, ',
		' z21_cod_tran, z21_num_tran, z21_num_sri, z21_valor, ',
		' z21_saldo ',
		' FROM cxct021, cxct001, gent003', 
		' WHERE z21_compania  = ', vg_codcia, 
		'   AND z21_localidad = ', vg_codloc, 
		'   AND z21_moneda    = "', rm_par.moneda,
		'"  AND z21_fecha_emi BETWEEN "', rm_par.inicial,
		'"  AND "', rm_par.final, '"',
		'   AND ', s_documento CLIPPED, 
		'   AND ', s_origen_nc CLIPPED,
		'   AND ', s_area CLIPPED,
	        '   AND ', s_cliente CLIPPED,
		'   AND ', s_saldo CLIPPED,
		'   AND ', s_origen CLIPPED,
		'   AND z01_codcli   = z21_codcli',
		'   AND g03_compania = z21_compania',
		'   AND g03_areaneg  = z21_areaneg',
		' ORDER BY 1, 7'
	PREPARE expresion FROM query
	DECLARE q_rep CURSOR FOR expresion
	OPEN q_rep
	FETCH q_rep INTO rm_consulta.*
	IF STATUS = NOTFOUND THEN
		CLOSE q_rep
		CALL fl_mensaje_consulta_sin_registros()
	ELSE
		CLOSE q_rep
		START REPORT reporte_documento_favor TO PIPE comando
		FOREACH q_rep INTO rm_consulta.*
			IF rm_consulta.tipo_documento = 'NC' THEN
				IF rm_par.origen_nc = 'A' THEN
					IF rm_consulta.cod_tran <> 'AF' THEN
						CONTINUE FOREACH
					END IF
				END IF
				IF rm_par.origen_nc = 'D' THEN
					IF rm_consulta.cod_tran <> 'DF' THEN
						CONTINUE FOREACH
					END IF
				END IF
			END IF
			OUTPUT TO REPORT reporte_documento_favor(rm_consulta.*)
		END FOREACH
		FINISH REPORT reporte_documento_favor
	END IF
END WHILE

END FUNCTION



FUNCTION control_ingreso()
DEFINE	r_moneda	RECORD LIKE gent013.*
DEFINE  r_cliente	RECORD LIKE cxct001.*
DEFINE  r_documento 	RECORD LIKE cxct004.*
DEFINE  r_area		RECORD LIKE gent003.*
DEFINE  codmon		LIKE gent013.g13_moneda
DEFINE  descmon		LIKE gent013.g13_nombre
DEFINE  codcli		LIKE cxct001.z01_codcli
DEFINE  nomcli		LIKE cxct001.z01_nomcli
DEFINE  coddoc		LIKE cxct004.z04_tipo_doc
DEFINE  descdoc		LIKE cxct004.z04_nombre
DEFINE  codarea		LIKE gent003.g03_areaneg
DEFINE  nomarea		LIKE gent003.g03_nombre 
DEFINE  decimales	LIKE gent013.g13_decimales

--LET rm_par.origen = 'Manual' ## Si queremos Combo Box
DISPLAY BY NAME rm_par.*
IF vg_gui = 0 THEN
	CALL muestra_flagsaldo(rm_par.saldo)
	CALL muestra_origen(rm_par.origen_doc)
	CALL muestra_origen_nc(rm_par.origen_nc)
END IF
LET rm_par.moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_moneda.* 
DISPLAY r_moneda.g13_nombre TO desc_moneda
LET int_flag = 0
INPUT BY NAME rm_par.moneda, rm_par.documento, rm_par.origen_nc, rm_par.area,
	rm_par.cliente, rm_par.inicial, rm_par.final, rm_par.saldo,
	rm_par.origen_doc
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		LET int_flag = 1
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY (F2)
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
			CALL fl_ayuda_tipo_documento_cobranzas('F')
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
	AFTER FIELD origen_nc
		IF vg_gui = 0 THEN
			IF rm_par.origen_nc IS NOT NULL THEN
				CALL muestra_origen_nc(rm_par.origen_nc)
			ELSE
				CLEAR tit_origen_nc
			END IF
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



REPORT reporte_documento_favor(fecha_doc, cliente, referencia, origen, area,
				tipo_documento, num_documento, cod_tran,
				num_tran, num_sri, valor_original, saldo_actual)

DEFINE fecha_doc	LIKE cxct021.z21_fecha_emi
DEFINE cliente		LIKE cxct001.z01_nomcli
DEFINE referencia    	LIKE cxct021.z21_referencia
DEFINE origen		LIKE cxct021.z21_origen
DEFINE area	    	LIKE gent003.g03_abreviacion
DEFINE tipo_documento	LIKE cxct021.z21_tipo_doc
DEFINE num_documento	LIKE cxct021.z21_num_doc
DEFINE cod_tran		LIKE cxct021.z21_cod_tran
DEFINE num_tran		LIKE cxct021.z21_num_tran
DEFINE num_sri		LIKE cxct021.z21_num_sri
DEFINE valor_original	LIKE cxct021.z21_valor
DEFINE saldo_actual	LIKE cxct021.z21_saldo
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo           VARCHAR(80)
DEFINE modulo           VARCHAR(40)
DEFINE i,long           SMALLINT
DEFINE descr_estado	VARCHAR(9)		
DEFINE columna		SMALLINT
DEFINE desc_saldo	CHAR(25)
DEFINE desc_origen_doc	CHAR(25)
DEFINE desc_origen_nc	CHAR(25)
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
	LET modulo	= 'MODULO: COBRANZAS'
	LET long	= LENGTH(modulo)
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DE DOCUMENTOS A FAVOR', 80)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_comp
       	PRINT COLUMN 01,  rg_cia.g01_razonsocial,
       	      COLUMN 122, 'PÁGINA: ', PAGENO USING "&&&"
       	PRINT COLUMN 01,  modulo  CLIPPED,
	      COLUMN 34,  titulo,
              COLUMN 126, UPSHIFT(vg_proceso)
      	SKIP 1 LINES
	PRINT COLUMN 37, '*** MONEDA           :  ', rm_par.moneda
	--#IF rm_par.documento IS NOT NULL THEN
		PRINT COLUMN 37, '*** DOCUMENTO A FAVOR:  ', d_documento 
	--#END IF
        IF rm_par.origen_nc = 'A' AND rm_par.documento = 'NC' THEN
                LET desc_origen_nc = 'ANULACION'
                PRINT COLUMN 37, '*** ORIGEN DE LA N/C :  ' , desc_origen_nc
	ELSE
	        IF rm_par.origen_nc = 'D' AND rm_par.documento = 'NC' THEN
        	        LET desc_origen_nc = 'DEVOLUCION'
                	PRINT COLUMN 37, '*** ORIGEN DE LA N/C :  ' , desc_origen_nc
		ELSE
        		--#IF rm_par.origen_nc = 'T' AND rm_par.documento = 'NC'
			--#THEN
		                LET desc_origen_nc = 'T O D O'
                		PRINT COLUMN 37, '*** ORIGEN DE LA N/C :  ' , desc_origen_nc
		        --#END IF
	        END IF
        END IF
	--#IF rm_par.area IS NOT NULL THEN
		PRINT COLUMN 37, '*** AREA DE NEGOCIO  :  ', d_area		
	--#END IF	
	--#IF rm_par.cliente IS NOT NULL THEN
		PRINT COLUMN 37, '*** CLIENTE          :  ', d_cliente
	--#END IF
	PRINT COLUMN 37, '*** FECHA INICIAL    :  ', rm_par.inicial USING 'dd-mm-yyyy' 
	PRINT COLUMN 37, '*** FECHA FINAL      :  ', rm_par.final USING 'dd-mm-yyyy' 
	IF rm_par.saldo = 'S' THEN
		LET desc_saldo = 'SALDO > 0'
		PRINT COLUMN 37, '*** SALDO            :  ' , desc_saldo
	ELSE
		LET desc_saldo = 'TODOS' 
		PRINT COLUMN 37, '*** SALDO            :  ' , desc_saldo
	END IF	
        IF rm_par.origen_doc  = 'M' THEN
                LET desc_origen_doc = 'MANUAL'
                PRINT COLUMN 37, '*** ORIGEN           :  ' , desc_origen_doc
	ELSE
	        IF rm_par.origen_doc  = 'A' THEN
        	        LET desc_origen_doc = 'AUTOMATICO'
               		PRINT COLUMN 37, '*** ORIGEN           :  ' , desc_origen_doc
		ELSE
        		--#IF rm_par.origen_doc  = 'T' THEN
		                LET desc_origen_doc = 'TODOS'
                		PRINT COLUMN 37, '*** ORIGEN           :  ' , desc_origen_doc
		        --#END IF
	        END IF
        END IF
	SKIP 1 LINES
	PRINT COLUMN 01,  'FECHA IMPRESION: ', TODAY USING 'dd-mm-yyyy', 
			  1 SPACES, TIME,
              COLUMN 114, 'USUARIO: ',  usuario
      	SKIP 1 LINES
	PRINT COLUMN 01,  '------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 01,  'F. DCTO.',
	      COLUMN 12,  'CLIENTE',
	      COLUMN 35,  'REFERENCIA',
	      COLUMN 62,  'O',
	      COLUMN 64,  'A. NEG.',
	      COLUMN 72,  'DOCUMENTO',
	      COLUMN 83,  'TRANSACC.',		
	      COLUMN 94,  'No. SRI',
	      COLUMN 112, 'VALOR ORI.',
	      COLUMN 123, 'SALDO ACT.'
	PRINT COLUMN 01,  '------------------------------------------------------------------------------------------------------------------------------------'
	
ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 01,  fecha_doc USING 'dd-mm-yyyy', 
	      COLUMN 12,  cliente[1, 22],
	      COLUMN 35,  referencia[1, 26],
	      COLUMN 62,  origen,
	      COLUMN 64,  area[1, 7],
	      COLUMN 72,  tipo_documento, '-',
	      COLUMN 75,  num_documento		USING '<<<<<<<', 
	      COLUMN 83,  cod_tran, '-',
	      COLUMN 86,  num_tran		USING '<<<<<<<', 
	      COLUMN 94,  num_sri, 
	      COLUMN 112, valor_original	USING '###,##&.##',
	      COLUMN 123, saldo_actual		USING '###,##&.##'

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 112, '----------',
	      COLUMN 123, '----------'
	PRINT COLUMN 112, SUM(valor_original)	USING '###,##&.##',
	      COLUMN 123, SUM(saldo_actual)	USING '###,##&.##';
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



FUNCTION muestra_origen_nc(origen)
DEFINE origen		CHAR(1)

CASE origen
	WHEN 'A'
		DISPLAY 'ANULACION'  TO tit_origen_nc
	WHEN 'D'
		DISPLAY 'DEVOLUCION' TO tit_origen_nc
	WHEN 'T'
		DISPLAY 'T O D O'    TO tit_origen_nc
	OTHERWISE
		CLEAR origen_nc, tit_origen_nc
END CASE

END FUNCTION
