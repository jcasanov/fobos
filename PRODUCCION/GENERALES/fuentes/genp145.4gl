--------------------------------------------------------------------------------
-- Titulo           : genp145.4gl - Cambio de Fecha del Sistema
-- Elaboracion      : 07-Feb-2018
-- Autor            : NPC
-- Formato Ejecucion: fglrun genp145 base modulo compania
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par			RECORD
							g100_localidad	LIKE gent100.g100_localidad,
							g100_usuario	LIKE gent100.g100_usuario,
							g05_nombres		LIKE gent005.g05_nombres,
							g100_fecha		LIKE gent100.g100_fecha
						END RECORD
DEFINE rm_detalle		ARRAY[500] OF RECORD
							g101_tipo		LIKE gent101.g101_tipo,
							g15_nombre		LIKE gent015.g15_nombre,
							g50_nombre		LIKE gent050.g50_nombre,
							g101_numero_ini	LIKE gent101.g101_numero_ini,
							g101_numero_fin	LIKE gent101.g101_numero_fin
						END RECORD
DEFINE rm_modulo		ARRAY[500] OF LIKE gent101.g101_modulo
DEFINE vm_row_num		SMALLINT        	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_row_max		SMALLINT			-- MAXIMO DE FILAS LEIDAS



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
LET vg_proceso = arg_val(0)
CALL startlog('../logs/' || vg_proceso CLIPPED || '.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_genf145_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
				BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_genf145_1 FROM '../forms/genf145_1'
ELSE
	OPEN FORM f_genf145_1 FROM '../forms/genf145_1c'
END IF
DISPLAY FORM f_genf145_1
LET vm_row_num = 0
LET vm_row_max = 500
CALL control_proceso()

END FUNCTION



FUNCTION control_proceso()

WHILE TRUE
	CALL borrar_detalle()
	CALL mostrar_botones_detalle()
	CALL muestra_contadores(0, 0)
	CALL control_ingreso()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL ingresa_detalle()
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	IF NOT procesar_detalle() THEN
		CONTINUE WHILE
	END IF
	EXIT WHILE
END WHILE

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

INITIALIZE rm_par.* TO NULL
FOR i = 1 TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
FOR i = 1 TO vm_row_max
	INITIALIZE rm_detalle[i].*, rm_modulo[i] TO NULL
END FOR
LET vm_row_num = 0

END FUNCTION



FUNCTION mostrar_botones_detalle()

--#DISPLAY "TP"			TO tit_col1
--#DISPLAY "Proceso"	TO tit_col2
--#DISPLAY "Módulo"		TO tit_col3
--#DISPLAY "Sec. Ini."	TO tit_col4
--#DISPLAY "Sec. Fin."	TO tit_col5

END FUNCTION



FUNCTION muestra_contadores(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION control_ingreso()

CALL ingresa_cabecera()
IF int_flag THEN
	RETURN
END IF
IF NOT cargar_detalle() THEN
	RETURN
END IF

END FUNCTION



FUNCTION ingresa_cabecera()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g05		RECORD LIKE gent005.*

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(g100_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_par.g100_localidad = r_g02.g02_localidad
				DISPLAY BY NAME rm_par.g100_localidad
			END IF
		END IF
		IF INFIELD(g100_usuario) THEN
			CALL fl_ayuda_usuarios("A")
				RETURNING r_g05.g05_usuario, r_g05.g05_nombres
			IF r_g05.g05_usuario IS NOT NULL THEN
				LET rm_par.g100_usuario = r_g05.g05_usuario
				LET rm_par.g05_nombres  = r_g05.g05_nombres
				DISPLAY BY NAME rm_par.g100_usuario, rm_par.g05_nombres
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		LET rm_par.g100_localidad = vg_codloc
		CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*
		LET rm_par.g100_usuario = r_g05.g05_usuario
		LET rm_par.g05_nombres  = r_g05.g05_nombres
		DISPLAY BY NAME rm_par.g100_localidad, rm_par.g100_usuario,
						rm_par.g05_nombres
	AFTER FIELD g100_localidad
		IF rm_par.g100_localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par.g100_localidad)
				RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD g100_localidad
			END IF
			IF r_g02.g02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD g100_localidad
			END IF
		END IF
	AFTER FIELD g100_usuario
		IF rm_par.g100_usuario IS NOT NULL THEN
			CALL fl_lee_usuario(rm_par.g100_usuario) RETURNING r_g05.*
			IF r_g05.g05_usuario IS NULL THEN
				CALL fl_mostrar_mensaje('Este usuario no existe.','exclamation')
				NEXT FIELD g100_usuario
			END IF
			LET rm_par.g05_nombres = r_g05.g05_nombres
			IF r_g05.g05_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD g100_usuario
			END IF
		ELSE
			LET rm_par.g05_nombres = NULL
		END IF
		DISPLAY BY NAME rm_par.g05_nombres
END INPUT

END FUNCTION



FUNCTION cargar_detalle()
DEFINE resul		SMALLINT

LET resul = 0
IF NOT obtener_secuencias_activas() THEN
	RETURN resul
END IF
IF NOT comparar_secuencias() THEN
	RETURN resul
END IF
LET resul = 1
DECLARE q_sec CURSOR FOR
	SELECT * FROM tmp_secuencias
		ORDER BY 5 DESC
LET vm_row_num = 1
FOREACH q_sec INTO rm_detalle[vm_row_num].*, rm_modulo[vm_row_num]
	LET vm_row_num = vm_row_num + 1
	IF vm_row_num > vm_row_max THEN
		CALL fl_mensaje_arreglo_incompleto()
		LET resul = 0
		EXIT FOREACH
	END IF
END FOREACH
DROP TABLE tmp_secuencias
LET vm_row_num = vm_row_num - 1
IF vm_row_num = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET resul = 0
END IF
RETURN resul

END FUNCTION



FUNCTION ingresa_detalle()
DEFINE resp			CHAR(6)
DEFINE i, j			SMALLINT

OPTIONS
	INSERT KEY F30,
	DELETE KEY F31

CALL set_count(vm_row_num)
LET int_flag = 0
INPUT ARRAY rm_detalle WITHOUT DEFAULTS FROM rm_detalle.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	BEFORE INPUT
		CALL dialog.keysetlabel('DELETE', '')
		CALL dialog.keysetlabel('INSERT', '')
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		CALL muestra_contadores(i, vm_row_num)
	BEFORE INSERT
		CANCEL INSERT
	BEFORE DELETE
		CANCEL DELETE
	AFTER FIELD g101_numero_fin
		IF rm_detalle[i].g101_numero_fin <= rm_detalle[i].g101_numero_ini THEN
			CALL fl_mostrar_mensaje('La secuencia final no puede ser menor o igual a la secuencia inicial.', 'exclamation')
			NEXT FIELD g101_numero_fin
		END IF
END INPUT

END FUNCTION



FUNCTION procesar_detalle()
DEFINE r_g100			RECORD LIKE gent100.*
DEFINE inserto, i		SMALLINT

BEGIN WORK
WHENEVER ERROR CONTINUE

	INITIALIZE r_g100.* TO NULL
	DECLARE q_g100_up CURSOR FOR
		SELECT * FROM gent100
			WHERE g100_compania  = vg_codcia
			  AND g100_localidad = rm_par.g100_localidad
		FOR UPDATE

	OPEN q_g100_up
	FETCH q_g100_up INTO r_g100.*
	IF STATUS <> 0 AND STATUS <> NOTFOUND THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		RETURN 0
	END IF

	DELETE FROM gent101
		WHERE g101_compania  = r_g100.g100_compania
		  AND g101_localidad = r_g100.g100_localidad

	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo borrar el registro en la tabla gent101 (detalle). Por favor llame al ADMINISTRADOR.', 'exclamation')
		RETURN 0
	END IF

	DELETE FROM gent100
		WHERE g100_compania  = r_g100.g100_compania
		  AND g100_localidad = r_g100.g100_localidad

	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo borrar el registro en la tabla gent100 (cabecera). Por favor llame al ADMINISTRADOR.', 'exclamation')
		RETURN 0
	END IF


	INSERT INTO gent100

		(g100_compania, g100_localidad, g100_usuario, g100_fecha)


		VALUES
			(vg_codcia, rm_par.g100_localidad, rm_par.g100_usuario,
			 rm_par.g100_fecha)

	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo insertar el registro en la tabla gent100 (cabecera). Por favor llame al ADMINISTRADOR.', 'exclamation')
		RETURN 0
	END IF

	LET inserto = 1
	FOR i = 1 TO vm_row_num

		INSERT INTO gent101
			(g101_compania, g101_localidad, g101_modulo, g101_tipo,
			 g101_numero_ini, g101_numero_fin)

			VALUES
				(vg_codcia, rm_par.g100_localidad, rm_modulo[i],
				 rm_detalle[i].g101_tipo, rm_detalle[i].g101_numero_ini,
				 rm_detalle[i].g101_numero_fin)

		IF STATUS <> 0 THEN
			WHENEVER ERROR STOP
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('No se pudo insertar el registro en la tabla gent101 (detalle). Por favor llame al ADMINISTRADOR.', 'exclamation')
			LET inserto = 0
			EXIT FOR
		END IF

	END FOR

	IF NOT inserto THEN
		RETURN 0
	END IF

WHENEVER ERROR STOP
COMMIT WORK

CALL fl_mostrar_mensaje('Cambio de Fecha en el Sistema OK.', 'info')
RETURN 1

END FUNCTION



FUNCTION obtener_secuencias_activas()
DEFINE query		CHAR(1000)
DEFINE expr_usu		VARCHAR(100)
DEFINE cuantos		SMALLINT

ERROR ' Obteniendo secuencias de gent015 o gent100 y gent101 ...'
--

{** Obteniendo las secuencias que se encuentran las tablas de secuencia por
		localidad, usuario y fecha.
		Estos registros se los carga en la tabla temporal tmp_sec y se retorna
		de la función, en caso de que existan registros en las tablas gent100
		y gent101.
		Las tablas menciondas, solo tiene un registro por localidad, usuario
		y fecha, en caso de procesar este registro en el programa, se borrará
		el existente y se insertará el actual.
**}
LET expr_usu = NULL
IF rm_par.g100_usuario IS NOT NULL THEN
	LET expr_usu = '  AND g100_usuario   = "', rm_par.g100_usuario CLIPPED, '"'
END IF

LET query = 'SELECT g100_compania AS cia, g100_localidad AS loc, ',
					'g101_modulo AS modulo, "AA" AS bode, g101_tipo AS tipo, ',
					'g101_numero_ini AS numero ',
				'FROM gent100, gent101 ',
				'WHERE g100_compania  = ', vg_codcia,
				'  AND g100_localidad = ', rm_par.g100_localidad,
				expr_usu CLIPPED, ' ',
				'  AND g100_fecha     = "', rm_par.g100_fecha, '" ',
				'  AND g101_compania  = g100_compania ',
				'  AND g101_localidad = g100_localidad ',
				'INTO TEMP tmp_sec'

PREPARE exec_sec FROM query
EXECUTE exec_sec

SELECT COUNT(*) INTO cuantos FROM tmp_sec

IF cuantos > 0 THEN
	RETURN 1
END IF

DROP TABLE tmp_sec
--

--

{** Obteniendo las secuencias de las transacciones de INVENTARIO con el valor
		que tiene la variable rm_par.fecha, para cargarlas en la tabla
		temporal: tmp_sec
**}

SELECT r19_compania AS cia, r19_localidad AS loc, "RE" AS modulo, "AA" AS bode,
		r19_cod_tran AS tipo, MAX(r19_num_tran) AS numero
	FROM rept019
	WHERE r19_localidad     = rm_par.g100_localidad
	  AND DATE(r19_fecing) <= rm_par.g100_fecha
	GROUP BY 1, 2, 3, 4, 5
	INTO TEMP tmp_sec
--

--

{** Obteniendo las secuencias de las ordenes de despacho de INVENTARIO con el
		valor que tiene la variable rm_par.fecha, para cargarlas en la tabla
		temporal: tmp_sec
**}

INSERT INTO tmp_sec
	SELECT r34_compania AS cia, r34_localidad AS loc, "RE" AS modulo,
			r34_bodega AS bode, 'OD' AS tipo, MAX(r34_num_ord_des) AS numero
		FROM rept034
		WHERE r34_localidad     = rm_par.g100_localidad
		  AND DATE(r34_fecing) <= rm_par.g100_fecha
		GROUP BY 1, 2, 3, 4, 5
--

--

{** Obteniendo las secuencias de las notas de entrega de INVENTARIO con el
		valor que tiene la variable rm_par.fecha, para cargarlas en la tabla
		temporal: tmp_sec
**}

INSERT INTO tmp_sec
	SELECT r36_compania AS cia, r36_localidad AS loc, "RE" AS modulo,
			r36_bodega AS bode, 'ND' AS tipo, MAX(r36_num_ord_des) AS numero
		FROM rept036
		WHERE r36_localidad     = rm_par.g100_localidad
		  AND DATE(r36_fecing) <= rm_par.g100_fecha
		GROUP BY 1, 2, 3, 4, 5
--

--

{** Obteniendo las secuencias de las proformas de INVENTARIO con el valor que
		tiene la variable rm_par.fecha, para cargarlas en la tabla
		temporal: tmp_sec
**}

INSERT INTO tmp_sec
	SELECT r21_compania AS cia, r21_localidad AS loc, "RE" AS modulo,
			"AA" AS bode, 'PF' AS tipo, MAX(r21_numprof) AS numero
		FROM rept021
		WHERE r21_localidad     = rm_par.g100_localidad
		  AND DATE(r21_fecing) <= rm_par.g100_fecha
		GROUP BY 1, 2, 3, 4, 5
--

--

{** Obteniendo las secuencias de las preventas de INVENTARIO con el valor
		que tiene la variable rm_par.fecha, para cargarlas en la tabla
		temporal: tmp_sec
**}

INSERT INTO tmp_sec
	SELECT r23_compania AS cia, r23_localidad AS loc, "RE" AS modulo,
			"AA" AS bode, 'PV' AS tipo, MAX(r23_numprof) AS numero
		FROM rept023
		WHERE r23_localidad     = rm_par.g100_localidad
		  AND DATE(r23_fecing) <= rm_par.g100_fecha
		GROUP BY 1, 2, 3, 4, 5
--

--

{** Obteniendo las secuencias de las transacciones de COBRANZAS con el valor
		que tiene la variable rm_par.fecha, para cargarlas en la tabla
		temporal: tmp_sec
**}

INSERT INTO tmp_sec
	SELECT z22_compania AS cia, z22_localidad AS loc, "CO" AS modulo,
			"AA" AS bode, z22_tipo_trn AS tipo, MAX(z22_num_trn) AS numero
		FROM cxct022
		WHERE z22_localidad     = rm_par.g100_localidad
		  AND DATE(z22_fecing) <= rm_par.g100_fecha
		GROUP BY 1, 2, 3, 4, 5
--

--

{** Obteniendo las secuencias de los documentos a favor de COBRANZAS con el
		valor que tiene la variable rm_par.fecha, para cargarlas en la tabla
		temporal: tmp_sec
**}

INSERT INTO tmp_sec
	SELECT z21_compania AS cia, z21_localidad AS loc, "CO" AS modulo,
			"AA" AS bode, z21_tipo_doc AS tipo, MAX(z21_num_doc) AS numero
		FROM cxct021
		WHERE z21_localidad     = rm_par.g100_localidad
		  AND DATE(z21_fecing) <= rm_par.g100_fecha
		GROUP BY 1, 2, 3, 4, 5
--

--

{** Obteniendo las secuencias de las solicitudes de cobro de COBRANZAS con el
		valor que tiene la variable rm_par.fecha, para cargarlas en la tabla
		temporal: tmp_sec
**}

INSERT INTO tmp_sec
	SELECT z24_compania AS cia, z24_localidad AS loc, "CO" AS modulo,
			"AA" AS bode, "SC" AS tipo, MAX(z24_numero_sol) AS numero
		FROM cxct024
		WHERE z24_localidad     = rm_par.g100_localidad
		  AND DATE(z24_fecing) <= rm_par.g100_fecha
		GROUP BY 1, 2, 3, 4, 5
--

--

{** Obteniendo las secuencias de las transacciones de TESORERIA con el valor
		valor que tiene la variable rm_par.fecha, para cargarlas en la tabla
		temporal: tmp_sec
**}

INSERT INTO tmp_sec
	SELECT p22_compania AS cia, p22_localidad AS loc, "TE" AS modulo,
			"AA" AS bode, p22_tipo_trn AS tipo, MAX(p22_num_trn) AS numero
		FROM cxpt022
		WHERE p22_localidad     = rm_par.g100_localidad
		  AND DATE(p22_fecing) <= rm_par.g100_fecha
		GROUP BY 1, 2, 3, 4, 5
--

--

{** Obteniendo las secuencias de los documentos a favor de TESORERIA con el
		valor que tiene la variable rm_par.fecha, para cargarlas en la tabla
		temporal: tmp_sec
**}

INSERT INTO tmp_sec
	SELECT p21_compania AS cia, p21_localidad AS loc, "TE" AS modulo,
			"AA" AS bode, p21_tipo_doc AS tipo, MAX(p21_num_doc) AS numero
		FROM cxpt021
		WHERE p21_localidad     = rm_par.g100_localidad
		  AND DATE(p21_fecing) <= rm_par.g100_fecha
		GROUP BY 1, 2, 3, 4, 5
--

--

{** Obteniendo las secuencias de las retenciones de TESORERIA con el valor
		que tiene la variable rm_par.fecha, para cargarlas en la tabla
		temporal: tmp_sec
**}

INSERT INTO tmp_sec
	SELECT p27_compania AS cia, p27_localidad AS loc, "TE" AS modulo,
			"AA" AS bode, "RT" AS tipo, MAX(p27_num_ret) AS numero
		FROM cxpt027
		WHERE p27_localidad     = rm_par.g100_localidad
		  AND DATE(p27_fecing) <= rm_par.g100_fecha
		GROUP BY 1, 2, 3, 4, 5
--

--

{** Obteniendo las secuencias de las ordenes de compras en el modulo de COMPRAS
		con el valor que tiene la variable rm_par.fecha, para cargarlas en la
		tabla temporal: tmp_sec
**}

INSERT INTO tmp_sec
	SELECT c10_compania AS cia, c10_localidad AS loc, "OC" AS modulo,
			"AA" AS bode, "OC" AS tipo, MAX(c10_numero_oc) AS numero
		FROM ordt010
		WHERE c10_localidad     = rm_par.g100_localidad
		  AND DATE(c10_fecing) <= rm_par.g100_fecha
		GROUP BY 1, 2, 3, 4, 5
--

--

{** Este SELECT es para obtener el numero de registros que contiene la tabla 
		temporal: tmp_sec
		SI la variable cuantos = 0, la función retorna FALSE (0) y dropea la
			tabla temporal tmp_sec
		CASO CONTRARIO la variable cuantos > 0, la función retorna TRUE (1)
**}

SELECT COUNT(*) INTO cuantos FROM tmp_sec
--

IF cuantos = 0 THEN
	DROP TABLE tmp_sec
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION comparar_secuencias()
DEFINE fec_cur		VARCHAR(19)
DEFINE fecha_cur	DATETIME YEAR TO SECOND
DEFINE query		CHAR(600)
DEFINE cuantos		SMALLINT

ERROR ' Comparando secuencias con la tabla gent015 ...'

SELECT a.*, numero, "U" AS actua
	FROM gent015 a, OUTER tmp_sec
	WHERE g15_compania   = cia
	  AND g15_localidad  = loc
	  AND g15_modulo     = modulo
	  AND g15_bodega     = bode
	  AND g15_tipo       = tipo
	  AND g15_numero    <> numero
	INTO TEMP tmp_sec_faltan

LET fec_cur   = rm_par.g100_fecha USING "yyyy-mm-dd", " ",
					EXTEND(CURRENT, HOUR TO SECOND)
LET fecha_cur = fec_cur

LET query = 'INSERT INTO tmp_sec_faltan ',
				'SELECT cia, loc, modulo, bode, tipo, ',
						'(SELECT g15_nombre ',
							'FROM gent015 ',
							'WHERE g15_compania   = cia ',
							'  AND g15_localidad  = loc ',
							'  AND g15_modulo     = modulo ',
							'  AND g15_bodega     = bode ',
							'  AND g15_tipo       = tipo), ',
						'numero, ',
						'CASE WHEN "', rm_par.g100_usuario CLIPPED, '" = "" ',
							'THEN "', rm_par.g100_usuario CLIPPED, '" ',
							'ELSE "FOBOS" ',
						'END, ',
						'"', fecha_cur, '", numero, "I" AS actua ',
					'FROM tmp_sec ',
					'WHERE NOT EXISTS ',
						'(SELECT 1 FROM gent015 ',
							'WHERE g15_compania   = cia ',
							'  AND g15_localidad  = loc ',
							'  AND g15_modulo     = modulo ',
							'  AND g15_bodega     = bode ',
							'  AND g15_tipo       = tipo) '

PREPARE exec_query FROM query
EXECUTE exec_query

DROP TABLE tmp_sec
--

--

{** Este SELECT es para obtener el numero de registros que contiene la tabla 
		temporal: tmp_sec_faltan
		SI la variable cuantos = 0, la función retorna FALSE (0) y dropea la
			tabla temporal tmp_sec_faltan
		CASO CONTRARIO la variable cuantos > 0, la función retorna TRUE (1)
**}

SELECT COUNT(*) INTO cuantos FROM tmp_sec_faltan

IF cuantos = 0 THEN
	DROP TABLE tmp_sec_faltan
	RETURN 0
END IF
--

--

{** Este SELECT es para quitar los registros "duplicados" que se encuentran en
		la tabla tmp_sec_faltan dejando solo los registros únicos en la tabla
		tmp_secuencias
**}

SELECT g15_tipo AS tipo, g15_nombre AS nom_proc, g50_nombre AS nom_mod,
		g15_numero AS num_ini, g15_numero + 1 AS num_fin, g15_modulo AS modu
	FROM tmp_sec_faltan, gent050
	WHERE g50_modulo = g15_modulo
	  AND g15_numero > 0
	GROUP BY 1, 2, 3, 4, 5, 6
	INTO TEMP tmp_secuencias

INSERT INTO tmp_secuencias
	SELECT g15_tipo AS tipo, g15_nombre AS nom_proc, g50_nombre AS nom_mod,
			g15_numero AS num_ini, g15_numero + 1 AS num_fin, g15_modulo AS modu
		FROM tmp_sec_faltan, gent050
		WHERE g50_modulo = g15_modulo
		  AND g15_numero = 0
		  AND NOT EXISTS
			(SELECT 1 FROM tmp_secuencias a
				WHERE a.tipo     = g15_tipo
				  AND a.modu     = g15_modulo)
		GROUP BY 1, 2, 3, 4, 5, 6

DROP TABLE tmp_sec_faltan
--

RETURN 1

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
