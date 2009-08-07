
------------------------------------------------------------------------------
-- Titulo               : vehp400.4gl --  Listado de Facturación de Vehiculos 
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  veh400 base modulo compañía localidad
-- Ultima Correción     : ?
-- Motivo Corrección    : ? 

--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
database diteca
                                                                                
DEFINE vm_programa      VARCHAR(12)
DEFINE d_bodega  	VARCHAR(20)
DEFINE d_linea 		VARCHAR(20)
DEFINE d_vendedor	VARCHAR(20)

DEFINE rm_par RECORD
	moneda		CHAR(2),
	inicial		DATE,
	final		DATE,
	bodega		CHAR(2),
	linea		CHAR(5),
	vendedor	SMALLINT
END RECORD

DEFINE rm_consulta	RECORD 
	fecha_venta	DATE,
	tipo_trn	LIKE veht030.v30_cod_tran,
	num_trn		LIKE veht030.v30_num_tran, 
	cliente		LIKE cxct001.z01_nomcli,
	vendedor	LIKE veht001.v01_nombres,
	modelo		LIKE veht022.v22_modelo, 
	precio		LIKE veht031.v31_precio,
	valor_descuento	LIKE veht031.v31_val_descto,
	impuesto	LIKE veht030.v30_porc_impto,
	valor_neto	LIKE veht031.v31_costo
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
LET vg_proceso  = 'vehp400'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vm_programa || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE query 		VARCHAR(1000)
DEFINE comando          VARCHAR(100)
DEFINE s_Bodega		VARCHAR(50)
DEFINE s_linea		VARCHAR(50)
DEFINE s_vendedor	VARCHAR(50)


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
OPEN FORM frm_listado FROM '../forms/vehf400_1'
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

	LET s_bodega	 = ' 1 = 1'
	LET s_linea      = ' 1 = 1'
	LET s_vendedor   = ' 1 = 1'

	IF rm_par.bodega IS NOT NULL THEN
		LET s_bodega = ' v30_bodega_ori = "' || rm_par.bodega || '"'  
	END IF
	
	IF rm_par.linea IS NOT NULL THEN
		LET s_linea = ' v20_linea = "' || rm_par.linea || '"'
	END IF

	IF rm_par.vendedor IS NOT NULL THEN
		LET s_vendedor = ' v01_vendedor = ' || rm_par.vendedor  
	END IF

	
	LET query = 'SELECT date(v30_fecing), v30_cod_tran, ' || 
		' v30_num_tran, z01_nomcli,' ||
		' v01_iniciales, v22_modelo, v31_precio,' ||
		' v31_val_descto, v30_porc_impto,' ||
		' ((v31_precio - v31_val_descto) * (1 + (v30_porc_impto / 100))) net' ||
		' FROM veht030, veht031, cxct001, veht001, veht020, veht022' || 
		' WHERE v30_compania = ' || vg_codcia || 
		' AND v30_localidad = '  || vg_codloc ||
		' AND v30_cod_tran in  ("FA", "DF")' ||
		' AND v30_moneda = "' || rm_par.moneda || '"' ||
		' AND date(v30_fecing) BETWEEN "' || rm_par.inicial ||
		'" AND "' || rm_par.final || '"' ||
		' AND ' || s_bodega ||
		' AND ' || s_vendedor ||  
		' AND v31_compania = v30_compania' ||
		' AND v31_localidad = v30_localidad' ||
		' AND v31_cod_tran = v30_cod_tran' ||
		' AND v31_num_tran = v30_num_tran' ||
		' AND v22_compania = v31_compania' ||
		' AND v22_localidad = v31_localidad' ||
		' AND v22_codigo_veh = v31_codigo_veh' ||
		' AND v20_compania = v22_compania' ||
		' AND v20_modelo = v22_modelo' ||
		' AND ' || s_linea || 
		' AND z01_codcli = v30_codcli' ||
		' AND v01_vendedor = v30_vendedor' ||
		' ORDER BY 1'
	display query
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
	START REPORT reporte_facturacion_veh TO PIPE comando
	FOREACH q_rep INTO rm_consulta.*
		OUTPUT TO REPORT reporte_facturacion_veh(rm_consulta.*)
	END FOREACH
	FINISH REPORT reporte_facturacion_veh
END WHILE

END FUNCTION



FUNCTION control_ingreso()
DEFINE	r_moneda	RECORD LIKE gent013.*
DEFINE  r_vendedor	RECORD LIKE veht001.*
DEFINE  r_bodega 	RECORD LIKE veht002.*
DEFINE  r_linea		RECORD LIKE veht003.*
DEFINE  codmon		LIKE gent013.g13_moneda
DEFINE  descmon		LIKE gent013.g13_nombre
DEFINE  codven		LIKE veht001.v01_vendedor
DEFINE  nomven		LIKE veht001.v01_nombres
DEFINE  codbod		LIKE veht002.v02_bodega
DEFINE  descbod		LIKE veht002.v02_nombre
DEFINE  codlinea	LIKE veht003.v03_linea
DEFINE  nomlinea	LIKE veht003.v03_nombre 
DEFINE  decimales	LIKE gent013.g13_decimales

LET int_flag = 0
INPUT BY NAME rm_par.*  WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		RETURN

	ON KEY (F2)
		IF infield(moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING codmon, descmon, decimales
			IF codmon IS NOT NULL THEN
				LET rm_par.moneda = codmon
				DISPLAY codmon TO moneda
				DISPLAY descmon TO desc_moneda
			END IF
			LET int_flag = 0
		END IF


		IF infield(bodega) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia)
				RETURNING codbod, descbod
			IF codbod IS NOT NULL THEN
				LET rm_par.bodega = codbod
				DISPLAY codbod 	TO bodega
				DISPLAY descbod	TO desc_bodega
			END IF
			LET int_flag = 0
		END IF
 
		IF infield(linea) THEN
			CALL fl_ayuda_lineas_veh(vg_codcia)
				RETURNING codlinea, nomlinea
			IF codlinea IS NOT NULL THEN
				LET rm_par.linea = codlinea
				DISPLAY codlinea TO linea
				DISPLAY nomlinea TO desc_linea
			END IF
			LET int_flag = 0
		END IF


		IF infield(vendedor) THEN
			CALL fl_ayuda_vendedores_veh(vg_codcia)
				RETURNING codven, nomven
			IF codven IS NOT NULL THEN
				LET rm_par.vendedor = codven
				DISPLAY codven	TO vendedor
				DISPLAY nomven	TO desc_vendedor
			END IF
			LET int_flag = 0
		END IF

	AFTER INPUT  
		IF rm_par.inicial IS NULL OR rm_par.final IS NULL THEN
			CONTINUE INPUT
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

	AFTER FIELD bodega
		IF rm_par.bodega IS NOT NULL THEN
			CALL fl_lee_bodega_veh(vg_codcia, rm_par.bodega)
				RETURNING r_bodega.*
			IF r_bodega.v02_bodega IS NULL THEN
				CALL fgl_winmessage('PHOBOS',
					'Bodega no existe',
					'exclamation')
				NEXT FIELD bodega
			ELSE
				LET d_bodega = r_bodega.v02_nombre
				DISPLAY r_bodega.v02_nombre 	
					TO desc_bodega
			END IF
		ELSE
			CLEAR desc_bodega
		END IF
		
	AFTER FIELD linea
		 IF rm_par.linea IS NOT NULL THEN
			CALL fl_lee_linea_veh(vg_codcia, rm_par.linea)
				RETURNING r_linea.*
			IF r_linea.v03_linea IS NULL THEN

				CALL fgl_winmessage('PHOBOS',
					'Línea no existe',
					'exclamation')
				NEXT FIELD linea
			ELSE
				LET d_linea = r_linea.v03_nombre
				DISPLAY r_linea.v03_nombre TO desc_linea 	
			END IF
		ELSE
			CLEAR desc_linea
		END IF
		
	
	AFTER FIELD vendedor
		IF rm_par.vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_veh(vg_codcia, rm_par.vendedor)
				RETURNING r_vendedor.*
			IF r_vendedor.v01_vendedor IS NULL THEN
				CALL fgl_winmessage('PHOBOS', 
					'Vendedor no existe',
					'exclamation')
				NEXT FIELD vendedor
			ELSE
				LET d_vendedor = r_vendedor.v01_nombres
				DISPLAY r_vendedor.v01_nombres 
					TO desc_vendedor
			END IF
		ELSE
			CLEAR desc_vendedor
		END IF
END INPUT

END FUNCTION

REPORT reporte_facturacion_veh(fecha_venta, tipo_trn, num_trn, cliente, 
				vendedor, modelo, precio,
				valor_descuento, impuesto, valor_neto)

DEFINE	fecha_venta	DATE
DEFINE	tipo_trn	LIKE veht030.v30_cod_tran
DEFINE	num_trn		LIKE veht030.v30_num_tran 
DEFINE	cliente		LIKE cxct001.z01_nomcli
DEFINE	vendedor	LIKE veht001.v01_nombres
DEFINE	modelo		LIKE veht022.v22_modelo 
DEFINE	precio		LIKE veht031.v31_precio
DEFINE	valor_descuento	LIKE veht031.v31_val_descto
DEFINE	impuesto	LIKE veht030.v30_porc_impto
DEFINE	valor_neto	LIKE veht031.v31_costo
DEFINE  usuario         VARCHAR(19,15)
DEFINE  titulo          VARCHAR(80)
DEFINE  modulo          VARCHAR(40)
DEFINE  i,long          SMALLINT
DEFINE  descr_estado	VARCHAR(9)		
DEFINE  columna		SMALLINT

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
					'LISTADO DE FACTURACION DE VEHICULOS', 
					'52')
		RETURNING titulo

        	PRINT COLUMN 1,   rg_cia.g01_razonsocial,
              	      COLUMN 120, 'Página: ', PAGENO USING "&&&"

        	PRINT COLUMN 1,   modulo  CLIPPED,
		      COLUMN 44,  titulo,
                      COLUMN 109, UPSHIFT(vm_programa)

      	SKIP 1 LINES
	
	PRINT COLUMN 20, '*** Moneda:             ', rm_par.moneda

	PRINT COLUMN 20, '*** Fecha Inicial:      ', rm_par.inicial
	PRINT COLUMN 20, '*** Fecha Final:        ', rm_par.final

	IF rm_par.bodega IS NOT NULL THEN
		PRINT COLUMN 20, '*** Punto de venta:     ', d_bodega 
	END IF

	IF rm_par.linea IS NOT NULL THEN
		PRINT COLUMN 20, '*** Línea de venta:     ', d_linea		
	END IF	

	IF rm_par.vendedor IS NOT NULL THEN
		PRINT COLUMN 20, '*** Vendedor:           ', d_vendedor
	END IF
	

	SKIP 1 LINES
	
	PRINT COLUMN 01, 'Fecha impresión: ', TODAY USING 'dd-mmm-yyyy', 
			 1 SPACES, TIME,
              COLUMN 120, usuario
                                                                                
      	SKIP 1 LINES

		PRINT COLUMN 1,   'Fecha de Venta',
		      COLUMN 16,  'T.',          
		      COLUMN 19,  'N. Transac',
		      COLUMN 37,  'Cliente',
		      COLUMN 58,  'Vend.',     
		      COLUMN 64,  'M. Veh.  ',    		
		      COLUMN 80,  'Precio',
		      COLUMN 93,  'Descuento',
		      COLUMN 111, 'Imp.',
		      COLUMN 121, 'Valor Neto'

		PRINT COLUMN 1,   '--------------------',
		      COLUMN 16,  '---------',
		      COLUMN 19,  '------------',
		      COLUMN 37,  '----------------',
		      COLUMN 58,  '-------',
		      COLUMN 64,  '-------------------',
		      COLUMN 84,  '------------',
		      COLUMN 93,  '----------------',
		      COLUMN 107, '-------------',
		      COLUMN 118, '------'
	ON EVERY ROW
		PRINT COLUMN 1,   fecha_venta,
		      COLUMN 16,  tipo_trn[1, 2],
		      COLUMN 19,  num_trn,
		      COLUMN 37,  cliente[1, 15],
		      COLUMN 58,  vendedor,
		      COLUMN 64,  modelo,
		      COLUMN 75,  precio 		USING '##,###,##&.##', 
		      COLUMN 86,  valor_descuento 	USING '##,###,##&.##',
		      COLUMN 100, impuesto 		USING '##,###,##&.##',
		      COLUMN 118, valor_neto 		USING '##,###,##&.##'
	ON LAST ROW
		NEED 3 LINES
		PRINT COLUMN 80,  '--------------------',
		      COLUMN 100, '------------------',
		      COLUMN 118, '-------------'
		PRINT COLUMN 78,  SUM(precio) 		USING '###,###,##&.##',
		      COLUMN 72,  SUM(valor_descuento) 	USING '###,###,##&.##', 
		      COLUMN 117, SUM(valor_neto) 	USING '###,###,##&.##' 
END REPORT
