DATABASE aceros



DEFINE base1, base2	CHAR(20)
DEFINE codcia1, codcia2	LIKE gent001.g01_compania
--DEFINE division		LIKE rept003.r03_codigo
DEFINE marca		LIKE rept073.r73_marca



MAIN

	IF num_args() <> 4 AND num_args() <> 5 THEN
		DISPLAY 'Parametros Incorrectos. BASE_ORIGEN BASE_DESTINO ',
			'COMPAÑIA_ORIGEN COMPAÑIA_DESTINO [MARCA]'
		EXIT PROGRAM
	END IF
	LET base1    = arg_val(1)
	LET base2    = arg_val(2)
	LET codcia1  = arg_val(3)
	LET codcia2  = arg_val(4)
	--LET division = arg_val(5)
	IF num_args() = 5 THEN
		LET marca = arg_val(5)
	END IF
	CALL ejecuta_proceso()
	DISPLAY 'Actualización Terminada OK.'

END MAIN



FUNCTION ejecuta_proceso()
DEFINE r_ite, r_r10	RECORD LIKE rept010.*
DEFINE r_r87		RECORD LIKE rept087.*
DEFINE i		INTEGER

DATABASE base1
SET ISOLATION TO DIRTY READ
DISPLAY 'Descargando precios de ítems. Por favor espere ...'
IF num_args() <> 5 THEN
	UNLOAD TO "item.unl"
		SELECT * FROM rept010
			WHERE r10_compania  = codcia1
			  AND r10_codigo    MATCHES '15????'
			  --AND r10_linea     = division
			  AND r10_marca     IN('POWERS', 'INTERS', 'MILWAU')
ELSE
	UNLOAD TO "item.unl"
		SELECT * FROM rept010
			WHERE r10_compania  = codcia1
			  --AND r10_linea     = division
			  AND r10_marca     = marca
END IF
CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base2
WHENEVER ERROR STOP
SET ISOLATION TO DIRTY READ
DISPLAY ' '
DISPLAY 'Subiendo la información ...'
SELECT * FROM rept010 WHERE r10_compania = 77 INTO TEMP tmp_r10
LOAD FROM "item.unl" INSERT INTO tmp_r10
DISPLAY ' '
DISPLAY 'Actualizando Precios de Items. Por favor espere ...'
DECLARE q_r10 CURSOR FOR SELECT * FROM tmp_r10
LET i = 0
FOREACH q_r10 INTO r_ite.*
	INITIALIZE r_r10.*, r_r87.* TO NULL
	SELECT * INTO r_r10.*
		FROM rept010
		WHERE r10_compania = codcia2
		  AND r10_codigo   = r_ite.r10_codigo
	UPDATE rept010
		SET r10_precio_ant = r10_precio_mb
		WHERE r10_compania IN (codcia1, codcia2)
		  AND r10_codigo   = r_ite.r10_codigo
	UPDATE rept010
		SET r10_precio_mb   = r_ite.r10_precio_mb,
                    r10_fec_camprec = r_ite.r10_fec_camprec
		WHERE r10_compania IN (codcia1, codcia2)
		  AND r10_codigo   = r_ite.r10_codigo
	LET r_r87.r87_compania    = codcia2
	LET r_r87.r87_localidad   = 6
	LET r_r87.r87_item        = r_ite.r10_codigo
	SELECT NVL(MAX(r87_secuencia), 0) + 1 INTO r_r87.r87_secuencia
	        FROM rept087
	        WHERE r87_compania = r_r87.r87_compania
	          AND r87_item     = r_r87.r87_item
	LET r_r87.r87_precio_act  = r_ite.r10_precio_mb
	LET r_r87.r87_precio_ant  = r_r10.r10_precio_mb
	IF r_r87.r87_precio_ant IS NULL THEN
		LET r_r87.r87_precio_ant = 0
	END IF
	LET r_r87.r87_usu_camprec = 'FOBOS'
	LET r_r87.r87_fec_camprec = CURRENT
	INSERT INTO rept087 VALUES (r_r87.*)
	DISPLAY 'Actualizando el precio del Item ', r_ite.r10_codigo CLIPPED,
		'. Marca ', r_r10.r10_marca CLIPPED, '.'
	LET i = i + 1
END FOREACH
DISPLAY 'Se actualizaron un total de ', i USING "<<<<<&", ' Items. Ok'
DISPLAY ' '

END FUNCTION
