------------------------------------------------------------------------------
-- Titulo               : cxpp412.4gl --  Listado de Documentos Deudores 
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  cxpp412 base modulo compañía localidad
-- Ultima Correción     : 15-Jul-2002
-- Motivo Corrección    : Correcciones Varias (RCA) 

--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios      VARCHAR(12)
DEFINE d_documento      VARCHAR(20)
DEFINE d_proveedor	VARCHAR(20)
DEFINE d_cliente	VARCHAR(20)
DEFINE rm_par RECORD
	moneda		CHAR(2),
	documento	CHAR(2),
	proveedor	SMALLINT,
	inicial		DATE,
	final		DATE,
	saldo 		CHAR(1),
	origen_doc	CHAR(1)
END RECORD
DEFINE rm_consulta	RECORD 
	fecha_doc	LIKE cxpt020.p20_fecha_emi,
	proveedor	LIKE cxpt001.p01_nomprov,
	origen		LIKE cxpt020.p20_origen,
	tipo_documento	LIKE cxpt020.p20_tipo_doc,
	num_documento	LIKE cxpt020.p20_num_doc,
	sec_documento	LIKE cxpt020.p20_dividendo,
	valor_capital	LIKE cxpt020.p20_valor_cap,
	valor_interes	LIKE cxpt020.p20_valor_int,
	saldo_capital 	LIKE cxpt020.p20_saldo_cap,
	saldo_interes	LIKE cxpt020.p20_saldo_int
END RECORD
DEFINE vm_page 		SMALLINT
DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT



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

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxpp412'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE query 		CHAR(700)
DEFINE comando          VARCHAR(100)
DEFINE s_documento	VARCHAR(50)
DEFINE s_proveedor	VARCHAR(50)
DEFINE s_saldo		VARCHAR(50)
DEFINE s_origen_doc	VARCHAR(50)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*

LET vm_top	= 1
LET vm_left	= 2
LET vm_right	= 90
LET vm_bottom	= 4
LET vm_page	= 66

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 14
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
	OPEN FORM frm_listado FROM '../forms/cxpf412_1'
ELSE
	OPEN FORM frm_listado FROM '../forms/cxpf412_1c'
END IF
DISPLAY FORM frm_listado

LET int_flag = 0
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
	CALL fl_control_reportes() RETURNING comando
	IF INT_FLAG THEN
		CONTINUE WHILE
	END IF

	LET s_documento = ' 1 = 1'
	LET s_proveedor = ' 1 = 1'
	LET s_saldo     = ' 1 = 1'
	LET s_origen_doc= ' 1 = 1'

	IF rm_par.documento IS NOT NULL THEN
		LET s_documento = ' p20_tipo_doc = "' || rm_par.documento || '"'  
	END IF
	
	IF rm_par.proveedor IS NOT NULL THEN
		LET s_proveedor = ' p20_codprov = ' || rm_par.proveedor  
	END IF

	IF rm_par.saldo IS NOT NULL THEN
		LET s_saldo = ' p20_saldo = ' || rm_par.saldo  
	END IF
	
        IF rm_par.saldo IS NOT NULL THEN
                IF rm_par.saldo = 'S' THEN
                     LET s_saldo = ' p20_saldo_cap +  p20_saldo_int > 0'
                ELSE
                     LET s_saldo = ' 1 = 1 '
                END IF
        ELSE
                LET s_saldo = ' p20_saldo > 0 '
        END IF
        IF rm_par.origen_doc IS NOT NULL THEN
                IF rm_par.origen_doc = 'M' THEN
                        LET s_origen_doc = " p20_origen = 'M'"
                END IF
                IF rm_par.origen_doc = 'A' THEN
                        LET s_origen_doc = " p20_origen = 'A'"
                END IF
                IF rm_par.origen_doc = 'T' THEN
                        LET s_origen_doc = " 1 = 1 "
                END IF
        END IF

	LET query = 'SELECT p20_fecha_emi, p01_nomprov, ' || 
		' p20_origen,  p20_tipo_doc,' ||
		' p20_num_doc, p20_dividendo,' ||
		' p20_valor_cap, p20_valor_int,' ||
		' p20_saldo_cap, p20_saldo_int' ||
		' FROM cxpt020, cxpt001' || 
		' WHERE p20_compania = ' || vg_codcia || 
		' AND p20_localidad = '  || vg_codloc || 
		' AND p20_moneda = "' || rm_par.moneda || 
		'" AND p20_fecha_emi BETWEEN "' || rm_par.inicial ||
		'" AND "' || rm_par.final || '"' ||
		' AND ' || s_documento || 
		' AND ' || s_proveedor ||
		' AND ' || s_saldo ||
		' AND ' || s_origen_doc ||
		' AND p01_codprov = p20_codprov' ||
		' ORDER BY 1, 5'
	PREPARE expresion FROM query
	DECLARE q_rep CURSOR FOR expresion
	OPEN q_rep
	FETCH q_rep INTO rm_consulta.*
	IF STATUS = NOTFOUND THEN
		CLOSE q_rep
		CALL fl_mensaje_consulta_sin_registros()
	ELSE
		CLOSE q_rep
		START REPORT reporte_documento_deudor TO PIPE comando
		FOREACH q_rep INTO rm_consulta.*
			OUTPUT TO REPORT reporte_documento_deudor(rm_consulta.*)
		END FOREACH
		FINISH REPORT reporte_documento_deudor
	END IF
END WHILE

END FUNCTION


FUNCTION control_ingreso()
DEFINE	r_moneda	RECORD LIKE gent013.*
DEFINE  r_documento 	RECORD LIKE cxpt004.*
DEFINE  r_proveedor	RECORD LIKE cxpt001.*
DEFINE  codmon		LIKE gent013.g13_moneda
DEFINE  descmon		LIKE gent013.g13_nombre
DEFINE  coddoc		LIKE cxpt004.p04_tipo_doc
DEFINE  descdoc		LIKE cxpt004.p04_nombre
DEFINE  codprov		LIKE cxpt001.p01_codprov
DEFINE  nomprov		LIKE cxpt001.p01_nomprov 
DEFINE  decimales	LIKE gent013.g13_decimales

LET rm_par.saldo      = 'S'
LET rm_par.origen_doc = 'M'
DISPLAY BY NAME rm_par.*
IF vg_gui = 0 THEN
	CALL muestra_flagsaldo(rm_par.saldo)
	CALL muestra_origen(rm_par.origen_doc)
END IF
LET int_flag = 0
INPUT BY NAME rm_par.moneda, rm_par.documento, rm_par.proveedor, rm_par.inicial,
	rm_par.final, rm_par.saldo, rm_par.origen_doc
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
			CALL fl_ayuda_tipo_documento_tesoreria('D')
				RETURNING coddoc, descdoc
			IF coddoc IS NOT NULL THEN
				LET rm_par.documento = coddoc
				DISPLAY coddoc 	TO documento
				DISPLAY descdoc	TO desc_documento
			END IF
			LET int_flag = 0
		END IF
 
		IF INFIELD(proveedor) THEN
			CALL fl_ayuda_proveedores()
				RETURNING codprov, nomprov
			IF codprov IS NOT NULL THEN
				LET rm_par.proveedor = codprov
				DISPLAY codprov	TO proveedor
				DISPLAY nomprov	TO desc_proveedor
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
				--CALL fgl_winmessage(vg_producto,'No existe moneda','exclamation')
				CALL fl_mostrar_mensaje('No existe moneda','exclamation')
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
			CALL fl_lee_tipo_doc_tesoreria(rm_par.documento)
				RETURNING r_documento.*
			IF r_documento.p04_tipo_doc IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Documento no existe.','exclamation')
				CALL fl_mostrar_mensaje('Documento no existe.','exclamation')
				NEXT FIELD documento
			ELSE
				LET d_documento = r_documento.p04_nombre
				DISPLAY r_documento.p04_nombre 	
					TO desc_documento
			END IF
		ELSE
			CLEAR desc_documento
		END IF
		
	AFTER FIELD proveedor
		 IF rm_par.proveedor IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_par.proveedor)
				RETURNING r_proveedor.*
			IF r_proveedor.p01_codprov IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Proveedor no existe.','exclamation')
				CALL fl_mostrar_mensaje('Proveedor no existe.','exclamation')
				NEXT FIELD proveedor
			ELSE
				LET d_proveedor = r_proveedor.p01_nomprov
				DISPLAY r_proveedor.p01_nomprov 
						TO desc_proveedor 	
			END IF
		ELSE
			CLEAR desc_proveedor
		END IF
	
        AFTER FIELD inicial
                IF rm_par.inicial IS NULL THEN
                        --CALL fgl_winmessage(vg_producto,'Debe especificar la fecha inicial.','exclamation')
			CALL fl_mostrar_mensaje('Debe especificar la fecha inicial.','exclamation')
                        NEXT FIELD inicial
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
		IF rm_par.inicial IS NULL OR rm_par.final IS NULL THEN
                        --CALL fgl_winmessage(vg_producto,'Debe especificar la fecha inicial.','exclamation')
			CALL fl_mostrar_mensaje('Debe especificar la fecha inicial.','exclamation')
                        NEXT FIELD inicial
		END IF

		IF rm_par.inicial > rm_par.final THEN
			--CALL fgl_winmessage(vg_producto,'La fecha inicial debe ser menor o igual que la fecha final.','exclamation')
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual que la fecha final.','exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION

REPORT reporte_documento_deudor(fecha_doc, proveedor, origen,  
				tipo_documento, num_documento, sec_documento,
				valor_capital, valor_interes,
				saldo_capital, saldo_interes)

DEFINE fecha_doc	LIKE cxpt020.p20_fecha_emi
DEFINE proveedor	LIKE cxpt001.p01_nomprov
DEFINE origen		LIKE cxpt020.p20_origen
DEFINE tipo_documento	LIKE cxpt020.p20_tipo_doc
DEFINE num_documento	LIKE cxpt020.p20_num_doc
DEFINE sec_documento	LIKE cxpt020.p20_dividendo
DEFINE valor_capital	LIKE cxpt020.p20_valor_cap
DEFINE valor_interes	LIKE cxpt020.p20_valor_int
DEFINE saldo_capital	LIKE cxpt020.p20_saldo_cap
DEFINE saldo_interes	LIKE cxpt020.p20_saldo_int
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo           VARCHAR(80)
DEFINE modulo           VARCHAR(40)
DEFINE i,long           SMALLINT
DEFINE descr_estado	VARCHAR(9)		
DEFINE columna		SMALLINT
DEFINE desc_saldo	CHAR(25)
DEFINE desc_origen_doc	CHAR(25)

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	2
	RIGHT  MARGIN	90
	BOTTOM MARGIN	4
	PAGE   LENGTH	66

FORMAT
	PAGE HEADER
		LET modulo	= 'Módulo: Tesorería'
		LET long	= LENGTH(modulo)
		
		CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
		CALL fl_justifica_titulo('C', 
					'LISTADO DE DOCUMENTOS DEUDORES', 
					'52')
		RETURNING titulo

        	PRINT COLUMN 1,   rg_cia.g01_razonsocial,
              	      COLUMN 120, 'Página: ', PAGENO USING "&&&"

        	PRINT COLUMN 1,   modulo  CLIPPED,
		      COLUMN 44,  titulo,
                      COLUMN 109, UPSHIFT(vg_proceso)

      	SKIP 1 LINES
	
	PRINT COLUMN 20, '*** Moneda:             ', rm_par.moneda

	--#IF rm_par.documento IS NOT NULL THEN
		PRINT COLUMN 20, '*** Documento a Favor:  ', d_documento 
	--#END IF

	--#IF rm_par.proveedor IS NOT NULL THEN
		PRINT COLUMN 20, '*** Area de Negocio:    ', d_proveedor		
	--#END IF	

	
	PRINT COLUMN 20, '*** Fecha Inicial:      ', rm_par.inicial USING 'dd-mm-yyyy'
	PRINT COLUMN 20, '*** Fecha Final:        ', rm_par.final USING 'dd-mm-yyyy'

        IF rm_par.saldo = 'S' THEN
                LET desc_saldo = 'Saldo > 0'
        	PRINT COLUMN 20, '*** Saldo:              ' , desc_saldo
        ELSE
                LET desc_saldo = 'Todos'
                PRINT COLUMN 20, '*** Saldo:              ' , desc_saldo
        END IF

        IF rm_par.origen_doc  = 'M' THEN
                LET desc_origen_doc = 'Manual'
                PRINT COLUMN 20, '*** Origen:             ' , desc_origen_doc
	ELSE
	        IF rm_par.origen_doc  = 'A' THEN
        	        LET desc_origen_doc = 'Automatico'
                	PRINT COLUMN 20, '*** Origen:             ' , desc_origen_doc
		ELSE
		        --#IF rm_par.origen_doc  = 'T' THEN
                		LET desc_origen_doc = 'Todos'
		                PRINT COLUMN 20, '*** Origen:             ' , desc_origen_doc
		        --#END IF
	        END IF
        END IF

	SKIP 1 LINES
	
	PRINT 01, 'Fecha impresión: ', vg_fecha USING 'dd-mm-yyyy', 
			 1 SPACES, TIME,
              COLUMN 120, usuario
                                                                                
      	SKIP 1 LINES

		PRINT COLUMN 1,   'F. Dcto   ',
		      COLUMN 12,  'Proveedor',          
		      COLUMN 36,  'O',
		      COLUMN 38,  'DO',     
		      COLUMN 41,  'Numero',    		
		      COLUMN 66,  'Sec.',
		      COLUMN 72,  'Valor Capital',
		      COLUMN 86,  'Valor Interés',
		      COLUMN 101, 'Saldo Capital',
		      COLUMN 118, 'Saldo Interés'

		PRINT COLUMN 1,   '-----------',
		      COLUMN 12,  '------------------------',
		      COLUMN 37,  '-------',
		      COLUMN 44,  '------',
		      COLUMN 50,  '------------',
		      COLUMN 62,  '-----',
		      COLUMN 67,  '----------------',
		      COLUMN 83,  '----------------',
		      COLUMN 99,  '------------------',
		      COLUMN 117, '--------------'

	ON EVERY ROW
		PRINT COLUMN 1,   fecha_doc	USING "dd-mm-yyyy",
		      COLUMN 12,  proveedor[1, 23],
		      COLUMN 36,  origen,
		      COLUMN 38,  tipo_documento,
		      COLUMN 41,  num_documento,
		      COLUMN 60,  sec_documento CLIPPED, 
		      COLUMN 69,  valor_capital USING '##,###,##&.##',
		      COLUMN 85,  valor_interes USING '##,###,##&.##',
		      COLUMN 101, saldo_capital USING '##,###,##&.##',
		      COLUMN 118, saldo_interes USING '##,###,##&.##'

	ON LAST ROW
		NEED 3 LINES
		PRINT COLUMN 72,  '----------------',
		      COLUMN 83,  '----------------',
		      COLUMN 99,  '----------------',
		      COLUMN 115, '-----------'
		PRINT COLUMN 70,  SUM(valor_capital) USING '###,###,##&.##',
		      COLUMN 84,  SUM(valor_interes) USING '###,###,##&.##', 
		      COLUMN 100,  SUM(saldo_capital) USING '###,###,##&.##', 
		      COLUMN 117, SUM(saldo_interes) USING '###,###,##&.##' 
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
