DATABASE aceros



DEFINE codcia		LIKE gent001.g01_compania
DEFINE base, base1	CHAR(20)



MAIN

	IF num_args() <> 1 AND num_args() <> 2 THEN
		DISPLAY 'Número de Parametros Incorrectos. Falta BASE o SERVER.'
		EXIT PROGRAM
	END IF
	LET base   = arg_val(1)
	LET base1  = base CLIPPED
	LET codcia = 1
	IF num_args() = 2 THEN
		LET base  = base CLIPPED, '@', arg_val(2)
	END IF
	CALL activar_base()
	CALL equipara_tabla_jer()

END MAIN



FUNCTION activar_base()
DEFINE r_g51		RECORD LIKE gent051.*

CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051
	WHERE g51_basedatos = base1
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base1
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION equipara_tabla_jer()

CALL crear_temporales()
CALL cargar_temporales()
BEGIN WORK
	CALL procesar_tablas()
COMMIT WORK
CALL borrar_tablas_tr()
DISPLAY ' '
DISPLAY 'Proceso Terminado OK.'

END FUNCTION



FUNCTION crear_temporales()

DISPLAY ' '
DISPLAY 'Creando tablas temporales ...'
SELECT * FROM rept003 WHERE r03_compania = 10 INTO TEMP tr_divis
SELECT * FROM rept070 WHERE r70_compania = 10 INTO TEMP tr_linea
SELECT * FROM rept071 WHERE r71_compania = 10 INTO TEMP tr_grupo
SELECT * FROM rept072 WHERE r72_compania = 10 INTO TEMP tr_clase
SELECT * FROM rept073 WHERE r73_compania = 10 INTO TEMP tr_marca
SELECT * FROM rept077 WHERE r77_compania = 10 INTO TEMP tr_codut
SELECT * FROM rept005 WHERE r05_codigo   = 'CACA' INTO TEMP tr_unimed
SELECT * FROM gent038 WHERE g38_capitulo = 'CACA' INTO TEMP tr_capitu
SELECT * FROM gent016 WHERE g16_partida  = 'CACA' INTO TEMP tr_partid
DISPLAY 'Creadas tablas temporales ...'

END FUNCTION



FUNCTION cargar_temporales()

DISPLAY ' '
DISPLAY 'Cargando tablas temporales para el proceso ...'
LOAD FROM "division.txt" INSERT INTO tr_divis
LOAD FROM "lineas.txt"   INSERT INTO tr_linea
LOAD FROM "grupos.txt"   INSERT INTO tr_grupo
LOAD FROM "clases.txt"   INSERT INTO tr_clase
LOAD FROM "marcas.txt"   INSERT INTO tr_marca
LOAD FROM "codutil.txt"  INSERT INTO tr_codut
LOAD FROM "medida.txt"   INSERT INTO tr_unimed
LOAD FROM "capitulo.txt" INSERT INTO tr_capitu
LOAD FROM "partidas.txt" INSERT INTO tr_partid
DISPLAY 'Cargadas tablas temporales ...'

END FUNCTION



FUNCTION procesar_tablas()

DISPLAY ' '
DISPLAY 'Procesando ...'
CALL procesar_division()
CALL procesar_lineas()
CALL procesar_grupos()
CALL procesar_clases()
CALL procesar_marcas()
CALL procesar_codigo_util()
CALL procesar_unidades_med()
CALL procesar_capitulos()
CALL procesar_partidas()

END FUNCTION



FUNCTION procesar_division()
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE i, j		SMALLINT

DISPLAY ' '
DECLARE q_div CURSOR FOR SELECT * FROM tr_divis
DISPLAY 'Procesando Divisiones ...'
LET i = 0
LET j = 0
FOREACH q_div INTO r_r03.*
	SELECT * FROM rept003
		WHERE r03_compania = r_r03.r03_compania
		  AND r03_codigo   = r_r03.r03_codigo
	IF STATUS = NOTFOUND THEN
		DISPLAY 'Insertando la División ', r_r03.r03_codigo
		LET r_r03.r03_fecing = CURRENT
		INSERT INTO rept003 VALUES(r_r03.*)
		LET i = i + 1
	ELSE
		DISPLAY 'Actualizando la División ', r_r03.r03_codigo
		UPDATE rept003
			SET r03_nombre      = r_r03.r03_nombre,
			    r03_estado      = r_r03.r03_estado,
			    r03_area        = r_r03.r03_area,
			    r03_porc_uti    = r_r03.r03_porc_uti,
			    r03_tipo        = r_r03.r03_tipo,
			    r03_dcto_tal    = r_r03.r03_dcto_tal,
			    r03_dcto_cont   = r_r03.r03_dcto_cont,
			    r03_dcto_cred   = r_r03.r03_dcto_cred,
			    r03_grupo_linea = r_r03.r03_grupo_linea
			WHERE r03_compania = r_r03.r03_compania
			  AND r03_codigo   = r_r03.r03_codigo
		LET j = j + 1
	END IF
END FOREACH
DISPLAY 'Se Insertaron ', i USING "<<<&", ' y se Actualizaron ', j USING "<<<&",
	' Divisiones. OK'

END FUNCTION



FUNCTION procesar_lineas()
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE i, j		SMALLINT

DISPLAY ' '
DECLARE q_lin CURSOR FOR SELECT * FROM tr_linea
DISPLAY 'Procesando Líneas ...'
LET i = 0
LET j = 0
FOREACH q_lin INTO r_r70.*
	SELECT * FROM rept070
		WHERE r70_compania  = r_r70.r70_compania
		  AND r70_linea     = r_r70.r70_linea
		  AND r70_sub_linea = r_r70.r70_sub_linea
	IF STATUS = NOTFOUND THEN
		DISPLAY 'Insertando la Línea ', r_r70.r70_sub_linea
		LET r_r70.r70_fecing = CURRENT
		INSERT INTO rept070 VALUES(r_r70.*)
		LET i = i + 1
	ELSE
		DISPLAY 'Actualizando la Línea ', r_r70.r70_sub_linea
		UPDATE rept070
			SET r70_desc_sub = r_r70.r70_desc_sub
			WHERE r70_compania  = r_r70.r70_compania
			  AND r70_linea     = r_r70.r70_linea
			  AND r70_sub_linea = r_r70.r70_sub_linea
		LET j = j + 1
	END IF
END FOREACH
DISPLAY 'Se Insertaron ', i USING "<<<&", ' y se Actualizaron ', j USING "<<<&",
	' Líneas. OK'

END FUNCTION



FUNCTION procesar_grupos()
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE i, j		SMALLINT

DISPLAY ' '
DECLARE q_grp CURSOR FOR SELECT * FROM tr_grupo
DISPLAY 'Procesando Grupos ...'
LET i = 0
LET j = 0
FOREACH q_grp INTO r_r71.*
	SELECT * FROM rept071
		WHERE r71_compania  = r_r71.r71_compania
		  AND r71_linea     = r_r71.r71_linea
		  AND r71_sub_linea = r_r71.r71_sub_linea
		  AND r71_cod_grupo = r_r71.r71_cod_grupo
	IF STATUS = NOTFOUND THEN
		DISPLAY 'Insertando el Grupo ', r_r71.r71_cod_grupo
		LET r_r71.r71_fecing = CURRENT
		INSERT INTO rept071 VALUES(r_r71.*)
		LET i = i + 1
	ELSE
		DISPLAY 'Actualizando el Grupo ', r_r71.r71_cod_grupo
		UPDATE rept071
			SET r71_desc_grupo = r_r71.r71_desc_grupo
			WHERE r71_compania  = r_r71.r71_compania
			  AND r71_linea     = r_r71.r71_linea
			  AND r71_sub_linea = r_r71.r71_sub_linea
			  AND r71_cod_grupo = r_r71.r71_cod_grupo
		LET j = j + 1
	END IF
END FOREACH
DISPLAY 'Se Insertaron ', i USING "<<<&", ' y se Actualizaron ', j USING "<<<&",
	' Grupos. OK'

END FUNCTION



FUNCTION procesar_clases()
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE i, j		SMALLINT

DISPLAY ' '
DECLARE q_cla CURSOR FOR SELECT * FROM tr_clase
DISPLAY 'Procesando Clases ...'
LET i = 0
LET j = 0
FOREACH q_cla INTO r_r72.*
	SELECT * FROM rept072
		WHERE r72_compania  = r_r72.r72_compania
		  AND r72_linea     = r_r72.r72_linea
		  AND r72_sub_linea = r_r72.r72_sub_linea
		  AND r72_cod_grupo = r_r72.r72_cod_grupo
		  AND r72_cod_clase = r_r72.r72_cod_clase
	IF STATUS = NOTFOUND THEN
		DISPLAY 'Insertando la Clase ', r_r72.r72_cod_clase
		LET r_r72.r72_fecing = CURRENT
		INSERT INTO rept072 VALUES(r_r72.*)
		LET i = i + 1
	ELSE
		DISPLAY 'Actualizando la Clase ', r_r72.r72_cod_clase
		UPDATE rept072
			SET r72_desc_clase = r_r72.r72_desc_clase
			WHERE r72_compania  = r_r72.r72_compania
			  AND r72_linea     = r_r72.r72_linea
			  AND r72_sub_linea = r_r72.r72_sub_linea
			  AND r72_cod_grupo = r_r72.r72_cod_grupo
			  AND r72_cod_clase = r_r72.r72_cod_clase
		LET j = j + 1
	END IF
END FOREACH
DISPLAY 'Se Insertaron ', i USING "<<<&", ' y se Actualizaron ', j USING "<<<&",
	' Clases. OK'

END FUNCTION



FUNCTION procesar_marcas()
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE i, j		SMALLINT

DISPLAY ' '
DECLARE q_mar CURSOR FOR SELECT * FROM tr_marca
DISPLAY 'Procesando Marcas ...'
LET i = 0
LET j = 0
FOREACH q_mar INTO r_r73.*
	SELECT * FROM rept073
		WHERE r73_compania = r_r73.r73_compania
		  AND r73_marca    = r_r73.r73_marca
	IF STATUS = NOTFOUND THEN
		DISPLAY 'Insertando la Marca ', r_r73.r73_marca
		LET r_r73.r73_fecing = CURRENT
		INSERT INTO rept073 VALUES(r_r73.*)
		LET i = i + 1
	ELSE
		DISPLAY 'Actualizando la Marca ', r_r73.r73_marca
		UPDATE rept073
			SET r73_desc_marca = r_r73.r73_desc_marca
			WHERE r73_compania = r_r73.r73_compania
			  AND r73_marca    = r_r73.r73_marca
		LET j = j + 1
	END IF
END FOREACH
DISPLAY 'Se Insertaron ', i USING "<<<&", ' y se Actualizaron ', j USING "<<<&",
	' Marcas. OK'

END FUNCTION



FUNCTION procesar_codigo_util()
DEFINE r_r77		RECORD LIKE rept077.*
DEFINE i, j		SMALLINT

DISPLAY ' '
DECLARE q_cdu CURSOR FOR SELECT * FROM tr_codut
DISPLAY 'Procesando Códigos de Utilidad ...'
LET i = 0
LET j = 0
FOREACH q_cdu INTO r_r77.*
	SELECT * FROM rept077
		WHERE r77_compania    = r_r77.r77_compania
		  AND r77_codigo_util = r_r77.r77_codigo_util
	IF STATUS = NOTFOUND THEN
		DISPLAY 'Insertando Código de Utilidad ', r_r77.r77_codigo_util
		LET r_r77.r77_fecing = CURRENT
		INSERT INTO rept077 VALUES(r_r77.*)
		LET i = i + 1
	ELSE
		DISPLAY 'Actualizando Código de Utilidad ',r_r77.r77_codigo_util
		UPDATE rept077
			SET r77_multiplic  = r_r77.r77_multiplic,
			    r77_dscmax_ger = r_r77.r77_dscmax_ger,
			    r77_dscmax_jef = r_r77.r77_dscmax_jef,
			    r77_dscmax_ven = r_r77.r77_dscmax_ven,
			    r77_util_min   = r_r77.r77_util_min,
			    r77_desc_promo = r_r77.r77_desc_promo,
			    r77_util_promo = r_r77.r77_util_promo
			WHERE r77_compania    = r_r77.r77_compania
			  AND r77_codigo_util = r_r77.r77_codigo_util
		LET j = j + 1
	END IF
END FOREACH
DISPLAY 'Se Insertaron ', i USING "<<<&", ' y se Actualizaron ', j USING "<<<&",
	' Códigos de Utilidad. OK'

END FUNCTION



FUNCTION procesar_unidades_med()
DEFINE r_r05		RECORD LIKE rept005.*
DEFINE i, j		SMALLINT

DISPLAY ' '
DECLARE q_uni CURSOR FOR SELECT * FROM tr_unimed
DISPLAY 'Procesando Unidades de Medida ...'
LET i = 0
LET j = 0
FOREACH q_uni INTO r_r05.*
	SELECT * FROM rept005
		WHERE r05_codigo = r_r05.r05_codigo
	IF STATUS = NOTFOUND THEN
		DISPLAY 'Insertando Unidad de Medida ', r_r05.r05_codigo
		LET r_r05.r05_fecing = CURRENT
		INSERT INTO rept005 VALUES(r_r05.*)
		LET i = i + 1
	ELSE
		DISPLAY 'Actualizando Unidad de Medida ', r_r05.r05_codigo
		UPDATE rept005
			SET r05_siglas    = r_r05.r05_siglas,
			    r05_decimales = r_r05.r05_decimales
			WHERE r05_codigo = r_r05.r05_codigo
		LET j = j + 1
	END IF
END FOREACH
DISPLAY 'Se Insertaron ', i USING "<<<&", ' y se Actualizaron ', j USING "<<<&",
	' Unidades de Medida. OK'

END FUNCTION



FUNCTION procesar_capitulos()
DEFINE r_g38		RECORD LIKE gent038.*
DEFINE i, j		SMALLINT

DISPLAY ' '
DECLARE q_cap CURSOR FOR SELECT * FROM tr_capitu
DISPLAY 'Procesando Capitulos ...'
LET i = 0
LET j = 0
FOREACH q_cap INTO r_g38.*
	SELECT * FROM gent038
		WHERE g38_capitulo = r_g38.g38_capitulo
	IF STATUS = NOTFOUND THEN
		DISPLAY 'Insertando el Capitulo ', r_g38.g38_capitulo
		LET r_g38.g38_fecing = CURRENT
		INSERT INTO gent038 VALUES(r_g38.*)
		LET i = i + 1
	ELSE
		DISPLAY 'Actualizando el Capitulo ', r_g38.g38_capitulo
		UPDATE gent038
			SET g38_desc_cap = r_g38.g38_desc_cap
			WHERE g38_capitulo = r_g38.g38_capitulo
		LET j = j + 1
	END IF
END FOREACH
DISPLAY 'Se Insertaron ', i USING "<<<&", ' y se Actualizaron ', j USING "<<<&",
	' Capitulos. OK'

END FUNCTION



FUNCTION procesar_partidas()
DEFINE r_g16		RECORD LIKE gent016.*
DEFINE i, j		SMALLINT

DISPLAY ' '
DECLARE q_par CURSOR FOR SELECT * FROM tr_partid
DISPLAY 'Procesando Partidas ...'
LET i = 0
LET j = 0
FOREACH q_par INTO r_g16.*
	SELECT * FROM gent016
		WHERE g16_partida = r_g16.g16_partida
	IF STATUS = NOTFOUND THEN
		DISPLAY 'Insertando la Partida ', r_g16.g16_partida
		LET r_g16.g16_fecing = CURRENT
		INSERT INTO gent016 VALUES(r_g16.*)
		LET i = i + 1
	ELSE
		DISPLAY 'Actualizando la Partida ', r_g16.g16_partida
		UPDATE gent016
			SET g16_desc_par   = r_g16.g16_desc_par,
			    g16_niv_par    = r_g16.g16_niv_par,
			    g16_nacional   = r_g16.g16_nacional,
			    g16_verifcador = r_g16.g16_verifcador,
			    g16_porcentaje = r_g16.g16_porcentaje,
			    g16_salvagu    = r_g16.g16_salvagu
			WHERE g16_partida = r_g16.g16_partida
		LET j = j + 1
	END IF
END FOREACH
DISPLAY 'Se Insertaron ', i USING "<<<&", ' y se Actualizaron ', j USING "<<<&",
	' Partidas. OK'

END FUNCTION



FUNCTION borrar_tablas_tr()

DISPLAY ' '
DROP TABLE tr_divis
DROP TABLE tr_linea
DROP TABLE tr_grupo
DROP TABLE tr_clase
DROP TABLE tr_marca
DROP TABLE tr_codut
DROP TABLE tr_unimed
DROP TABLE tr_capitu
DROP TABLE tr_partid
DISPLAY 'Borrando las tablas temporales ...'

END FUNCTION
