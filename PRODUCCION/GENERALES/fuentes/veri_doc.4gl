DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE base		CHAR(20)
DEFINE max_dias		INTEGER
DEFINE tipo_doc		LIKE gent037.g37_tipo_doc
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*



MAIN

	IF num_args() <> 5 THEN
		DISPLAY 'Número de Parametros Incorrectos. Son: BASE Compañía Localidad maximo_dias Tipo_Doc. '
		EXIT PROGRAM
	END IF
	LET base     = arg_val(1)
	LET codcia   = arg_val(2)
	LET codloc   = arg_val(3)
	LET max_dias = arg_val(4)
	LET tipo_doc = arg_val(5)
	CALL activar_base()
	CALL validar_parametros()
	CALL verifica_docs_sri()

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
	WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION validar_parametros()

INITIALIZE r_g01.*, r_g02.* TO NULL
SELECT * INTO r_g01.* FROM gent001
	WHERE g01_compania = codcia
IF r_g01.g01_compania IS NULL THEN
	DISPLAY 'No existe la Compañía ', codcia USING '<<&', '.'
	EXIT PROGRAM
END IF
SELECT * INTO r_g02.* FROM gent002
	WHERE g02_compania  = codcia
	  AND g02_localidad = codloc
IF r_g02.g02_compania IS NULL THEN
	DISPLAY 'No existe la Localidad ', codcia USING '<<&', '.'
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION verifica_docs_sri()
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE r_g39		RECORD LIKE gent039.*
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_p04		RECORD LIKE cxpt004.*
DEFINE num_dias		INTEGER
DEFINE num_dias_c	VARCHAR(10)
DEFINE num_ini, num_fin	VARCHAR(16)

SELECT * INTO r_g37.*, r_g39.*
	FROM gent037, gent039
	WHERE g37_compania  = codcia
	  AND g37_localidad = codloc
	  AND g37_tipo_doc  = tipo_doc
	  AND g37_secuencia IN
		(SELECT MAX(g37_secuencia) FROM gent037
			WHERE g37_compania  = codcia
			  AND g37_localidad = codloc
			  AND g37_tipo_doc  = tipo_doc)
	  AND g39_compania  = g37_compania
	  AND g39_localidad = g37_localidad
	  AND g39_tipo_doc  = g37_tipo_doc
	  AND g39_secuencia = g37_secuencia
LET num_dias = r_g37.g37_fecha_exp - TODAY
IF num_dias <= max_dias THEN
	SELECT * INTO r_z04.* FROM cxct004
		WHERE z04_tipo_doc = r_g37.g37_tipo_doc
	IF r_g37.g37_tipo_doc = 'RT' THEN
		SELECT * INTO r_p04.* FROM cxpt004
			WHERE p04_tipo_doc = r_g37.g37_tipo_doc
		LET r_z04.z04_nombre = r_p04.p04_nombre
	END IF
	LET num_dias_c = num_dias USING "---&"
	LET num_ini    = r_g37.g37_pref_sucurs, '-', r_g37.g37_pref_pto_vta,
			 '-', r_g39.g39_num_sri_ini USING "&&&&&&&"
	LET num_fin    = r_g37.g37_pref_sucurs, '-', r_g37.g37_pref_pto_vta,
			 '-', r_g39.g39_num_sri_fin USING "&&&&&&&"
	DISPLAY	r_g02.g02_abreviacion CLIPPED, " - ", r_z04.z04_nombre CLIPPED,
		". ATENCION: Faltan ", num_dias_c USING '-<<&',
		" dias para caducar los Documentos (SRI) de ",
		r_z04.z04_nombre CLIPPED, '   SERIE: ', num_ini CLIPPED, ' AL ',
		num_fin CLIPPED		--, " -- LOCALIDAD: ",
END IF

END FUNCTION
