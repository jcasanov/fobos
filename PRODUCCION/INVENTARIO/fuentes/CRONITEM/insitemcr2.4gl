DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE base, base1	CHAR(20)
DEFINE tiempo		SMALLINT



MAIN

	CALL startlog('insitemcr2.err')
	IF num_args() <> 5 THEN
		DISPLAY 'No. Parametros Incorrectos. Faltan BASE_D SERVER_D BASE_C SERVER_C TIEMPO_EJ'
		EXIT PROGRAM
	END IF
	LET codcia = 1
	CALL crear_items()

END MAIN



FUNCTION crear_items()

LET tiempo = arg_val(5)
LET tiempo = tiempo * 2
CALL alzar_base_ser(arg_val(1), arg_val(2))
CALL descargar_tablas()
CALL alzar_base_ser(arg_val(3), arg_val(4))
CALL crear_temporales()
CALL cargar_temporales()
BEGIN WORK
	CALL procesar_tablas()
COMMIT WORK
CALL borrar_tablas_tr()
DISPLAY ' '
DISPLAY 'Proceso Terminado OK.'

END FUNCTION



FUNCTION alzar_base_ser(b, s)
DEFINE b, s		CHAR(20)

LET base  = b
LET base1 = base CLIPPED
LET base  = base CLIPPED, '@', s
CALL activar_base()

END FUNCTION



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



FUNCTION descargar_tablas()

DISPLAY ' '
DISPLAY 'Descargando tablas de la jerarquía de items ...'
UNLOAD TO "division.txt"
	SELECT * FROM rept003
		WHERE r03_compania  = codcia
		  AND r03_fecing   >= CURRENT - tiempo UNITS MINUTE
UNLOAD TO "lineas.txt"
	SELECT * FROM rept070
		WHERE r70_compania  = codcia
		  AND r70_fecing   >= CURRENT - tiempo UNITS MINUTE
UNLOAD TO "grupos.txt"
	SELECT * FROM rept071
		WHERE r71_compania  = codcia
		  AND r71_fecing   >= CURRENT - tiempo UNITS MINUTE
UNLOAD TO "clases.txt"
	SELECT * FROM rept072
		WHERE r72_compania  = codcia
		  AND r72_fecing   >= CURRENT - tiempo UNITS MINUTE
UNLOAD TO "medida.txt"
	SELECT * FROM rept005
		WHERE r05_fecing   >= CURRENT - tiempo UNITS MINUTE
UNLOAD TO "bodega.txt"
	SELECT * FROM rept002
		WHERE r02_compania  = codcia
		  AND r02_fecing   >= CURRENT - tiempo UNITS MINUTE
UNLOAD TO "item.txt"
	SELECT * FROM rept010
		WHERE r10_compania  = codcia
		  AND r10_fecing   >= CURRENT - tiempo UNITS MINUTE
UNLOAD TO "item_sto.txt"
	SELECT * FROM rept011
		WHERE r11_compania  = codcia
		  AND r11_bodega IN (SELECT r00_bodega_fact FROM rept000
					WHERE r00_compania = codcia)
		  AND r11_item   IN (SELECT r10_codigo FROM rept010
					WHERE r10_compania = codcia
					  AND r10_fecing  >= CURRENT - tiempo
						UNITS MINUTE)
DISPLAY 'Descargadas tablas ...'

END FUNCTION



FUNCTION crear_temporales()

DISPLAY ' '
DISPLAY 'Creando tablas temporales ...'
SELECT * FROM rept003 WHERE r03_compania = 10     INTO TEMP tr_divis
SELECT * FROM rept070 WHERE r70_compania = 10     INTO TEMP tr_linea
SELECT * FROM rept071 WHERE r71_compania = 10     INTO TEMP tr_grupo
SELECT * FROM rept072 WHERE r72_compania = 10     INTO TEMP tr_clase
SELECT * FROM rept005 WHERE r05_codigo   = 'CACA' INTO TEMP tr_unimed
SELECT * FROM rept002 WHERE r02_codigo   = 'CACA' INTO TEMP tr_bodega
SELECT * FROM rept010 WHERE r10_codigo   = 'CACA' INTO TEMP tr_item
SELECT * FROM rept011 WHERE r11_item     = 'CACA' INTO TEMP tr_item_sto
DISPLAY 'Creadas tablas temporales ...'

END FUNCTION



FUNCTION cargar_temporales()

DISPLAY ' '
DISPLAY 'Cargando tablas temporales para el proceso ...'
LOAD FROM "division.txt"	INSERT INTO tr_divis
LOAD FROM "lineas.txt"		INSERT INTO tr_linea
LOAD FROM "grupos.txt"		INSERT INTO tr_grupo
LOAD FROM "clases.txt"		INSERT INTO tr_clase
LOAD FROM "medida.txt"		INSERT INTO tr_unimed
LOAD FROM "bodega.txt"		INSERT INTO tr_bodega
LOAD FROM "item.txt"		INSERT INTO tr_item
LOAD FROM "item_sto.txt"	INSERT INTO tr_item_sto
DISPLAY 'Cargadas tablas temporales ...'

END FUNCTION



FUNCTION procesar_tablas()

DISPLAY ' '
DISPLAY 'Procesando ...'
CALL procesar_division()
CALL procesar_lineas()
CALL procesar_grupos()
CALL procesar_clases()
CALL procesar_unidades_med()
CALL procesar_bodegas()
CALL crear_item_stock()
--CALL procesar_items()

END FUNCTION



FUNCTION procesar_division()
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE cuanto		INTEGER
DEFINE i		SMALLINT

DISPLAY ' '
SELECT COUNT(*) INTO cuanto FROM tr_divis
IF cuanto = 0 THEN
	DISPLAY 'No hay nuevas Divisiones ...'
	RETURN
END IF
DECLARE q_div CURSOR FOR SELECT * FROM tr_divis
DISPLAY 'Procesando Divisiones ...'
LET i = 0
FOREACH q_div INTO r_r03.*
	SELECT * FROM rept003
		WHERE r03_compania = r_r03.r03_compania
		  AND r03_codigo   = r_r03.r03_codigo
	IF STATUS <> NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	DISPLAY 'Insertando la División ', r_r03.r03_codigo
	CALL validar_usuario(r_r03.r03_usuario) RETURNING r_r03.r03_usuario
	LET r_r03.r03_fecing = CURRENT
	INSERT INTO rept003 VALUES(r_r03.*)
	LET i = i + 1
END FOREACH
IF i > 0 THEN
	DISPLAY 'Se Insertaron ', i USING "<<<&", ' Divisiones. OK'
ELSE
	DISPLAY 'No se Inserto ninguna División.'
END IF

END FUNCTION



FUNCTION procesar_lineas()
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE cuanto		INTEGER
DEFINE i		SMALLINT

DISPLAY ' '
SELECT COUNT(*) INTO cuanto FROM tr_linea
IF cuanto = 0 THEN
	DISPLAY 'No hay nuevas Líneas ...'
	RETURN
END IF
DECLARE q_lin CURSOR FOR SELECT * FROM tr_linea
DISPLAY 'Procesando Líneas ...'
LET i = 0
FOREACH q_lin INTO r_r70.*
	SELECT * FROM rept070
		WHERE r70_compania  = r_r70.r70_compania
		  AND r70_linea     = r_r70.r70_linea
		  AND r70_sub_linea = r_r70.r70_sub_linea
	IF STATUS <> NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	DISPLAY 'Insertando la Línea ', r_r70.r70_sub_linea
	CALL validar_usuario(r_r70.r70_usuario) RETURNING r_r70.r70_usuario
	LET r_r70.r70_fecing = CURRENT
	INSERT INTO rept070 VALUES(r_r70.*)
	LET i = i + 1
END FOREACH
IF i > 0 THEN
	DISPLAY 'Se Insertaron ', i USING "<<<&", ' Líneas. OK'
ELSE
	DISPLAY 'No se Inserto ninguna Línea.'
END IF

END FUNCTION



FUNCTION procesar_grupos()
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE cuanto		INTEGER
DEFINE i		SMALLINT

DISPLAY ' '
SELECT COUNT(*) INTO cuanto FROM tr_grupo
IF cuanto = 0 THEN
	DISPLAY 'No hay nuevos Grupos ...'
	RETURN
END IF
DECLARE q_grp CURSOR FOR SELECT * FROM tr_grupo
DISPLAY 'Procesando Grupos ...'
LET i = 0
FOREACH q_grp INTO r_r71.*
	SELECT * FROM rept071
		WHERE r71_compania  = r_r71.r71_compania
		  AND r71_linea     = r_r71.r71_linea
		  AND r71_sub_linea = r_r71.r71_sub_linea
		  AND r71_cod_grupo = r_r71.r71_cod_grupo
	IF STATUS <> NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	DISPLAY 'Insertando el Grupo ', r_r71.r71_cod_grupo
	CALL validar_usuario(r_r71.r71_usuario) RETURNING r_r71.r71_usuario
	LET r_r71.r71_fecing = CURRENT
	INSERT INTO rept071 VALUES(r_r71.*)
	LET i = i + 1
END FOREACH
IF i > 0 THEN
	DISPLAY 'Se Insertaron ', i USING "<<<&", ' Grupos. OK'
ELSE
	DISPLAY 'No se Inserto ningun Grupo.'
END IF

END FUNCTION



FUNCTION procesar_clases()
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE cuanto		INTEGER
DEFINE i		SMALLINT

DISPLAY ' '
SELECT COUNT(*) INTO cuanto FROM tr_clase
IF cuanto = 0 THEN
	DISPLAY 'No hay nuevas Clases ...'
	RETURN
END IF
DECLARE q_cla CURSOR FOR SELECT * FROM tr_clase
DISPLAY 'Procesando Clases ...'
LET i = 0
FOREACH q_cla INTO r_r72.*
	SELECT * FROM rept072
		WHERE r72_compania  = r_r72.r72_compania
		  AND r72_linea     = r_r72.r72_linea
		  AND r72_sub_linea = r_r72.r72_sub_linea
		  AND r72_cod_grupo = r_r72.r72_cod_grupo
		  AND r72_cod_clase = r_r72.r72_cod_clase
	IF STATUS <> NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	DISPLAY 'Insertando la Clase ', r_r72.r72_cod_clase
	CALL validar_usuario(r_r72.r72_usuario) RETURNING r_r72.r72_usuario
	LET r_r72.r72_fecing = CURRENT
	INSERT INTO rept072 VALUES(r_r72.*)
	LET i = i + 1
END FOREACH
IF i > 0 THEN
	DISPLAY 'Se Insertaron ', i USING "<<<&", ' Clases. OK'
ELSE
	DISPLAY 'No se Inserto ninguna Clase.'
END IF

END FUNCTION



FUNCTION procesar_unidades_med()
DEFINE r_r05		RECORD LIKE rept005.*
DEFINE cuanto		INTEGER
DEFINE i		SMALLINT

DISPLAY ' '
SELECT COUNT(*) INTO cuanto FROM tr_unimed
IF cuanto = 0 THEN
	DISPLAY 'No hay nuevas Unidades de Medida ...'
	RETURN
END IF
DECLARE q_uni CURSOR FOR SELECT * FROM tr_unimed
DISPLAY 'Procesando Unidades de Medida ...'
LET i = 0
FOREACH q_uni INTO r_r05.*
	SELECT * FROM rept005
		WHERE r05_codigo = r_r05.r05_codigo
	IF STATUS <> NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	DISPLAY 'Insertando Unidad de Medida ', r_r05.r05_codigo
	CALL validar_usuario(r_r05.r05_usuario) RETURNING r_r05.r05_usuario
	LET r_r05.r05_fecing = CURRENT
	INSERT INTO rept005 VALUES(r_r05.*)
	LET i = i + 1
END FOREACH
IF i > 0 THEN
	DISPLAY 'Se Insertaron ', i USING "<<<&", ' Unidades de Medida. OK'
ELSE
	DISPLAY 'No se Inserto ninguna Unidad de Medida.'
END IF

END FUNCTION



FUNCTION procesar_bodegas()
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE cuanto		INTEGER
DEFINE i		SMALLINT

DISPLAY ' '
SELECT COUNT(*) INTO cuanto FROM tr_bodega
IF cuanto = 0 THEN
	DISPLAY 'No hay nuevas Bodegas ...'
	RETURN
END IF
DECLARE q_bod CURSOR FOR SELECT * FROM tr_bodega
DISPLAY 'Procesando Bodegas ...'
LET i = 0
FOREACH q_bod INTO r_r02.*
	SELECT * FROM rept002
		WHERE r02_compania = r_r02.r02_compania
		  AND r02_codigo   = r_r02.r02_codigo
	IF STATUS <> NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	DISPLAY 'Insertando Bodega ', r_r02.r02_codigo
	CALL validar_usuario(r_r02.r02_usuario) RETURNING r_r02.r02_usuario
	LET r_r02.r02_fecing = CURRENT
	INSERT INTO rept002 VALUES(r_r02.*)
	LET i = i + 1
END FOREACH
IF i > 0 THEN
	DISPLAY 'Se Insertaron ', i USING "<<<&", ' Bodegas. OK'
ELSE
	DISPLAY 'No se Inserto ninguna Bodega.'
END IF

END FUNCTION



FUNCTION procesar_items()
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE cuanto		INTEGER
DEFINE i		SMALLINT

DISPLAY ' '
SELECT COUNT(*) INTO cuanto FROM tr_item
IF cuanto = 0 THEN
	DISPLAY 'No hay nuevos Items ...'
	RETURN
END IF
UPDATE tr_item SET r10_cod_util = 'RE000' WHERE r10_compania = codcia
DECLARE q_item CURSOR FOR SELECT * FROM tr_item
DISPLAY 'Procesando Items ...'
LET i = 0
FOREACH q_item INTO r_r10.*
	SELECT * FROM rept010
		WHERE r10_compania = r_r10.r10_compania
		  AND r10_codigo   = r_r10.r10_codigo
	IF STATUS <> NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	DISPLAY 'Insertando Item ', r_r10.r10_codigo
	CALL validar_usuario(r_r10.r10_usuario) RETURNING r_r10.r10_usuario
	LET r_r10.r10_fecing = CURRENT
	INSERT INTO rept010 VALUES(r_r10.*)
	LET i = i + 1
END FOREACH
IF i > 0 THEN
	CALL crear_item_stock()
	DISPLAY 'Se Insertaron ', i USING "<<<&", ' Items. OK'
ELSE
	DISPLAY 'No se Inserto ningun Item.'
END IF

END FUNCTION



FUNCTION crear_item_stock()
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE cuanto		INTEGER
DEFINE i		SMALLINT

DISPLAY ' '
SELECT COUNT(*) INTO cuanto FROM tr_item_sto
IF cuanto = 0 THEN
	DISPLAY 'No hay nuevos Items con Stock ...'
	RETURN
END IF
DECLARE q_item_sto CURSOR FOR SELECT * FROM tr_item_sto
DISPLAY 'Procesando Items con Stock ...'
LET i = 0
FOREACH q_item_sto INTO r_r11.*
display r_r11.*
	SELECT * FROM rept011
		WHERE r11_compania = r_r11.r11_compania
		  AND r11_bodega   = r_r11.r11_bodega
		  AND r11_item     = r_r11.r11_item
	IF STATUS <> NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	DISPLAY 'Insertando Item con Stock ', r_r11.r11_item
	INSERT INTO rept011 VALUES(r_r11.*)
	LET i = i + 1
END FOREACH
IF i > 0 THEN
	DISPLAY 'Se Insertaron ', i USING "<<<&", ' Items con Stock. OK'
ELSE
	DISPLAY 'No se Inserto ningun Item con Stock.'
END IF

END FUNCTION



FUNCTION validar_usuario(usuario)
DEFINE usuario		LIKE gent005.g05_usuario

SELECT * FROM gent005 WHERE g05_usuario = usuario
IF STATUS = NOTFOUND THEN
	LET usuario = 'FOBOS'
END IF
RETURN usuario

END FUNCTION



FUNCTION borrar_tablas_tr()

DISPLAY ' '
DROP TABLE tr_divis
DROP TABLE tr_linea
DROP TABLE tr_grupo
DROP TABLE tr_clase
DROP TABLE tr_unimed
DROP TABLE tr_bodega
DROP TABLE tr_item
DROP TABLE tr_item_sto
DISPLAY 'Borrando las tablas temporales ...'
RUN ' rm division.txt'
RUN ' rm lineas.txt'
RUN ' rm grupos.txt'
RUN ' rm clases.txt'
RUN ' rm medida.txt'
RUN ' rm bodega.txt'
RUN ' rm item.txt'
RUN ' rm item_sto.txt'

END FUNCTION
