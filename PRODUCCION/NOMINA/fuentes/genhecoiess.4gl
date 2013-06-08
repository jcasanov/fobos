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

DISPLAY 'Generando Archivo extras.txt, por favor espere ...'
LET fecha_ini = MDY(vm_mes, 01, vm_anio)
LET fecha_fin = fecha_ini + 1 UNITS MONTH - 1 UNITS DAY
SELECT n30_num_doc_id cedula, n30_nombres, NVL(SUM(n33_valor), 0) valor
	FROM rolt033, rolt030
	WHERE n33_compania    = codcia
	  AND n33_cod_liqrol IN ('Q1', 'Q2')
	  AND n33_fecha_ini  >= fecha_ini
	  AND n33_fecha_fin  <= fecha_fin
	  AND n33_cod_rubro  IN (8, 10, 13, 17)
	  AND n30_compania    = n33_compania
	  AND n30_cod_trab    = n33_cod_trab
	GROUP BY 1, 2
	HAVING NVL(SUM(n33_valor), 0) > 0
	INTO TEMP t1
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
