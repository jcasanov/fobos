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
DEFINE vm_cerro		INTEGER
DEFINE vm_guia_cp	INTEGER



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
LET vm_cerro = 0
IF rm_r95.r95_estado = 'A' THEN
	LET mensaje = 'La Guía de Remisión No. ', rm_r95.r95_num_sri CLIPPED,
			--rm_r95.r95_guia_remision USING "<<<<<<<<&",
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
	LET vm_cerro = 1
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
DEFINE query		CHAR(1500)
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
LET vm_guia_cp = 0
IF cod_tran = 'TR' THEN
	LET query = 'SELECT r20_item, r20_cant_ven, r10_uni_med,',
			' r72_desc_clase, r10_nombre, r20_orden, r20_num_tran,',
			' r19_bodega_ori, r19_bodega_dest, r19_codcli ',
			' FROM rept097, rept019, rept020, rept010, rept072 ',
			' WHERE r97_compania      = ', vg_codcia,
			'   AND r97_localidad     = ', vg_codloc,
			'   AND r97_cod_tran      = "', cod_tran, '"',
			'   AND r97_guia_remision = ', rm_r95.r95_guia_remision,
			'   AND r19_compania      = r97_compania ',
			'   AND r19_localidad     = r97_localidad ',
			'   AND r19_cod_tran      = r97_cod_tran ',
			'   AND r19_num_tran      = r97_num_tran ',
			'   AND r20_compania      = r19_compania ',
			'   AND r20_localidad     = r19_localidad ',
			'   AND r20_cod_tran      = r19_cod_tran ',
			'   AND r20_num_tran      = r19_num_tran ',
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
IF cod_tran = 'TR' THEN
	CALL tiene_bodega_cp() RETURNING vm_guia_cp
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
IF vm_cerro THEN
	CALL generar_doc_elec(rm_r95.r95_guia_remision)
END IF

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
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE r_r36		RECORD LIKE rept036.*
--DEFINE r_r38		RECORD LIKE rept038.*
DEFINE r_r96		RECORD LIKE rept096.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE proc_orden1	LIKE rept095.r95_proc_orden
DEFINE proc_orden2	LIKE rept095.r95_proc_orden
DEFINE documento	VARCHAR(60)
DEFINE usuario		VARCHAR(10,5)
DEFINE modulo		VARCHAR(27)
DEFINE numero		VARCHAR(35)
DEFINE col		SMALLINT
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
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
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
	{--
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
	--}
	CALL fl_lee_tipo_doc(rm_r19.r19_cod_tran) RETURNING r_z04.*
	LET numero = rm_g02.g02_serie_cia USING "&&&", "-",
			rm_g02.g02_serie_loc USING "&&&", "-",
			rm_r19.r19_num_tran USING "&&&&&&&&&"
	--LET documento = "COMPROBANTE GUIA DE REMISION No. GR - ",
	LET documento = "GUIA DE REMISION No. GR - ",
			rm_g02.g02_serie_cia USING "&&&", "-",
			rm_g02.g02_serie_loc USING "&&&", "-",
			rm_r95.r95_guia_remision USING "&&&&&&&&&"
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	SKIP 2 LINES
	{--
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, ASCII escape, ASCII act_neg, modulo CLIPPED,
	      COLUMN 039, documento CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso),
			ASCII escape, ASCII des_neg
	--}
	PRINT COLUMN 002, ASCII escape, ASCII act_12cpi, ASCII escape,
			ASCII act_dob1, ASCII act_dob2,
			ASCII escape, ASCII act_neg,
	      COLUMN 026, documento CLIPPED,
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_10cpi,
		ASCII escape, ASCII des_neg
	SKIP 1 LINES
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 003, "FECHA INICIACION DEL TRASLADO: ",
	      COLUMN 046, rm_r95.r95_fecha_initras USING "dd-mm-yyyy",
	      COLUMN 072, ASCII escape, ASCII act_neg,
			"COMPROBANTE DE VENTA: ",
			ASCII escape, ASCII des_neg
	IF rm_r19.r19_cod_tran = 'FA' THEN
		LET r_g21.g21_nombre = r_z04.z04_nombre CLIPPED
	END IF
	IF rm_r95.r95_fecha_fintras IS NOT NULL THEN
		PRINT COLUMN 001, "FECHA TERMINACION DEL TRASLADO: ",
		      COLUMN 044, rm_r95.r95_fecha_fintras USING "dd-mm-yyyy",
		      COLUMN 070, "TIPO: ",
		      COLUMN 100, r_g21.g21_nombre CLIPPED
	ELSE
		PRINT COLUMN 070, "TIPO: ",
		      COLUMN 100, r_g21.g21_nombre CLIPPED
	END IF
	--SKIP 1 LINES
	PRINT COLUMN 001, ASCII escape, ASCII act_neg,
			"MOTIVO DEL TRASLADO: ",
			ASCII escape, ASCII des_neg,
	      COLUMN 074, "NUMERO: ";
	IF rm_r19.r19_cod_tran = 'FA' THEN
		PRINT COLUMN 104, numero CLIPPED
	ELSE
		PRINT COLUMN 104, " "
	END IF
	PRINT COLUMN 001, "VENTA: ";
	IF rm_r95.r95_motivo = 'V' OR vm_guia_cp THEN
		PRINT COLUMN 022, 'X';
	ELSE
		PRINT COLUMN 022, ' ';
	END IF
	PRINT COLUMN 030, "TRASLADO ENTRE ESTABLECIMIENTOS",
	      COLUMN 070, "FECHA DE EMISION: ",
	      COLUMN 100, DATE(rm_r19.r19_fecing) USING "dd-mm-yyyy"
	PRINT COLUMN 001, "DEVOLUCION: ";
	LET proc_orden1 = rm_r95.r95_proc_orden[01, 30]
	LET proc_orden2 = rm_r95.r95_proc_orden[31, 60]
	IF rm_r95.r95_motivo = 'D' THEN
		PRINT COLUMN 022, 'X',
		      COLUMN 030, "DE UNA MISMA EMPRESA: ";
		IF rm_r95.r95_entre_local = 'S' AND NOT vm_guia_cp THEN
			PRINT COLUMN 065, 'X';
		ELSE
			PRINT COLUMN 065, ' ';
		END IF
		PRINT COLUMN 070, "No.PROCESO/ORDEN: ",
		      COLUMN 100, proc_orden1 CLIPPED
	ELSE
		PRINT COLUMN 030, "DE UNA MISMA EMPRESA: ";
		IF rm_r95.r95_entre_local = 'S' AND NOT vm_guia_cp THEN
			PRINT COLUMN 065, 'X';
		ELSE
			PRINT COLUMN 065, ' ';
		END IF
		PRINT COLUMN 070, "No.PROCESO/ORDEN: ",
		      COLUMN 100, proc_orden1 CLIPPED
	END IF
	PRINT COLUMN 001, "IMPORTACION: ";
	IF rm_r95.r95_motivo = 'I' THEN
		PRINT COLUMN 022, 'X';
	ELSE
		PRINT COLUMN 022, ' ';
	END IF
	PRINT COLUMN 100, proc_orden2 CLIPPED
	SKIP 1 LINES
	--PRINT COLUMN 070, "AUTORIZACION SRI: ",
	--      COLUMN 100, rm_r95.r95_autoriz_sri
	PRINT COLUMN 001, "FECHA DE EMISON: ",
	      COLUMN 024, rm_r95.r95_fecha_emi USING "dd-mm-yyyy",
	      COLUMN 070, ASCII escape, ASCII act_neg,
			"IDENTIFICACION DE LA PERSONA",
			ASCII escape, ASCII des_neg
	PRINT COLUMN 001, "PUNTO DE PARTIDA: ",
	      COLUMN 024, rm_r95.r95_punto_part[1, 46] CLIPPED,
	      COLUMN 070, ASCII escape, ASCII act_neg,
			"ENCARGADA DEL TRANSPORTE:",
			ASCII escape, ASCII des_neg
	IF LENGTH(rm_r95.r95_punto_part) > 46 THEN
		PRINT COLUMN 024, rm_r95.r95_punto_part[47, 92] CLIPPED;
	ELSE
		PRINT COLUMN 024, ' ';
	END IF
	PRINT COLUMN 070, "NOMBRE o RAZON SOCAL: ",
	      COLUMN 091, rm_r95.r95_persona_guia[1, 50] CLIPPED
	PRINT COLUMN 001, ASCII escape, ASCII act_neg,
			"DESTINATARIO: ",
			ASCII escape, ASCII des_neg,
	      COLUMN 074, "RUC/CI: ",
	      COLUMN 091, rm_r95.r95_persona_id CLIPPED,
	      COLUMN 109, "PLACA: ",
	      COLUMN 117, rm_r95.r95_placa CLIPPED
	PRINT COLUMN 001, "NOMBRE o RAZON SOCAL: ",
	      COLUMN 033, rm_r95.r95_persona_dest[1, 95] CLIPPED
	PRINT COLUMN 001, "RUC/CI: ",
	      COLUMN 033, rm_r95.r95_pers_id_dest CLIPPED
	PRINT COLUMN 001, "PUNTO DE LLEGADA: ",
	      COLUMN 033, rm_r95.r95_punto_lleg[1, 97] CLIPPED
	PRINT COLUMN 001, "FECHA IMPRESION : ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 114, "USUARIO: ", usuario
	SKIP 1 LINES
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "CANTIDAD",
	      COLUMN 025, "UNID. MED.",
	      COLUMN 044, "ITEM",
	      COLUMN 055, "DESCRIPCION";
	IF rm_r19.r19_cod_tran = 'FA' THEN
		PRINT COLUMN 122, " "
	ELSE
		PRINT COLUMN 122, "DOCUMENTO"
	END IF
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	IF tot_lineas <= rm_r00.r00_numlin_fact THEN
		NEED 2 LINES
		PRINT COLUMN 001, r_rep.cantidad	USING '###,##&.##',
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

PAGE TRAILER
	--IF rm_r19.r19_cod_tran = 'FA' THEN
		IF vm_guia_cp THEN
			DECLARE q_cp2 CURSOR FOR
				SELECT r19_codcli
					FROM t1
			OPEN q_cp2
			FETCH q_cp2 INTO rm_r19.r19_codcli
			CLOSE q_cp2
			FREE q_cp2
		END IF
		CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
						rm_r19.r19_codcli)
			RETURNING r_z02.*
		PRINT COLUMN 002, ASCII escape, ASCII act_12cpi, ASCII escape,
				ASCII act_dob1, ASCII act_dob2,
				ASCII escape, ASCII act_neg,
		      COLUMN 008, "COPIA SIN DERECHO A CREDITO TRIBUTARIO",
			ASCII escape, ASCII act_dob1, ASCII des_dob,
			ASCII escape, ASCII act_10cpi,
			ASCII escape, ASCII des_neg,
			ASCII escape, ASCII act_comp
		PRINT COLUMN 002, "Estimado cliente: Su comprobante electronico ",
				"usted lo recibira en su cuenta de correo:"
		PRINT COLUMN 002, ASCII escape, ASCII act_neg,
				r_z02.z02_email CLIPPED, '.',
				ASCII escape, ASCII des_neg
		PRINT COLUMN 002, "Tambien podra consultar y descargar sus ",
				"comprobantes electronicos a traves del portal"
		PRINT COLUMN 002, "web ",
				ASCII escape, ASCII act_neg,
				"https://innobeefactura.com.",
				ASCII escape, ASCII des_neg,
				" Sus datos para el primer acceso son Usuario: "
		PRINT COLUMN 002, ASCII escape, ASCII act_neg,
				rm_r19.r19_cedruc CLIPPED, "@innobeefactura.com",
				ASCII escape, ASCII des_neg,
				" y su Clave: ",
				ASCII escape, ASCII act_neg,
				rm_r19.r19_cedruc CLIPPED, ".",
				ASCII escape, ASCII des_neg
	{--
	ELSE
		PRINT COLUMN 002, ASCII escape, ASCII act_12cpi, ASCII escape,
				ASCII act_dob1, ASCII act_dob2,
				ASCII escape, ASCII act_neg,
		      COLUMN 008, "COPIA SIN DERECHO A CREDITO TRIBUTARIO",
			ASCII escape, ASCII act_dob1, ASCII des_dob,
			ASCII escape, ASCII act_10cpi,
			ASCII escape, ASCII des_neg
		PRINT COLUMN 002, "Estimado cliente: Por cada comprobante electronico,",
				" usted recibira un email de notificacion;",
				" tambien podra consultar y descargar"
		PRINT COLUMN 002, "sus comprobantes electronicos desde cualquier ",
				"lugar (24/7), a traves de nuestro portal web ",
				ASCII escape, ASCII act_neg,
				"https://innobeefactura.com.",
				ASCII escape, ASCII des_neg
		PRINT COLUMN 001, " "
		PRINT COLUMN 001, " "
		PRINT COLUMN 001, " "
	END IF
	--}
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
--DEFINE r_r38		RECORD LIKE rept038.*
DEFINE r_r96		RECORD LIKE rept096.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE documento	VARCHAR(60)
DEFINE usuario		VARCHAR(10,5)
DEFINE modulo		VARCHAR(27)
DEFINE numero		VARCHAR(35)
DEFINE col		SMALLINT
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
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
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
	{--
	INITIALIZE r_r38.* TO NULL
	SELECT * INTO r_r38.*
		FROM rept038
		WHERE r38_compania    = rm_r19.r19_compania
		  AND r38_localidad   = rm_r19.r19_localidad
		  AND r38_tipo_fuente = 'PR'
		  AND r38_cod_tran    = rm_r19.r19_cod_tran
		  AND r38_num_tran    = rm_r19.r19_num_tran
	CALL fl_lee_tipo_doc(r_r38.r38_tipo_doc) RETURNING r_z04.*
	LET numero = r_r38.r38_num_sri CLIPPED, ' (', rm_r19.r19_num_tran USING "<<<<<<<&", ')'
	--}
	CALL fl_lee_tipo_doc(rm_r19.r19_cod_tran) RETURNING r_z04.*
	LET numero = rm_g02.g02_serie_cia USING "&&&", "-",
			rm_g02.g02_serie_loc USING "&&&", "-",
			rm_r19.r19_num_tran USING "&&&&&&&&&"
	LET documento = "COMPROBANTE GUIA DE REMISION No. GR- ",
			rm_g02.g02_serie_cia USING "&&&", "-",
			rm_g02.g02_serie_loc USING "&&&", "-",
			rm_r95.r95_guia_remision USING "&&&&&&&&&"
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	SKIP 3 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, ASCII escape, ASCII act_neg, modulo CLIPPED,
	      COLUMN 039, documento CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso),
			ASCII escape, ASCII des_neg
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA INICIACION DEL TRASLADO: ",
	      COLUMN 042, rm_r95.r95_fecha_initras USING "dd-mm-yyyy"
	IF rm_r19.r19_cod_tran = 'FA' THEN
		LET r_g21.g21_nombre = r_z04.z04_nombre CLIPPED
	END IF
	IF rm_r95.r95_fecha_fintras IS NOT NULL THEN
		PRINT COLUMN 001, "FECHA TERMINACION DEL TRASLADO: ",
		      COLUMN 044, rm_r95.r95_fecha_fintras USING "dd-mm-yyyy",
		      COLUMN 070, "TIPO: ",
		      COLUMN 088, r_g21.g21_nombre CLIPPED
	ELSE
		PRINT COLUMN 070, "TIPO: ",
		      COLUMN 088, r_g21.g21_nombre CLIPPED
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "MOTIVO DEL TRASLADO: ",
	      COLUMN 070, "NUMERO: ";
	IF rm_r19.r19_cod_tran = 'FA' THEN
		PRINT COLUMN 091, numero CLIPPED
	ELSE
		PRINT COLUMN 091, " "
	END IF
	PRINT COLUMN 001, "VENTA: ";
	IF rm_r95.r95_motivo = 'V' THEN
		PRINT COLUMN 031, 'X'
	ELSE
		PRINT COLUMN 099, ' '
	END IF
	SKIP 1 LINES
	PRINT COLUMN 030, "TRASLADO ENTRE ESTABLECIMIENTOS"
	PRINT COLUMN 001, "DEVOLUCION: ";
	IF rm_r95.r95_motivo = 'D' THEN
		PRINT COLUMN 027, 'X';
		IF rm_r95.r95_entre_local = 'S' THEN
			PRINT COLUMN 075, 'X'
		ELSE
			PRINT COLUMN 075, ' '
		END IF
		PRINT COLUMN 070, "FECHA DE EMISION: ",
		      COLUMN 100, DATE(rm_r19.r19_fecing) USING "dd-mm-yyyy"
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

PAGE TRAILER
	PRINT COLUMN 002, ASCII escape, ASCII act_12cpi, ASCII escape,
			ASCII act_dob1, ASCII act_dob2,
			ASCII escape, ASCII act_neg,
	      COLUMN 008, "COPIA SIN DERECHO A CREDITO TRIBUTARIO",
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_12cpi, ASCII escape, ASCII des_neg
	PRINT COLUMN 002, "Estimado cliente: Por cada comprobante electronico,",
			" usted recibira un email de notificacion;",
			" tambien podra consultar y descargar"
	PRINT COLUMN 002, "sus comprobantes electronicos desde cualquier ",
			"lugar (24/7), a traves de nuestro portal web ",
			ASCII escape, ASCII act_neg,
			"https://innobeefactura.com.",
			ASCII escape, ASCII des_neg
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION generar_doc_elec(guia)
DEFINE guia		LIKE rept095.r95_guia_remision
DEFINE comando		VARCHAR(250)
DEFINE servid		VARCHAR(10)
DEFINE mensaje		VARCHAR(250)

LET servid  = FGL_GETENV("INFORMIXSERVER")
CASE servid
	WHEN "ACGYE01"
		LET servid = "idsgye01"
	WHEN "ACUIO01"
		LET servid = "idsuio01"
	WHEN "ACUIO02"
		LET servid = "idsuio02"
END CASE
LET comando = "fglgo gen_tra_ele ", vg_base CLIPPED, " ", servid CLIPPED, " ",
		vg_codcia, " ", vg_codloc, " GR ", guia, " GRI"
RUN comando
LET mensaje = FGL_GETENV("HOME"), '/tmp/GR_ELEC/'
CALL fl_mostrar_mensaje('Archivo XML de GUIA REMISION Generado en: ' || mensaje, 'info')

END FUNCTION



FUNCTION tiene_bodega_cp()
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r09		RECORD LIKE rept009.*
DEFINE bod_o, bod_d	LIKE rept002.r02_codigo

DECLARE q_cp CURSOR FOR
	SELECT r19_bodega_ori, r19_bodega_dest
		FROM t1
OPEN q_cp
FETCH q_cp INTO bod_o, bod_d
CLOSE q_cp
FREE q_cp
CALL fl_lee_bodega_rep(vg_codcia, bod_o) RETURNING r_r02.*
CALL fl_lee_tipo_ident_bod(r_r02.r02_compania, r_r02.r02_tipo_ident)
	RETURNING r_r09.*
IF r_r09.r09_tipo_ident = "Y" THEN
	RETURN 1
END IF
CALL fl_lee_bodega_rep(vg_codcia, bod_d) RETURNING r_r02.*
CALL fl_lee_tipo_ident_bod(r_r02.r02_compania, r_r02.r02_tipo_ident)
	RETURNING r_r09.*
IF r_r09.r09_tipo_ident = "Y" THEN
	RETURN 1
END IF
RETURN 0

END FUNCTION
