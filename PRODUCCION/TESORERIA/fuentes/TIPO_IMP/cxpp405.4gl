--------------------------------------------------------------------------------
-- Titulo           : cxpp405.4gl - IMPRESION COMPROBANTE DE RETENCIONES
-- Elaboracion      : 01-feb-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxpp405 BD MODULO COMPANIA LOCALIDAD RETENCION
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_p27		RECORD LIKE cxpt027.*
DEFINE rm_p01		RECORD LIKE cxpt001.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE vm_num_ret	LIKE cxpt027.p27_num_ret 
DEFINE nomprov1		LIKE cxpt001.p01_nomprov
DEFINE nomprov2		LIKE cxpt001.p01_nomprov
DEFINE vm_lin, vm_lim_i	SMALLINT
DEFINE vm_lin_imp	SMALLINT
DEFINE vm_tot_lin_imp	SMALLINT
DEFINE vm_max_lin_imp	SMALLINT
DEFINE vm_salto_fin	SMALLINT
DEFINE vm_total_val	DECIMAL(12,2)
DEFINE vm_tot_val_g	DECIMAL(12,2)
DEFINE unavez, paginas	SMALLINT



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
DEFINE cuantos		INTEGER
DEFINE i, limite	INTEGER
DEFINE query		CHAR(400)
DEFINE comando		VARCHAR(100)

CALL fl_nivel_isolation()
INITIALIZE rm_p27.* TO NULL
LET vm_max_lin_imp = 3
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
SELECT * FROM cxpt028
	WHERE p28_compania  = vg_codcia
	  AND p28_localidad = vg_codloc
	  AND p28_num_ret   = vm_num_ret
	INTO TEMP tmp_ret
SELECT COUNT(*) INTO cuantos FROM tmp_ret WHERE p28_tipo_ret = 'F'
IF cuantos = 0 THEN
	SELECT COUNT(*) INTO cuantos FROM tmp_ret WHERE p28_tipo_ret = 'I'
END IF
LET query = 'SELECT TRUNC(', cuantos, ' / ', vm_max_lin_imp, ') + ',
		'CASE WHEN MOD(', cuantos, ', ', vm_max_lin_imp, ') > 0 ',
			'THEN 1 ELSE 0 END CASE',
		' FROM dual ',
		' INTO TEMP t1'
PREPARE cons_sum FROM query
EXECUTE cons_sum
SELECT * INTO limite FROM t1
DROP TABLE t1
LET paginas = 0
IF limite > 1 THEN
	LET paginas = 1
END IF
FOR i = 1 TO limite
	CALL control_main_reporte(comando)
END FOR
--DROP TABLE tmp_ret

END FUNCTION



FUNCTION control_main_reporte(comando)
DEFINE r_p28_i		RECORD LIKE cxpt028.*
DEFINE r_p28_f		RECORD LIKE cxpt028.*
DEFINE comando		VARCHAR(100)
DEFINE query		CHAR(400)

LET vm_tot_val_g = 0
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
SELECT * FROM tmp_ret WHERE p28_compania = 777 INTO TEMP t1
INITIALIZE r_p28_i.*, r_p28_f.* TO NULL 
LET query = 'SELECT FIRST ', vm_max_lin_imp, ' * ',
		' FROM tmp_ret ',
		' WHERE p28_tipo_ret = "F" ',
		' ORDER BY p28_codprov, p28_tipo_doc, p28_num_doc, ',
			'p28_dividendo'
PREPARE cons_p28_f FROM query
DECLARE q_p28_f CURSOR FOR cons_p28_f
LET query = 'SELECT FIRST ', vm_max_lin_imp, ' * ',
		' FROM tmp_ret ',
		' WHERE p28_tipo_ret = "I" ',
		' ORDER BY p28_codprov, p28_tipo_doc, p28_num_doc, ',
			'p28_dividendo'
PREPARE cons_p28_i FROM query
DECLARE q_p28_i CURSOR FOR cons_p28_i
START REPORT report_retencion TO PIPE comando
LET vm_tot_lin_imp = 0
FOREACH q_p28_f INTO r_p28_f.*
	LET vm_tot_lin_imp = vm_tot_lin_imp + 1
END FOREACH
LET vm_lim_i = 4
IF vm_tot_lin_imp = 0 THEN
	LET vm_lim_i = 8
END IF
OPEN q_p28_f
LET vm_lin	 = 0
LET vm_lin_imp	 = 0
LET vm_total_val = 0
WHILE TRUE     	
	FETCH q_p28_f INTO r_p28_f.*
	IF r_p28_f.p28_num_ret IS NULL THEN
		EXIT WHILE   
	END IF
	INSERT INTO t1 VALUES(r_p28_f.*)
	LET vm_lin_imp = vm_lin_imp + 1
	OUTPUT TO REPORT report_retencion(r_p28_f.*)
	INITIALIZE r_p28_f.* TO NULL 
	LET vm_lin = vm_lin + 1
END WHILE
LET vm_tot_lin_imp = 0
FOREACH q_p28_i INTO r_p28_i.*
	LET vm_tot_lin_imp = vm_tot_lin_imp + 1
END FOREACH
OPEN q_p28_i
LET vm_lin_imp	 = 0
LET vm_total_val = 0
LET vm_salto_fin = 2
IF vm_tot_lin_imp = 0 THEN
	LET vm_salto_fin = 10
END IF
LET unavez = 1
WHILE TRUE     	
	FETCH q_p28_i INTO r_p28_i.*
	IF r_p28_i.p28_num_ret IS NULL THEN
		EXIT WHILE   
	END IF
	INSERT INTO t1 VALUES(r_p28_i.*)
	LET vm_lin_imp = vm_lin_imp + 1
	OUTPUT TO REPORT report_retencion(r_p28_i.*)
	INITIALIZE r_p28_i.* TO NULL 
END WHILE
FINISH REPORT report_retencion
DELETE FROM tmp_ret
	WHERE EXISTS (SELECT * FROM t1
			WHERE t1.p28_tipo_doc   = tmp_ret.p28_tipo_doc
			  AND t1.p28_num_doc    = tmp_ret.p28_num_doc
			  AND t1.p28_dividendo  = tmp_ret.p28_dividendo
			  AND t1.p28_tipo_ret   = tmp_ret.p28_tipo_ret
			  AND t1.p28_porcentaje = tmp_ret.p28_porcentaje)
DROP TABLE t1

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
DEFINE r_iva_fuente	RECORD LIKE cxpt028.*            
DEFINE r_c02		RECORD LIKE ordt002.*            
DEFINE des_tip		VARCHAR(15)
DEFINE codigo_var	VARCHAR(20)
DEFINE escape, i	SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	3
	RIGHT  MARGIN	132
	BOTTOM MARGIN	3
	PAGE   LENGTH	44

FORMAT

PAGE HEADER
	--print 'E';
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	--print '&k4S' 	-- Letra condensada (12 cpi)
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar la negrita
	LET des_neg	= 72		# Desactivar la negrita
	SKIP 3 LINES
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_neg
	PRINT COLUMN 21,  rm_p01.p01_codprov USING "&&&&&&",
	      COLUMN 28,  nomprov1 CLIPPED
	PRINT COLUMN 21,  nomprov2 CLIPPED,
	      COLUMN 97,  DATE(rm_p27.p27_fecing) USING "dd-mm-yyyy"
	PRINT COLUMN 21,  rm_p01.p01_num_doc
	PRINT COLUMN 21,  rm_p01.p01_direccion1[1,40],
	      COLUMN 83,  "No. INTERNO: ",
	      COLUMN 97,  rm_p27.p27_num_ret	  USING "<<<<<<<<"
	PRINT COLUMN 02,  "TELEFONO: ",
	      COLUMN 21,  rm_p01.p01_telefono1 CLIPPED
	PRINT COLUMN 21,  YEAR(TODAY) USING "####"
	SKIP 3 LINES
	--print '&k2S' 		-- Letra condensada (16 cpi)

ON EVERY ROW
	LET codigo_var = NULL
	IF r_iva_fuente.p28_tipo_ret = 'I' THEN
		LET codigo_var = '       ', r_iva_fuente.p28_codigo_sri CLIPPED
		--LET codigo_var = '       2041'
		--IF (vm_tot_lin_imp = 1 OR vm_tot_lin_imp = vm_max_lin_imp - 1)
		IF vm_lin_imp = 1 THEN
		  --AND unavez)
		--THEN
			--FOR i = 1 TO 5 - vm_lin
			FOR i = 1 TO vm_lim_i
				--SKIP 1 LINES
				PRINT ' '
			END FOR
			LET unavez = 0
		END IF
{--
		IF paginas AND vm_lin_imp = 1 THEN
			LET unavez = 1
		END IF
--}
	END IF
	IF r_iva_fuente.p28_tipo_ret = 'F' THEN
		LET codigo_var = '       ', r_iva_fuente.p28_codigo_sri CLIPPED
	END IF
	CALL fl_lee_tipo_retencion(vg_codcia, r_iva_fuente.p28_tipo_ret,
					r_iva_fuente.p28_porcentaje)
		RETURNING r_c02.*
	CASE r_c02.c02_tipo_fuente
		WHEN 'B'
			LET des_tip = 'BIENES'
		WHEN 'S'
			LET des_tip = 'SERVICIOS'
		WHEN 'T'
			LET des_tip = 'BIEN/SERVICIO'
	END CASE
	PRINT COLUMN 02,  "FACTURA", " ", codigo_var CLIPPED,
	      COLUMN 40,  r_iva_fuente.p28_num_doc,
	      COLUMN 60,  r_iva_fuente.p28_valor_base	USING "###,###,##&.##",
	      COLUMN 77,  r_iva_fuente.p28_porcentaje	USING "##&.##",
	      COLUMN 88,  des_tip,
	      COLUMN 114, r_iva_fuente.p28_valor_ret	USING "###,###,##&.##"
	LET vm_total_val = vm_total_val + r_iva_fuente.p28_valor_ret
	LET vm_tot_val_g = vm_tot_val_g + r_iva_fuente.p28_valor_ret
	IF vm_tot_lin_imp = vm_lin_imp THEN
		FOR i = 1 TO vm_max_lin_imp - vm_lin_imp
			SKIP 1 LINES
		END FOR
		PRINT COLUMN 114, vm_total_val		USING "###,###,##&.##"
	END IF

ON LAST ROW
	FOR i = 1 TO vm_salto_fin
		SKIP 1 LINES
	END FOR
	PRINT COLUMN 114, vm_tot_val_g			USING "###,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII des_neg
	
END REPORT
