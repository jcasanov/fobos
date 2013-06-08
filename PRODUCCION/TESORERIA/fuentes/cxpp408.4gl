------------------------------------------------------------------------------
-- Titulo               : cxpp408.4gl --  Listado de Transacciones
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  cxpp413 base modulo compañía localidad
-- Ultima Correción     : 15-jul-2002
-- Motivo Corrección    : Correcciones Varias (RCA) 

--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios      VARCHAR(12)
DEFINE d_transaccion    VARCHAR(20)
DEFINE d_proveedor	VARCHAR(20)
DEFINE rm_par RECORD
	moneda		CHAR(2),
	transaccion	CHAR(2),
	proveedor	SMALLINT,
	inicial		DATE,
	final		DATE,
	origen_doc	CHAR(1)
END RECORD

DEFINE rm_consulta	RECORD 
	fecha_doc		LIKE cxpt022.p22_fecha_emi,
	proveedor		LIKE cxpt001.p01_nomprov,
	origen			LIKE cxpt022.p22_origen,
	tipo_transac		LIKE cxpt022.p22_tipo_trn,
	numero_transac		LIKE cxpt022.p22_num_trn,
	dcto_aplico		LIKE cxpt023.p23_tipo_doc,
	num_dcto_aplico		LIKE cxpt023.p23_num_doc,
	sec_dcto_aplico		LIKE cxpt023.p23_div_doc,
	dcto_aplicado		LIKE cxpt023.p23_tipo_favor,
	num_dcto_aplicado 	LIKE cxpt023.p23_doc_favor,
	valor_capital		LIKE cxpt023.p23_valor_cap,
	valor_interes		LIKE cxpt023.p23_valor_int
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
LET vg_proceso = 'cxpp408'
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
DEFINE estado		CHAR(1)
DEFINE s_transaccion	VARCHAR(50)
DEFINE s_proveedor	VARCHAR(50)
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
	OPEN FORM frm_listado FROM '../forms/cxpf408_1'
ELSE
	OPEN FORM frm_listado FROM '../forms/cxpf408_1c'
END IF
DISPLAY FORM frm_listado

LET int_flag = 0
INITIALIZE rm_par.* TO NULL 
LET rm_par.moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO desc_moneda
LET rm_par.inicial = TODAY
LET rm_par.final = TODAY

WHILE (TRUE)
	CALL control_ingreso()
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF INT_FLAG THEN
		CONTINUE WHILE
	END IF

	LET s_transaccion = ' 1 = 1'
	LET s_proveedor   = ' 1 = 1'
	LET s_origen_doc  = ' 1 = 1'

	IF rm_par.transaccion IS NOT NULL THEN
		LET s_transaccion = ' p22_tipo_trn = "' || rm_par.transaccion ||							 '"'  
	END IF
	
	IF rm_par.proveedor IS NOT NULL THEN
		LET s_proveedor = ' p22_codprov = ' || rm_par.proveedor 
	END IF
        IF rm_par.origen_doc IS NOT NULL THEN
                IF rm_par.origen_doc = 'M' THEN
                        LET s_origen_doc = " p22_origen = 'M'"
                END IF
                IF rm_par.origen_doc = 'A' THEN
                        LET s_origen_doc = " p22_origen = 'A'"
                END IF
                IF rm_par.origen_doc = 'T' THEN
                        LET s_origen_doc = ' 1 = 1 '
                END IF
        END IF

	LET query = 'SELECT p22_fecha_emi, p01_nomprov, ' || 
		' p22_origen, p22_tipo_trn, p22_num_trn,' ||
		' p23_tipo_doc, p23_num_doc, p23_div_doc, ' ||
		' p23_tipo_favor, p23_doc_favor, ' ||
		' p23_valor_cap, p23_valor_int ' || 
		' FROM cxpt022, cxpt023, cxpt001' || 
		' WHERE p22_compania = ' || vg_codcia || 
		' AND p22_localidad = '  || vg_codloc || 
	        ' AND ' || s_proveedor ||
		' AND p22_moneda = "' || rm_par.moneda ||
		'" AND p22_fecha_emi BETWEEN "' || rm_par.inicial ||
		'" AND "' || rm_par.final || '"' ||
		' AND ' || s_transaccion || 
		' AND ' || s_origen_doc || 
		' AND p23_compania = p22_compania' ||
		' AND p23_localidad = p22_localidad' ||
		' AND p23_codprov = p22_codprov' ||
		' AND p23_tipo_trn = p22_tipo_trn' ||
		' AND p23_num_trn = p22_num_trn' ||
		' AND p01_codprov = p22_codprov' ||
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
DEFINE  r_proveedor	RECORD LIKE cxpt001.*
DEFINE  r_transaccion 	RECORD LIKE cxpt004.*
DEFINE  codmon		LIKE gent013.g13_moneda
DEFINE  descmon		LIKE gent013.g13_nombre
DEFINE  codprov		LIKE cxpt001.p01_codprov
DEFINE  nomprov		LIKE cxpt001.p01_nomprov
DEFINE  codtrn		LIKE gent021.g21_cod_tran
DEFINE  desctrn		LIKE gent021.g21_nombre
DEFINE  decimales	LIKE gent013.g13_decimales

LET rm_par.origen_doc = 'M'
DISPLAY BY NAME rm_par.*
IF vg_gui = 0 THEN
	CALL muestra_origen(rm_par.origen_doc)
END IF
LET int_flag = 0
INPUT BY NAME rm_par.moneda, rm_par.transaccion, rm_par.proveedor,
	rm_par.inicial, rm_par.final, rm_par.origen_doc
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
			END IF
				NEXT FIELD moneda
		END IF
		IF INFIELD(transaccion) THEN
			CALL fl_ayuda_tipo_documento_tesoreria('T')
				RETURNING codtrn, desctrn
			IF codtrn IS NOT NULL THEN
				LET rm_par.transaccion = codtrn
				DISPLAY codtrn 	TO transaccion
				DISPLAY desctrn	TO desc_transaccion
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
                        --CALL fgl_winmessage(vg_producto,'Debe especificar la moneda','exclamation')
			CALL fl_mostrar_mensaje('Debe especificar la moneda','exclamation')
                        NEXT FIELD moneda
		END IF
	AFTER FIELD transaccion
		IF rm_par.transaccion IS NOT NULL THEN
			CALL fl_lee_tipo_doc_tesoreria(rm_par.transaccion)
				RETURNING r_transaccion.*
			IF r_transaccion.p04_tipo_doc IS NULL THEN
				--CALL fgl_winmessage(vg_prodcuto,'Tipo de Transacción no existe','exclamation')
				CALL fl_mostrar_mensaje('Tipo de Transacción no existe.','exclamation')
				NEXT FIELD transaccion
			ELSE
				LET d_transaccion = r_transaccion.p04_nombre
				DISPLAY r_transaccion.p04_nombre 	
					TO desc_transaccion
			END IF
		ELSE
			CLEAR desc_transaccion
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
                        --CALL fgl_winmessage(vg_producto,'Debe especificar la fecha inicial','exclamation')
			CALL fl_mostrar_mensaje('Debe especificar la fecha inicial','exclamation')
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
	AFTER INPUT  
		IF rm_par.inicial > rm_par.final THEN
			--CALL fgl_winmessage(vg_producto,'La fecha inicial debe ser menor o igual que la fecha final.','exclamation')
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual que la fecha final.','exclamation')
			NEXT FIELD inicial
		END IF
END INPUT

END FUNCTION



REPORT reporte_transaccion_documentos(fecha_doc, proveedor, origen, 
				tipo_transac, numero_transac,
				dcto_aplico, num_dcto_aplico, sec_dcto_aplico,
				dcto_aplicado, num_dcto_aplicado, 
				valor_capital, valor_interes)
	
DEFINE	fecha_doc		LIKE cxpt022.p22_fecha_emi
DEFINE	proveedor		LIKE cxpt001.p01_nomprov
DEFINE	origen			LIKE cxpt020.p20_origen
DEFINE	tipo_transac		LIKE cxpt022.p22_tipo_trn
DEFINE	numero_transac		LIKE cxpt022.p22_num_trn
DEFINE	dcto_aplico		LIKE cxpt023.p23_tipo_doc
DEFINE	num_dcto_aplico		LIKE cxpt023.p23_num_doc
DEFINE	sec_dcto_aplico		LIKE cxpt023.p23_div_doc
DEFINE	dcto_aplicado		LIKE cxpt023.p23_tipo_favor
DEFINE	num_dcto_aplicado 	LIKE cxpt023.p23_doc_favor
DEFINE	valor_capital		LIKE cxpt023.p23_valor_cap
DEFINE	valor_interes		LIKE cxpt023.p23_valor_int
DEFINE 	titulo          	VARCHAR(80)
DEFINE 	modulo           	VARCHAR(40)
DEFINE 	i,long           	SMALLINT
DEFINE 	descr_estado		VARCHAR(9)		
DEFINE 	columna			SMALLINT
DEFINE  usuario			VARCHAR(15)
DEFINE  desc_tipo		char(30)
DEFINE  desc_origen_doc		char(30)

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

	--#IF rm_par.transaccion IS NOT NULL THEN
		PRINT COLUMN 20, '*** Tipo de Transacción: ', d_transaccion 
	--#END IF

	--#IF rm_par.proveedor IS NOT NULL THEN
		PRINT COLUMN 20, '*** Proveedor:           ', d_proveedor
	--#END IF
	
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
	ELSE
	        IF rm_par.origen_doc  = 'A' THEN
        	        LET desc_origen_doc = 'Automatico'
                	PRINT COLUMN 20, '*** Origen:              ' , desc_origen_doc
		ELSE
		        --#IF rm_par.origen_doc  = 'T' THEN
                		LET desc_origen_doc = 'Todos'
		                PRINT COLUMN 20, '*** Origen:              ' , desc_origen_doc
		        --#END IF
	        END IF
        END IF

	SKIP 1 LINES
	
	PRINT COLUMN 01, 'Fecha impresión: ', TODAY USING 'dd-mm-yyyy', 
			 1 SPACES, TIME,
              COLUMN 120, usuario
                                                                                
      	SKIP 1 LINES

		PRINT COLUMN 1,   'F. Doc.  ',
		      COLUMN 12,  'Proveedor',
		      COLUMN 41,  'O.',
		      COLUMN 44,  'T.',
		      COLUMN 47,  'No. Tran.',
		      COLUMN 59,  'Aplicó',
		      COLUMN 66,  'No. Doc.',		
		      COLUMN 82,  'Sec.',
		      COLUMN 90,  'Aplicado',
		      COLUMN 99,  'No. Doc.',
		      COLUMN 111, 'Valor Cap.',
		      COLUMN 123, 'Valor Int.'
 
		PRINT COLUMN 1,   '-----------',
		      COLUMN 12,  '-----------------------------',
		      COLUMN 41,  '---',
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
		      COLUMN 12,  proveedor[1,27],
		      COLUMN 41,  origen,
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
		NEED 3 LINES
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
