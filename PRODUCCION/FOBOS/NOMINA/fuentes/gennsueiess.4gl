DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE base		CHAR(20)
DEFINE vm_anio, vm_mes	SMALLINT



MAIN

	IF num_args() <> 4 AND num_args() <> 5 THEN
		DISPLAY 'Error de Parametros. Falta la BASE LOCALIDAD AÑO MES o MEDIO_AUMENTO (X).'
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

DISPLAY 'Generando Archivo nuevosue.txt, por favor espere ...'
LET fecha_ini = MDY(vm_mes, 01, vm_anio)
LET fecha_fin = fecha_ini + 1 UNITS MONTH - 1 UNITS DAY
LET fecha     = fecha_fin
CALL cargar_temporal(1, 15, 17, 0, 0, fecha)
IF vm_anio = 2004 OR vm_anio = 2005 THEN
	IF vm_mes = 2 THEN
		LET fecha_fin = fecha_ini - 1 UNITS DAY
		LET fecha_ini = fecha_ini - 1 UNITS MONTH
	END IF
END IF
LET query = 'SELECT UNIQUE n32_cod_trab, n32_sueldo FROM rolt032 ',
		' WHERE n32_compania    = ', codcia,
		'   AND n32_cod_liqrol IN("Q1", "Q2") ',
		'   AND n32_fecha_ini  >= "', fecha_ini, '" ',
		'   AND n32_fecha_fin  <= "', fecha_fin, '" ',
		' ORDER BY n32_sueldo DESC, n32_cod_trab ASC'
PREPARE cons_n32 FROM query
DECLARE q_n32 CURSOR FOR cons_n32
LET fecha_fin = fecha_ini - 1 UNITS DAY
LET fecha_ini = fecha_ini - 1 UNITS MONTH
FOREACH q_n32 INTO r_n32.n32_cod_trab, r_n32.n32_sueldo
	IF vm_anio = 2004 OR vm_anio = 2005 THEN
		IF vm_mes = 2 THEN
			IF retorna_empleado_insertado_temp(r_n32.n32_cod_trab)
			THEN
				CONTINUE FOREACH
			END IF
			CALL cargar_temporal(2, codcia, codloc,
						r_n32.n32_cod_trab, 0, fecha)
			CONTINUE FOREACH
		END IF
	END IF
	CALL retorna_sueldo_ant(codcia, 'Q2', fecha_ini, fecha_fin,
				r_n32.n32_cod_trab)
		RETURNING sueldo_ant
	IF r_n32.n32_sueldo = sueldo_ant THEN
		CALL retorna_sueldo_ant(codcia, 'Q1', fecha_ini, fecha_fin,
					r_n32.n32_cod_trab)
			RETURNING sueldo_ant
		IF r_n32.n32_sueldo = sueldo_ant THEN
			CONTINUE FOREACH
		END IF
	END IF
	IF retorna_empleado_insertado_temp(r_n32.n32_cod_trab) THEN
		CONTINUE FOREACH
	END IF
	IF sueldo_ant IS NULL THEN
		LET sueldo_ant = 0
	END IF
	CALL cargar_temporal(2, codcia, codloc, r_n32.n32_cod_trab, sueldo_ant,
				fecha)
END FOREACH
UNLOAD TO "nuevosue.txt" DELIMITER ";"
	SELECT ruc, sucursal, anio, mes, tipo, cedula, nuevo_sueldo FROM t1
DROP TABLE t1
RUN 'sed -e "1,$ s/;$//g" nuevosue.txt > nuevosue2.txt'
RUN 'mv nuevosue2.txt nuevosue.txt'
RUN 'unix2dos nuevosue.txt'
DISPLAY 'Archivo con Nuevo Sueldo por Trabajador, para el IESS, generado OK.'

END FUNCTION



FUNCTION cargar_temporal(flag, cia, loc, cod_trab, suel_ant, fecha)
DEFINE flag		SMALLINT
DEFINE cia		LIKE gent002.g02_compania
DEFINE loc		LIKE gent002.g02_localidad
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE suel_ant		LIKE rolt030.n30_sueldo_mes
DEFINE fecha		LIKE rolt030.n30_fecha_sal
DEFINE query		CHAR(800)
DEFINE expr_tab		CHAR(30)
DEFINE expr_sue		CHAR(120)
DEFINE v_rus		SMALLINT

LET query    = NULL
LET expr_tab = ' INTO TEMP t1'
IF flag = 2 THEN
	LET query    = 'INSERT INTO t1 '
	LET expr_tab = '   AND n30_cod_trab  = ', cod_trab
END IF
LET expr_sue = ' LPAD(n30_sueldo_mes, 14, 0) nuevo_sueldo '
IF num_args() = 5 THEN
	LET v_rus = 0
	IF vm_anio = 2004 OR vm_anio = 2005 THEN
		IF vm_mes = 1 THEN
			LET v_rus = 8
		END IF
	END IF
	LET expr_sue = ' LPAD(ROUND(n30_sueldo_mes - ((n30_sueldo_mes - ',v_rus,
			' - ', suel_ant,') / 2), 2), 14, 0) nuevo_sueldo '
END IF
LET query = query CLIPPED,
	' SELECT g02_numruc ruc, "0009" sucursal, ', vm_anio, ' anio, ',
		' LPAD(', vm_mes, ', 2, 0) mes, "MSU" tipo, ',
		' n30_num_doc_id cedula, ',
		expr_sue CLIPPED,
		', n30_cod_trab ',
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



FUNCTION retorna_sueldo_ant(cia, codrol, fecha_ini, fecha_fin, cod_trab)
DEFINE cia		LIKE rolt032.n32_compania
DEFINE codrol		LIKE rolt032.n32_cod_liqrol
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE cod_trab		LIKE rolt032.n32_cod_trab
DEFINE r_n32_aux	RECORD LIKE rolt032.*
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE

LET fec_ini = fecha_ini
LET fec_fin = MDY(MONTH(fecha_fin), 15, YEAR(fecha_fin))
IF codrol = 'Q2' THEN
	LET fec_ini = MDY(MONTH(fecha_ini), 16, YEAR(fecha_ini))
	LET fec_fin = fecha_fin
END IF
INITIALIZE r_n32_aux.* TO NULL
SELECT * INTO r_n32_aux.* FROM rolt032
	WHERE n32_compania   = cia
	  AND n32_cod_liqrol = codrol
	  AND n32_fecha_ini  = fec_ini
	  AND n32_fecha_fin  = fec_fin
	  AND n32_cod_trab   = cod_trab
RETURN r_n32_aux.n32_sueldo

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
