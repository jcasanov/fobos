------------------------------------------------------------------------------
-- Titulo               : cxcp412.4gl --  Listado de Documentos Deudores 
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  cxcp412 base modulo compañía localidad
-- Ultima Correción     : 09-JUL-2002
-- Motivo Corrección    : CORRECCIONES VARIAS (RCA) 

--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
database diteca
                                                                                
DEFINE vm_demonios      VARCHAR(12)
DEFINE d_documento      VARCHAR(20)
DEFINE d_area 		VARCHAR(20)
DEFINE d_cliente	VARCHAR(20)

DEFINE rm_par RECORD
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
	fecha_doc	LIKE cxct020.z20_fecha_emi,
	cliente		LIKE cxct001.z01_nomcli,
	origen		LIKE cxct020.z20_origen,
	area		LIKE gent003.g03_abreviacion,
	tipo_documento	LIKE cxct020.z20_tipo_doc,
	num_documento	LIKE cxct020.z20_num_doc,
	sec_documento	LIKE cxct020.z20_linea,
	valor_capital	LIKE cxct020.z20_valor_cap,
	valor_interes	LIKE cxct020.z20_valor_int,
	saldo_capital 	LIKE cxct020.z20_saldo_cap,
	saldo_interes	LIKE cxct020.z20_saldo_int
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
CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 THEN   
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxcp412'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE query 		VARCHAR(700)
DEFINE comando          VARCHAR(100)
DEFINE s_documento	VARCHAR(50)
DEFINE s_area		VARCHAR(50)
DEFINE s_cliente	VARCHAR(50)
DEFINE s_saldo		VARCHAR(50)
DEFINE s_origen_doc	VARCHAR(50)

LET vm_top	= 1
LET vm_left	= 2
LET vm_right	= 90
LET vm_bottom	= 4
LET vm_page	= 66

CALL fl_nivel_isolation()
OPEN WINDOW wf AT 3,2 WITH 15 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP, ACCEPT KEY F12
OPEN FORM frm_listado FROM '../forms/cxcf412_1'
DISPLAY FORM frm_listado

LET int_flag = 0
INITIALIZE rm_par.* TO NULL 
LET rm_par.final = TODAY


WHILE (TRUE)
	CALL control_ingreso()
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF INT_FLAG THEN
		EXIT WHILE
	END IF

	LET s_documento = ' 1 = 1'
	LET s_area      = ' 1 = 1'
	LET s_cliente   = ' 1 = 1'
	LET s_saldo     = ' 1 = 1'
	LET s_origen_doc= ' 1 = 1'

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
	
	LET query = 'SELECT z20_fecha_emi, z01_nomcli, ' || 
		' z20_origen, g03_abreviacion, z20_tipo_doc,' ||
		' z20_num_doc, z20_dividendo,' ||
		' z20_valor_cap, z20_valor_int,' ||
		' z20_saldo_cap, z20_saldo_int' ||
		' FROM cxct020, cxct001, gent003' || 
		' WHERE z20_compania = ' || vg_codcia || 
		' AND z20_localidad = '  || vg_codloc || 
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
		' ORDER BY 1'
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

LET rm_par.saldo     = 'S'
LET rm_par.origen_doc = 'M'
LET int_flag = 0
INPUT BY NAME rm_par.*  WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		RETURN

	ON KEY (F2)
		IF infield(moneda) THEN
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

		IF infield(documento) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('D')
				RETURNING coddoc, descdoc
			IF coddoc IS NOT NULL THEN
				LET rm_par.documento = coddoc
				DISPLAY coddoc 	TO documento
				DISPLAY descdoc	TO desc_documento
			END IF
			LET int_flag = 0
		END IF
 
		IF infield(area) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING codarea, nomarea
			IF codarea IS NOT NULL THEN
				LET rm_par.area = codarea
				DISPLAY codarea	TO area
				DISPLAY nomarea	TO desc_area
			END IF
			LET int_flag = 0
		END IF

		IF infield(cliente) THEN
			CALL fl_ayuda_cliente_general()
				RETURNING codcli, nomcli
			IF codcli IS NOT NULL THEN
				LET rm_par.cliente = codcli
				DISPLAY codcli	TO cliente
				DISPLAY nomcli	TO desc_cliente
			END IF
			LET int_flag = 0
		END IF

	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda)
				RETURNING r_moneda.*
			IF r_moneda.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'No existe moneda',
					'exclamation')
				NEXT FIELD moneda
			ELSE
				DISPLAY r_moneda.g13_nombre TO desc_moneda
			END IF
		ELSE
                        CALL fgl_winmessage(vg_producto,
                                'Debe especificar la moneda',
                                'exclamation')
                        NEXT FIELD moneda
		END IF

	AFTER FIELD documento
		IF rm_par.documento IS NOT NULL THEN
			CALL fl_lee_tipo_doc(rm_par.documento)
				RETURNING r_documento.*
			IF r_documento.z04_tipo_doc IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Documento no existe',
					'exclamation')
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

				CALL fgl_winmessage(vg_producto,
					'Area de negocio no existe',
					'exclamation')
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
				CALL fgl_winmessage(vg_producto, 
					'Cliente no existe',
					'exclamation')
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
                        CALL fgl_winmessage(vg_producto,
                                'Debe especificar la fecha inicial',
                                'exclamation')
                        NEXT FIELD inicial
                END IF

        AFTER INPUT
                IF rm_par.inicial IS NULL OR rm_par.final IS NULL THEN
                        CALL fgl_winmessage(vg_producto,
                                'Debe especificar la fecha inicial',
                                'exclamation')
                        NEXT FIELD inicial
                END IF
                                                                                
                IF rm_par.inicial > rm_par.final THEN
                        CALL fgl_winmessage(vg_producto,
                           'La fecha inicial debe ser menor o igual que ' ||
                           'la fecha final.',
                           'exclamation')
                        CONTINUE INPUT
                END IF
END INPUT

END FUNCTION

REPORT reporte_documento_deudor(fecha_doc, cliente, origen, area, 
				tipo_documento, num_documento, sec_documento,
				valor_capital, valor_interes,
				saldo_capital, saldo_interes)

DEFINE fecha_doc	LIKE cxct020.z20_fecha_emi
DEFINE cliente		LIKE cxct001.z01_nomcli
DEFINE origen		LIKE cxct020.z20_origen
DEFINE area	    	LIKE gent003.g03_abreviacion
DEFINE tipo_documento	LIKE cxct020.z20_tipo_doc
DEFINE num_documento	LIKE cxct020.z20_num_doc
DEFINE sec_documento	LIKE cxct020.z20_linea
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

OUTPUT
	TOP 	MARGIN vm_top
	LEFT 	MARGIN vm_left
	RIGHT 	MARGIN vm_right
	BOTTOM	MARGIN vm_bottom
	PAGE 	LENGTH vm_page

FORMAT
	PAGE HEADER
		LET modulo	= 'Módulo: Cobranzas'
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

	IF rm_par.documento IS NOT NULL THEN
		PRINT COLUMN 20, '*** Documento a Favor:  ', d_documento 
	END IF

	IF rm_par.area IS NOT NULL THEN
		PRINT COLUMN 20, '*** Area de Negocio:    ', d_area		
	END IF	

	IF rm_par.cliente IS NOT NULL THEN
		PRINT COLUMN 20, '*** Cliente:            ', d_cliente
	END IF
	
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
	END IF
	IF rm_par.origen_doc  = 'A' THEN
		LET desc_origen_doc = 'Automatico'
        	PRINT COLUMN 20, '*** Origen:             ' , desc_origen_doc
	END IF
	IF rm_par.origen_doc  = 'T' THEN
		LET desc_origen_doc = 'Todos'
        	PRINT COLUMN 20, '*** Origen:             ' , desc_origen_doc
	END IF

        SKIP 1 LINES
	
	PRINT COLUMN 01, 'Fecha impresión: ', TODAY USING 'dd-mmm-yyyy', 
			 1 SPACES, TIME,
              COLUMN 120, usuario
                                                                                
      	SKIP 1 LINES

		PRINT COLUMN 1,   'F. Dcto   ',
		      COLUMN 12,  'Cliente',          
		      COLUMN 29,  'O.',
		      COLUMN 32,  'A. Negocio',
		      COLUMN 44,  'Dcto.',     
		      COLUMN 50,  'No.  ',    		
		      COLUMN 62,  'Sec.',
		      COLUMN 67,  'Valor Capital',
		      COLUMN 83,  'Valor Interés',
		      COLUMN 99,  'Saldo Capital',
		      COLUMN 117, 'Saldo Interés'

		PRINT COLUMN 1,   '-----------',
		      COLUMN 12,  '-----------------',
		      COLUMN 29,  '---',
		      COLUMN 32,  '-------------',
		      COLUMN 44,  '------',
		      COLUMN 50,  '-----------',
		      COLUMN 62,  '-----',
		      COLUMN 67,  '-----------------',
		      COLUMN 83,  '---------------',
		      COLUMN 99,  '-----------------',
		      COLUMN 110, '--------------'
	ON EVERY ROW
		PRINT COLUMN 1,   fecha_doc,
		      COLUMN 12,  cliente[1, 15],
		      COLUMN 29,  origen,
		      COLUMN 32,  area[1, 10],
		      COLUMN 44,  tipo_documento,
		      COLUMN 50,  num_documento,
		      COLUMN 60,  sec_documento CLIPPED, 
		      COLUMN 67,  valor_capital USING '##,###,##&.##',
		      COLUMN 83,  valor_interes USING '##,###,##&.##',
		      COLUMN 99,  saldo_capital USING '##,###,##&.##',
		      COLUMN 117, saldo_interes USING '##,###,##&.##'
	ON LAST ROW
		NEED 2 LINES
		PRINT COLUMN 67,  '----------------',
		      COLUMN 83,  '----------------',
		      COLUMN 99,  '----------------',
		      COLUMN 115, '----------------'
		PRINT COLUMN 67,  SUM(valor_capital) USING '###,###,##&.##',
		      COLUMN 83,  SUM(valor_interes) USING '###,###,##&.##', 
		      COLUMN 99,  SUM(saldo_capital) USING '###,###,##&.##', 
		      COLUMN 117, SUM(saldo_interes) USING '###,###,##&.##' 
END REPORT
