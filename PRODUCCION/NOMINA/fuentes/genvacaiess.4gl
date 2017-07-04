DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE base		CHAR(20)
DEFINE vm_anio, vm_mes	SMALLINT



MAIN

	IF num_args() <> 4 AND num_args() <> 5 THEN
		DISPLAY 'Error Parametros. Falta BASE LOCAL AÑO MES o RESTAURAR_SUELDO (X).'
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
DEFINE fecha		DATE
DEFINE query		CHAR(400)
DEFINE cuantos		INTEGER
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE sueldo_ant	LIKE rolt032.n32_sueldo
DEFINE suel_sect	LIKE rolt017.n17_valor

DISPLAY 'Generando Archivo nuevosuevac.txt, por favor espere ...'
LET fecha_ini = MDY(vm_mes, 01, vm_anio)
LET fecha_fin = fecha_ini + 1 UNITS MONTH - 1 UNITS DAY
LET fecha     = fecha_fin
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
CALL cargar_temporal(1, 15, 17, 0, 0, fecha)
LET query = 'SELECT n32_cod_trab, NVL(SUM(n32_tot_gan), 0) ',
		' FROM rolt032 ',
		' WHERE n32_compania    = ', codcia,
		'   AND n32_cod_liqrol IN("Q1", "Q2") ',
		'   AND n32_fecha_ini  >= "', fecha_ini, '" ',
		'   AND n32_fecha_fin  <= "', fecha_fin, '" ',
		' GROUP BY n32_cod_trab ',
		' ORDER BY 2 DESC, n32_cod_trab ASC'
PREPARE cons_n32 FROM query
DECLARE q_n32 CURSOR FOR cons_n32
FOREACH q_n32 INTO r_n32.n32_cod_trab, r_n32.n32_tot_gan
	DECLARE q_n33 CURSOR FOR
		SELECT * FROM rolt033
			WHERE n33_compania    = codcia
			  AND n33_cod_liqrol IN ('Q1', 'Q2')
			  AND n33_fecha_ini  >= fecha_ini
			  AND n33_fecha_fin  <= fecha_fin
			  AND n33_cod_trab    = r_n32.n32_cod_trab
			  AND n33_cod_rubro   = (SELECT n06_cod_rubro
						FROM rolt006
						WHERE n06_flag_ident = 'VV')
			  AND n33_valor       > 0
	OPEN q_n33
	FETCH q_n33
	IF STATUS = NOTFOUND THEN
		CLOSE q_n33
		FREE q_n33
		CONTINUE FOREACH
	END IF
	CLOSE q_n33
	FREE q_n33
	CALL retorna_sueldo(r_n32.n32_cod_trab, fecha_ini, fecha_fin)
		RETURNING r_n32.n32_sueldo
	IF r_n32.n32_sueldo <= r_n32.n32_tot_gan THEN
		CONTINUE FOREACH
	END IF
	IF retorna_empleado_insertado_temp(r_n32.n32_cod_trab) THEN
		CONTINUE FOREACH
	END IF
	SELECT NVL(n17_valor, 0) INTO suel_sect
		FROM rolt030, rolt017
		WHERE n30_compania  = codcia
		  AND n30_cod_trab  = r_n32.n32_cod_trab
		  AND n17_sectorial = n30_sectorial
	CASE num_args()
		WHEN 4
			IF r_n32.n32_tot_gan < suel_sect THEN
				LET r_n32.n32_tot_gan = suel_sect
			END IF
			CALL cargar_temporal(2, codcia, codloc,
				r_n32.n32_cod_trab, r_n32.n32_tot_gan, fecha)
		WHEN 5
			IF r_n32.n32_tot_gan < suel_sect THEN
				LET r_n32.n32_sueldo = r_n32.n32_sueldo -
							(suel_sect -
							r_n32.n32_tot_gan)
			END IF
			CALL cargar_temporal(2, codcia, codloc,
				r_n32.n32_cod_trab, r_n32.n32_sueldo, fecha)
	END CASE
END FOREACH
UNLOAD TO "nuevosuevac.txt" DELIMITER ";"
	SELECT ruc, sucursal, anio, mes, tipo, cedula, nuevo_sueldo FROM t1
DROP TABLE t1
RUN 'sed -e "1,$ s/;$//g" nuevosuevac.txt > nuevosuevac2.txt'
RUN 'mv nuevosuevac2.txt nuevosuevac.txt'
RUN 'unix2dos nuevosuevac.txt'
DISPLAY 'Archivo Nuevo Sueldo (VACACIONES) por Empleado, para el IESS, generado OK.'

END FUNCTION



FUNCTION cargar_temporal(flag, cia, loc, cod_trab, suel_nue, fecha)
DEFINE flag		SMALLINT
DEFINE cia		LIKE gent002.g02_compania
DEFINE loc		LIKE gent002.g02_localidad
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE suel_nue		LIKE rolt032.n32_tot_gan
DEFINE fecha		LIKE rolt030.n30_fecha_sal
DEFINE query		CHAR(800)
DEFINE expr_tab		CHAR(30)
DEFINE anio, mes	SMALLINT

LET anio = vm_anio
LET mes  = vm_mes
IF num_args() = 5 THEN
	LET mes = mes + 1
	IF mes = 13 THEN
		LET anio = anio + 1
		LET mes  = 1
	END IF
END IF
LET query    = NULL
LET expr_tab = ' INTO TEMP t1'
IF flag = 2 THEN
	LET query    = 'INSERT INTO t1 '
	LET expr_tab = '   AND n30_cod_trab  = ', cod_trab
END IF
IF suel_nue IS NULL THEN
	SELECT n30_sueldo_mes INTO suel_nue
		FROM rolt030
		WHERE n30_compania = codcia
		  AND n30_cod_trab = cod_trab
END IF
LET query = query CLIPPED,
	' SELECT g02_numruc ruc, "0009" sucursal, ', anio, ' anio, ',
		' LPAD(', mes, ', 2, 0) mes, "MSU" tipo, ',
		' n30_num_doc_id cedula, ',
		' LPAD(', suel_nue, ', 14, 0) nuevo_sueldo, n30_cod_trab ',
		' FROM gent002, rolt030 ',
		' WHERE g02_compania  = ', cia,
		'   AND g02_localidad = ', loc,
		'   AND n30_compania  = g02_compania ',
		'   AND (n30_estado   = "A" OR (n30_estado <> "A" ',
		'   AND EXTEND(n30_fecha_sal, YEAR TO MONTH) >= ',
		'	EXTEND(MDY(', MONTH(fecha), ',', DAY(fecha), ',',
				YEAR(fecha), '), YEAR TO MONTH)))',
		expr_tab CLIPPED
PREPARE cons_t1 FROM query
EXECUTE cons_t1

END FUNCTION



FUNCTION retorna_sueldo(cod_trab, fecha_ini, fecha_fin)
DEFINE cod_trab		LIKE rolt032.n32_cod_trab
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE suel1, suel2	LIKE rolt032.n32_sueldo

SELECT NVL(n32_sueldo, 0) INTO suel1
	FROM rolt032
	WHERE n32_compania    = codcia
	  AND n32_cod_liqrol  = 'Q1'
	  AND n32_fecha_ini  >= fecha_ini
	  AND n32_fecha_fin  <= fecha_fin
	  AND n32_cod_trab    = cod_trab 

SELECT NVL(n32_sueldo, 0) INTO suel2
	FROM rolt032
	WHERE n32_compania    = codcia
	  AND n32_cod_liqrol  = 'Q2'
	  AND n32_fecha_ini  >= fecha_ini
	  AND n32_fecha_fin  <= fecha_fin
	  AND n32_cod_trab    = cod_trab 

IF suel1 <= suel2 THEN
	RETURN suel1
ELSE
	RETURN suel2
END IF

END FUNCTION



FUNCTION retorna_empleado_insertado_temp(cod_trab)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE cod_tr		LIKE rolt032.n32_cod_trab

LET cod_tr = NULL
SELECT n30_cod_trab INTO cod_tr FROM t1 WHERE n30_cod_trab = cod_trab
IF cod_tr IS NOT NULL THEN
	RETURN 1
END IF
RETURN 0

END FUNCTION
