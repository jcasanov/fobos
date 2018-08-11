DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc, codloc2	LIKE gent002.g02_localidad
DEFINE base		CHAR(20)



MAIN

	IF num_args() <> 2 THEN
		DISPLAY 'Error Parametros. Falta BASE y LOCALIDAD.'
		EXIT PROGRAM
	END IF
	LET codcia = 1
	LET base   = arg_val(1)
	LET codloc = arg_val(2)
	CASE codloc
		WHEN 1
			LET codloc2 = 2
		WHEN 3
			LET codloc2 = 4
	END CASE
	CALL activar_base()
	CALL validar_parametros()
	CALL ejecuta_proceso()

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
SELECT * INTO r_g51.* FROM gent051 WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION validar_parametros()
DEFINE r_g02		RECORD LIKE gent002.*

INITIALIZE r_g02.* TO NULL
SELECT * INTO r_g02.* FROM gent002
	WHERE g02_compania  = codcia
	  AND g02_localidad = codloc
IF r_g02.g02_compania IS NULL THEN
	DISPLAY 'No existe la Localidad ', codloc USING "<<<&",
		' en la base de datos.'
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION ejecuta_proceso()

IF obtener_documentos_clientes_arr() = 0 THEN
	RETURN
END IF

END FUNCTION



FUNCTION obtener_documentos_clientes_arr()
DEFINE cuantos		INTEGER

SELECT MAX(z22_fecing) fecha, z22_compania, z22_localidad, z22_codcli,
	z23_tipo_doc tipo_doc, z23_num_doc num_doc, z23_div_doc div_doc
	FROM cxct022, cxct023
	WHERE z22_compania   = codcia
	  AND z22_localidad IN (codloc, codloc2)
	  AND z23_compania   = z22_compania
	  AND z23_localidad  = z22_localidad
	  AND z23_codcli     = z22_codcli
	  AND z23_tipo_trn   = z22_tipo_trn
	  AND z23_num_trn    = z22_num_trn
	GROUP BY 2, 3, 4, 5, 6, 7
	INTO TEMP t1
SELECT z23_codcli, NVL(sum(z23_saldo_cap + z23_saldo_int + z23_valor_cap +
		z23_valor_int), 0) saldo_z23
	FROM t1, cxct023
	WHERE z23_compania  = z22_compania
	  AND z23_localidad = z22_localidad
	  AND z23_codcli    = z22_codcli
	  AND z23_tipo_doc  = tipo_doc
	  AND z23_num_doc   = num_doc
	  AND z23_div_doc   = div_doc
	GROUP BY 1
	INTO TEMP t2
DROP TABLE t1
SELECT z20_codcli, NVL(sum(z20_saldo_cap + z20_saldo_int), 0) saldo_z20
	FROM cxct020
	WHERE z20_compania   = codcia
	  AND z20_localidad IN (codloc, codloc2)
	GROUP BY 1
	INTO TEMP t3
SELECT z20_codcli, saldo_z20, saldo_z23
	FROM t2, t3
	WHERE z20_codcli  = z23_codcli
	  AND saldo_z20  <> saldo_z23
	INTO TEMP t4
DROP TABLE t2
DROP TABLE t3
SELECT COUNT(*) total_cli INTO cuantos FROM t4
IF cuantos = 0 THEN
	DISPLAY 'No hay ningún documento que cuadrar saldo en la cxct023.'
	RETURN 0
END IF
SELECT z20_compania compania, z20_localidad localidad, z20_codcli codcli,
	z20_tipo_doc tipo_doc, z20_num_doc num_doc, z20_dividendo div_doc,
	z20_valor_cap valor_cap, z20_valor_int valor_int,
	z20_saldo_cap saldo_cap, z20_saldo_int saldo_int, z20_fecha_vcto fec_v
	FROM cxct020
	WHERE z20_compania   = codcia
	  AND z20_localidad IN (codloc, codloc2)
	  AND z20_codcli    IN (SELECT t4.z20_codcli FROM t4)
	INTO TEMP temp_doc
DROP TABLE t4
RETURN 1

END FUNCTION
