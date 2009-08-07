-----------------------------------------------------------------------------
-- Titulo           : cxpp413.4gl - Listado retenciones pagadas          
-- Elaboracion      : 09-ene-2006
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxpp413 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cia		RECORD LIKE gent001.*

DEFINE rm_par		RECORD
	anio			SMALLINT,
	mes				SMALLINT,
	n_mes			VARCHAR(19),
	tipo_ret		CHAR(1)
END RECORD

DEFINE rm_cons		RECORD
	nom_prov 	LIKE cxpt001.p01_nomprov,
	tipo_doc	LIKE cxpt001.p01_tipo_doc,
	num_doc		LIKE cxpt001.p01_num_doc,
	porcentaje	LIKE cxpt028.p28_porcentaje,
	base		LIKE cxpt028.p28_valor_base,
	retenido	LIKE cxpt028.p28_valor_ret,
	num_ret		SMALLINT,
	tipo_ret	LIKE cxpt028.p28_tipo_ret
END RECORD




MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp413.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso  = 'cxpp413'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 13 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/cxpf413_1"
DISPLAY FORM f_rep
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE comando		VARCHAR(100)
DEFINE fecha_ini	DATE 
DEFINE fecha_fin	DATE 
DEFINE expr_ret		VARCHAR(100)

INITIALIZE rm_par.* TO NULL

LET rm_par.anio     = YEAR(TODAY)
LET rm_par.mes      = MONTH(TODAY)
LET rm_par.tipo_ret = 'T'

WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*

	LET expr_ret = ' '
	IF rm_par.tipo_ret <> 'T' THEN
		LET expr_ret = ' AND p28_tipo_ret = "', rm_par.tipo_ret, '"'
	END IF 

	{*
 	 * Fechas inicial y final siempre seran primer dia del mes y ultimo dia
	 * del mes respectivamente.
	 *}
	LET fecha_ini = mdy(rm_par.mes, 1, rm_par.anio)
	LET fecha_fin = (fecha_ini + 1 UNITS MONTH) - 1 UNITS DAY

	LET query = 'SELECT p01_nomprov, p01_tipo_doc, p01_num_doc, ' ||
    	   		      ' p28_porcentaje, SUM(p28_valor_base) valor_base, ' ||
	       			  ' SUM(p28_valor_ret) valor_ret, COUNT(*) num_ret, ' ||
					  ' p28_tipo_ret ' ||
	             ' FROM cxpt027, cxpt028, cxpt001 ' ||
				' WHERE p27_compania  = ' || vg_codcia ||
				'   AND p27_localidad = ' || vg_codloc ||
				'   AND p27_estado    = "A" ' ||
				'   AND p27_moneda    = "DO"	' ||
				'   AND DATE(p27_fecing) BETWEEN "' || fecha_ini || '"' ||
										'    AND "' || fecha_fin || '"' ||
				'   AND p28_compania  = p27_compania ' ||
				'   AND p28_localidad = p27_localidad ' ||
				'   AND p28_num_ret   = p27_num_ret ' ||
				'   AND p28_codprov   = p27_codprov ' ||
				expr_ret CLIPPED ||
				'   AND p01_codprov   = p27_codprov ' ||
				' GROUP BY p01_nomprov, p01_tipo_doc, p01_num_doc, ' ||
						'  p28_tipo_ret, p28_porcentaje ' ||
				' ORDER BY p28_tipo_ret, p01_nomprov, p28_porcentaje '  

	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	OPEN q_deto
	FETCH q_deto
	IF STATUS = NOTFOUND THEN
		CLOSE q_deto
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	CLOSE q_deto
	START REPORT rep_reten TO PIPE comando
	FOREACH q_deto INTO rm_cons.*
		OUTPUT TO REPORT rep_reten(rm_cons.*)
	END FOREACH
	FINISH REPORT rep_reten
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE  r_c02		RECORD LIKE ordt002.*

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
END INPUT

END FUNCTION



REPORT rep_reten(nom_prov, tipo_doc, num_doc, porcentaje, base, retenido, num_ret, tipo_ret)
DEFINE nom_prov 	LIKE cxpt001.p01_nomprov
DEFINE tipo_doc		LIKE cxpt001.p01_tipo_doc
DEFINE num_doc		LIKE cxpt001.p01_num_doc
DEFINE porcentaje	LIKE cxpt028.p28_porcentaje
DEFINE base			LIKE cxpt028.p28_valor_base
DEFINE retenido		LIKE cxpt028.p28_valor_ret
DEFINE num_ret		SMALLINT
DEFINE tipo_ret		LIKE cxpt028.p28_tipo_ret

DEFINE desc_ret     VARCHAR(15)

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	2
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT
PAGE HEADER
	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'RESUMEN MENSUAL DE RETENCIONES PAGADAS', 80)
		RETURNING titulo

	PRINT COLUMN 1, rm_cia.g01_razonsocial,
  	      COLUMN 120, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 52, titulo CLIPPED,
	      COLUMN 124, "CXPP413" 

	PRINT COLUMN 48, "** Año            : ", rm_par.anio USING '&&&&' 
	PRINT COLUMN 48, "** Mes            : ", rm_par.mes  USING '&&'

	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 112, usuario
	SKIP 1 LINES

	PRINT COLUMN 1,   "Proveedor",
	      COLUMN 43,  "Tipo Doc",
	      COLUMN 53,  "Número Documento",
	      COLUMN 71,  "Porc.",
	      COLUMN 78,  fl_justifica_titulo('D', "Valor Base", 16),
	      COLUMN 96,  fl_justifica_titulo('D', "Valor Retenido", 16),
		  COLUMN 114, "Total Ret."
	PRINT "----------------------------------------------------------------------------------------------------------------------------------"

BEFORE GROUP OF tipo_ret
	SKIP 1 LINES
	CASE tipo_ret
		WHEN 'I' 
			LET desc_ret = 'I V A'
		WHEN 'F' 
			LET desc_ret = 'F U E N T E'
	END CASE
	PRINT COLUMN 1, "** Tipo Retención : ", desc_ret CLIPPED 
	SKIP 1 LINES

ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 1,   nom_prov CLIPPED,
	      COLUMN 46,  tipo_doc CLIPPED,
	      COLUMN 53,  num_doc CLIPPED,
	      COLUMN 71,  porcentaje USING '##&.&&',
	      COLUMN 78, base USING "-,---,---,--&.&&",
	      COLUMN 96, retenido USING "---,---,--&.&&",
	      COLUMN 114, num_ret USING "######"

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
