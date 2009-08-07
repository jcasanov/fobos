
-------------------------------------------------------------------------------
-- Titulo               : cxpp410.4gl --  Listado de Retenciones
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  cxcp410 base modulo compañía localidad
-- Ultima Correción     : ?
-- Motivo Corrección    : ? 

--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_par RECORD
	moneda		VARCHAR(2),
	inicial		DATE,
	final		DATE,
	departamento	INTEGER
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

DEFINE rm_g34	 	RECORD LIKE gent034.*                               

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
LET vg_proceso  = 'cxpp410'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE query 		VARCHAR(1000)
DEFINE comando          VARCHAR(100)
DEFINE estado		CHAR(1)
DEFINE string		VARCHAR(100)

LET vm_top	= 1
LET vm_left	= 2
LET vm_right	= 90
LET vm_bottom	= 4
LET vm_page	= 66

CALL fl_nivel_isolation()
OPEN WINDOW wf AT 3,2 WITH 10 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP, ACCEPT KEY F12
OPEN FORM frm_listado FROM '../forms/cxpf410_1'
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

	LET string = '1 = 1'
	IF rm_par.departamento IS  NOT NULL THEN
		LET string = ' p20_cod_depto = ' || rm_par.departamento
	END IF
	LET query = ''
	LET query = 'SELECT p01_nomprov, p20_fecha_emi, p28_num_ret,' || 
		' p28_num_doc, p20_fecha_emi, p28_tipo_ret, p27_moneda,' ||
		' p28_valor_base, p28_porcentaje, p28_valor_ret ' ||
		' FROM cxpt027, cxpt028, cxpt020, cxpt001' || 
		' WHERE p27_compania = ' || vg_codcia || 
		' AND p27_localidad = '  || vg_codloc || 
		' AND p27_moneda = "' || rm_par.moneda || '" '||
		' AND p28_compania = p27_compania'   || 
		' AND p28_localidad = p27_localidad' || 
		' AND p28_num_ret = p27_num_ret' ||
		' AND p28_codprov = p27_codprov' ||
		' AND p01_codprov = p27_codprov' ||
		' AND p20_compania = p28_compania'   || 
		' AND p20_localidad = p28_localidad' || 
		' AND p20_codprov = p28_codprov' ||
		' AND p20_tipo_doc = p28_tipo_doc' ||
		' AND p20_num_doc = p28_num_doc' ||
                ' AND p20_fecha_emi BETWEEN "' || rm_par.inicial ||
                ' " AND "' || rm_par.final || 
		' " AND ' || string ||
--                ' " AND p20_cod_depto = ' || rm_par.departamento ||  
		' ORDER BY 1, 2'
	PREPARE expresion FROM query
	DECLARE q_rep CURSOR FOR expresion
	OPEN q_rep
	FETCH q_rep INTO rm_consulta.*
	IF STATUS = NOTFOUND THEN
		CLOSE q_rep
		CALL fl_mensaje_consulta_sin_registros()
		RETURN
	END IF
	CLOSE q_rep
	START REPORT reporte_retenciones TO PIPE comando
	FOREACH q_rep INTO rm_consulta.*
		OUTPUT TO REPORT reporte_retenciones(rm_consulta.*)
	END FOREACH
	FINISH REPORT reporte_retenciones
END WHILE

END FUNCTION


FUNCTION control_ingreso()
DEFINE r_moneda		RECORD LIKE gent013.*
DEFINE r_departamento	RECORD LIKE gent034.*
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE nombre_mon	LIKE gent013.g13_nombre
DEFINE decimales	LIKE gent013.g13_decimales
DEFINE departamento	LIKE gent034.g34_cod_depto
DEFINE desc_departa	LIKE gent034.g34_nombre

LET int_flag = 0
INPUT BY NAME rm_par.*  WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		RETURN

	ON KEY (F2)
		IF infield(moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING moneda, nombre_mon, decimales
			IF moneda IS NOT NULL THEN
				LET rm_par.moneda = moneda
				DISPLAY moneda TO moneda
				DISPLAY nombre_mon TO desc_moneda
			END IF
		END IF

		IF infield(departamento) THEN
			CALL fl_ayuda_departamentos(vg_codcia)
				RETURNING departamento, desc_departa
--				RETURNING proveedor, desc_proveedor
			IF departamento IS NOT NULL THEN 
				LET rm_par.departamento = departamento
				DISPLAY departamento TO departamento
				DISPLAY desc_departa TO desc_departa
			END IF
		END IF
		LET int_flag = 0
	AFTER INPUT  
		IF rm_par.inicial IS NULL OR rm_par.final IS NULL THEN
			NEXT FIELD inicial
		END IF

		IF rm_par.inicial > rm_par.final THEN
			CALL fgl_winmessage('PHOBOS',
			   'La fecha inicial debe ser menor o igual que ' ||
			   'la fecha final.',
			   'exclamation')
			CONTINUE INPUT
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
			CLEAR desc_moneda
		END IF

			
	AFTER FIELD departamento
		IF rm_par.departamento IS NOT NULL THEN
			CALL fl_lee_departamento(vg_codcia,rm_par.departamento) 
				RETURNING r_departamento.*
				
			IF r_departamento.g34_cod_depto IS NULL THEN
				CALL fgl_winmessage('PHOBOS',
						'No existe departamento',
						'exclamation')
				NEXT FIELD departamento
			ELSE
				DISPLAY r_departamento.g34_nombre 
					TO desc_departa
			END IF
		ELSE
			CLEAR desc_departa
		END IF

END INPUT

END FUNCTION


REPORT reporte_retenciones(proveedor, fecha_retencion, num_retencion, 
		num_factura, fecha_factura, tipo_retencion, moneda, 
		valor_base, porc_retencion, valor_retencion)


DEFINE	departamento	LIKE cxpt020.p20_cod_depto
DEFINE	proveedor	LIKE cxpt001.p01_nomprov
DEFINE	fecha_retencion	LIKE cxpt020.p20_fecha_emi
DEFINE	num_retencion	LIKE cxpt028.p28_num_ret
DEFINE	num_factura     LIKE cxpt028.p28_num_doc
DEFINE	fecha_factura	LIKE cxpt020.p20_fecha_emi
DEFINE	tipo_retencion	LIKE cxpt028.p28_tipo_doc
DEFINE	moneda		LIKE cxpt027.p27_moneda
DEFINE	valor_base	LIKE cxpt028.p28_valor_base
DEFINE	porc_retencion	LIKE cxpt028.p28_porcentaje
DEFINE	valor_retencion LIKE cxpt028.p28_valor_ret
DEFINE 	usuario         VARCHAR(19,15)
DEFINE 	titulo          VARCHAR(80)
DEFINE 	modulo          VARCHAR(40)
DEFINE 	i,long          SMALLINT
DEFINE 	descr_estado	VARCHAR(9)		
DEFINE nombre		LIKE gent034.g34_nombre

OUTPUT
	TOP 	MARGIN vm_top
	LEFT 	MARGIN vm_left
	RIGHT 	MARGIN vm_right
	BOTTOM	MARGIN vm_bottom
	PAGE 	LENGTH vm_page

FORMAT
	PAGE HEADER
-----------------
        INITIALIZE rm_g34.* TO NULL
	display ' DEPAR ... ' , rm_par.departamento
        DECLARE q_depar CURSOR FOR
                SELECT * FROM gent034
                 WHERE g34_compania = vg_codcia
                   AND g34_cod_depto= rm_par.departamento
                OPEN q_depar
                FETCH q_depar INTO rm_g34.*
		display 'G34 .. ', rm_g34.g34_nombre
                IF STATUS <> NOTFOUND THEN
                         LET nombre = rm_g34.g34_nombre CLIPPED
                END IF
        CLOSE q_depar
        FREE  q_depar
-----------------
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
      PRINT COLUMN 18, '*** Fecha Inicial: ', rm_par.inicial USING "dd-mm-yyyy"
      PRINT COLUMN 18, '*** Fecha Final  : ', rm_par.final   USING "dd-mm-yyyy"
      IF rm_par.departamento IS NULL THEN
      		PRINT COLUMN 18, '*** Departamento : TODOS'
	ELSE
        	PRINT COLUMN 18, '*** Departamento : ', nombre
      END IF
	
	SKIP 1 LINES
	
	PRINT COLUMN 01, 'Fecha impresión: ', TODAY USING 'dd-mm-yyyy', 
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
		      COLUMN 27,  fecha_retencion,
		      COLUMN 35,  num_retencion CLIPPED,
		      COLUMN 52,  num_factura CLIPPED,
		      COLUMN 68,  fecha_factura CLIPPED,
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
