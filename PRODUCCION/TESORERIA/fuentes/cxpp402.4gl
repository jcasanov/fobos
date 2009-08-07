-----------------------------------------------------------------------------
-- Titulo           : cxpp402.4gl - Listado retenciones pagadas          
-- Elaboracion      : 23-nov-2004
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxpp402 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE

DEFINE rm_cons		RECORD
	nom_depto	LIKE gent034.g34_nombre,
	nom_prov 	LIKE cxpt001.p01_nomprov,
	factura		LIKE ordt013.c13_factura,
	retencion	VARCHAR(20),
	base		LIKE cxpt028.p28_valor_base,
	retenido	LIKE cxpt028.p28_valor_ret
END RECORD




MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp402.error')
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
LET vg_proceso = 'cxpp402'
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
OPEN FORM f_rep FROM "../forms/repf402_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE comando		VARCHAR(100)
DEFINE fecha		LIKE cxpt027.p27_fecing

LET vm_fecha_ini = MDY(MONTH(TODAY), 1, YEAR(TODAY))
LET vm_fecha_fin = TODAY

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

	LET query = "SELECT (SELECT g34_nombre FROM gent034  ",
		    "         WHERE g34_cod_depto = c10_cod_depto) ",
		    "       (SELECT p01_nomprov FROM cxpt001 ", 
		    "	      WHERE p01_codprov = c10_codprov) ",
       		    "       c13_factura, p28_tipo_ret || ' ' || ",
                    "       ROUND(p28_porcentaje, 0) || '%'",
                    "       p28_valor_base, p28_valor_ret, ",
		    "       p27_fecing ",
  		    "  FROM ordt010, ordt013, cxpt027, cxpt028 ",
 		    " WHERE c10_compania  = ", vg_codcia, 
 		    "   AND c10_localidad = ", vg_codloc,
		    "   AND DATE(c10_fecing) BETWEEN '", vm_fecha_ini, "'",
					     "   AND '", vm_fecha_fin, "'",
                    "   AND c13_compania  = c10_compania ",
   	  	    "	AND c13_localidad = c10_localidad ",
  		    "	AND c13_numero_oc = c10_numero_oc ",
		    "   AND p27_compania  = c13_compania ",
		    "   AND p27_localidad = c13_localidad ",
		    "   AND p27_num_ret   = c13_num_ret ",
		    "   AND p27_estado    = 'A' ",
		    "   AND p28_compania  = p27_compania ",
		    "   AND p28_localidad = p27_localidad ",
		    "   AND p28_num_ret   = p27_num_ret ",
		    " ORDER BY 7, 1, 2, 3, 4, " 

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
	FOREACH q_deto INTO rm_cons.*, fecha 
		OUTPUT TO REPORT rep_reten(rm_cons.*, MONTH(fecha))
	END FOREACH
	FINISH REPORT rep_reten
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

LET int_flag = 0
INPUT BY NAME vm_fecha_ini, vm_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		ELSE
			LET vm_fecha_ini = fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fgl_winmessage(vg_producto,'Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT

END FUNCTION



REPORT rep_reten(nom_depto, nom_prov, factura, retencion, base, retenido, mes)
DEFINE nom_depto	LIKE gent034.g34_nombre
DEFINE nom_prov 	LIKE cxpt001.p01_nomprov
DEFINE factura		LIKE ordt013.c13_factura
DEFINE retencion	VARCHAR(20)
DEFINE base		LIKE cxpt028.p28_valor_base
DEFINE retenido		LIKE cxpt028.p28_valor_ret
DEFINE mes		SMALLINT

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
	print 'E'; print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&k4S'	                -- Letra (12 cpi)
	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO RETENCIONES PAGADAS', 80)
		RETURNING titulo

	PRINT COLUMN 1, rm_cia.g01_razonsocial,
  	      COLUMN 120, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 52, titulo CLIPPED,
	      COLUMN 124, "CXPP402" 

	PRINT COLUMN 48, "** Fecha Inicial : ", vm_fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 48, "** Fecha Final   : ", vm_fecha_fin USING "dd-mm-yyyy"
	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 112, usuario
	SKIP 1 LINES
	print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 1,   "Departamento",
	      COLUMN 42,  "Proveedor",
	      COLUMN 84,  "No. Fact.",
	      COLUMN 101, "Retencion",
	      COLUMN 123, "Valor Base",
	      COLUMN 141, "Valor Retenido"
	PRINT "----------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 1,   nom_depto[1,40] CLIPPED,
	      COLUMN 42,  nom_prov[1,40] CLIPPED,
	      COLUMN 84,  factura,
	      COLUMN 101, retencion,
	      COLUMN 123, base USING "-,---,---,--&.&&",
	      COLUMN 141, retenido USING "---,---,--&.&&"

BEFORE GROUP mes

ON LAST ROW
	PRINT COLUMN 48, "TOTALES ==>  ", total_bru USING "-,---,---,--&.##",
	      COLUMN 79,  total_des USING "---,---,--&.##",
	      COLUMN 95,  total_iva USING "---,---,--&.##",
	      COLUMN 111, total_net USING "-,---,---,--&.##"

END REPORT



FUNCTION borrar_cabecera()

CLEAR r19_moneda, tit_moneda, vm_fecha_ini, vm_fecha_fin
INITIALIZE rm_rep.*, vm_fecha_ini, vm_fecha_fin TO NULL

END FUNCTION



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
