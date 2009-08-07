------------------------------------------------------------------------------
-- Titulo               : cxpp411.4gl --  Listado de Documentos a Favor
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  cxcp411 base modulo compañía localidad
-- Ultima Correción     : 15-Jul-2002
-- Motivo Corrección    : Correcciones Varias (RCA) 

--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
database diteca
                                                                                
DEFINE vm_demonios      VARCHAR(12)
DEFINE d_documento      VARCHAR(20)
DEFINE d_proveedor	VARCHAR(20)

DEFINE rm_par RECORD
	moneda		CHAR(2),
	documento	CHAR(2),
	proveedor	INTEGER,
	inicial		DATE,
	final		DATE,
	saldo 		CHAR(1),
	origen_doc	CHAR(1)
END RECORD

DEFINE rm_consulta	RECORD 
	fecha_doc	LIKE cxpt021.p21_fecha_emi,
	proveedor	LIKE cxpt001.p01_nomprov,
	referencia	LIKE cxpt021.p21_referencia,
	origen		LIKE cxpt021.p21_origen,
	tipo_documento	LIKE cxpt021.p21_tipo_doc,
	num_documento	LIKE cxpt021.p21_num_doc,
	valor_original	LIKE cxpt021.p21_valor,
	saldo_actual 	LIKE cxpt021.p21_saldo
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
LET vg_proceso = 'cxpp411'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE query 		VARCHAR(700)
DEFINE comando          VARCHAR(100)
DEFINE estado		CHAR(1)
DEFINE s_documento	VARCHAR(50)
DEFINE s_proveedor	VARCHAR(50)
DEFINE s_saldo		VARCHAR(50)
DEFINE s_origen_doc		VARCHAR(50)


LET vm_top	= 1
LET vm_left	= 2
LET vm_right	= 90
LET vm_bottom	= 4
LET vm_page	= 66

CALL fl_nivel_isolation()
OPEN WINDOW wf AT 3,2 WITH 14 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP, ACCEPT KEY F12
OPEN FORM frm_listado FROM '../forms/cxpf411_1'
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
	LET s_proveedor = ' 1 = 1'
	LET s_saldo     = ' 1 = 1'
	LET s_origen_doc= ' 1 = 1'

	IF rm_par.documento IS NOT NULL THEN
		LET s_documento = ' p21_tipo_doc = "' || rm_par.documento || '"'  
	END IF
	
	IF rm_par.proveedor IS NOT NULL THEN
		LET s_proveedor = ' p21_codprov = ' || rm_par.proveedor  
	END IF

        IF rm_par.saldo IS NOT NULL THEN
                IF rm_par.saldo = 'S' THEN
                        LET s_saldo = ' p21_saldo > 0 '
                ELSE
                        LET s_saldo = ' p21_saldo >= 0 '
                END IF
        ELSE
                LET s_saldo = ' p21_saldo > 0 '
        END IF
        IF rm_par.origen_doc IS NOT NULL THEN
                IF rm_par.origen_doc = 'M' THEN
                        LET s_origen_doc = " p21_origen = 'M'"
                        display rm_par.origen_doc
                END IF
                IF rm_par.origen_doc = 'A' THEN
                        LET s_origen_doc = " p21_origen = 'A'"
                        display rm_par.origen_doc
                END IF
                IF rm_par.origen_doc = 'T' THEN
			LET s_origen_doc = " p21_origen IN ('A','M') "
                        display rm_par.origen_doc
                END IF
        END IF
	
	LET query = 'SELECT p21_fecha_emi, p01_nomprov, p21_referencia,' || 
		' p21_origen, p21_tipo_doc, p21_num_doc,' ||
		' p21_valor, p21_saldo FROM cxpt021, cxpt001' || 
		' WHERE p21_compania = ' || vg_codcia || 
		' AND p21_localidad = '  || vg_codloc || 
		' AND p21_moneda = "' || rm_par.moneda ||
		'" AND p21_fecha_emi BETWEEN "' || rm_par.inicial ||
		'" AND "' || rm_par.final || '"' ||
		' AND ' || s_documento || 
		' AND ' || s_proveedor ||
		' AND ' || s_saldo ||
		' AND ' || s_origen_doc ||
		' AND p01_codprov = p21_codprov' ||
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
		START REPORT reporte_documento_favor TO PIPE comando
		FOREACH q_rep INTO rm_consulta.*
			OUTPUT TO REPORT reporte_documento_favor(rm_consulta.*)
		END FOREACH
		FINISH REPORT reporte_documento_favor
	END IF
END WHILE

END FUNCTION



FUNCTION control_ingreso()
DEFINE	r_moneda	RECORD LIKE gent013.*
DEFINE  r_documento 	RECORD LIKE cxct004.*
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
			CALL fl_ayuda_tipo_documento_tesoreria('F')
				RETURNING coddoc, descdoc
			IF coddoc IS NOT NULL THEN
				LET rm_par.documento = coddoc
				DISPLAY coddoc 	TO documento
				DISPLAY descdoc	TO desc_documento
			END IF
			LET int_flag = 0
		END IF
 
		IF infield(proveedor) THEN
			CALL fl_ayuda_proveedores()
				RETURNING codprov, nomprov
			IF codprov IS NOT NULL THEN
				LET rm_par.proveedor = codprov
				DISPLAY codprov	TO proveedor
				DISPLAY nomprov	TO desc_proveedor
			END IF
			LET int_flag = 0
		END IF

	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda)
				RETURNING r_moneda.*
			IF r_moneda.g13_moneda IS NULL THEN
				CALL fgl_winmessage('PHOBOS',
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
			CALL fl_lee_tipo_doc_tesoreria(rm_par.documento)
				RETURNING r_documento.*
			IF r_documento.z04_tipo_doc IS NULL THEN
				CALL fgl_winmessage('PHOBOS',
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
		
	AFTER FIELD proveedor
		 IF rm_par.proveedor IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_par.proveedor)
				RETURNING r_proveedor.*
			IF r_proveedor.p01_codprov IS NULL THEN
				CALL fgl_winmessage('PHOBOS',
					'Area de negocio no existe',
					'exclamation')
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
                        CALL fgl_winmessage('PHOBOS',
                           'La fecha inicial debe ser menor o igual que ' ||
                           'la fecha final.',
                           'exclamation')
                        CONTINUE INPUT
                END IF

		
	
END INPUT

END FUNCTION

REPORT reporte_documento_favor(fecha_doc, proveedor, referencia, 
				origen, tipo_documento, 
				num_documento, valor_original,
				saldo_actual)

DEFINE fecha_doc	LIKE cxpt021.p21_fecha_emi
DEFINE proveedor	LIKE cxpt001.p01_nomprov
DEFINE referencia    	LIKE cxpt021.p21_referencia
DEFINE origen		LIKE cxpt021.p21_origen
DEFINE tipo_documento	LIKE cxpt021.p21_tipo_doc
DEFINE num_documento	LIKE cxpt021.p21_num_doc
DEFINE valor_original	LIKE cxpt021.p21_valor
DEFINE saldo_actual	LIKE cxpt021.p21_saldo
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo           VARCHAR(80)
DEFINE modulo           VARCHAR(40)
DEFINE i,long           SMALLINT
DEFINE descr_estado	VARCHAR(9)		
DEFINE columna		SMALLINT
DEFINE desc_saldo	CHAR(25)
DEFINE desc_origen_doc	CHAR(25)

OUTPUT
	TOP 	MARGIN vm_top
	LEFT 	MARGIN vm_left
	RIGHT 	MARGIN vm_right
	BOTTOM	MARGIN vm_bottom
	PAGE 	LENGTH vm_page

FORMAT
	PAGE HEADER
		LET modulo	= 'Módulo: Tesorería'
		LET long	= LENGTH(modulo)
		
		CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
		CALL fl_justifica_titulo('C', 
					'LISTADO DE DOCUMENTOS A FAVOR', 
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

	IF rm_par.proveedor IS NOT NULL THEN
		PRINT COLUMN 20, '*** Proveedor:        ', d_proveedor		
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
	
	PRINT COLUMN 01, 'Fecha impresión: ', TODAY USING 'dd-mm-yyyy', 
			 1 SPACES, TIME,
              COLUMN 120, usuario
                                                                                
      	SKIP 1 LINES

		PRINT COLUMN 1,   'Fecha Doc.',
		      COLUMN 12,  'Proveedor',
		      COLUMN 35,  'Referencia',
		      COLUMN 63,  'Origen',
		      COLUMN 70,  'Tipo Doc.',
		      COLUMN 81,  'No. Doc.',
		      COLUMN 95,  'Valor Original',		
		      COLUMN 115, 'Saldo Actual'

		PRINT COLUMN 1,   '-----------',
		      COLUMN 12,  '-----------------------',
		      COLUMN 35,  '----------------------------',
		      COLUMN 63,  '-------',
		      COLUMN 70,  '-----------',
		      COLUMN 81,  '--------------',
		      COLUMN 95,  '----------------------',
		      COLUMN 115, '-------------'
	
	ON EVERY ROW
		PRINT COLUMN 1,   fecha_doc,
		      COLUMN 12,  proveedor[1,20],
		      COLUMN 35,  referencia[1, 25],
		      COLUMN 63,  origen,
		      COLUMN 70,  tipo_documento,
		      COLUMN 81,  num_documento, 
		      COLUMN 96,  valor_original USING '##,###,##&.##',
		      COLUMN 115, saldo_actual USING '##,###,##&.##'

	ON LAST ROW
		NEED 3 LINES
		PRINT COLUMN 96, '--------------',
		      COLUMN 115,'-------------'
		PRINT COLUMN 95,  SUM(valor_original) USING '###,###,##&.##',
		      COLUMN 114, SUM(saldo_actual) USING '###,###,##&.##' 
END REPORT
