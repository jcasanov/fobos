--------------------------------------------------------------------------------
-- Titulo           : cxpp405.4gl - IMPRESION COMPROBANTE DE RETENCIONES
-- Elaboracion      : 05-jul-2017
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxpp405 BD MODULO COMPANIA LOCALIDAD RETENCION
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_p27			RECORD LIKE cxpt027.*
DEFINE rm_p01			RECORD LIKE cxpt001.*
DEFINE rm_cia			RECORD LIKE gent001.*
DEFINE rm_loc			RECORD LIKE gent002.*
DEFINE vm_num_ret		LIKE cxpt027.p27_num_ret 
DEFINE nomprov1			LIKE cxpt001.p01_nomprov
DEFINE nomprov2			LIKE cxpt001.p01_nomprov
DEFINE vm_lin_max		INTEGER
DEFINE vm_total_val		DECIMAL(12,2)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp405.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vm_num_ret = arg_val(5)
LET vg_proceso = 'cxpp405'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE query		CHAR(400)
DEFINE comando		VARCHAR(100)

CALL fl_nivel_isolation()
INITIALIZE rm_p27.* TO NULL
CALL fl_lee_retencion_cxp(vg_codcia, vg_codloc, vm_num_ret) RETURNING rm_p27.*
IF rm_p27.p27_num_ret IS NULL THEN	
	CALL fl_mostrar_mensaje('Retencion no existe.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_proveedor(rm_p27.p27_codprov) RETURNING rm_p01.*
IF rm_p01.p01_codprov IS NULL THEN
	CALL fl_mostrar_mensaje('Proveedor no existe.','stop')
	EXIT PROGRAM
END IF
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	EXIT PROGRAM
END IF
SELECT cxpt028.*, c03_concepto_ret
	FROM cxpt028, OUTER ordt003
	WHERE p28_compania       = vg_codcia
	  AND p28_localidad      = vg_codloc
	  AND p28_num_ret        = vm_num_ret
	  AND c03_compania       = p28_compania
	  AND c03_tipo_ret       = p28_tipo_ret
	  AND c03_porcentaje     = p28_porcentaje
	  AND c03_codigo_sri     = p28_codigo_sri
	  AND c03_fecha_ini_porc = p28_fecha_ini_porc
	INTO TEMP tmp_ret
LET vm_lin_max = 9
CALL control_main_reporte(comando)
DROP TABLE tmp_ret

END FUNCTION



FUNCTION control_main_reporte(comando)
DEFINE r_p28_f			RECORD
							p28_compania	LIKE cxpt028.p28_compania,
							p28_localidad	LIKE cxpt028.p28_localidad,
							p28_num_ret	LIKE cxpt028.p28_num_ret,
							p28_secuencia	LIKE cxpt028.p28_secuencia,
							p28_codprov	LIKE cxpt028.p28_codprov,
							p28_tipo_doc	LIKE cxpt028.p28_tipo_doc,
							p28_num_doc	LIKE cxpt028.p28_num_doc,
							p28_dividendo	LIKE cxpt028.p28_dividendo,
							p28_valor_fact	LIKE cxpt028.p28_valor_fact,
							p28_tipo_ret	LIKE cxpt028.p28_tipo_ret,
							p28_porcentaje	LIKE cxpt028.p28_porcentaje,
							p28_codigo_sri	LIKE cxpt028.p28_codigo_sri,
							p28_fecha_ini_porc LIKE cxpt028.p28_fecha_ini_porc,
							p28_valor_base	LIKE cxpt028.p28_valor_base,
							p28_valor_ret	LIKE cxpt028.p28_valor_ret,
							c03_concepto_ret LIKE ordt003.c03_concepto_ret
						END RECORD
DEFINE comando		VARCHAR(100)
DEFINE query		CHAR(400)

CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
LET nomprov1 = NULL
LET nomprov2 = rm_p01.p01_nomprov CLIPPED
IF LENGTH(rm_p01.p01_nomprov) > 55 THEN
	CALL obtener_nombre_prov_dos_lineas()
END IF
INITIALIZE r_p28_f.* TO NULL 
LET query = 'SELECT * FROM tmp_ret ',
		' ORDER BY p28_tipo_ret, p28_codprov, p28_tipo_doc, p28_num_doc, ',
			'p28_dividendo'
PREPARE cons_p28 FROM query
DECLARE q_p28 CURSOR FOR cons_p28
START REPORT report_retencion TO PIPE comando
LET vm_total_val = 0
FOREACH q_p28 INTO r_p28_f.*
	OUTPUT TO REPORT report_retencion(r_p28_f.*)
END FOREACH
FINISH REPORT report_retencion

END FUNCTION



FUNCTION obtener_nombre_prov_dos_lineas()
DEFINE i, l, tope	SMALLINT

LET tope = 60
IF LENGTH(rm_p01.p01_nomprov) < tope THEN
	LET tope = 55
END IF
LET nomprov1 = rm_p01.p01_nomprov[1, tope]
LET l        = tope
WHILE l > 1
	LET i = l + 1
	IF nomprov1[l, l] = " " AND tope = l THEN
		EXIT WHILE
	END IF
	IF rm_p01.p01_nomprov[i, i] = " " AND tope = l THEN
		EXIT WHILE
	END IF
	IF nomprov1[l, l] = " " THEN
		LET nomprov1 = nomprov1[1, l - 1] CLIPPED
		EXIT WHILE
	END IF
	LET l = l - 1
END WHILE
IF rm_p01.p01_nomprov[i, i] = " " AND tope = i - 1 THEN
	LET i = i + 1
END IF
LET nomprov2 = rm_p01.p01_nomprov[i, 95] CLIPPED

END FUNCTION



REPORT report_retencion(r_iva_fuente)
DEFINE r_iva_fuente	RECORD
						p28_compania	LIKE cxpt028.p28_compania,
						p28_localidad	LIKE cxpt028.p28_localidad,
						p28_num_ret	LIKE cxpt028.p28_num_ret,
						p28_secuencia	LIKE cxpt028.p28_secuencia,
						p28_codprov	LIKE cxpt028.p28_codprov,
						p28_tipo_doc	LIKE cxpt028.p28_tipo_doc,
						p28_num_doc	LIKE cxpt028.p28_num_doc,
						p28_dividendo	LIKE cxpt028.p28_dividendo,
						p28_valor_fact	LIKE cxpt028.p28_valor_fact,
						p28_tipo_ret	LIKE cxpt028.p28_tipo_ret,
						p28_porcentaje	LIKE cxpt028.p28_porcentaje,
						p28_codigo_sri	LIKE cxpt028.p28_codigo_sri,
						p28_fecha_ini_porc LIKE cxpt028.p28_fecha_ini_porc,
						p28_valor_base	LIKE cxpt028.p28_valor_base,
						p28_valor_ret	LIKE cxpt028.p28_valor_ret,
						c03_concepto_ret LIKE ordt003.c03_concepto_ret
					END RECORD
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE codigo_var	VARCHAR(20)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_dob1		SMALLINT
DEFINE act_dob2		SMALLINT
DEFINE des_dob		SMALLINT
DEFINE act_neg		SMALLINT
DEFINE des_neg		SMALLINT

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	0
	RIGHT  MARGIN	132
	BOTTOM MARGIN	3
	PAGE   LENGTH	44

FORMAT

PAGE HEADER
	--print 'E';
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&k4S' 	-- Letra condensada (12 cpi)
	LET escape		= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob		= 48		# Desactivar Doble Ancho
	LET act_neg		= 71		# Activar la negrita
	LET des_neg		= 72		# Desactivar la negrita
	SKIP 9 LINES
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 008, '(', rm_p01.p01_codprov USING "###&&&", ')',
	      COLUMN 017, nomprov2 CLIPPED,
	      COLUMN 081, ASCII escape, ASCII act_neg,
	      COLUMN 090, DATE(rm_p27.p27_fecing) USING "dd-mm-yyyy",
		ASCII escape, ASCII des_neg,
		ASCII escape, ASCII act_comp
	PRINT COLUMN 008, rm_p01.p01_num_doc,
		  COLUMN 095, "FACTURA"
	PRINT COLUMN 008, rm_p01.p01_direccion1[1,40],
	      COLUMN 095, r_iva_fuente.p28_num_doc CLIPPED
	SKIP 4 LINES

ON EVERY ROW
	NEED 1 LINES
	LET codigo_var = r_iva_fuente.p28_codigo_sri CLIPPED
	CALL fl_lee_tipo_retencion(vg_codcia,
								r_iva_fuente.p28_tipo_ret,
								r_iva_fuente.p28_porcentaje)
		RETURNING r_c02.*
	PRINT COLUMN 001, YEAR(rm_p27.p27_fecing)		USING "####",
	      COLUMN 015, r_iva_fuente.p28_valor_base	USING "###,###,##&.##",
	      COLUMN 045, r_c02.c02_nombre CLIPPED,
		  COLUMN 067, codigo_var CLIPPED,
	      COLUMN 080, r_iva_fuente.p28_porcentaje	USING "##&.##",
	      COLUMN 096, r_iva_fuente.p28_valor_ret	USING "###,###,##&.##"
	LET vm_total_val = vm_total_val + r_iva_fuente.p28_valor_ret

ON LAST ROW
	--#SKIP vm_lin_max LINES
	SKIP 1 LINES
	NEED 1 LINES
	PRINT COLUMN 096, vm_total_val					USING "###,###,##&.##"
	print ASCII escape;
	print ASCII desact_comp
	
END REPORT
