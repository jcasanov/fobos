------------------------------------------------------------------------------
-- Titulo           : repp434.4gl - Impresión Comprobante Guía de Remisión
-- Elaboracion      : 28-Jun-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp434 base módulo compañía localidad
-- 			guía_de_remisión cod_tran
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g02		RECORD LIKE gent002.*
DEFINE rm_r00		RECORD LIKE rept000.*
DEFINE rm_r19		RECORD LIKE rept019.*
DEFINE rm_r95		RECORD LIKE rept095.*
DEFINE rm_r97		RECORD LIKE rept097.*
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE tot_lineas	INTEGER



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp434.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp434'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE mensaje		CHAR(300)
DEFINE resp		CHAR(6)

CALL fl_nivel_isolation()
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_g02.*
IF rm_g02.g02_localidad IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
IF rm_r00.r00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No esta creada una compañía para el módulo de INVENTARIO.','stop')
	EXIT PROGRAM
END IF
INITIALIZE rm_r95.*, rm_r97.* TO NULL
LET rm_r95.r95_guia_remision = arg_val(5)
LET cod_tran                 = arg_val(6)
SELECT * INTO rm_r95.*
	FROM rept095
	WHERE r95_compania      = vg_codcia
	  AND r95_localidad     = vg_codloc
	  AND r95_guia_remision = rm_r95.r95_guia_remision
	  AND r95_estado        <> 'E'
IF rm_r95.r95_compania IS NULL THEN
	LET mensaje = 'No existe Guía de Remisión No. ',
			rm_r95.r95_guia_remision USING "<<<<<<<<&", '.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF rm_r95.r95_estado = 'A' THEN
	LET mensaje = 'La Guía de Remisión No. ',
			rm_r95.r95_guia_remision USING "<<<<<<<<&",
			' sera CERRADA. Recuerde que no podra ser modificada. ',
			'Desea continuar ?'
	CALL fl_hacer_pregunta(mensaje, 'Yes') RETURNING resp
	IF resp <> 'Yes' THEN
		EXIT PROGRAM
	END IF
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_r95 CURSOR FOR
		SELECT * FROM rept095
			WHERE r95_compania      = rm_r95.r95_compania
			  AND r95_localidad     = rm_r95.r95_localidad
			  AND r95_guia_remision = rm_r95.r95_guia_remision
			FOR UPDATE
	OPEN q_r95
	FETCH q_r95 INTO rm_r95.*
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	IF STATUS = NOTFOUND THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No existe el registro de guía de remisión. LLAME AL ADMINISTRADOR', 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	UPDATE rept095 SET r95_estado = 'C' WHERE CURRENT OF q_r95
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo cerrar la guía de remisión. LLAME AL ADMINISTRADOR', 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	COMMIT WORK
	WHENEVER ERROR STOP
END IF
SELECT * INTO rm_r97.*
	FROM rept097
	WHERE r97_compania      = vg_codcia
	  AND r97_localidad     = vg_codloc
	  AND r97_cod_tran      = 'FA'
	  AND r97_guia_remision = rm_r95.r95_guia_remision
CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, rm_r97.r97_cod_tran,
					rm_r97.r97_num_tran)
	RETURNING rm_r19.*
IF rm_r19.r19_compania IS NULL AND cod_tran = 'FA' THEN
	LET mensaje = 'No existe la Factura No. ', rm_r97.r97_cod_tran, '-',
			rm_r97.r97_num_tran USING "<<<<<<<<&", '.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE r_rep		RECORD
				item		LIKE rept020.r20_item,
				cantidad	LIKE rept037.r37_cant_ent,
				unidad		LIKE rept010.r10_uni_med,
				desc_clase	LIKE rept072.r72_desc_clase,
				descripcion	LIKE rept010.r10_nombre,
				secuencia	LIKE rept020.r20_orden,
				num_tran	LIKE rept020.r20_num_tran
			END RECORD
DEFINE comando		VARCHAR(100)
DEFINE query		CHAR(800)
DEFINE cont_lin		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
SELECT r96_compania, r96_localidad, r96_bodega, r96_num_entrega
	FROM rept097, rept096
	WHERE r97_compania      = vg_codcia
	  AND r97_localidad     = vg_codloc
	  AND r97_guia_remision = rm_r95.r95_guia_remision
	  AND r96_compania      = r97_compania
	  AND r96_localidad     = r97_localidad
	  AND r96_guia_remision = r97_guia_remision
	INTO TEMP tmp_guia
LET query = 'SELECT r37_item, NVL(SUM(r37_cant_ent), 0) r37_cant_ent,',
			' r10_uni_med, r72_desc_clase, r10_nombre ',
		' FROM tmp_guia, rept037, rept010, rept072 ',
		' WHERE r37_compania    = r96_compania ',
		'   AND r37_localidad   = r96_localidad ',
		'   AND r37_bodega      = r96_bodega ',
		'   AND r37_num_entrega = r96_num_entrega ',
		'   AND r10_compania    = r37_compania ',
		'   AND r10_codigo      = r37_item ',
		'   AND r72_compania    = r10_compania ',
		'   AND r72_linea       = r10_linea ',
		'   AND r72_sub_linea   = r10_sub_linea ',
		'   AND r72_cod_grupo   = r10_cod_grupo ',
		'   AND r72_cod_clase   = r10_cod_clase ',
		' GROUP BY 1, 3, 4, 5 '
IF cod_tran = 'TR' THEN
	LET query = 'SELECT r20_item, r20_cant_ven, r10_uni_med,',
			' r72_desc_clase, r10_nombre, r20_orden, r20_num_tran ',
			' FROM rept097, rept020, rept010, rept072 ',
			' WHERE r97_compania      = ', vg_codcia,
			'   AND r97_localidad     = ', vg_codloc,
			'   AND r97_cod_tran      = "', cod_tran, '"',
			'   AND r97_guia_remision = ', rm_r95.r95_guia_remision,
			'   AND r20_compania      = r97_compania ',
			'   AND r20_localidad     = r97_localidad ',
			'   AND r20_cod_tran      = r97_cod_tran ',
			'   AND r20_num_tran      = r97_num_tran ',
			'   AND r10_compania      = r20_compania ',
			'   AND r10_codigo        = r20_item ',
			'   AND r72_compania      = r10_compania ',
			'   AND r72_linea         = r10_linea ',
			'   AND r72_sub_linea     = r10_sub_linea ',
			'   AND r72_cod_grupo     = r10_cod_grupo ',
			'   AND r72_cod_clase     = r10_cod_clase ',
			' ORDER BY r20_orden '
END IF
LET query = query CLIPPED, ' INTO TEMP t1 '
PREPARE tmp_t1 FROM query
EXECUTE tmp_t1
SELECT COUNT(*) INTO tot_lineas FROM t1
IF tot_lineas = 0 THEN
	DROP TABLE t1
	DROP TABLE tmp_guia
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
DECLARE q_guia CURSOR FOR SELECT * FROM t1
IF vg_codloc < 6 THEN
	START REPORT reporte_guia_remision01 TO PIPE comando
ELSE
	START REPORT reporte_guia_remision02 TO PIPE comando
END IF
LET cont_lin = 1
FOREACH q_guia INTO r_rep.*
	IF vg_codloc < 6 THEN
		OUTPUT TO REPORT reporte_guia_remision01(r_rep.*)
	ELSE
		OUTPUT TO REPORT reporte_guia_remision02(r_rep.*)
	END IF
	LET cont_lin = cont_lin + 1
	IF cont_lin > rm_r00.r00_numlin_fact THEN
		EXIT FOREACH
	END IF
END FOREACH
IF vg_codloc < 6 THEN
	FINISH REPORT reporte_guia_remision01
ELSE
	FINISH REPORT reporte_guia_remision02
END IF
DROP TABLE t1
DROP TABLE tmp_guia

END FUNCTION



REPORT reporte_guia_remision01(r_rep)
DEFINE r_rep		RECORD
				item		LIKE rept020.r20_item,
				cantidad	LIKE rept037.r37_cant_ent,
				unidad		LIKE rept010.r10_uni_med,
				desc_clase	LIKE rept072.r72_desc_clase,
				descripcion	LIKE rept010.r10_nombre,
				secuencia	LIKE rept020.r20_orden,
				num_tran	LIKE rept020.r20_num_tran
			END RECORD
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE r_r36		RECORD LIKE rept036.*
DEFINE r_r38		RECORD LIKE rept038.*
DEFINE r_r96		RECORD LIKE rept096.*
DEFINE numero		VARCHAR(35)
DEFINE col		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	DECLARE q_tmp CURSOR FOR
		SELECT r96_bodega, r96_num_entrega
			FROM tmp_guia
	OPEN q_tmp
	FETCH q_tmp INTO r_r96.r96_bodega, r_r96.r96_num_entrega
	CLOSE q_tmp
	FREE q_tmp
	CALL fl_lee_nota_entrega(vg_codcia, vg_codloc, r_r96.r96_bodega,
					r_r96.r96_num_entrega)
		RETURNING r_r36.*
	CALL fl_lee_cod_transaccion(rm_r19.r19_cod_tran) RETURNING r_g21.*
	INITIALIZE r_r38.* TO NULL
	SELECT * INTO r_r38.*
		FROM rept038
		WHERE r38_compania    = rm_r19.r19_compania
		  AND r38_localidad   = rm_r19.r19_localidad
		  AND r38_tipo_fuente = 'PR'
		  AND r38_cod_tran    = rm_r19.r19_cod_tran
		  AND r38_num_tran    = rm_r19.r19_num_tran
	CALL fl_lee_tipo_doc(r_r38.r38_tipo_doc) RETURNING r_z04.*
	LET numero = r_r38.r38_num_sri CLIPPED, ' (',
			rm_r19.r19_num_tran USING "<<<<<<<&", ')'
	SKIP 5 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 044, rm_r95.r95_fecha_initras USING "dd-mm-yyyy"
	IF rm_r19.r19_cod_tran = 'FA' THEN
		LET r_g21.g21_nombre = r_z04.z04_nombre CLIPPED
	END IF
	IF rm_r95.r95_fecha_fintras IS NOT NULL THEN
		PRINT COLUMN 044, rm_r95.r95_fecha_fintras USING "dd-mm-yyyy",
		      COLUMN 100, r_g21.g21_nombre CLIPPED
	ELSE
		PRINT COLUMN 100, r_g21.g21_nombre CLIPPED
	END IF
	SKIP 1 LINES
	PRINT COLUMN 100, numero CLIPPED
	IF rm_r95.r95_motivo = 'V' THEN
		PRINT COLUMN 022, 'X'
	ELSE
		PRINT COLUMN 022, ' '
	END IF
	IF rm_r95.r95_motivo = 'D' THEN
		PRINT COLUMN 022, 'X';
		IF rm_r95.r95_entre_local = 'S' THEN
			PRINT COLUMN 065, 'X';
		ELSE
			PRINT COLUMN 065, ' ';
		END IF
		PRINT COLUMN 100, DATE(rm_r19.r19_fecing) USING "dd-mm-yyyy"
	ELSE
		IF rm_r95.r95_entre_local = 'S' THEN
			PRINT COLUMN 065, 'X';
		ELSE
			PRINT COLUMN 065, ' ';
		END IF
		PRINT COLUMN 100, DATE(rm_r19.r19_fecing) USING "dd-mm-yyyy"
	END IF
	IF rm_r95.r95_motivo = 'I' THEN
		PRINT COLUMN 022, 'X'
	ELSE
		PRINT COLUMN 022, ' '
	END IF
	PRINT COLUMN 100, rm_r95.r95_autoriz_sri
	PRINT COLUMN 024, rm_r95.r95_fecha_emi USING "dd-mm-yyyy"
	PRINT COLUMN 024, rm_r95.r95_punto_part[1, 46] CLIPPED
	IF LENGTH(rm_r95.r95_punto_part) > 46 THEN
		PRINT COLUMN 024, rm_r95.r95_punto_part[47, 92] CLIPPED;
	ELSE
		PRINT COLUMN 024, ' ';
	END IF
	SKIP 1 LINES
	PRINT COLUMN 091, rm_r95.r95_persona_guia[1, 50] CLIPPED
	PRINT COLUMN 091, rm_r95.r95_persona_id CLIPPED,
	      COLUMN 117, rm_r95.r95_placa CLIPPED
	PRINT COLUMN 033, rm_r95.r95_persona_dest[1, 95] CLIPPED
	PRINT COLUMN 033, rm_r95.r95_pers_id_dest CLIPPED
	PRINT COLUMN 033, rm_r95.r95_punto_lleg[1, 97] CLIPPED
	SKIP 3 LINES

ON EVERY ROW
	IF tot_lineas <= rm_r00.r00_numlin_fact THEN
		NEED 2 LINES
		PRINT COLUMN 004, r_rep.cantidad	USING '###,##&.##',
		      COLUMN 025, r_rep.unidad			CLIPPED,
		      COLUMN 044, r_rep.item[1, 7]		CLIPPED,
		      COLUMN 055, r_rep.desc_clase		CLIPPED
		PRINT COLUMN 055, r_rep.descripcion[1,65]	CLIPPED;
		IF cod_tran = 'TR' THEN
			PRINT COLUMN 122, r_rep.num_tran USING '<<<<<<<&'
		ELSE
			PRINT COLUMN 122, ' '
		END IF
	END IF
	
ON LAST ROW
	IF tot_lineas > rm_r00.r00_numlin_fact THEN
		PRINT COLUMN 005, "VER DETALLE DE ITEMS ADJUNTO",
				  " EN TRANSFERENCIAS: "
		SKIP 1 LINES
		DECLARE q_r97 CURSOR FOR
			SELECT r97_num_tran FROM rept097
				WHERE r97_compania      = vg_codcia
				  AND r97_localidad     = vg_codloc
				  AND r97_guia_remision=rm_r95.r95_guia_remision
				  AND r97_cod_tran      = cod_tran
				ORDER BY 1
		LET col = 10
		FOREACH q_r97 INTO r_rep.num_tran
			PRINT COLUMN col, cod_tran, '-',
				r_rep.num_tran USING '<<<<<<<&';
			LET col = col + 13
			IF col > 114 THEN
				PRINT ' '
				LET col = 10
			END IF
		END FOREACH
	END IF
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



REPORT reporte_guia_remision02(r_rep)
DEFINE r_rep		RECORD
				item		LIKE rept020.r20_item,
				cantidad	LIKE rept037.r37_cant_ent,
				unidad		LIKE rept010.r10_uni_med,
				desc_clase	LIKE rept072.r72_desc_clase,
				descripcion	LIKE rept010.r10_nombre,
				secuencia	LIKE rept020.r20_orden,
				num_tran	LIKE rept020.r20_num_tran
			END RECORD
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE r_r36		RECORD LIKE rept036.*
DEFINE r_r38		RECORD LIKE rept038.*
DEFINE r_r96		RECORD LIKE rept096.*
DEFINE numero		VARCHAR(35)
DEFINE col		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	3
	PAGE LENGTH	60

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	DECLARE q_tmp2 CURSOR FOR
		SELECT r96_bodega, r96_num_entrega
			FROM tmp_guia
	OPEN q_tmp2
	FETCH q_tmp2 INTO r_r96.r96_bodega, r_r96.r96_num_entrega
	CLOSE q_tmp2
	FREE q_tmp2
	CALL fl_lee_nota_entrega(vg_codcia, vg_codloc, r_r96.r96_bodega,
					r_r96.r96_num_entrega)
		RETURNING r_r36.*
	CALL fl_lee_cod_transaccion(rm_r19.r19_cod_tran) RETURNING r_g21.*
	INITIALIZE r_r38.* TO NULL
	SELECT * INTO r_r38.*
		FROM rept038
		WHERE r38_compania    = rm_r19.r19_compania
		  AND r38_localidad   = rm_r19.r19_localidad
		  AND r38_tipo_fuente = 'PR'
		  AND r38_cod_tran    = rm_r19.r19_cod_tran
		  AND r38_num_tran    = rm_r19.r19_num_tran
	CALL fl_lee_tipo_doc(r_r38.r38_tipo_doc) RETURNING r_z04.*
	LET numero = r_r38.r38_num_sri CLIPPED, ' (',
			rm_r19.r19_num_tran USING "<<<<<<<&", ')'
	SKIP 5 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 042, rm_r95.r95_fecha_initras USING "dd-mm-yyyy"
	IF rm_r19.r19_cod_tran = 'FA' THEN
		LET r_g21.g21_nombre = r_z04.z04_nombre CLIPPED
	END IF
	IF rm_r95.r95_fecha_fintras IS NOT NULL THEN
		PRINT COLUMN 044, rm_r95.r95_fecha_fintras USING "dd-mm-yyyy",
		      COLUMN 088, r_g21.g21_nombre CLIPPED
	ELSE
		PRINT COLUMN 088, r_g21.g21_nombre CLIPPED
	END IF
	SKIP 1 LINES
	PRINT COLUMN 091, numero CLIPPED
	IF rm_r95.r95_motivo = 'V' THEN
		PRINT COLUMN 031, 'X'
	ELSE
		PRINT COLUMN 099, ' '
	END IF
	SKIP 1 LINES
	IF rm_r95.r95_motivo = 'D' THEN
		PRINT COLUMN 027, 'X';
		IF rm_r95.r95_entre_local = 'S' THEN
			PRINT COLUMN 075, 'X'
		ELSE
			PRINT COLUMN 075, ' '
		END IF
		PRINT COLUMN 100, DATE(rm_r19.r19_fecing) USING "dd-mm-yyyy"
	ELSE
		IF rm_r95.r95_entre_local = 'S' THEN
			PRINT COLUMN 075, 'X'
		ELSE
			PRINT COLUMN 075, ' '
		END IF
		PRINT COLUMN 100, DATE(rm_r19.r19_fecing) USING "dd-mm-yyyy"
	END IF
	IF rm_r95.r95_motivo = 'I' THEN
		PRINT COLUMN 027, 'X';
	ELSE
		PRINT COLUMN 027, ' ';
	END IF
	PRINT COLUMN 102, rm_r95.r95_autoriz_sri
	PRINT COLUMN 026, rm_r95.r95_fecha_emi USING "dd-mm-yyyy"
	PRINT COLUMN 024, rm_r95.r95_punto_part[1, 46] CLIPPED
	IF LENGTH(rm_r95.r95_punto_part) > 46 THEN
		PRINT COLUMN 024, rm_r95.r95_punto_part[47, 92] CLIPPED;
	ELSE
		PRINT COLUMN 024, ' ';
	END IF
	SKIP 1 LINES
	PRINT COLUMN 084, rm_r95.r95_persona_guia[1, 50] CLIPPED
	PRINT COLUMN 091, rm_r95.r95_persona_id CLIPPED,
	      COLUMN 117, rm_r95.r95_placa CLIPPED
	PRINT COLUMN 031, rm_r95.r95_persona_dest[1, 95] CLIPPED
	PRINT COLUMN 016, rm_r95.r95_pers_id_dest CLIPPED
	PRINT COLUMN 025, rm_r95.r95_punto_lleg[1, 105] CLIPPED
	SKIP 3 LINES

ON EVERY ROW
	IF tot_lineas <= rm_r00.r00_numlin_fact THEN
		NEED 2 LINES
		PRINT COLUMN 004, r_rep.cantidad	USING '###,##&.##',
		      COLUMN 025, r_rep.unidad			CLIPPED,
		      COLUMN 044, r_rep.item[1, 7]		CLIPPED,
		      COLUMN 055, r_rep.desc_clase		CLIPPED
		PRINT COLUMN 055, r_rep.descripcion[1,65]	CLIPPED;
		IF cod_tran = 'TR' THEN
			PRINT COLUMN 122, r_rep.num_tran USING '<<<<<<<&'
		ELSE
			PRINT COLUMN 122, ' '
		END IF
	END IF
	
ON LAST ROW
	IF tot_lineas > rm_r00.r00_numlin_fact THEN
		PRINT COLUMN 005, "VER DETALLE DE ITEMS ADJUNTO",
				  " EN TRANSFERENCIAS: "
		SKIP 1 LINES
		DECLARE q_r97_2 CURSOR FOR
			SELECT r97_num_tran FROM rept097
				WHERE r97_compania      = vg_codcia
				  AND r97_localidad     = vg_codloc
				  AND r97_guia_remision=rm_r95.r95_guia_remision
				  AND r97_cod_tran      = cod_tran
				ORDER BY 1
		LET col = 10
		FOREACH q_r97_2 INTO r_rep.num_tran
			PRINT COLUMN col, cod_tran, '-',
				r_rep.num_tran USING '<<<<<<<&';
			LET col = col + 13
			IF col > 114 THEN
				PRINT ' '
				LET col = 10
			END IF
		END FOREACH
	END IF
	print ASCII escape;
	print ASCII desact_comp 

END REPORT
