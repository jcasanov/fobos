------------------------------------------------------------------------------
-- Titulo               : cxcp413.4gl --  Listado de Transacciones
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  cxcp413 base modulo compañía localidad
-- Ultima Correción     : ?
-- Motivo Corrección    : ? 

--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
database diteca
                                                                                
DEFINE vg_demonios      VARCHAR(12)
DEFINE d_transaccion    VARCHAR(20)
DEFINE d_area 		VARCHAR(20)
DEFINE d_cliente	VARCHAR(20)

DEFINE rm_par RECORD
	moneda		CHAR(2),
	transaccion	CHAR(2),
	area		SMALLINT,
	cliente		SMALLINT,
	inicial		DATE,
	final		DATE,
	origen_doc	CHAR(1)
END RECORD

DEFINE rm_consulta	RECORD 
	fecha_doc		LIKE cxct022.z22_fecha_emi,
	cliente			LIKE cxct001.z01_nomcli,
	origen			LIKE cxct020.z20_origen,
	area			LIKE gent003.g03_abreviacion,
	tipo_transac		LIKE cxct022.z22_tipo_trn,
	numero_transac		LIKE cxct022.z22_num_trn,
	dcto_aplico		LIKE cxct023.z23_tipo_doc,
	num_dcto_aplico		LIKE cxct023.z23_num_doc,
	sec_dcto_aplico		LIKE cxct023.z23_div_doc,
	dcto_aplicado		LIKE cxct023.z23_tipo_favor,
	num_dcto_aplicado 	LIKE cxct023.z23_doc_favor,
	valor_capital		LIKE cxct023.z23_valor_cap,
	valor_interes		LIKE cxct023.z23_valor_int
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
LET vg_proceso = 'cxcp413'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE query 		VARCHAR(800)
DEFINE comando          VARCHAR(100)
DEFINE estado		CHAR(1)
DEFINE s_transaccion	VARCHAR(50)
DEFINE s_area		VARCHAR(50)
DEFINE s_cliente	VARCHAR(50)
DEFINE s_origen_doc	VARCHAR(50)


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
OPEN FORM frm_listado FROM '../forms/cxcf413_1'
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

	LET s_transaccion = ' 1 = 1'
	LET s_area        = ' 1 = 1'
	LET s_cliente     = ' 1 = 1'
	LET s_origen_doc  = ' 1 = 1'

	IF rm_par.transaccion IS NOT NULL THEN
		LET s_transaccion = ' z22_tipo_trn = "' || rm_par.transaccion ||							 '"'  
	END IF
	
	IF rm_par.area IS NOT NULL THEN
		LET s_area = ' z22_areaneg = ' || rm_par.area  
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
	LET query = 'SELECT z22_fecha_emi, z01_nomcli, ' || 
		' z22_origen, g03_abreviacion, z22_tipo_trn, z22_num_trn,' ||
		' z23_tipo_doc, z23_num_doc, z23_div_doc, ' ||
		' z23_tipo_favor, z23_doc_favor, ' ||
		' z23_valor_cap, z23_valor_int ' || 
		' FROM cxct022, cxct023, cxct001, gent003' || 
		' WHERE z22_compania = ' || vg_codcia || 
		' AND z22_localidad = '  || vg_codloc || 
		' AND z22_moneda = "' || rm_par.moneda ||
		'" AND z22_fecha_emi BETWEEN "' || rm_par.inicial ||
		'" AND "' || rm_par.final || '"' ||
		' AND ' || s_transaccion || 
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
		CLOSE q_rep
		START REPORT reporte_transaccion_documentos TO PIPE comando
		FOREACH q_rep INTO rm_consulta.*
			OUTPUT TO REPORT 
				reporte_transaccion_documentos(rm_consulta.*)
		END FOREACH
		FINISH REPORT reporte_transaccion_documentos
	END IF
END WHILE

END FUNCTION



FUNCTION control_ingreso()
DEFINE	r_moneda	RECORD LIKE gent013.*
DEFINE  r_cliente	RECORD LIKE cxct001.*
DEFINE  r_transaccion 	RECORD LIKE cxct004.*
DEFINE  r_area		RECORD LIKE gent003.*
DEFINE  codmon		LIKE gent013.g13_moneda
DEFINE  descmon		LIKE gent013.g13_nombre
DEFINE  codcli		LIKE cxct001.z01_codcli
DEFINE  nomcli		LIKE cxct001.z01_nomcli
DEFINE  codtrn		LIKE gent021.g21_cod_tran
DEFINE  desctrn		LIKE gent021.g21_nombre
DEFINE  codarea		LIKE gent003.g03_areaneg
DEFINE  nomarea		LIKE gent003.g03_nombre 
DEFINE  decimales	LIKE gent013.g13_decimales

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
			END IF
				NEXT FIELD moneda
		END IF

		IF infield(transaccion) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('T')
				RETURNING codtrn, desctrn
			IF codtrn IS NOT NULL THEN
				LET rm_par.transaccion = codtrn
				DISPLAY codtrn 	TO transaccion
				DISPLAY desctrn	TO desc_transaccion
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

	AFTER FIELD transaccion
		IF rm_par.transaccion IS NOT NULL THEN
			CALL fl_lee_tipo_doc(rm_par.transaccion)
				RETURNING r_transaccion.*
			IF r_transaccion.z04_tipo_doc IS NULL THEN
				CALL fgl_winmessage('PHOBOS',
					'Tipo de Transacción no existe',
					'exclamation')
				NEXT FIELD transaccion
			ELSE
				LET d_transaccion = r_transaccion.z04_nombre
				DISPLAY r_transaccion.z04_nombre 	
					TO desc_transaccion
			END IF
		ELSE
			CLEAR desc_transaccion
		END IF
		
	AFTER FIELD area
		 IF rm_par.area IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia, rm_par.area)
				RETURNING r_area.*
			IF r_area.g03_areaneg IS NULL THEN

				CALL fgl_winmessage('PHOBOS',
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
				CALL fgl_winmessage('PHOBOS', 
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
                        CALL fgl_winmessage('PHOBOS',
                           'La fecha inicial debe ser menor o igual que ' ||
                           'la fecha final.',
                           'exclamation')
                        CONTINUE INPUT
                END IF
END INPUT

END FUNCTION

REPORT reporte_transaccion_documentos(fecha_doc, cliente, origen, 
				area, tipo_transac, numero_transac,
				dcto_aplico, num_dcto_aplico, sec_dcto_aplico,
				dcto_aplicado, num_dcto_aplicado, 
				valor_capital, valor_interes)
	
DEFINE	fecha_doc		LIKE cxct022.z22_fecha_emi
DEFINE	cliente			LIKE cxct001.z01_nomcli
DEFINE	origen			LIKE cxct020.z20_origen
DEFINE	area			LIKE gent003.g03_abreviacion
DEFINE	tipo_transac		LIKE cxct022.z22_tipo_trn
DEFINE	numero_transac		LIKE cxct022.z22_num_trn
DEFINE	dcto_aplico		LIKE cxct023.z23_tipo_doc
DEFINE	num_dcto_aplico		LIKE cxct023.z23_num_doc
DEFINE	sec_dcto_aplico		LIKE cxct023.z23_div_doc
DEFINE	dcto_aplicado		LIKE cxct023.z23_tipo_favor
DEFINE	num_dcto_aplicado 	LIKE cxct023.z23_doc_favor
DEFINE	valor_capital		LIKE cxct023.z23_valor_cap
DEFINE	valor_interes		LIKE cxct023.z23_valor_int
DEFINE 	titulo          	VARCHAR(80)
DEFINE 	modulo           	VARCHAR(40)
DEFINE 	i,long           	SMALLINT
DEFINE 	descr_estado		VARCHAR(9)		
DEFINE 	columna			SMALLINT
DEFINE  usuario			VARCHAR(15)
DEFINE  desc_tipo		CHAR(30)
DEFINE  desc_origen_doc		CHAR(30)

OUTPUT
	TOP 	MARGIN vm_top
	LEFT 	MARGIN vm_left
	RIGHT 	MARGIN vm_right
	BOTTOM	MARGIN vm_bottom
	PAGE 	LENGTH vm_page

FORMAT
	PAGE HEADER
	print 'E';
	print '&l26A';	-- Indica que voy a trabajar con hojas A4

		LET modulo	= 'Módulo: Cobranzas'
		LET long	= LENGTH(modulo)
		
		CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
		CALL fl_justifica_titulo('C', 
					'LISTADO DE TRANSACCIONES', 
					'52')
		RETURNING titulo

        	PRINT COLUMN 1,   rg_cia.g01_razonsocial,
              	      COLUMN 120, 'Página: ', PAGENO USING "&&&"

        	PRINT COLUMN 1,   modulo  CLIPPED,
		      COLUMN 44,  titulo,
                      COLUMN 109, UPSHIFT(vg_proceso)

      	SKIP 1 LINES
	
	PRINT COLUMN 20, '*** Moneda:              ', rm_par.moneda

	IF rm_par.transaccion IS NOT NULL THEN
		PRINT COLUMN 20, '*** Tipo de Transacción: ', d_transaccion 
	END IF

	IF rm_par.area IS NOT NULL THEN
		PRINT COLUMN 20, '*** Area de Negocio:     ', d_area		
	END IF	

	IF rm_par.cliente IS NOT NULL THEN
		PRINT COLUMN 20, '*** Cliente:             ', d_cliente
	END IF
	
	PRINT COLUMN 20, '*** Fecha Inicial:       ', rm_par.inicial USING 'dd-mm-yyyy'
	PRINT COLUMN 20, '*** Fecha Final:         ', rm_par.final USING 'dd-mm-yyyy'

	IF rm_par.transaccion IS NULL THEN
		LET desc_tipo = 'Todos'   	
		PRINT COLUMN 20, '*** Tipo:                ', desc_tipo
	ELSE
		LET desc_tipo = rm_par.transaccion
		PRINT COLUMN 20, '*** Tipo:                ', desc_tipo	
	END IF

        IF rm_par.origen_doc  = 'M' THEN
                LET desc_origen_doc = 'Manual'
                PRINT COLUMN 20, '*** Origen:              ' , desc_origen_doc
        END IF
        IF rm_par.origen_doc  = 'A' THEN
                LET desc_origen_doc = 'Automatico'
                PRINT COLUMN 20, '*** Origen:              ' , desc_origen_doc
        END IF
        IF rm_par.origen_doc  = 'T' THEN
                LET desc_origen_doc = 'Todos'
                PRINT COLUMN 20, '*** Origen:              ' , desc_origen_doc
        END IF

	--SKIP 1 LINES
	
	print '&k2S' 		-- Letra condensada
	PRINT COLUMN 01, 'Fecha impresión: ', TODAY USING 'dd-mm-yyyy', 
			 1 SPACES, TIME,
              COLUMN 120, usuario
                                                                                
      	SKIP 1 LINES

		PRINT COLUMN 1,   'F. Doc.  ',
		      COLUMN 12,  'Cliente',
		      COLUMN 29,  'O.',
		      COLUMN 32,  'Area',
		      COLUMN 44,  'Dcto',
		      COLUMN 50,  'No.Tran.',
		      COLUMN 59,  'Aplicó',
		      COLUMN 66,  'No. Doc.',		
		      COLUMN 78,  'Sec.',
		      COLUMN 90,  'Aplicado',
		      COLUMN 99,  'No. Doc.',
		      COLUMN 111, 'Valor Cap.',
		      COLUMN 123, 'Valor Int.'
 
		PRINT COLUMN 1,   '-----------',
		      COLUMN 12,  '-----------------',
		      COLUMN 29,  '---',
		      COLUMN 32,  '------------',
		      COLUMN 44,  '---',
		      COLUMN 47,  '------------',
		      COLUMN 59,  '-------',
		      COLUMN 66,  '------------',
		      COLUMN 78,  '------------',
		      COLUMN 90,  '---------',
		      COLUMN 99,  '------------',
		      COLUMN 111, '------------',
		      COLUMN 123, '----------'
	
	ON EVERY ROW
		PRINT COLUMN 1,   fecha_doc,
		      COLUMN 12,  cliente[1,15],
		      COLUMN 29,  origen,
		      COLUMN 32,  area,
		      COLUMN 44,  tipo_transac,
		      COLUMN 47,  numero_transac,
		      COLUMN 59,  dcto_aplico,
                      COLUMN 66,  num_dcto_aplico,
		      COLUMN 78,  sec_dcto_aplico,
		      COLUMN 90,  dcto_aplicado,
		      COLUMN 99,  num_dcto_aplicado,
		      COLUMN 111, valor_capital USING '-,---,--&.##', 
		      COLUMN 123, valor_interes	USING '---,--&.##'  

	ON LAST ROW
		NEED 2 LINES
		PRINT COLUMN 111, '------------',
		      COLUMN 123, '----------'
		PRINT COLUMN 111, SUM(valor_capital) USING '-,---,--&.##',
		      COLUMN 123, SUM(valor_interes) USING '---,--&.##' 
END REPORT
