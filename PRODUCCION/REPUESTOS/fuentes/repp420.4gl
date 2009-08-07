------------------------------------------------------------------------------
-- Titulo           : repp420.4gl - Listado utilidades facturas
-- Elaboracion      : 07-ene-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp420 base módulo compañía localidad
--		      [moneda tipo_tran fecha_ini fecha_fin utilidad_desde 
--		       utilidad_hasta col1 orden1 col2 orden2]
--		Si num_args() = 4 entonces el reporte fue llamado desde el
--		menu principal y hay que llamar a la rutina de parametros.
--		Si num_args() = 14 entonces el reporte fue llamado desde la
--	 	consulta repp301, NO llamar a la rutina de parametros.
-- Ultima Correccion: 16-jul-2002
-- Motivo Correccion: Standart de impresiòn en laser e incluir el nombre
--		      del cliente en la impresiòn. Se le agregò ON LAST ROW.
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_r19		RECORD LIKE rept019.*

DEFINE vm_moneda	LIKE gent013.g13_nombre
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE utilidad_desde	DECIMAL(7,2)
DEFINE utilidad_hasta	DECIMAL(7,2)
DEFINE vm_tipo_tran	LIKE rept019.r19_cod_tran
DEFINE vm_columna_1	SMALLINT
DEFINE vm_col1_orden	CHAR(4)
DEFINE vm_columna_2	SMALLINT
DEFINE vm_col2_orden	CHAR(4)

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp420.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4  AND num_args() <> 14 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp420'
LET vg_codloc   = arg_val(4)
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	

LET vm_moneda	  = rg_gen.g00_moneda_base
LET vm_fecha_fin  = TODAY
LET vm_tipo_tran  = 'FA'
LET vm_columna_1  = 1
LET vm_col1_orden = 'ASC'
INITIALIZE vm_columna_2, vm_col2_orden TO NULL
INITIALIZE utilidad_desde, utilidad_hasta, vm_fecha_ini TO NULL

IF num_args() = 14 THEN
	LET vm_moneda      = arg_val(5)
	LET vm_tipo_tran   = arg_val(6)
	LET vm_fecha_ini   = arg_val(7)
	LET vm_fecha_fin   = arg_val(8)
	LET utilidad_desde = arg_val(9)
	LET utilidad_hasta = arg_val(10)
	LET vm_columna_1   = arg_val(11)
	LET vm_col1_orden  = arg_val(12)
	LET vm_columna_2   = arg_val(13)
	LET vm_col2_orden  = arg_val(14)
	
	IF utilidad_desde = -1 THEN
		INITIALIZE utilidad_desde, utilidad_hasta TO NULL
	END IF
	IF vm_col1_orden = 'NOP' THEN
		INITIALIZE vm_col1_orden TO NULL
	END IF
	IF vm_col2_orden = 'NOP' THEN
		INITIALIZE vm_col2_orden TO NULL
	END IF
END IF

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

LET vm_top    = 1
LET vm_left   =	2
LET vm_right  =	90
LET vm_bottom =	4
LET vm_page   = 66

IF num_args() = 4 THEN
	OPEN WINDOW w_mas AT 3,2 WITH 08 ROWS, 80 COLUMNS
    		ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, 
    			BORDER, MESSAGE LINE LAST - 2)
	OPTIONS INPUT WRAP,
		ACCEPT KEY	F12
	OPEN FORM f_rep FROM "../forms/repf420_1"
	DISPLAY FORM f_rep
END IF
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE comando		VARCHAR(100)
DEFINE data_found	SMALLINT
DEFINE expr_tipo	VARCHAR(50)

DEFINE r_det RECORD
	fecha		DATE,
	tipo_tran	LIKE rept019.r19_cod_tran,
	num_tran	LIKE rept019.r19_num_tran,
	siglas_vend	LIKE rept001.r01_iniciales,
	nombre_cli	VARCHAR(23),
	tot_sin_impto	LIKE rept019.r19_tot_neto,
	tot_costo	LIKE rept019.r19_tot_neto,
	utilidad	DECIMAL(12,2)
END RECORD
DEFINE totales_s_impto	DECIMAL(12,2)
DEFINE totales_costo	DECIMAL(11,2)
DEFINE totales_utilidad	DECIMAL(11,2)

WHILE TRUE
	CALL fl_lee_moneda(vm_moneda) RETURNING rm_g13.*
	IF rm_g13.g13_moneda IS NULL THEN
	       	CALL fgl_winmessage(vg_producto, 'No existe moneda base.', 'stop')
	        EXIT PROGRAM
	END IF

	IF num_args() = 4 THEN
		DISPLAY rm_g13.g13_nombre TO nom_moneda
		
		CALL lee_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
	
	IF vm_tipo_tran = 'TO' THEN
		LET expr_tipo = ' r19_cod_tran IN ("FA","RQ") '
	ELSE
		LET expr_tipo = ' r19_cod_tran = "', vm_tipo_tran, '"'
	END IF
	LET totales_s_impto   = 0
	LET totales_costo     = 0
	LET totales_utilidad  = 0
	
	LET query = 'SELECT DATE(r19_fecing) fecha, r19_cod_tran, ',
		    '       r19_num_tran, ',
		    '	    r01_iniciales, ',
		    '	    r19_nomcli, ',
                    '       (r19_tot_bruto - r19_tot_dscto) sin_iva, ',
		    '       r19_tot_costo, 0 utilidad',
		    ' FROM rept019, rept001 ',
		    ' WHERE r19_compania  = ', vg_codcia,
		    '   AND r19_localidad = ', vg_codloc,
		    '   AND ', expr_tipo,
		    '   AND DATE(r19_fecing) ',
		    '	BETWEEN "', vm_fecha_ini, '" AND "', vm_fecha_fin, '"',
		    '  	AND r19_moneda   = "',vm_moneda, '" ',
		    '  	AND r01_compania = r19_compania ',
		    '  	AND r01_codigo   = r19_vendedor',
		    ' ORDER BY fecha ',
		    ' INTO TEMP tmp1 ' 
		    
	PREPARE cons FROM query
	EXECUTE cons

	UPDATE tmp1 SET 
		utilidad = ((sin_iva - r19_tot_costo) / r19_tot_costo) * 100
		WHERE r19_tot_costo > 0

	IF utilidad_desde IS NOT NULL THEN		
		DELETE FROM tmp1 
			WHERE utilidad NOT BETWEEN utilidad_desde 
				               AND utilidad_hasta
	END IF
		
	LET query = 'SELECT * FROM tmp1 ',
		    ' ORDER BY ', vm_columna_1, ' ', vm_col1_orden
	IF vm_columna_2 IS NOT NULL THEN
		LET query = query CLIPPED, ', ', vm_columna_2, 
					    ' ', vm_col2_orden
	END IF
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET data_found = 0
	
	START REPORT rep_utilidad TO PIPE comando
	FOREACH q_deto INTO r_det.*
		LET data_found = 1
		LET totales_s_impto = totales_s_impto + r_det.tot_sin_impto
		LET totales_costo   = totales_costo   + r_det.tot_costo
--		LET totales_utilidad= totales_utilidad+ r_det.utilidad
		OUTPUT TO REPORT rep_utilidad(r_det.*, totales_s_impto,
					      	       totales_costo)
	END FOREACH
	FREE q_deto
	FINISH REPORT rep_utilidad
	
	IF NOT data_found THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF
	IF num_args() = 14 THEN
		EXIT WHILE
		DROP TABLE tmp1;
	END IF
		
	DROP TABLE tmp1;
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE i,j,l,col	SMALLINT
DEFINE query		VARCHAR(600)

LET INT_FLAG   = 0
INPUT BY NAME vm_moneda, vm_fecha_ini, vm_fecha_fin, vm_tipo_tran, 
	      utilidad_desde, utilidad_hasta
	WITHOUT DEFAULTS

	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(vm_moneda, vm_fecha_ini, vm_fecha_fin, 
				     vm_tipo_tran, utilidad_desde, 
				     utilidad_hasta)
		THEN
			EXIT PROGRAM
		END IF
		LET INT_FLAG = 1 
		RETURN

	ON KEY(F2)
		IF INFIELD(vm_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING rm_g13.g13_moneda,
					  rm_g13.g13_nombre,
					  rm_g13.g13_decimales
			IF rm_g13.g13_moneda IS NOT NULL THEN
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF 
		END IF
		LET INT_FLAG = 0

	AFTER FIELD vm_moneda
		IF vm_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(vm_moneda) RETURNING rm_g13.* 
			IF rm_g13.g13_moneda IS NULL  THEN
				CALL fgl_winmessage(vg_producto,
						    'Moneda no existe.',
						    'exclamation')
				NEXT FIELD vm_moneda
			END IF
			DISPLAY rm_g13.g13_nombre TO nom_moneda 
		ELSE
			CLEAR nom_moneda
			NEXT FIELD vm_moneda
		END IF

	AFTER FIELD vm_fecha_ini
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
			IF vm_fecha_ini < '01-01-1990' THEN
				CALL fgl_winmessage(vg_producto,'Debe ingresa fechas mayores a las del año 1989.','exclamation')	
				NEXT FIELD vm_fecha_ini
			END IF
				
		ELSE 
			NEXT FIELD vm_fecha_ini
		END IF

	AFTER FIELD vm_fecha_fin
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
			IF vm_fecha_fin < '01-01-1990' THEN
				CALL fgl_winmessage(vg_producto,'Debe ingresa fechas mayores a las del año 1989.','exclamation')	
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			NEXT FIELD vm_fecha_fin
		END IF

	AFTER INPUT
		IF utilidad_desde > utilidad_hasta THEN
			CALL fgl_winmessage(vg_producto,'El procentaje de utilidad inicial debe ser menor al porcentaje de la utilidad final.','exclamation')
			NEXT FIELD utilidad_desde
		END IF
		IF vm_fecha_ini IS NULL OR vm_fecha_fin IS NULL THEN
			CONTINUE INPUT 
		END IF
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fgl_winmessage(vg_producto,
				'La fecha inicial debe ser menor a la fecha ' ||
				'final.',
				'exclamation')
			CONTINUE INPUT
		END IF
		IF utilidad_desde IS NULL AND utilidad_hasta IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'No ha ingresado la utilidad inicial. Debe ingresar las dos rangos de utilidad o si quiere ver todo blanque los dos campos de rangos de utilidad.','exclamation')
			CONTINUE INPUT 
		END IF
		IF utilidad_hasta IS NULL AND utilidad_desde IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'No ha ingresado la utilidad final. Debe ingresar las dos rangos de utilidad o si quiere ver todo blanque los dos campos de rangos de utilidad.','exclamation')
			CONTINUE INPUT 
		END IF
		IF utilidad_desde IS NULL AND utilidad_hasta IS NULL THEN
			EXIT INPUT
		END IF

END INPUT

END FUNCTION



REPORT rep_utilidad(fecha, tipo_tran, num_tran, siglas_vend, nombre_cli, 
		tot_sin_impto, tot_costo, utilidad, totales_s_impto,
		totales_costo)

DEFINE fecha		DATE
DEFINE tipo_tran	LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE siglas_vend	LIKE rept001.r01_iniciales
DEFINE nombre_cli	LIKE rept019.r19_nomcli
DEFINE tot_sin_impto	LIKE rept019.r19_tot_neto
DEFINE tot_costo	LIKE rept019.r19_tot_neto
DEFINE utilidad		DECIMAL(12,2)
DEFINE totales_s_impto	DECIMAL(12,2)
DEFINE totales_costo	DECIMAL(11,2)
DEFINE totales_utilidad	DECIMAL(11,2)


DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT


OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page
FORMAT
PAGE HEADER
	print 'E'; print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&k4S'	                -- Letra (12 cpi)
	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO UTILIDADES FACTURAS', 60)
		RETURNING titulo

	LET titulo = modulo, titulo

	PRINT COLUMN 1, rm_g01.g01_razonsocial,
	      COLUMN 80, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, titulo CLIPPED,
	      COLUMN 84, UPSHIFT(vg_proceso)
	      
	SKIP 1 LINES
	PRINT COLUMN 10, "** Moneda        : ", vm_moneda, ' ',rm_g13.g13_nombre
	PRINT COLUMN 10, "** Fecha Inicial : ", vm_fecha_ini USING "dd-mm-yyyy",
	      COLUMN 51, "** Fecha Final   : ", vm_fecha_fin USING "dd-mm-yyyy"
	IF utilidad_desde IS NOT NULL THEN
		PRINT COLUMN 10, "** Utilidad Desde: ", utilidad_desde 
			 	USING "-,---,---,--&.##",
		      COLUMN 51, "** Utilidad Hasta: ", utilidad_hasta
				USING "-,---,---,--&.##"
	END IF
	
	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 72, usuario
	SKIP 1 LINES
	print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 1,  "Fecha",
	      COLUMN 13, "TP",
	      COLUMN 17, fl_justifica_titulo('D', "Número", 15),
	      COLUMN 34, "Ven",
	      COLUMN 38, "Cliente",
	      COLUMN 64, fl_justifica_titulo('D', "Total sin Impto.", 16),
	      COLUMN 79, fl_justifica_titulo('D', "Total Costo",      16),
	      COLUMN 98, fl_justifica_titulo('D', "Utilidad",         16)

	PRINT COLUMN 1,  "------------",
	      COLUMN 13, "----",
	      COLUMN 17, "-----------------",
	      COLUMN 34, "-----",
	      COLUMN 38, "-------------------------",
	      COLUMN 64, "------------------",
	      COLUMN 81, "------------------",
	      COLUMN 98, "------------------"

ON EVERY ROW
	PRINT COLUMN 1,   fecha USING "dd-mm-yyyy",
	      COLUMN 13,  tipo_tran,
	      COLUMN 17,  fl_justifica_titulo('D', num_tran, 15),
	      COLUMN 34,  siglas_vend,
	      COLUMN 38,  nombre_cli,
	      COLUMN 64,  tot_sin_impto USING "-,---,---,--&.##",
	      COLUMN 81,  tot_costo     USING "---,---,--&.##",
	      COLUMN 98,  utilidad      USING "---,---,--&.##"

ON LAST ROW
	LET totales_utilidad = totales_s_impto - totales_costo
    PRINT COLUMN 64,  "----------------",
          COLUMN 81,  "--------------",
          COLUMN 98,  "--------------" 
    PRINT COLUMN 51, "TOTALES ==>  ", totales_s_impto USING "-,---,---,--&.##",
          COLUMN 81,  totales_costo 	USING "---,---,--&.##",
          COLUMN 98,  totales_utilidad 	USING "---,---,--&.##" 

END REPORT

FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
