--------------------------------------------------------------------------------
-- Titulo              : cxpp410.4gl --  Listado de Retenciones Proveedores
-- Elaboración         : 01-Abr-2002
-- Autor               : RRM
-- Formato de Ejecución: fglrun cxcp410 base modulo compañía localidad
-- Ultima Correción    : 07-Abr-2006 (NPC)
-- Motivo Corrección   : Varias correcciones
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_par		RECORD
				moneda		LIKE gent013.g13_moneda,
				inicial		DATE,
				final		DATE,
				proveedor	LIKE cxpt001.p01_codprov,
				tipo_oc		LIKE ordt001.c01_tipo_orden,
				tipo_porc	LIKE ordt002.c02_tipo_ret,
				valor_porc	LIKE ordt002.c02_porcentaje
			END RECORD
DEFINE rm_consulta	RECORD 
				proveedor	LIKE cxpt001.p01_nomprov,
				fecha_retencion	LIKE cxpt020.p20_fecha_emi,
				num_retencion	LIKE cxpt028.p28_num_ret,
				num_factura     LIKE cxpt028.p28_num_doc,
				fecha_factura	LIKE cxpt020.p20_fecha_emi,
				tipo_retencion	LIKE cxpt028.p28_tipo_doc,
				moneda		LIKE cxpt027.p27_moneda,
				valor_base	LIKE cxpt028.p28_valor_base,
				porc_retencion	LIKE cxpt028.p28_porcentaje,
				valor_retencion LIKE cxpt028.p28_valor_ret
			END RECORD
DEFINE vm_page 		SMALLINT
DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CALL startlog('../logs/cxpp410.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso  = 'cxpp410'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE query 		CHAR(2500)
DEFINE comando          VARCHAR(100)
DEFINE estado		CHAR(1)
DEFINE tabla		VARCHAR(10)
DEFINE string		VARCHAR(100)
DEFINE expr_ret		VARCHAR(200)
DEFINE expr_oc		CHAR(500)
DEFINE resp		CHAR(6)
DEFINE registro		CHAR(400)
DEFINE enter		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_r19		RECORD LIKE rept019.*

LET vm_top	= 1
LET vm_left	= 2
LET vm_right	= 90
LET vm_bottom	= 4
LET vm_page	= 66

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 12
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
	OPEN FORM frm_listado FROM '../forms/cxpf410_1'
ELSE
	OPEN FORM frm_listado FROM '../forms/cxpf410_1c'
END IF
DISPLAY FORM frm_listado

LET enter    = 13
LET int_flag = 0
INITIALIZE rm_par.* TO NULL 
LET rm_par.moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO desc_moneda
LET rm_par.inicial = TODAY
LET rm_par.final   = TODAY

WHILE (TRUE)
	CALL control_ingreso()
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF

	CALL fl_hacer_pregunta('Desea generar también un archivo de texto ?',
				'No')
		RETURNING resp

	LET int_flag = 0
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF

	LET string = NULL
	IF rm_par.proveedor IS NOT NULL THEN
		LET string = ' AND p27_codprov = ' || rm_par.proveedor
	END IF
	LET expr_ret = NULL
	IF rm_par.tipo_porc IS NOT NULL THEN
		LET expr_ret = '   AND p28_tipo_ret     = "',
							rm_par.tipo_porc, '"',
				'   AND p28_porcentaje   = ', rm_par.valor_porc
	END IF
	LET tabla   = NULL
	LET expr_oc = NULL
	IF rm_par.tipo_oc IS NOT NULL THEN
		LET tabla   = ', ordt010'
		LET expr_oc = ' WHERE c10_compania     = p20_compania ',
				'   AND c10_localidad    = p20_localidad ',
				'   AND c10_numero_oc    = p20_numero_oc ',
				'   AND c10_codprov      = p20_codprov ',
				'   AND c10_tipo_orden   = ', rm_par.tipo_oc,
				'   AND c10_estado       = "C" ',
				'   AND c10_fecha_fact   = p20_fecha_emi '
	END IF
	LET query = 'SELECT p01_nomprov, p27_fecing, p28_num_ret,',
			' p28_num_doc, p20_fecha_emi, p28_tipo_ret,',
			' p27_moneda, p28_valor_base, p28_porcentaje,',
			' p28_valor_ret, p20_compania, p20_localidad, ',
			' p20_numero_oc, p20_codprov ',
			' FROM cxpt027, cxpt028, cxpt020, cxpt001',
			' WHERE p27_compania     = ', vg_codcia,
			'   AND p27_localidad    = ', vg_codloc,
			'   AND p27_estado       = "A" ',
			'   AND p27_moneda       = "', rm_par.moneda, '"',
			string CLIPPED,
			'   AND DATE(p27_fecing) BETWEEN "', rm_par.inicial,
						  '" AND "', rm_par.final, '"',
			'   AND p28_compania     = p27_compania ',
			'   AND p28_localidad    = p27_localidad ',
			'   AND p28_num_ret      = p27_num_ret ',
			'   AND p28_codprov      = p27_codprov ',
			expr_ret CLIPPED,
			'   AND p20_compania     = p28_compania ',
			'   AND p20_localidad    = p28_localidad ',
			'   AND p20_codprov      = p28_codprov ',
			'   AND p20_tipo_doc     = p28_tipo_doc ',
			'   AND p20_num_doc      = p28_num_doc ',
			'   AND p20_dividendo    = p28_dividendo ',
			'   AND p01_codprov      = p20_codprov ',
			' INTO TEMP tmp_ret '
	PREPARE gen_tmp FROM query
	EXECUTE gen_tmp
	LET query = 'SELECT p01_nomprov, p27_fecing, p28_num_ret,',
			' p28_num_doc, p20_fecha_emi, p28_tipo_ret,',
			' p27_moneda, p28_valor_base, p28_porcentaje,',
			' p28_valor_ret ',
			' FROM tmp_ret', tabla CLIPPED,
			expr_oc CLIPPED,
			' ORDER BY 2, 3, 1'
	PREPARE expresion FROM query
	DECLARE q_rep CURSOR FOR expresion
	OPEN q_rep
	FETCH q_rep INTO rm_consulta.*
	IF STATUS = NOTFOUND THEN
		CLOSE q_rep
		CALL fl_mensaje_consulta_sin_registros()
		DROP TABLE tmp_ret
		CONTINUE WHILE
	END IF
	CLOSE q_rep
	START REPORT reporte_retenciones TO PIPE comando
	FOREACH q_rep INTO rm_consulta.*
		IF resp = 'Yes' THEN
			LET registro = rm_consulta.proveedor CLIPPED, '|',
					DATE(rm_consulta.fecha_retencion)
					USING "dd-mm-yyyy", '|',
					rm_consulta.num_retencion CLIPPED, '|',
					rm_consulta.num_factura CLIPPED, '|',
					rm_consulta.fecha_factura
					USING "dd-mm-yyyy", '|',
					rm_consulta.tipo_retencion CLIPPED, '|',
					rm_consulta.moneda CLIPPED, '|',
					rm_consulta.porc_retencion
					USING '##&.##', '|',
					rm_consulta.valor_base
					USING '#,###,##&.##', '|',
					rm_consulta.valor_retencion
					USING '#,###,##&.##'
			IF vg_gui = 1 THEN
				--#DISPLAY registro CLIPPED, ASCII(enter)
			ELSE
				DISPLAY registro CLIPPED
			END IF
		END IF
		OUTPUT TO REPORT reporte_retenciones(rm_consulta.*)
	END FOREACH
	FINISH REPORT reporte_retenciones
	DROP TABLE tmp_ret
	IF resp = 'Yes' THEN
		LET comando = 'mv ', vg_proceso CLIPPED, '.txt $HOME/tmp'
		RUN comando
		CALL fl_mostrar_mensaje('Se generó el Archivo ' || vg_proceso CLIPPED || '.txt', 'info')
	END IF
END WHILE

END FUNCTION


FUNCTION control_ingreso()
DEFINE r_moneda		RECORD LIKE gent013.*
DEFINE r_proveedor	RECORD LIKE cxpt001.*
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE nombre_mon	LIKE gent013.g13_nombre
DEFINE decimales	LIKE gent013.g13_decimales
DEFINE proveedor	LIKE cxpt001.p01_codprov
DEFINE desc_proveedor	LIKE cxpt001.p01_nomprov

LET int_flag = 0
INPUT BY NAME rm_par.moneda, rm_par.inicial, rm_par.final, rm_par.proveedor,
	rm_par.tipo_oc, rm_par.tipo_porc, rm_par.valor_porc
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.moneda, rm_par.inicial,
				     rm_par.final, rm_par.proveedor,
				     rm_par.tipo_oc, rm_par.tipo_porc,
				     rm_par.valor_porc)
		THEN
			LET int_flag = 1
			RETURN
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY (F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING moneda, nombre_mon, decimales
			IF moneda IS NOT NULL THEN
				LET rm_par.moneda = moneda
				DISPLAY moneda TO moneda
				DISPLAY nombre_mon TO desc_moneda
			END IF
		END IF

		IF INFIELD(proveedor) THEN
			CALL fl_ayuda_proveedores()
				RETURNING proveedor, desc_proveedor
			IF proveedor IS NOT NULL THEN 
				LET rm_par.proveedor = proveedor
				DISPLAY proveedor TO proveedor
				DISPLAY desc_proveedor TO desc_prov
			END IF
		END IF

		IF INFIELD(tipo_oc) THEN
			CALL fl_ayuda_tipos_ordenes_compras('T')
				RETURNING r_c01.c01_tipo_orden,
					  r_c01.c01_nombre
			IF r_c01.c01_tipo_orden IS NOT NULL THEN
				LET rm_par.tipo_oc = r_c01.c01_tipo_orden
				DISPLAY BY NAME rm_par.tipo_oc
				DISPLAY r_c01.c01_nombre TO desc_tipo
			END IF 
		END IF

		IF INFIELD(tipo_porc) OR INFIELD(valor_porc) THEN
			CALL fl_ayuda_retenciones(vg_codcia)
				RETURNING r_c02.c02_tipo_ret,
					  r_c02.c02_porcentaje,
					  r_c02.c02_nombre
			IF r_c02.c02_tipo_ret IS NOT NULL THEN
				LET rm_par.tipo_porc  = r_c02.c02_tipo_ret
				LET rm_par.valor_porc = r_c02.c02_porcentaje
				DISPLAY BY NAME rm_par.tipo_porc,
						rm_par.valor_porc
				DISPLAY r_c02.c02_nombre TO desc_porc
			END IF
		END IF
		LET int_flag = 0
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
			CLEAR desc_moneda
		END IF

	AFTER FIELD proveedor
		IF rm_par.proveedor IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_par.proveedor) 
				RETURNING r_proveedor.*
				
			IF r_proveedor.p01_codprov IS NULL THEN
				CALL fl_mostrar_mensaje('No existe proveedor.','exclamation')
				NEXT FIELD proveedor
			ELSE
				DISPLAY r_proveedor.p01_nomprov 
					TO desc_prov
			END IF
		ELSE
			CLEAR desc_prov
		END IF

	AFTER FIELD tipo_oc
		IF rm_par.tipo_oc IS NOT NULL THEN
			CALL fl_lee_tipo_orden_compra(rm_par.tipo_oc)
				RETURNING r_c01.*
			IF r_c01.c01_tipo_orden IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el tipo de orden en la Compañía.', 'exclamation')
				NEXT FIELD tipo_oc
			END IF
			DISPLAY r_c01.c01_nombre TO desc_tipo
		ELSE
			CLEAR desc_tipo
		END IF

	AFTER FIELD tipo_porc, valor_porc
		IF rm_par.tipo_porc IS NOT NULL AND
		   rm_par.valor_porc IS NOT NULL
		THEN
			CALL fl_lee_tipo_retencion(vg_codcia, rm_par.tipo_porc,
							rm_par.valor_porc)
				RETURNING r_c02.*
			DISPLAY r_c02.c02_nombre TO desc_porc
			IF r_c02.c02_tipo_ret IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el tipo de retención en la Compañía.', 'exclamation')
				NEXT FIELD valor_porc
			END IF
			LET rm_par.tipo_porc  = r_c02.c02_tipo_ret
			LET rm_par.valor_porc = r_c02.c02_porcentaje
			DISPLAY BY NAME rm_par.tipo_porc,
					rm_par.valor_porc
			DISPLAY r_c02.c02_nombre TO desc_porc
		ELSE
			INITIALIZE rm_par.tipo_porc, rm_par.valor_porc TO NULL
			CLEAR tipo_porc, valor_porc, desc_porc
		END IF

	AFTER INPUT  
		IF rm_par.inicial IS NULL OR rm_par.final IS NULL THEN
			NEXT FIELD inicial
		END IF

		IF rm_par.inicial > rm_par.final THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual que la fecha final.','exclamation')
			CONTINUE INPUT
		END IF

		IF rm_par.tipo_porc IS NOT NULL THEN
			IF rm_par.valor_porc IS NULL THEN
				NEXT FIELD valor_porc
			END IF
		END IF

		IF rm_par.valor_porc IS NOT NULL THEN
			IF rm_par.tipo_porc IS NULL THEN
				NEXT FIELD tipo_porc
			END IF
		END IF
END INPUT

END FUNCTION


REPORT reporte_retenciones(proveedor, fecha_retencion, num_retencion, 
		num_factura, fecha_factura, tipo_retencion, moneda, 
		valor_base, porc_retencion, valor_retencion)
DEFINE proveedor	LIKE cxpt001.p01_nomprov
DEFINE fecha_retencion	LIKE cxpt027.p27_fecing
DEFINE num_retencion	LIKE cxpt028.p28_num_ret
DEFINE num_factura      LIKE cxpt028.p28_num_doc
DEFINE fecha_factura	LIKE cxpt020.p20_fecha_emi
DEFINE tipo_retencion	LIKE cxpt028.p28_tipo_doc
DEFINE moneda		LIKE cxpt027.p27_moneda
DEFINE valor_base	LIKE cxpt028.p28_valor_base
DEFINE porc_retencion	LIKE cxpt028.p28_porcentaje
DEFINE valor_retencion  LIKE cxpt028.p28_valor_ret
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo           VARCHAR(80)
DEFINE modulo           VARCHAR(40)
DEFINE i,long           SMALLINT
DEFINE descr_estado	VARCHAR(9)		

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	2
	RIGHT  MARGIN	90
	BOTTOM MARGIN	4
	PAGE   LENGTH	66

FORMAT
	PAGE HEADER
		LET modulo	= 'Módulo: Tesoreria'
		LET long	= LENGTH(modulo)
		
		CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
		CALL fl_justifica_titulo('C', 
					'LISTADO DE RETENCIONES', 
					'52')
		RETURNING titulo
        	PRINT COLUMN 1,   rg_cia.g01_razonsocial,
              	      COLUMN 120, 'Página: ', PAGENO USING '&&&'
        	PRINT COLUMN 1,   modulo  CLIPPED,
		      COLUMN 44,  titulo,
                      COLUMN 109, UPSHIFT(vg_proceso)

      	SKIP 1 LINES
	
	PRINT COLUMN 040, '** Fecha Inicial    : ',
		rm_par.inicial USING "dd-mm-yyyy"
	PRINT COLUMN 040, '** Fecha Final      : ',
		rm_par.final USING "dd-mm-yyyy"

	IF rm_par.tipo_oc IS NOT NULL THEN
		CALL fl_lee_tipo_orden_compra(rm_par.tipo_oc) RETURNING r_c01.*
		PRINT COLUMN 040, '** Tipo Orden Compra: ',
			rm_par.tipo_oc USING "<<<&", ' ',
			r_c01.c01_nombre CLIPPED
	ELSE
		PRINT COLUMN 040, '** Tipo Orden Compra: T O D O S'
	END IF

	IF rm_par.tipo_porc IS NOT NULL THEN
		CALL fl_lee_tipo_retencion(vg_codcia, rm_par.tipo_porc,
						rm_par.valor_porc)
			RETURNING r_c02.*
		PRINT COLUMN 040, '** Tipo Retencion   : ', rm_par.tipo_porc,
			' ', rm_par.valor_porc USING "##&.##", ' ',
			r_c02.c02_nombre CLIPPED
	ELSE
		PRINT COLUMN 040, '** Tipo Retencion   : T O D O S'
	END IF

	SKIP 1 LINES
	
	PRINT COLUMN 01, 'Fecha impresión: ', TODAY USING 'dd-mmm-yyyy', 
			 1 SPACES, TIME,
              COLUMN 120, usuario
                                                                                
      	SKIP 1 LINES

		PRINT COLUMN 1,   'Proveedor',
		      COLUMN 27,  'F. Ret.',
		      COLUMN 39,  'No. Ret.',
		      COLUMN 52,  'No. Fact.',
		      COLUMN 68,  'F. Fact.',
		      COLUMN 80,  'Tipo. Ret.',
		      COLUMN 91,  'M.',		
		      COLUMN 94,  'Porc. Ret.',
		      COLUMN 107, 'Valor Base',
		      COLUMN 121, 'Valor Ret.'
			

		PRINT COLUMN 1,   '---------------------------',
		      COLUMN 27,  '-------------',
		      COLUMN 39,  '--------------',
		      COLUMN 52,  '-------------',
		      COLUMN 68,  '-------------',
		      COLUMN 80,  '-------------',
		      COLUMN 91,  '--------',
		      COLUMN 94,  '-------------',
		      COLUMN 107, '------------',
		      COLUMN 112, '----'


	ON EVERY ROW
		PRINT COLUMN 1,   proveedor[1, 25] CLIPPED,
		      COLUMN 27,  DATE(fecha_retencion)	USING "dd-mm-yyyy",
		      COLUMN 35,  num_retencion CLIPPED,
		      COLUMN 52,  num_factura CLIPPED,
		      COLUMN 68,  fecha_factura		USING "dd-mm-yyyy",
		      COLUMN 80,  tipo_retencion CLIPPED,
		      COLUMN 91,  moneda CLIPPED, 
		      COLUMN 97,  porc_retencion USING '##&.##' CLIPPED,
		      COLUMN 107, valor_base USING '#,###,##&.##' CLIPPED,
		      COLUMN 112, valor_retencion USING '#,###,##&.##'

	ON LAST ROW
		NEED 3 LINES
		PRINT COLUMN 107,  '-------------',
		      COLUMN 112,  '-----------'
		PRINT COLUMN 107,  SUM(valor_base) USING '#,###,##&.##',
		      COLUMN 112,  SUM(valor_retencion) USING '#,###,##&.##'
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

