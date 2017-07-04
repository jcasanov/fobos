DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE base		CHAR(20)
DEFINE vm_anio, vm_mes	SMALLINT



MAIN

	IF num_args() <> 4 THEN
		DISPLAY 'Error de Parametros. Falta la BASE LOCALIDAD AÑO MES.'
		EXIT PROGRAM
	END IF
	LET codcia  = 1
	LET base    = arg_val(1)
	LET codloc  = arg_val(2)
	LET vm_anio = arg_val(3)
	LET vm_mes  = arg_val(4)
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
SELECT * INTO r_g51.* FROM gent051
	WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION validar_parametros()

IF vm_anio < 2003 THEN
	DISPLAY 'El año no puede ser menor al 2003.'
	EXIT PROGRAM
END IF
IF vm_mes < 1 OR vm_mes > 12 THEN
	DISPLAY 'El mes no puede ser menor a 1 ni tampoco mayor a 12.'
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION ejecuta_proceso()
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE query		CHAR(400)
DEFINE cuantos		INTEGER
DEFINE nombre		LIKE rolt030.n30_nombres
DEFINE num_doc_id	LIKE rolt030.n30_num_doc_id
DEFINE sueldo		LIKE rolt030.n30_sueldo_mes
DEFINE valor_ext	LIKE rolt032.n32_tot_gan
DEFINE r_n32		RECORD LIKE rolt032.*

DISPLAY 'Generando Archivo extras.txt, por favor espere ...'
LET fecha_ini = MDY(vm_mes, 01, vm_anio)
LET fecha_fin = fecha_ini + 1 UNITS MONTH - 1 UNITS DAY
SELECT UNIQUE n32_cod_liqrol
	FROM rolt032
	WHERE n32_compania   = codcia
	  AND n32_fecha_ini >= fecha_ini
	  AND n32_fecha_fin <= fecha_fin
	INTO TEMP caca
SELECT COUNT(*) INTO cuantos FROM caca
DROP TABLE caca
IF cuantos < 2 THEN
	DISPLAY 'Este mes no tiene aún las 2 quincenas ingresadas.'
	EXIT PROGRAM
END IF
SELECT n33_cod_trab, n30_num_doc_id cedula, n30_nombres,
	NVL(SUM(n33_valor), 0) valor
	FROM rolt033, rolt030
	WHERE n33_compania    = codcia
	  AND n33_cod_liqrol IN ('Q1', 'Q2')
	  AND n33_fecha_ini  >= fecha_ini
	  AND n33_fecha_fin  <= fecha_fin
	  --AND n33_cod_rubro  IN (8, 10, 13, 23)
	  AND n33_cod_rubro  IN
		(SELECT b.n08_rubro_base
		FROM rolt006 a, rolt008 b
		WHERE a.n06_estado     = 'A'
		  AND a.n06_flag_ident = 'AP'
		  AND b.n08_cod_rubro  = a.n06_cod_rubro
		  AND b.n08_rubro_base NOT IN
			(SELECT c.n06_cod_rubro
			FROM rolt006 c
			WHERE c.n06_flag_ident IN ('VT', 'VV', 'VE', 'VM')))
	  AND n30_compania    = n33_compania
	  AND n30_cod_trab    = n33_cod_trab
	GROUP BY 1, 2, 3
	HAVING NVL(SUM(n33_valor), 0) > 0
	INTO TEMP t1
DECLARE q_n32 CURSOR FOR
	SELECT n32_cod_trab, NVL(SUM(n32_tot_gan), 0)
		FROM rolt032
		WHERE n32_compania    = codcia
		  AND n32_cod_liqrol IN ('Q1', 'Q2')
		  AND n32_fecha_ini  >= fecha_ini
		  AND n32_fecha_fin  <= fecha_fin
		GROUP BY 1
FOREACH q_n32 INTO r_n32.n32_cod_trab, r_n32.n32_tot_gan
	SELECT UNIQUE n33_cod_trab FROM rolt033
		WHERE n33_compania    = codcia
		  AND n33_cod_liqrol IN ('Q1', 'Q2')
		  AND n33_fecha_ini  >= fecha_ini
		  AND n33_fecha_fin  <= fecha_fin
		  AND n33_cod_trab    = r_n32.n32_cod_trab
		  AND n33_cod_rubro   = (SELECT n06_cod_rubro
						FROM rolt006
						WHERE n06_flag_ident = 'VV')
		  AND n33_valor       > 0
	IF STATUS = NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	SELECT n30_nombres, n30_num_doc_id, n30_sueldo_mes
		INTO nombre, num_doc_id, sueldo
		FROM rolt030
		WHERE n30_compania = codcia
		  AND n30_cod_trab = r_n32.n32_cod_trab
	LET valor_ext = r_n32.n32_tot_gan - sueldo
	IF valor_ext > 0 THEN
		SELECT UNIQUE n33_cod_trab FROM t1
			WHERE n33_cod_trab = r_n32.n32_cod_trab
		IF STATUS = NOTFOUND THEN
			INSERT INTO t1
				VALUES(r_n32.n32_cod_trab, num_doc_id, nombre,
					valor_ext)
			DISPLAY 'Ins. en T1 Emp. ',
				r_n32.n32_cod_trab USING "<<<&&&",
				' VALOR_EXT = ', valor_ext USING "--,--&.##",
				' TOT_GAN = ', r_n32.n32_tot_gan
				USING "##,##&.##", ' SUELDO = ',
				sueldo using "##,##&.##"
			CONTINUE FOREACH
		END IF
		UPDATE t1 SET valor = valor_ext
			WHERE n33_cod_trab = r_n32.n32_cod_trab
		DISPLAY 'Act. en T1 Emp. ', r_n32.n32_cod_trab USING "<<<&&&",
			' VALOR_EXT = ', valor_ext USING "--,--&.##",
			' TOT_GAN = ', r_n32.n32_tot_gan USING "##,##&.##",
			' SUELDO = ', sueldo using "##,##&.##"
	ELSE
		DISPLAY 'Eli. en T1 Emp. ',
			r_n32.n32_cod_trab USING "<<<&&&",
			' VALOR_EXT = ', valor_ext USING "--,--&.##",
			' TOT_GAN = ', r_n32.n32_tot_gan USING "##,##&.##",
			' SUELDO = ', sueldo using "##,##&.##"
		DELETE FROM t1 WHERE n33_cod_trab = r_n32.n32_cod_trab
	END IF
END FOREACH
LET query = 'SELECT g02_numruc ruc, "0009" sucursal, ', vm_anio, ' anio, ',
		' LPAD(', vm_mes, ', 2, 0) mes, "INS" tipo, cedula, ',
		' LPAD(valor, 14, 0) valor_ext, "O" causa ',
		' FROM t1, gent002 ',
		' WHERE g02_compania  = ', codcia,
		'   AND g02_localidad = ', codloc,
		' INTO TEMP t2'
PREPARE cons_t2 FROM query
EXECUTE cons_t2
DROP TABLE t1
UNLOAD TO "extras.txt" DELIMITER ";" SELECT * FROM t2
DROP TABLE t2
RUN 'sed -e "1,$ s/;$//g" extras.txt > extras2.txt'
RUN 'mv extras2.txt extras.txt'
RUN 'unix2dos extras.txt'
DISPLAY 'Archivo con valores extras por trabajador, para el IESS, generado OK.'

END FUNCTION
