--------------------------------------------------------------------------------
-- Titulo           : rolp408.4gl - Listado de Aporte al IESS
-- Elaboracion      : 23-Ago-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp408 base modulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n06		RECORD LIKE rolt006.*
DEFINE rm_n32		RECORD LIKE rolt032.*
DEFINE rm_n66		RECORD LIKE rolt066.*
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g02		RECORD LIKE gent002.*
DEFINE n32_mes_proceso	LIKE rolt032.n32_mes_proceso
DEFINE tit_mes		VARCHAR(10)
DEFINE incluir_ext	CHAR(1)
DEFINE tot_emp		INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp408.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 6 THEN  -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de paráametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp408'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
IF rm_g01.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_g02.*
IF rm_g02.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 10
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf408_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf408_1 FROM '../forms/rolf408_1'
ELSE
	OPEN FORM f_rolf408_1 FROM '../forms/rolf408_1c'
END IF
DISPLAY FORM f_rolf408_1
IF NOT cargar_datos_liq() THEN
	LET int_flag = 0
	CLOSE WINDOW w_rolf408_1
	EXIT PROGRAM
END IF
LET incluir_ext = 'N'
IF num_args() <> 3 THEN
	LET rm_n32.n32_fecha_ini = arg_val(4)
	LET rm_n32.n32_fecha_fin = arg_val(5)
	LET incluir_ext          = arg_val(6)
	DISPLAY BY NAME rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin,
			incluir_ext
	LET n32_mes_proceso = NULL
	IF EXTEND(rm_n32.n32_fecha_ini, YEAR TO MONTH) =
	   EXTEND(rm_n32.n32_fecha_fin, YEAR TO MONTH)
	THEN
		LET n32_mes_proceso = MONTH(rm_n32.n32_fecha_ini)
	END IF
	IF n32_mes_proceso IS NOT NULL THEN
		CALL retorna_mes()
	ELSE
		LET tit_mes = NULL
	END IF
END IF
WHILE TRUE
	CALL mostrar_datos_liq()
	IF num_args() = 3 THEN
		CALL lee_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	END IF
	CALL control_reporte()
	IF vg_codloc = 1 THEN
		--CALL control_archivo()
	END IF
	IF num_args() <> 3 THEN
		EXIT WHILE
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_rolf408_1
EXIT PROGRAM

END FUNCTION



FUNCTION cargar_datos_liq()
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE mensaje		VARCHAR(200)

INITIALIZE rm_n32.* TO NULL
CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración general para este módulo.', 'stop')
	RETURN 0
END IF
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración para esta compañía.', 'stop')
	RETURN 0
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fl_mostrar_mensaje('Compañía no está activa.', 'stop')
	RETURN 0
END IF
INITIALIZE r_n05.* TO NULL
DECLARE q_n05 CURSOR FOR
	SELECT * FROM rolt005
		WHERE n05_compania = vg_codcia
		  AND n05_proceso[1] IN ('M', 'Q', 'S')
		ORDER BY n05_fec_cierre DESC
OPEN q_n05
FETCH q_n05 INTO r_n05.*
INITIALIZE r_n32.* TO NULL
DECLARE q_ultliq CURSOR FOR
	SELECT * FROM rolt032
		WHERE n32_compania  = r_n05.n05_compania
		  AND n32_estado   <> 'E'
		ORDER BY n32_fecha_fin DESC
OPEN q_ultliq
FETCH q_ultliq INTO r_n32.*
LET rm_n32.n32_ano_proceso = r_n32.n32_ano_proceso
LET rm_n32.n32_mes_proceso = r_n32.n32_mes_proceso
LET n32_mes_proceso        = rm_n32.n32_mes_proceso
CALL retorna_mes()
INITIALIZE rm_n06.* TO NULL
SELECT * INTO rm_n06.* FROM rolt006 WHERE n06_flag_ident = 'AP'
LET rm_n32.n32_fecha_ini = MDY(rm_n32.n32_mes_proceso, 01,
				rm_n32.n32_ano_proceso)
LET rm_n32.n32_fecha_fin = MDY(rm_n32.n32_mes_proceso, 01,
				rm_n32.n32_ano_proceso)
				+ 1 UNITS MONTH - 1 UNITS DAY
RETURN 1

END FUNCTION



FUNCTION mostrar_datos_liq()

DISPLAY BY NAME rm_n32.n32_ano_proceso, n32_mes_proceso, tit_mes,
		rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin, incluir_ext

END FUNCTION



FUNCTION lee_parametros()
DEFINE anio		LIKE rolt032.n32_ano_proceso
DEFINE mes_aux		LIKE rolt032.n32_mes_proceso
DEFINE fec_ini		LIKE rolt032.n32_fecha_ini
DEFINE fec_fin		LIKE rolt032.n32_fecha_fin
DEFINE dia		SMALLINT

LET int_flag = 0
INPUT BY NAME rm_n32.n32_ano_proceso, n32_mes_proceso,
	rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin, incluir_ext
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(n32_mes_proceso) THEN
			CALL fl_ayuda_mostrar_meses() RETURNING mes_aux, tit_mes
			IF mes_aux IS NOT NULL THEN
				LET n32_mes_proceso = mes_aux
				CALL retorna_mes()
				DISPLAY BY NAME n32_mes_proceso, tit_mes
				CALL mostrar_fechas()
			END IF
                END IF
		LET int_flag = 0
	BEFORE FIELD n32_ano_proceso
		LET anio = rm_n32.n32_ano_proceso
	BEFORE FIELD n32_fecha_ini
		LET fec_ini = rm_n32.n32_fecha_ini
	BEFORE FIELD n32_fecha_fin
		LET fec_fin = rm_n32.n32_fecha_fin
	AFTER FIELD n32_ano_proceso
		IF NOT FIELD_TOUCHED(n32_ano_proceso) THEN
			CONTINUE INPUT
		END IF
		IF rm_n32.n32_ano_proceso IS NOT NULL THEN
			IF rm_n32.n32_ano_proceso > YEAR(TODAY) THEN
				CALL fl_mostrar_mensaje('El año no puede ser mayor al año vigente.', 'exclamation')
				NEXT FIELD n32_ano_proceso
			END IF
		ELSE
			LET rm_n32.n32_ano_proceso = anio
			DISPLAY BY NAME rm_n32.n32_ano_proceso
		END IF
		CALL mostrar_fechas()
	AFTER FIELD n32_mes_proceso
		IF NOT FIELD_TOUCHED(n32_mes_proceso) THEN
			CONTINUE INPUT
		END IF
		IF n32_mes_proceso IS NOT NULL THEN
			CALL retorna_mes()
		ELSE
			LET tit_mes = NULL
		END IF
		DISPLAY BY NAME tit_mes
		CALL mostrar_fechas()
	AFTER FIELD n32_fecha_ini
		IF n32_mes_proceso IS NOT NULL THEN
			CALL mostrar_fechas()
			CONTINUE INPUT
		END IF
		IF rm_n32.n32_fecha_ini IS NULL THEN
			LET rm_n32.n32_fecha_ini = fec_ini
			DISPLAY BY NAME rm_n32.n32_fecha_ini
		END IF
		IF YEAR(rm_n32.n32_fecha_ini) <> rm_n32.n32_ano_proceso THEN
			CALL fl_mostrar_mensaje('El anio de la fecha inicial no puede ser diferente que el anio de proceso.', 'exclamation')
			NEXT FIELD n32_fecha_ini
		END IF
		IF DAY(rm_n32.n32_fecha_ini) > 15 THEN
			LET dia = 16
		ELSE
			LET dia = 1
		END IF
		LET rm_n32.n32_fecha_ini = MDY(MONTH(rm_n32.n32_fecha_ini), dia,
						YEAR(rm_n32.n32_fecha_ini))
		DISPLAY BY NAME rm_n32.n32_fecha_ini
	AFTER FIELD n32_fecha_fin
		IF n32_mes_proceso IS NOT NULL THEN
			CALL mostrar_fechas()
			CONTINUE INPUT
		END IF
		IF rm_n32.n32_fecha_fin IS NULL THEN
			LET rm_n32.n32_fecha_fin = fec_fin
			DISPLAY BY NAME rm_n32.n32_fecha_fin
		END IF
		IF YEAR(rm_n32.n32_fecha_fin) <> rm_n32.n32_ano_proceso THEN
			CALL fl_mostrar_mensaje('El anio de la fecha final no puede ser diferente que el anio de proceso.', 'exclamation')
			NEXT FIELD n32_fecha_fin
		END IF
		IF DAY(rm_n32.n32_fecha_fin) >= 16 THEN
			LET dia = 1
		ELSE
			LET dia = 15
		END IF
		LET rm_n32.n32_fecha_fin = MDY(MONTH(rm_n32.n32_fecha_fin), dia,
						YEAR(rm_n32.n32_fecha_fin))
		IF dia = 1 THEN
			LET rm_n32.n32_fecha_fin = rm_n32.n32_fecha_fin
						+ 1 UNITS MONTH - 1 UNITS DAY
		END IF
		DISPLAY BY NAME rm_n32.n32_fecha_fin
	AFTER INPUT
		IF EXTEND(MDY(n32_mes_proceso,01,rm_n32.n32_ano_proceso),
			YEAR TO MONTH) >
		   EXTEND(TODAY, YEAR TO MONTH)
		THEN
			CALL fl_mostrar_mensaje('El periodo de anio y mes no puede ser mayor al periodo de anio y mes corriente.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF rm_n32.n32_fecha_ini > rm_n32.n32_fecha_fin THEN
			CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor que la fecha final.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT
LET rm_n32.n32_mes_proceso = n32_mes_proceso

END FUNCTION



FUNCTION control_archivo()
DEFINE comando		VARCHAR(150)
DEFINE archivo		VARCHAR(12)

CALL fl_lee_datos_aportes_reserva(vg_codcia, 1) RETURNING rm_n66.*
IF rm_n66.n66_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe el registro de datos extra para generar la planilla de aportes.', 'stop')
	EXIT PROGRAM
END IF
LET archivo = rm_n66.n66_pre_arch, rm_n32.n32_mes_proceso USING '&&',
		rm_g01.g01_numpatronal[1, 5], '.TXT'
LET comando = 'Generando archivo plano ', archivo CLIPPED,
		' espere por favor ... '
ERROR comando
CALL archivo_planilla(archivo)
LET comando = 'mv aporte_iess.txt ', archivo CLIPPED
RUN comando
LET comando = 'mv ', archivo CLIPPED, ' $HOME/tmp/', archivo CLIPPED
RUN comando
ERROR '                                                            '

END FUNCTION



FUNCTION archivo_planilla(archivo)
DEFINE archivo		VARCHAR(12)
DEFINE c		LIKE rolt032.n32_cod_trab
DEFINE cod_trab		LIKE rolt032.n32_cod_trab
DEFINE nombres		LIKE rolt030.n30_nombres
DEFINE dias_trab	LIKE rolt032.n32_dias_trab
DEFINE dias_adic	LIKE rolt032.n32_dias_trab
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE sueldo		DECIMAL(14,2)
DEFINE total		DECIMAL(14,2)
DEFINE long, enter	SMALLINT
DEFINE nro_empleados	SMALLINT
DEFINE total_ca		VARCHAR(12)
DEFINE condicion_afi	VARCHAR(10)
DEFINE registro		VARCHAR(236)

LET enter = 13
DECLARE q_par CURSOR FOR
	SELECT UNIQUE n32_cod_trab, n30_nombres
		FROM rolt032, rolt030
		WHERE n32_compania    = vg_codcia
		  AND n32_ano_proceso = rm_n32.n32_ano_proceso
		  AND n32_mes_proceso = rm_n32.n32_mes_proceso
		  AND n32_estado      <> 'E'
		  AND n32_compania    = n30_compania
		  AND n32_cod_trab    = n30_cod_trab
		ORDER BY n30_nombres
OPEN q_par
FETCH q_par INTO cod_trab, nombres
IF STATUS = NOTFOUND THEN
	ERROR '                                                            '
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE q_par
	FREE q_par
	RETURN
END IF
LET r_g01.g01_numpatronal = rm_g01.g01_numpatronal[1, 11]
LET long                  = LENGTH(r_g01.g01_numpatronal)
IF long < 11 THEN
	LET r_g01.g01_numpatronal = rm_g01.g01_numpatronal[1, 11],
					11 - long SPACES
END IF
LET r_g01.g01_razonsocial = rm_g01.g01_razonsocial[1, 30]
LET long                  = LENGTH(r_g01.g01_razonsocial)
IF long < 30 THEN
	LET r_g01.g01_razonsocial = rm_g01.g01_razonsocial[1, 30],
					30 - long SPACES
END IF
LET r_g02.g02_direccion = rm_g02.g02_direccion[1, 27]
LET long                = LENGTH(r_g02.g02_direccion)
IF long < 27 THEN
	LET r_g02.g02_direccion = rm_g02.g02_direccion[1, 27], 27 - long SPACES
END IF
LET registro = rm_n66.n66_sec_patronal, r_g01.g01_numpatronal[1, 11],
		r_g01.g01_razonsocial[1, 30],
		rm_g02.g02_numruc USING '&&&&&&&&&&&&&',
		rm_n66.n66_provincia USING '&&', rm_n66.n66_canton USING '&&&',
		rm_n66.n66_parroquia USING '&&&&', r_g02.g02_direccion[1, 27]
LET r_g01.g01_replegal = rm_g01.g01_replegal[1, 28]
LET long               = LENGTH(r_g01.g01_replegal)
IF long < 28 THEN
	LET r_g01.g01_replegal = rm_g01.g01_replegal[1, 28], 28 - long SPACES
END IF
LET long     = LENGTH(rm_g02.g02_telefono1)
LET registro = registro, rm_g02.g02_telefono1[long - 5, long],
		r_g01.g01_replegal[1, 28], 2 SPACES, rm_g01.g01_cedrepl[1, 10],
		rm_n66.n66_concepto_pago USING '#', '0000000000000000',
		rm_n32.n32_fecha_ini USING 'YYYYMM',
		rm_n32.n32_fecha_fin USING 'YYYYMM',
		'00000000000000000000000000000000000000000000000',
		rm_n66.n66_tipo_seguro USING '&&&',
		rm_n66.n66_tipo_planilla USING '&&&'
LET nro_empleados = 0
FOREACH q_par INTO cod_trab, nombres
	LET nro_empleados = nro_empleados + 1
END FOREACH
LET registro = registro, nro_empleados USING '&&&&&'
{--
SELECT SUM(n33_valor) INTO total
	FROM rolt008, rolt033
	WHERE n08_cod_rubro  = rm_n06.n06_cod_rubro
	  AND n33_compania   = vg_codcia
	  AND n33_fecha_ini >= rm_n32.n32_fecha_ini
	  AND n33_fecha_fin <= rm_n32.n32_fecha_fin
	  AND n33_cod_rubro  = n08_rubro_base
--}
SELECT SUM(n32_tot_gan) INTO total
	FROM rolt032
	WHERE n32_compania   = vg_codcia
	  AND n32_fecha_ini >= rm_n32.n32_fecha_ini
	  AND n32_fecha_fin <= rm_n32.n32_fecha_fin
LET total_ca = total USING "&&&&&&&&&.&&"
LET total_ca = total_ca[1, 9], total_ca[11, 12]
LET registro = registro, total_ca, '1'
DISPLAY registro, ASCII(enter)
FOREACH q_par INTO cod_trab, nombres
	LET dias_trab = 0
	SELECT n32_cod_trab, NVL(SUM(n32_dias_trab), 0),NVL(SUM(n32_tot_gan), 0)
		INTO c, dias_trab, sueldo
		FROM rolt032
		WHERE n32_compania   = vg_codcia
		  AND n32_fecha_ini >= rm_n32.n32_fecha_ini
		  AND n32_fecha_fin <= rm_n32.n32_fecha_fin
		  AND n32_cod_trab   = cod_trab
		  AND n32_estado    <> 'E'
		GROUP BY n32_cod_trab
	{--
	LET sueldo = 0
	SELECT SUM(n33_valor) INTO sueldo
		FROM rolt008, rolt033
		WHERE n08_cod_rubro  = rm_n06.n06_cod_rubro
		  AND n33_compania   = vg_codcia
		  AND n33_fecha_ini >= rm_n32.n32_fecha_ini
		  AND n33_fecha_fin <= rm_n32.n32_fecha_fin
		  AND n33_cod_trab   = cod_trab
		  AND n33_cod_rubro  = n08_rubro_base
	--}
	CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
	LET r_n30.n30_nombres = nombres
	LET long              = LENGTH(nombres)
	IF long < 30 THEN
		LET r_n30.n30_nombres = nombres, 30 - long SPACES
	END IF
	LET registro = rm_n32.n32_fecha_ini USING 'YYYYMM',
			r_n30.n30_carnet_seg[1, 13] USING '&&&&&&&&&&&&&',
			r_n30.n30_num_doc_id[1, 10] USING '&&&&&&&&&&',
			r_n30.n30_nombres[1, 30], '000000000000',
			r_n30.n30_sectorial USING '&&&&&&&&&&'
	LET condicion_afi = '00', '00000000'
	IF dias_trab < 30 THEN
		IF r_n30.n30_fecha_reing IS NULL THEN
			IF (r_n30.n30_fecha_ing >= rm_n32.n32_fecha_ini) AND
			   (r_n30.n30_fecha_ing <= rm_n32.n32_fecha_fin)
			THEN
				LET condicion_afi = '01',
					r_n30.n30_fecha_ing USING 'YYYYMMDD'
			END IF
		ELSE
			IF (r_n30.n30_fecha_reing >= rm_n32.n32_fecha_ini) AND
			   (r_n30.n30_fecha_reing <= rm_n32.n32_fecha_fin)
			THEN
				LET condicion_afi = '01',
					r_n30.n30_fecha_reing USING 'YYYYMMDD'
			END IF
		END IF
		LET dias_adic = 0
		SELECT NVL(SUM(n33_valor), 0)
			INTO dias_adic
			FROM rolt033
			WHERE n33_compania   = vg_codcia
			  AND n33_fecha_ini >= rm_n32.n32_fecha_ini
			  AND n33_fecha_fin <= rm_n32.n32_fecha_fin
			  AND n33_cod_trab   = cod_trab
			  AND n33_cod_rubro IN
				(SELECT n08_rubro_base
					FROM rolt006, rolt008
					WHERE n06_flag_ident = 'DT'
					  AND n08_cod_rubro  = n06_cod_rubro
					  AND n08_rubro_base NOT IN
						(SELECT n06_cod_rubro
						FROM rolt006
						WHERE n06_flag_ident = 'DF'))
		LET dias_trab = dias_trab + dias_adic
		IF dias_trab > 30 THEN
			LET dias_trab = 30
		END IF
	END IF
	IF r_n30.n30_fecha_sal IS NOT NULL AND r_n30.n30_estado <> 'J' THEN
		IF r_n30.n30_fecha_reing IS NULL THEN
			LET condicion_afi = '02',
					r_n30.n30_fecha_sal USING 'YYYYMMDD'
		END IF
	END IF
	LET total_ca = sueldo USING "&&&&&&&.&&"
	LET total_ca = total_ca[1, 7], total_ca[9, 10]
	LET registro = registro, total_ca, dias_trab USING '&&', '00',
			condicion_afi, 131 SPACES, '2'
	DISPLAY registro, ASCII(enter)
END FOREACH
CALL fl_mostrar_mensaje('Generado el archivo texto ' || archivo || '.', 'info')

END FUNCTION



FUNCTION retorna_mes()

CALL fl_justifica_titulo('I', fl_retorna_nombre_mes(n32_mes_proceso), 10)
	RETURNING tit_mes

END FUNCTION 



FUNCTION mostrar_fechas()

IF n32_mes_proceso IS NOT NULL THEN
	CALL fl_retorna_rango_fechas_proceso(vg_codcia, 'ME',
						rm_n32.n32_ano_proceso,
						n32_mes_proceso)
		RETURNING rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin
ELSE
	LET rm_n32.n32_fecha_ini = MDY(01, 01, rm_n32.n32_ano_proceso)
	LET rm_n32.n32_fecha_fin = MDY(12, 31, rm_n32.n32_ano_proceso)
END IF
DISPLAY BY NAME rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin

END FUNCTION 



FUNCTION control_reporte()
DEFINE r_rep		RECORD
				cod_trab	LIKE rolt030.n30_cod_trab,
				cedula		LIKE rolt030.n30_num_doc_id,
				empleado	LIKE rolt030.n30_nombres,
				dias_trab	LIKE rolt032.n32_dias_trab,
				fecha_nov	DATE,
				codigo_nov	LIKE rolt022.n22_tipo_arch,
				sueldo		LIKE rolt032.n32_sueldo,
				valor_ext	LIKE rolt027.n27_valor_ext,
				valor_rol	DECIMAL(12,2),
				ap_iess_per	DECIMAL(12,2),
				ap_iess_pat	DECIMAL(12,2),
				ap_iess		DECIMAL(12,2)
			END RECORD
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

IF NOT preparar_query() THEN
	RETURN
END IF
IF incluir_ext = 'S' THEN
	CALL obtener_extras()
END IF
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	DROP TABLE tmp_emp
	RETURN
END IF
DECLARE q_emp CURSOR FOR SELECT * FROM tmp_emp ORDER BY empleado
START REPORT report_empleados_iess TO PIPE comando
FOREACH q_emp INTO r_rep.*
	{--
	IF r_rep.fecha_nov IS NOT NULL THEN
		CALL retorna_sueldo_parc(r_rep.cod_trab) RETURNING r_rep.sueldo
	END IF
	--}
	OUTPUT TO REPORT report_empleados_iess(r_rep.*)
END FOREACH
FINISH REPORT report_empleados_iess
DROP TABLE tmp_emp

END FUNCTION



FUNCTION preparar_query()
DEFINE query		CHAR(15000)

SELECT * FROM rolt033
	WHERE n33_compania    = vg_codcia
	  AND n33_cod_liqrol IN ("Q1", "Q2")
	  AND n33_fecha_ini  >= rm_n32.n32_fecha_ini
	  AND n33_fecha_fin  <= rm_n32.n32_fecha_fin
	  AND n33_cant_valor  = "V"
	  AND n33_valor       > 0
	INTO TEMP tmp_n33
LET query = 'SELECT a.n32_cod_trab AS cod_trab, n30_num_doc_id AS cedula, ',
		'n30_nombres AS empleado, NVL(SUM(a.n32_dias_trab),0) AS dias,',
		' NVL(CASE WHEN n30_fecha_reing IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_reing, YEAR TO MONTH) = ',
			'EXTEND(MDY(a.n32_mes_proceso, 01, a.n32_ano_proceso),',
				' YEAR TO MONTH) ',
			'THEN n30_fecha_reing ',
			'END ',
		'END, ',
		'NVL(CASE WHEN n30_fecha_ing IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_ing, YEAR TO MONTH) = ',
			'EXTEND(MDY(a.n32_mes_proceso, 01,a.n32_ano_proceso), ',
				'YEAR TO MONTH) ',
			'THEN n30_fecha_ing ',
			'END ',
		'END, ',
		'NVL(CASE WHEN n30_fecha_sal IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_sal, YEAR TO MONTH) = ',
			'EXTEND(MDY(a.n32_mes_proceso, 01,a.n32_ano_proceso), ',
				'YEAR TO MONTH) ',
			'THEN n30_fecha_sal ',
			'END ',
		'END, ',
		'(SELECT MAX(n47_fecini_vac + n47_dias_goza UNITS DAY) ',
			'FROM rolt047 ',
			'WHERE n47_compania         = n30_compania ',
			'  AND YEAR(n47_fecha_fin)  = a.n32_ano_proceso ',
			'  AND MONTH(n47_fecha_fin) = a.n32_mes_proceso ',
			'  AND n47_cod_trab         = a.n32_cod_trab)',
		'))) AS fecha_nov, ',
		'CASE WHEN NVL((SELECT SUM(b.n32_dias_trab) ',
			'FROM rolt032 b ',
			'WHERE b.n32_compania    = n30_compania ',
			'  AND b.n32_ano_proceso = a.n32_ano_proceso ',
			'  AND b.n32_mes_proceso = a.n32_mes_proceso ',
			'  AND b.n32_cod_trab    = a.n32_cod_trab), 0) = ',
				'(SELECT n00_dias_mes FROM rolt000 ',
				'WHERE n00_serial = n30_compania) ',
		'THEN ',
		'NVL(CASE WHEN n30_fecha_reing IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_reing, YEAR TO MONTH) = ',
			'EXTEND(MDY(a.n32_mes_proceso, 01, a.n32_ano_proceso),',
				' YEAR TO MONTH) ',
			'THEN (SELECT n22_tipo_arch ',
				'FROM rolt022 ',
				'WHERE n22_compania    = n30_compania ',
				'  AND n22_codigo_arch = 4) ',
			'END ',
		'END, ',
		'NVL(CASE WHEN n30_fecha_ing IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_ing, YEAR TO MONTH) = ',
			'EXTEND(MDY(a.n32_mes_proceso, 01,a.n32_ano_proceso), ',
				'YEAR TO MONTH) ',
			'THEN (SELECT n22_tipo_arch ',
				'FROM rolt022 ',
				'WHERE n22_compania    = n30_compania ',
				'  AND n22_codigo_arch = 4) ',
			'END ',
		'END, ',
		'NVL(CASE WHEN n30_fecha_sal IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_sal, YEAR TO MONTH) = ',
			'EXTEND(MDY(a.n32_mes_proceso, 01,a.n32_ano_proceso), ',
				'YEAR TO MONTH) ',
			'THEN (SELECT n22_tipo_arch ',
				'FROM rolt022 ',
				'WHERE n22_compania    = n30_compania ',
				'  AND n22_codigo_arch = 5) ',
			'END ',
		'END, ',
		'(SELECT UNIQUE n26_tipo_arch ',
			'FROM rolt026, rolt027 ',
			'WHERE n26_compania    = n30_compania ',
			'  AND n26_codigo_arch = 2 ',
			'  AND n26_ano_carga   = a.n32_ano_proceso ',
			'  AND n26_mes_carga   = a.n32_mes_proceso ',
			'  AND n26_estado     <> "E" ',
			'  AND n27_compania    = n26_compania ',
			'  AND n27_ano_proceso = n26_ano_proceso ',
			'  AND n27_mes_proceso = n26_mes_proceso ',
			'  AND n27_codigo_arch = n26_codigo_arch ',
			'  AND n27_tipo_arch   = n26_tipo_arch ',
			'  AND n27_secuencia   = n26_secuencia ',
			'  AND n27_estado     <> "E" ',
			'  AND n27_cod_trab    = n30_cod_trab)',
		'))) ',
		'ELSE CASE WHEN ',
		' NVL(NVL(CASE WHEN n30_fecha_reing IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_reing, YEAR TO MONTH) = ',
			'EXTEND(MDY(a.n32_mes_proceso, 01, a.n32_ano_proceso),',
				' YEAR TO MONTH) ',
			'THEN n30_fecha_reing ',
			'END ',
		'END, ',
		'NVL(CASE WHEN n30_fecha_ing IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_ing, YEAR TO MONTH) = ',
			'EXTEND(MDY(a.n32_mes_proceso, 01,a.n32_ano_proceso), ',
				'YEAR TO MONTH) ',
			'THEN n30_fecha_ing ',
			'END ',
		'END, ',
		'NVL(CASE WHEN n30_fecha_sal IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_sal, YEAR TO MONTH) = ',
			'EXTEND(MDY(a.n32_mes_proceso, 01,a.n32_ano_proceso), ',
				'YEAR TO MONTH) ',
			'THEN n30_fecha_sal ',
			'END ',
		'END, ',
		'(SELECT MAX(n47_fecini_vac + n47_dias_goza UNITS DAY) ',
			'FROM rolt047 ',
			'WHERE n47_compania         = n30_compania ',
			'  AND YEAR(n47_fecha_fin)  = a.n32_ano_proceso ',
			'  AND MONTH(n47_fecha_fin) = a.n32_mes_proceso ',
			'  AND n47_cod_trab         = a.n32_cod_trab)',
		'))), "01/01/1980") = "01/01/1980" ',
			'THEN "EMF" ',
			'ELSE CASE WHEN ',
		'NVL(NVL(CASE WHEN n30_fecha_reing IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_reing, YEAR TO MONTH) = ',
			'EXTEND(MDY(a.n32_mes_proceso, 01, a.n32_ano_proceso),',
				' YEAR TO MONTH) ',
			'THEN (SELECT n22_tipo_arch ',
				'FROM rolt022 ',
				'WHERE n22_compania    = n30_compania ',
				'  AND n22_codigo_arch = 4) ',
			'END ',
		'END, ',
		'NVL(CASE WHEN n30_fecha_ing IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_ing, YEAR TO MONTH) = ',
			'EXTEND(MDY(a.n32_mes_proceso, 01,a.n32_ano_proceso), ',
				'YEAR TO MONTH) ',
			'THEN (SELECT n22_tipo_arch ',
				'FROM rolt022 ',
				'WHERE n22_compania    = n30_compania ',
				'  AND n22_codigo_arch = 4) ',
			'END ',
		'END, ',
		'NVL(CASE WHEN n30_fecha_sal IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_sal, YEAR TO MONTH) = ',
			'EXTEND(MDY(a.n32_mes_proceso, 01,a.n32_ano_proceso), ',
				'YEAR TO MONTH) ',
			'THEN (SELECT n22_tipo_arch ',
				'FROM rolt022 ',
				'WHERE n22_compania    = n30_compania ',
				'  AND n22_codigo_arch = 5) ',
			'END ',
		'END, ',
		'(SELECT UNIQUE n26_tipo_arch ',
			'FROM rolt026, rolt027 ',
			'WHERE n26_compania    = n30_compania ',
			'  AND n26_codigo_arch = 2 ',
			'  AND n26_ano_carga   = a.n32_ano_proceso ',
			'  AND n26_mes_carga   = a.n32_mes_proceso ',
			'  AND n26_estado     <> "E" ',
			'  AND n27_compania    = n26_compania ',
			'  AND n27_ano_proceso = n26_ano_proceso ',
			'  AND n27_mes_proceso = n26_mes_proceso ',
			'  AND n27_codigo_arch = n26_codigo_arch ',
			'  AND n27_tipo_arch   = n26_tipo_arch ',
			'  AND n27_secuencia   = n26_secuencia ',
			'  AND n27_estado     <> "E" ',
			'  AND n27_cod_trab    = n30_cod_trab)',
		'))), "01/01/1980") = "01/01/1980" ',
				'THEN "VAC" ',
				'ELSE ',
		'NVL(CASE WHEN n30_fecha_reing IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_reing, YEAR TO MONTH) = ',
			'EXTEND(MDY(a.n32_mes_proceso, 01, a.n32_ano_proceso),',
				' YEAR TO MONTH) ',
			'THEN (SELECT n22_tipo_arch ',
				'FROM rolt022 ',
				'WHERE n22_compania    = n30_compania ',
				'  AND n22_codigo_arch = 4) ',
			'END ',
		'END, ',
		'NVL(CASE WHEN n30_fecha_ing IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_ing, YEAR TO MONTH) = ',
			'EXTEND(MDY(a.n32_mes_proceso, 01,a.n32_ano_proceso), ',
				'YEAR TO MONTH) ',
			'THEN (SELECT n22_tipo_arch ',
				'FROM rolt022 ',
				'WHERE n22_compania    = n30_compania ',
				'  AND n22_codigo_arch = 4) ',
			'END ',
		'END, ',
		'NVL(CASE WHEN n30_fecha_sal IS NOT NULL ',
		'THEN CASE WHEN EXTEND(n30_fecha_sal, YEAR TO MONTH) = ',
			'EXTEND(MDY(a.n32_mes_proceso, 01,a.n32_ano_proceso), ',
				'YEAR TO MONTH) ',
			'THEN (SELECT n22_tipo_arch ',
				'FROM rolt022 ',
				'WHERE n22_compania    = n30_compania ',
				'  AND n22_codigo_arch = 5) ',
			'END ',
		'END, ',
		'(SELECT UNIQUE n26_tipo_arch ',
			'FROM rolt026, rolt027 ',
			'WHERE n26_compania    = n30_compania ',
			'  AND n26_codigo_arch = 2 ',
			'  AND n26_ano_carga   = a.n32_ano_proceso ',
			'  AND n26_mes_carga   = a.n32_mes_proceso ',
			'  AND n26_estado     <> "E" ',
			'  AND n27_compania    = n26_compania ',
			'  AND n27_ano_proceso = n26_ano_proceso ',
			'  AND n27_mes_proceso = n26_mes_proceso ',
			'  AND n27_codigo_arch = n26_codigo_arch ',
			'  AND n27_tipo_arch   = n26_tipo_arch ',
			'  AND n27_secuencia   = n26_secuencia ',
			'  AND n27_estado     <> "E" ',
			'  AND n27_cod_trab    = n30_cod_trab)',
		'))) ',
				'END ',
			'END ',
		'END AS cod_nov, ',
		'CASE WHEN NVL(SUM((SELECT SUM(n33_valor) ',
			'FROM tmp_n33 ',
			'WHERE n33_compania   = a.n32_compania ',
			'  AND n33_fecha_ini  = a.n32_fecha_ini ',
			'  AND n33_fecha_fin  = a.n32_fecha_fin ',
			'  AND n33_cod_trab   = a.n32_cod_trab ',
			'  AND n33_cod_rubro IN ',
				'(SELECT n06_cod_rubro ',
				'FROM rolt006 ',
				'WHERE n06_flag_ident IN ("VT", "VV", "OV", ',
						'"VE", "SX", "SY")))), 0) >= ',
			'NVL(SUM(a.n32_sueldo / ',
			'(SELECT COUNT(*) ',
				'FROM rolt032 b ',
				'WHERE b.n32_compania    = a.n32_compania ',
				'  AND b.n32_ano_proceso = a.n32_ano_proceso ',
				'  AND b.n32_mes_proceso = a.n32_mes_proceso ',
				'  AND b.n32_cod_trab    = a.n32_cod_trab)),0)',
		' THEN ',
			'NVL(SUM(a.n32_sueldo / ',
			'(SELECT COUNT(*) ',
				'FROM rolt032 b ',
				'WHERE b.n32_compania    = a.n32_compania ',
				'  AND b.n32_ano_proceso = a.n32_ano_proceso ',
				'  AND b.n32_mes_proceso = a.n32_mes_proceso ',
				'  AND b.n32_cod_trab    = a.n32_cod_trab)), ',
			'0)',
		' ELSE ',
			'NVL(SUM((SELECT SUM(n33_valor) ',
				'FROM tmp_n33 ',
				'WHERE n33_compania   = a.n32_compania ',
				'  AND n33_fecha_ini  = a.n32_fecha_ini ',
				'  AND n33_fecha_fin  = a.n32_fecha_fin ',
				'  AND n33_cod_trab   = a.n32_cod_trab ',
				'  AND n33_cod_rubro IN ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident IN ("VT", "VV", ',
						'"OV", "VE", "SX", "SY")))), 0) ',
		' END AS sueldo, ',
		--retorna_columna_val(4) CLIPPED, ' AS valor_ext, ',
		retorna_columna_val(1) CLIPPED, ' - ',
		'(CASE WHEN NVL(SUM((SELECT SUM(n33_valor) ',
			'FROM tmp_n33 ',
			'WHERE n33_compania   = a.n32_compania ',
			'  AND n33_fecha_ini  = a.n32_fecha_ini ',
			'  AND n33_fecha_fin  = a.n32_fecha_fin ',
			'  AND n33_cod_trab   = a.n32_cod_trab ',
			'  AND n33_cod_rubro IN ',
				'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident IN ("VT", "VV", ',
						'"OV", "VE", "SX", "SY")))), 0) >= ',
			'NVL(SUM(a.n32_sueldo / ',
			'(SELECT COUNT(*) ',
				'FROM rolt032 b ',
				'WHERE b.n32_compania    = a.n32_compania ',
				'  AND b.n32_ano_proceso = a.n32_ano_proceso ',
				'  AND b.n32_mes_proceso = a.n32_mes_proceso ',
				'  AND b.n32_cod_trab    = a.n32_cod_trab)),0)',
		' THEN ',
			'NVL(SUM(a.n32_sueldo / ',
			'(SELECT COUNT(*) ',
				'FROM rolt032 b ',
				'WHERE b.n32_compania    = a.n32_compania ',
				'  AND b.n32_ano_proceso = a.n32_ano_proceso ',
				'  AND b.n32_mes_proceso = a.n32_mes_proceso ',
				'  AND b.n32_cod_trab    = a.n32_cod_trab)), ',
			'0)',
		' ELSE ',
			'NVL(SUM((SELECT SUM(n33_valor) ',
				'FROM tmp_n33 ',
				'WHERE n33_compania   = a.n32_compania ',
				'  AND n33_fecha_ini  = a.n32_fecha_ini ',
				'  AND n33_fecha_fin  = a.n32_fecha_fin ',
				'  AND n33_cod_trab   = a.n32_cod_trab ',
				'  AND n33_cod_rubro IN ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident IN ("VT", "VV", ',
						'"OV", "VE", "SX", "SY")))), 0) ',
		' END) AS valor_ext, ',
		retorna_columna_val(1) CLIPPED, ' AS valor_rol, ',
		retorna_columna_val(2) CLIPPED, ' AS ap_iess_per, ',
		retorna_columna_val(3) CLIPPED, ' AS ap_iess_pat, ',
		retorna_columna_val(2) CLIPPED, ' + ',
		retorna_columna_val(3) CLIPPED, ' AS ap_iess ',
		' FROM rolt032 a, rolt030 ',
		' WHERE a.n32_compania    = ', vg_codcia,
		'   AND a.n32_cod_liqrol IN ("Q1", "Q2") ',
		'   AND a.n32_fecha_ini  >= "', rm_n32.n32_fecha_ini, '"',
		'   AND a.n32_fecha_fin  <= "', rm_n32.n32_fecha_fin, '"',
		'   AND a.n32_estado     <> "E" ',
		'   AND n30_compania      = a.n32_compania ',
		'   AND n30_cod_trab      = a.n32_cod_trab ',
		'   AND n30_cod_trab     <> 170 ',
		' GROUP BY 1, 2, 3, 5, 6 ',
		' INTO TEMP t1 '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
SELECT COUNT(*) INTO tot_emp FROM t1
DROP TABLE tmp_n33
IF tot_emp = 0 THEN
	DROP TABLE t1
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
END IF
IF n32_mes_proceso IS NOT NULL THEN
	SELECT * FROM t1 INTO TEMP tmp_emp
ELSE
	SELECT cod_trab, cedula, empleado,
		NVL(SUM(dias), 0) AS dias,
		"" fecha_nov, "" cod_nov,
		NVL(SUM(sueldo), 0) AS sueldo,
		NVL(SUM(valor_ext), 0) AS valor_ext,
		NVL(SUM(valor_rol), 0) AS valor_rol,
		NVL(SUM(ap_iess_per), 0) AS ap_iess_per,
		NVL(SUM(ap_iess_pat), 0) AS ap_iess_pat,
		NVL(SUM(ap_iess), 0) AS ap_iess
		FROM t1
		GROUP BY 1, 2, 3, 5, 6
		INTO TEMP tmp_emp
END IF
SELECT COUNT(*) INTO tot_emp FROM tmp_emp
DROP TABLE t1
RETURN 1

END FUNCTION



FUNCTION retorna_columna_val(flag)
DEFINE flag		SMALLINT
DEFINE expr_col		CHAR(600)
DEFINE expr_rub		CHAR(300)
DEFINE expr_seg		CHAR(200)
DEFINE det_tot		LIKE rolt033.n33_det_tot

LET expr_seg = NULL
IF flag = 1 OR flag = 3 THEN
	LET expr_rub = '  AND n33_cod_rubro  IN ',
				'(SELECT n08_rubro_base ',
				'FROM rolt008 ',
				'WHERE n08_cod_rubro = ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident = "AP")) '
	LET det_tot  = "DI"
	IF flag = 3 THEN
		LET expr_seg = ' * (SELECT n13_porc_cia / 100 ',
				'FROM rolt013 ',
				'WHERE n13_cod_seguro = n30_cod_seguro) '
	END IF
END IF
IF flag = 2 THEN
	LET expr_rub = '  AND n33_cod_rubro  IN ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident = "AP") '
	LET det_tot  = "DE"
END IF
IF flag = 4 THEN
	LET expr_rub = '  AND n33_cod_rubro  IN ',
					'(SELECT n06_cod_rubro ',
					'FROM rolt006 ',
					'WHERE n06_flag_ident IN ("V5", "V1",',
					' "CO", "C1", "C2", "C3", "VE")) '
	LET det_tot  = "DI"
END IF
LET expr_col = 'SUM(NVL((SELECT SUM(n33_valor) ',
		'FROM tmp_n33 ',
	  	'WHERE n33_compania    = a.n32_compania ',
		'  AND n33_cod_liqrol  = a.n32_cod_liqrol ',
		'  AND n33_fecha_ini   = a.n32_fecha_ini ',
		'  AND n33_fecha_fin   = a.n32_fecha_fin ',
		'  AND n33_cod_trab    = a.n32_cod_trab ',
		expr_rub CLIPPED,
		'  AND n33_det_tot     = "', det_tot, '"), 0)',
		expr_seg CLIPPED, ') '
RETURN expr_col CLIPPED

END FUNCTION



FUNCTION obtener_extras()
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE nombre		LIKE rolt030.n30_nombres
DEFINE sueldo		LIKE rolt030.n30_sueldo_mes
DEFINE valor_ext	LIKE rolt032.n32_tot_gan
DEFINE query		CHAR(600)
DEFINE expr_sql		VARCHAR(100)
DEFINE cuantos		INTEGER

LET expr_sql = NULL
IF rm_n32.n32_ano_proceso IS NOT NULL THEN
	LET expr_sql = '   AND n26_mes_carga   = ', rm_n32.n32_mes_proceso
END IF
LET query = 'SELECT COUNT(*) ctos ',
		' FROM rolt026, rolt027 ',
		' WHERE n26_compania    = ', vg_codcia,
		'   AND n26_codigo_arch = 2 ',
		'   AND n26_ano_carga   = ', rm_n32.n32_ano_proceso,
		expr_sql CLIPPED,
		'   AND n26_estado     <> "E" ',
		' INTO TEMP t1 '
PREPARE exec_ctos FROM query
EXECUTE exec_ctos
SELECT * INTO cuantos FROM t1
DROP TABLE t1
IF cuantos = 0 THEN
	CALL fl_mostrar_mensaje('No existen diferencias que incluir en este periodo.', 'info')
	RETURN
END IF
SELECT n33_cod_trab, NVL(SUM(n33_valor), 0) valor
	FROM rolt033
	WHERE n33_compania    = vg_codcia
	  AND n33_cod_liqrol IN ('Q1', 'Q2')
	  AND n33_fecha_ini  >= rm_n32.n32_fecha_ini
	  AND n33_fecha_fin  <= rm_n32.n32_fecha_fin
	  AND n33_cod_rubro  IN
		(SELECT b.n08_rubro_base
			FROM rolt006 a, rolt008 b
				WHERE a.n06_estado     = 'A'
				  AND a.n06_flag_ident = 'AP'
				  AND b.n08_cod_rubro  = a.n06_cod_rubro
				  AND b.n08_rubro_base NOT IN
					(SELECT c.n06_cod_rubro
					FROM rolt006 c
					WHERE c.n06_flag_ident IN
					('VT', 'VV', 'VE', 'VM', 'OV', 'SX', 'SY')))
	GROUP BY 1
	HAVING NVL(SUM(n33_valor), 0) > 0
	INTO TEMP t1
DECLARE q_n32 CURSOR FOR
	SELECT n32_cod_trab, NVL(SUM(n32_tot_gan), 0)
		FROM rolt032
		WHERE n32_compania    = vg_codcia
		  AND n32_cod_liqrol IN ('Q1', 'Q2')
		  AND n32_fecha_ini  >= rm_n32.n32_fecha_ini
		  AND n32_fecha_fin  <= rm_n32.n32_fecha_fin
		GROUP BY 1
FOREACH q_n32 INTO r_n32.n32_cod_trab, r_n32.n32_tot_gan
	{--
	SELECT UNIQUE n33_cod_trab FROM rolt033
		WHERE n33_compania    = vg_codcia
		  AND n33_cod_liqrol IN ('Q1', 'Q2')
		  AND n33_fecha_ini  >= rm_n32.n32_fecha_ini
		  AND n33_fecha_fin  <= rm_n32.n32_fecha_fin
		  AND n33_cod_trab    = r_n32.n32_cod_trab
		  AND n33_cod_rubro   = (SELECT n06_cod_rubro
						FROM rolt006
						WHERE n06_flag_ident = 'VV')
		  AND n33_valor       > 0
	IF STATUS = NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	--}
	SELECT n30_nombres, n30_sueldo_mes
		INTO nombre, sueldo
		FROM rolt030
		WHERE n30_compania = vg_codcia
		  AND n30_cod_trab = r_n32.n32_cod_trab
		  AND n30_estado   = 'A'
	LET valor_ext = r_n32.n32_tot_gan - sueldo
	IF valor_ext > 0 THEN
		SELECT UNIQUE n33_cod_trab
			FROM t1
			WHERE n33_cod_trab = r_n32.n32_cod_trab
		IF STATUS = NOTFOUND THEN
			INSERT INTO t1
				VALUES(r_n32.n32_cod_trab, valor_ext)
			ERROR 'Ins. en T1 Emp. ',
				r_n32.n32_cod_trab USING "<<<&&&",
				' VALOR_EXT = ', valor_ext USING "--,--&.##",
				' TOT_GAN = ', r_n32.n32_tot_gan
				USING "##,##&.##", ' SUELDO = ',
				sueldo using "##,##&.##"
			CONTINUE FOREACH
		END IF
		UPDATE t1 SET valor = valor_ext
			WHERE n33_cod_trab = r_n32.n32_cod_trab
		ERROR 'Act. en T1 Emp. ', r_n32.n32_cod_trab USING "<<<&&&",
			' VALOR_EXT = ', valor_ext USING "--,--&.##",
			' TOT_GAN = ', r_n32.n32_tot_gan USING "##,##&.##",
			' SUELDO = ', sueldo using "##,##&.##"
	ELSE
		ERROR 'Eli. en T1 Emp. ',
			r_n32.n32_cod_trab USING "<<<&&&",
			' VALOR_EXT = ', valor_ext USING "--,--&.##",
			' TOT_GAN = ', r_n32.n32_tot_gan USING "##,##&.##",
			' SUELDO = ', sueldo using "##,##&.##"
		DELETE FROM t1 WHERE n33_cod_trab = r_n32.n32_cod_trab
	END IF
END FOREACH
LET expr_sql = NULL
IF rm_n32.n32_ano_proceso IS NOT NULL THEN
	LET expr_sql = '   AND n26_mes_carga   = ', rm_n32.n32_mes_proceso
END IF
LET query = 'SELECT n27_cod_trab, NVL(SUM(n27_valor_ext), 0) valor_ext, ',
		'NVL(SUM(n27_valor_adi), 0) valor_adi ',
		' FROM rolt026, rolt027 ',
		' WHERE n26_compania    = ', vg_codcia,
		'   AND n26_codigo_arch = 2 ',
		'   AND n26_ano_carga   = ', rm_n32.n32_ano_proceso,
		expr_sql CLIPPED,
		'   AND n26_estado     <> "E" ',
		'   AND n27_compania    = n26_compania ',
		'   AND n27_ano_proceso = n26_ano_proceso ',
		'   AND n27_mes_proceso = n26_mes_proceso ',
		'   AND n27_codigo_arch = n26_codigo_arch ',
		'   AND n27_tipo_arch   = n26_tipo_arch ',
		'   AND n27_secuencia   = n26_secuencia ',
		'   AND n27_estado     <> "E" ',
		' GROUP BY 1 ',
		' INTO TEMP t2 '
PREPARE exec_t2 FROM query
EXECUTE exec_t2
LET query = 'SELECT CASE WHEN n33_cod_trab IS NOT NULL ',
				'THEN n33_cod_trab ',
				'ELSE n27_cod_trab ',
			'END cod_emp, ',
		'(NVL(valor_ext + valor_adi, 0) - NVL(valor, 0)) val_ext ',
		' FROM t1, OUTER t2 ',
		' WHERE n33_cod_trab = n27_cod_trab ',
		' UNION ',
		' SELECT CASE WHEN n27_cod_trab IS NOT NULL ',
				'THEN n27_cod_trab ',
				'ELSE n33_cod_trab ',
			'END cod_emp, ',
		'(NVL(valor_ext + valor_adi, 0) - NVL(valor, 0)) val_ext ',
		' FROM t2, OUTER t1 ',
		' WHERE n27_cod_trab = n33_cod_trab ',
		' INTO TEMP t3 '
PREPARE exec_t3 FROM query
EXECUTE exec_t3
DROP TABLE t1
DROP TABLE t2
SELECT cod_emp, val_ext,
	val_ext * (SELECT n13_porc_trab / 100
			FROM rolt030, rolt013
			WHERE n30_compania   = vg_codcia
			  AND n30_cod_trab   = cod_emp
			  AND n13_cod_seguro = n30_cod_seguro) AS ap_per,
	val_ext * (SELECT n13_porc_cia / 100
			FROM rolt030, rolt013
			WHERE n30_compania   = vg_codcia
			  AND n30_cod_trab   = cod_emp
			  AND n13_cod_seguro = n30_cod_seguro) AS ap_pat,
	(val_ext * (SELECT n13_porc_trab / 100
			FROM rolt030, rolt013
			WHERE n30_compania   = vg_codcia
			  AND n30_cod_trab   = cod_emp
			  AND n13_cod_seguro = n30_cod_seguro)) +
	(val_ext * (SELECT n13_porc_cia / 100
			FROM rolt030, rolt013
			WHERE n30_compania   = vg_codcia
			  AND n30_cod_trab   = cod_emp
			  AND n13_cod_seguro = n30_cod_seguro)) AS v_iess
	FROM t3
	WHERE val_ext <> 0
	INTO TEMP t4
DROP TABLE t3
UPDATE tmp_emp
	SET valor_ext   = valor_ext   + (SELECT val_ext
						FROM t4
						WHERE cod_emp = cod_trab),
	    valor_rol   = valor_rol   + (SELECT val_ext
						FROM t4
						WHERE cod_emp = cod_trab),
	    ap_iess_per = ap_iess_per + (SELECT ap_per
						FROM t4
						WHERE cod_emp = cod_trab),
	    ap_iess_pat = ap_iess_pat + (SELECT ap_pat
						FROM t4
						WHERE cod_emp = cod_trab),
	    ap_iess     = ap_iess     + (SELECT v_iess
						FROM t4
						WHERE cod_emp = cod_trab)
	WHERE cod_trab IN (SELECT cod_emp FROM t4)
DROP TABLE t4

END FUNCTION



FUNCTION retorna_sueldo_parc(cod_trab)
DEFINE cod_trab		LIKE rolt032.n32_cod_trab
DEFINE sueldo_parc	LIKE rolt030.n30_sueldo_mes

SELECT NVL(SUM(n33_valor), 0)
	INTO sueldo_parc
	FROM rolt032, rolt033
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_fecha_ini  >= rm_n32.n32_fecha_ini
	  AND n32_fecha_fin  <= rm_n32.n32_fecha_fin
	  AND n32_cod_trab    = cod_trab
	  AND n32_estado     <> "E"
	  AND n33_compania    = n32_compania
	  AND n33_cod_liqrol  = n32_cod_liqrol
	  AND n33_fecha_ini   = n32_fecha_ini
	  AND n33_fecha_fin   = n32_fecha_fin
	  AND n33_cod_trab    = n32_cod_trab
	  AND n33_cod_rubro  IN (SELECT n08_rubro_base
				FROM rolt008
				WHERE n08_cod_rubro  =
					(SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident = "AP")
				  AND n08_rubro_base IN
					(SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident IN ("VT", "VE",
							"VM", "VV", "SX", "SY")))
	  AND n33_valor       > 0
RETURN sueldo_parc

END FUNCTION



REPORT report_empleados_iess(r_rep)
DEFINE r_rep		RECORD
				cod_trab	LIKE rolt030.n30_cod_trab,
				cedula		LIKE rolt030.n30_num_doc_id,
				empleado	LIKE rolt030.n30_nombres,
				dias_trab	LIKE rolt032.n32_dias_trab,
				fecha_nov	DATE,
				codigo_nov	LIKE rolt022.n22_tipo_arch,
				sueldo		LIKE rolt032.n32_sueldo,
				valor_ext	LIKE rolt027.n27_valor_ext,
				valor_rol	DECIMAL(12,2),
				ap_iess_per	DECIMAL(12,2),
				ap_iess_pat	DECIMAL(12,2),
				ap_iess		DECIMAL(12,2)
			END RECORD
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_neg;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 007, r_g01.g01_razonsocial,
  	      COLUMN 128, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 053, "PLANILLA APORTES AL I.E.S.S.",
	      COLUMN 125, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 045, "** PERIODO PLANILLA: ",
		rm_n32.n32_fecha_ini USING "dd-mm-yyyy", ' - ',
		rm_n32.n32_fecha_fin USING "dd-mm-yyyy"
	IF incluir_ext = 'S' THEN
		PRINT COLUMN 050, "** INCLUIDO LAS DIFERENCIAS **"
	ELSE
		PRINT COLUMN 050, "** NO INCLUIDA LAS DIFERENCIAS **"
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 009, "CEDULA",
	      COLUMN 023, "E M P L E A D O S",
	      COLUMN 047, " DT",
	      COLUMN 051, "FECHA NOV.",
	      COLUMN 062, "CDN",
	      COLUMN 066, "SUELDO MES",
	      COLUMN 077, "VALOR EXT.",
	      COLUMN 088, "TOTAL GANADO",
	      COLUMN 101, "AP.  9.35%",
	      COLUMN 112, "AP. 11.15%",
	      COLUMN 123, "APOR. IESS"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------";
	print ASCII escape;
	print ASCII des_neg

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, r_rep.cod_trab		USING "<<&&&",
	      COLUMN 007, r_rep.cedula			CLIPPED,
	      COLUMN 018, r_rep.empleado[1, 28]		CLIPPED,
	      COLUMN 047, r_rep.dias_trab		USING "#&&",
	      COLUMN 051, r_rep.fecha_nov		USING "dd-mm-yyyy",
	      COLUMN 062, r_rep.codigo_nov		CLIPPED,
	      COLUMN 066, r_rep.sueldo			USING "###,##&.##",
	      COLUMN 077, r_rep.valor_ext		USING "###,##&.##",
	      COLUMN 088, r_rep.valor_rol		USING "#,###,##&.##",
	      COLUMN 101, r_rep.ap_iess_per		USING "###,##&.##",
	      COLUMN 112, r_rep.ap_iess_pat		USING "###,##&.##",
	      COLUMN 123, r_rep.ap_iess			USING "###,##&.##"
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 068, "----------",
	      COLUMN 079, "----------",
	      COLUMN 090, "------------",
	      COLUMN 103, "----------",
	      COLUMN 114, "----------",
	      COLUMN 125, "----------"
	PRINT COLUMN 001, "No. DE EMPLEADOS: ", tot_emp USING "<<<&",
	      COLUMN 053, "TOTALES ==>  ",
	      COLUMN 066, SUM(r_rep.sueldo)		USING "###,##&.##",
	      COLUMN 077, SUM(r_rep.valor_ext)		USING "###,##&.##",
	      COLUMN 088, SUM(r_rep.valor_rol)		USING "#,###,##&.##",
	      COLUMN 101, SUM(r_rep.ap_iess_per)	USING "###,##&.##",
	      COLUMN 112, SUM(r_rep.ap_iess_pat)	USING "###,##&.##",
	      COLUMN 123, SUM(r_rep.ap_iess)		USING "###,##&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII desact_comp

END REPORT
