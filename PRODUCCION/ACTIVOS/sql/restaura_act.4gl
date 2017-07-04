DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE base, base1	CHAR(20)
DEFINE baseser		CHAR(40)



MAIN

	IF num_args() <> 4 THEN
		DISPLAY 'No. Parametros Incorrectos. Faltan BASE_D SERVER_D BASE_C SERVER_C'
		EXIT PROGRAM
	END IF
	LET codcia = 1
	CALL cargar_activos_baja_mal()

END MAIN



FUNCTION cargar_activos_baja_mal()

CALL alzar_base_ser(arg_val(1), arg_val(2))
SET ISOLATION TO DIRTY READ
CALL descargar_tablas()
CALL alzar_base_ser(arg_val(3), arg_val(4))
SET ISOLATION TO DIRTY READ
CALL crear_temporales()
CALL cargar_temporales()
{
LET baseser = arg_val(3) CLIPPED, '@', arg_val(4) CLIPPED
BEGIN WORK
SET LOCK MODE TO WAIT
	CALL procesar_tablas()
SET LOCK MODE TO NOT WAIT
COMMIT WORK
CALL borrar_tablas_tr()
CALL procesar_sucural()
}
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
DISPLAY 'Descargando activos que fueron dados de baja ...'
UNLOAD TO "activos_baja.txt"
	SELECT a12_compania, a12_codigo_bien
		FROM actt012
		WHERE a12_compania     = codcia
		  AND a12_codigo_tran  = 'BA'
		  AND YEAR(a12_fecing) = 2008
DISPLAY 'Descargados activos fijos ...'

END FUNCTION



FUNCTION crear_temporales()

DISPLAY ' '
DISPLAY 'Creando tablas temporales ...'
SELECT a12_compania cia, a12_codigo_bien activo
	FROM actt012
	WHERE a12_compania = 10
	INTO TEMP tr_act
DISPLAY 'Creadas tablas temporales ...'

END FUNCTION



FUNCTION cargar_temporales()

DISPLAY ' '
DISPLAY 'Cargando tablas temporales para el proceso ...'
LOAD FROM "activos_baja.txt" INSERT INTO tr_act
UNLOAD TO "activos_bien.txt"
	SELECT * FROM actt010
		WHERE a10_compania = codcia
		  AND EXISTS (SELECT 1 FROM tr_act
				WHERE cia    = a10_compania
				  AND activo = a10_codigo_bien)
DISPLAY 'Cargadas tablas temporales ...'

END FUNCTION



FUNCTION procesar_tablas()

DISPLAY ' '
DISPLAY 'Procesando ...'
CALL procesar_activos()

END FUNCTION



FUNCTION procesar_activos()
{--
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
	WHENEVER ERROR CONTINUE
	INSERT INTO rept003 VALUES(r_r03.*)
	IF STATUS < 0 THEN
		DISPLAY '  ERROR: No se ha podido INSERTAR la División ',
			r_r03.r03_codigo CLIPPED, '. BASE: ', baseser CLIPPED,
			' STATUS: ', STATUS, '.'
		WHENEVER ERROR STOP
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
	LET i = i + 1
END FOREACH
IF i > 0 THEN
	DISPLAY 'Se Insertaron ', i USING "<<<&", ' Divisiones. OK'
ELSE
	DISPLAY 'No se Inserto ninguna División.'
END IF
--}

END FUNCTION



FUNCTION borrar_tablas_tr()

DISPLAY ' '
DROP TABLE tr_act
DISPLAY 'Borrando las tablas temporales ...'
RUN ' rm activos_baja.txt'

END FUNCTION
