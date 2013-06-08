--------------------------------------------------------------------------------
-- Titulo           : rolp220.4gl - Generación proceso decimo cuarto
-- Elaboracion      : 01-sep-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp220 base modulo compania [cod_trab] [flag] 
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_proceso	LIKE rolt003.n03_proceso
DEFINE rm_n00		RECORD LIKE rolt000.*  
DEFINE rm_n03		RECORD LIKE rolt003.*
DEFINE rm_n90		RECORD LIKE rolt090.*
DEFINE rm_par		RECORD 
				n36_fecha_ini	LIKE rolt032.n32_fecha_ini,
				n36_fecha_fin	LIKE rolt032.n32_fecha_fin,
				n36_ano_proceso	LIKE rolt032.n32_ano_proceso,
				n36_mes_proceso	LIKE rolt032.n32_mes_proceso,
				n_mes		VARCHAR(12)
			END RECORD
DEFINE vm_num_nov	INTEGER



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp220.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 5 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp220'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_220 AT 3,2 WITH 9 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_220 FROM '../forms/rolf220_1'
DISPLAY FORM f_220
LET vm_proceso = 'DC'
CALL control_generar()

END FUNCTION



FUNCTION control_generar()
DEFINE resp		VARCHAR(6)
DEFINE r_n01		RECORD LIKE rolt001.*  
DEFINE r_n05		RECORD LIKE rolt005.*  
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n36		RECORD LIKE rolt036.*
DEFINE mensaje		VARCHAR(250)
DEFINE fecha_compania	LIKE rolt036.n36_fecha_ini
DEFINE fecha_proceso	LIKE rolt036.n36_fecha_ini
DEFINE comando		CHAR(100)
DEFINE anhos		SMALLINT
DEFINE meses		SMALLINT

CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe configuración general para este módulo.',
		'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_proceso_roles(vm_proceso) RETURNING rm_n03.*
IF rm_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('Proceso no está configurado.', 'stop')
	EXIT PROGRAM
END IF 

INITIALIZE r_n05.* TO NULL
SELECT * INTO r_n05.* FROM rolt005 
	WHERE n05_compania = vg_codcia 
          AND n05_activo   = 'S' 
IF (num_args() <> 5 AND r_n05.n05_proceso <> vm_proceso) OR 
   (num_args() =  5 AND r_n05.n05_proceso <> 'AF') THEN
	CALL fl_mostrar_mensaje('Está activo el proceso: ' || 
				 r_n05.n05_proceso, 'stop')
	EXIT PROGRAM
END IF
INITIALIZE r_n05.* TO NULL
SELECT * INTO r_n05.* FROM rolt005 
	WHERE n05_compania = vg_codcia 
	 AND  n05_proceso  = vm_proceso
		
                                     --AND n05_activo   = 'S' 

INITIALIZE rm_par.* TO NULL
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe configuración para esta compañía.',
		'stop')
	EXIT PROGRAM
END IF
IF r_n01.n01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto,
		'Compañía no está activa.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_conf_adic_rol(vg_codcia) RETURNING rm_n90.*
IF rm_n90.n90_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuracion adicional de nomina en la tabla rolt090.', 'stop')
	EXIT PROGRAM
END IF
LET rm_par.n36_ano_proceso = r_n01.n01_ano_proceso
LET rm_par.n36_mes_proceso = r_n01.n01_mes_proceso
LET rm_par.n_mes           = 
	fl_justifica_titulo('I', 
		fl_retorna_nombre_mes(rm_par.n36_mes_proceso), 12)

LET fecha_proceso = MDY(rm_n03.n03_mes_ini, rm_n03.n03_dia_ini, 
                        r_n01.n01_ano_proceso)
IF fecha_proceso > MDY(r_n01.n01_mes_proceso, DAY(current), r_n01.n01_ano_proceso) THEN
	IF r_n05.n05_proceso <> 'AF' THEN
		CALL fl_mostrar_mensaje('Este proceso debe realizarse después del ' || 
	        	rm_n03.n03_dia_ini || ' de ' || 
			fl_justifica_titulo('I', fl_retorna_nombre_mes(
				rm_n03.n03_mes_ini), 12) CLIPPED ||
			' del ' || r_n01.n01_ano_proceso || '.', 'stop')
		EXIT PROGRAM
	END IF	
END IF

CASE r_n05.n05_proceso
	WHEN vm_proceso 
		IF rm_n03.n03_mes_fin = 1 THEN
			LET meses = 12
			LET anhos = rm_par.n36_ano_proceso - 1 
		ELSE
			LET meses = rm_n03.n03_mes_fin - 1
			LET anhos = rm_par.n36_ano_proceso 
		END IF
	WHEN 'AF'
		DECLARE q_ultliq CURSOR FOR 
			SELECT * FROM rolt036
				WHERE n36_compania = vg_codcia
				  AND n36_proceso  = vm_proceso
				  AND n36_estado   = 'P'
				ORDER BY n36_fecha_fin DESC

		INITIALIZE r_n36.* TO NULL
		OPEN  q_ultliq
		FETCH q_ultliq INTO r_n36.*
		CLOSE q_ultliq
		FREE  q_ultliq

		IF r_n36.n36_compania IS NULL THEN
			IF rm_n03.n03_mes_fin = 1 THEN
				LET meses = 12
				LET anhos = rm_par.n36_ano_proceso - 1 
			ELSE
				LET meses = rm_n03.n03_mes_fin - 1
				LET anhos = rm_par.n36_ano_proceso 
			END IF
		ELSE
			LET anhos = r_n36.n36_ano_proceso + 1
			LET meses = r_n36.n36_mes_proceso + 1
		END IF
END CASE
CALL fl_retorna_rango_fechas_proceso(vg_codcia, vm_proceso, anhos, meses)
	RETURNING rm_par.n36_fecha_ini, rm_par.n36_fecha_fin

DISPLAY BY NAME rm_par.*
IF r_n05.n05_activo = 'N' AND r_n05.n05_fecfin_act = rm_par.n36_fecha_fin THEN
	LET mensaje = 'El décimo cuarto del periodo: ', 
		       rm_par.n36_fecha_ini USING 'dd-mm-yyyy', ' - ',
		       rm_par.n36_fecha_fin USING 'dd-mm-yyyy',
                     ' ya fue procesado.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	RETURN
END IF 

IF r_n05.n05_proceso IS NOT NULL THEN
	IF r_n05.n05_proceso = vm_proceso AND r_n05.n05_activo = 'S' THEN
		CALL fl_hacer_pregunta('Desea regenerar las novedades ya existentes para este periodo?. Se perderán los datos ya generados.', 'No') RETURNING resp
		IF resp = 'No' THEN
			EXIT PROGRAM
		END IF 	
	ELSE	
		IF r_n05.n05_proceso <> 'AF' AND r_n05.n05_activo = 'S' THEN
			CALL fl_mostrar_mensaje('Ya existe otro proceso de roles activo.', 
	           	                        'stop')
			EXIT PROGRAM
		END IF
	END IF
END IF

IF num_args() <> 5 THEN
	CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
	IF resp <> 'Yes' THEN
		EXIT PROGRAM	
	END IF
END IF

BEGIN WORK
LET vm_num_nov = 0
MESSAGE 'Se estan calculando los valores del decimo. Por favor, espere...' 
CALL genera_novedades()
IF vm_num_nov > 0 AND num_args() <> 5 THEN
	INITIALIZE r_n05.* TO NULL
	SELECT * INTO r_n05.* FROM rolt005 WHERE n05_compania = vg_codcia
			      AND n05_proceso  = vm_proceso

	IF r_n05.n05_compania IS NULL THEN
		LET r_n05.n05_compania   = vg_codcia
		LET r_n05.n05_proceso    = vm_proceso
		LET r_n05.n05_activo     = 'S'
		LET r_n05.n05_fecini_act = rm_par.n36_fecha_ini
		LET r_n05.n05_fecfin_act = rm_par.n36_fecha_fin
		LET r_n05.n05_fec_ultcie = rm_par.n36_fecha_fin
		LET r_n05.n05_fec_cierre = rm_par.n36_fecha_fin
		LET r_n05.n05_usuario    = vg_usuario 
		LET r_n05.n05_fecing     = CURRENT 

		INSERT INTO rolt005 VALUES (r_n05.*)
	ELSE
		UPDATE rolt005 SET
		        n05_activo     = 'S',
		        n05_fecini_act = rm_par.n36_fecha_ini,
		        n05_fecfin_act = rm_par.n36_fecha_fin,
		        n05_fec_ultcie = rm_par.n36_fecha_fin,
		        n05_fec_cierre = rm_par.n36_fecha_fin,
		        n05_usuario    = vg_usuario,
		        n05_fecing     = CURRENT 
	        WHERE n05_compania = vg_codcia
		  AND n05_proceso  = vm_proceso
	END IF
END IF
MESSAGE '' 
COMMIT WORK
LET mensaje = 'Novedades de roles generadas: ', vm_num_nov USING '##&'
IF num_args() <> 5 THEN
	CALL fl_mostrar_mensaje(mensaje, 'info')
END IF

END FUNCTION



FUNCTION genera_novedades()
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n36		RECORD LIKE rolt036.*
DEFINE r_n37		RECORD LIKE rolt037.*

DEFINE op		LIKE rolt004.n04_operacion
DEFINE rubro		LIKE rolt033.n33_cod_rubro
DEFINE valor 		LIKE rolt036.n36_ganado_real
DEFINE dsctos 		LIKE rolt036.n36_descuentos

DEFINE query		CHAR(3000)
DEFINE cod_trab		LIKE rolt036.n36_cod_trab

DEFINE fecha_ini	LIKE rolt036.n36_fecha_ini
DEFINE fecha_fin	LIKE rolt036.n36_fecha_fin
DEFINE total_ganado	LIKE rolt036.n36_ganado_real
DEFINE anhos_trab	SMALLINT
DEFINE meses_trab	SMALLINT
DEFINE dias_trab	SMALLINT

DEFINE estado		CHAR(1)

DEFINE dias_a, num_m	SMALLINT
DEFINE ult_dia		SMALLINT
DEFINE factor		DECIMAL(18, 10)

LET estado = 'A'
INITIALIZE cod_trab TO NULL
IF num_args() = 5 AND arg_val(5) = 'F' THEN
	LET cod_trab = arg_val(4)
	LET estado = 'F'
END IF

WHENEVER ERROR CONTINUE
LET query = 'DELETE FROM rolt037 ', 
      		' WHERE n37_compania  =  ', vg_codcia,
      		'   AND n37_proceso   = "', vm_proceso, '"',
      		'   AND n37_fecha_ini = DATE("', rm_par.n36_fecha_ini, '")',
      		'   AND n37_fecha_fin = DATE("', rm_par.n36_fecha_fin, '")'
IF cod_trab IS NOT NULL THEN
	LET query = query, ' AND n37_cod_trab = ', cod_trab 
END IF
PREPARE stmnt1 FROM query
EXECUTE stmnt1
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo borrar detalle de '
				|| 'liquidacion de decimos (rolt037). '
				|| 'Intente mas tarde.', 'stop')
	EXIT PROGRAM
END IF

LET query = 'DELETE FROM rolt036 ',
      		' WHERE n36_compania  =  ', vg_codcia,
      		'   AND n36_proceso   = "', vm_proceso, '"',
      		'   AND n36_fecha_ini = DATE("', rm_par.n36_fecha_ini, '")',
      		'   AND n36_fecha_fin = DATE("', rm_par.n36_fecha_fin, '")',
		'   AND n36_estado    = "', estado, '"'
IF cod_trab IS NOT NULL THEN
	LET query = query, ' AND n36_cod_trab = ', cod_trab 
END IF
PREPARE stmnt2 FROM query
EXECUTE stmnt2
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo borrar cabecera de '
				|| 'liquidacion de decimos (rolt036). '
				|| 'Intente mas tarde.', 'stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP

IF cod_trab IS NULL THEN
	LET query = 'SELECT * FROM rolt030 ',
			' WHERE n30_compania   = ', vg_codcia,
			'   AND n30_estado     = "A"',
			'   AND n30_tipo_trab  = "N"',
			'   AND n30_fecha_ing <= DATE("', 
				rm_par.n36_fecha_fin, '")',
			'   AND n30_fecha_sal IS NULL ',
                  	'   AND (n30_fecha_reing IS NULL ',
                        '    OR n30_fecha_reing <= DATE("',
					rm_par.n36_fecha_fin, '"))',
			'   AND n30_tipo_contr = "F"',
		    ' UNION ',
		    'SELECT * FROM rolt030 ',
			' WHERE n30_compania     = ', vg_codcia,
			'   AND n30_estado       = "A"',
			'   AND n30_tipo_trab    = "N"',
			'   AND n30_fecha_reing <= DATE("', 
				rm_par.n36_fecha_fin, '")',
			'   AND n30_fecha_sal IS NOT NULL ',
			'   AND n30_fecha_reing > n30_fecha_sal ',
			'   AND n30_tipo_contr = "F" '
ELSE
	LET query = 'SELECT * FROM rolt030 ',
			' WHERE n30_compania  = ', vg_codcia,
			'   AND n30_cod_trab  = ', cod_trab,
			'   AND n30_tipo_trab = "N"'
END IF

PREPARE cons_trab FROM query
DECLARE q_trab CURSOR FOR cons_trab

FOREACH q_trab INTO r_n30.*
	MESSAGE 'Procesando trabajador: ', r_n30.n30_nombres CLIPPED, '...'
	LET query = 'SELECT ', vg_codcia, ' AS compania, "', vm_proceso,
			'" AS proceso, MDY(', MONTH(rm_par.n36_fecha_ini), ', ',
			DAY(rm_par.n36_fecha_ini), ', ',
			YEAR(rm_par.n36_fecha_ini), ') AS fecha_ini,',
			' MDY(', MONTH(rm_par.n36_fecha_fin), ', ',
			DAY(rm_par.n36_fecha_fin), ', ',
			YEAR(rm_par.n36_fecha_fin), ') AS fecha_fin,',
			r_n30.n30_cod_trab, ' AS cod_trab, n45_cod_rubro',
			' AS cod_rubd, n45_num_prest AS num_pre, n06_orden, ',
			'n06_det_tot, n06_imprime_0, SUM(n46_saldo) AS saldo ',
		' FROM rolt045, rolt046, rolt006 ',
		' WHERE n45_compania   = ', vg_codcia,
		'   AND n45_cod_trab   = ', r_n30.n30_cod_trab, 
		'   AND n45_estado     IN ("A", "R", "P") ',
		'   AND n46_compania   = n45_compania ',
		'   AND n46_num_prest  = n45_num_prest ',
		'   AND n46_cod_liqrol = "', vm_proceso, '"',	
		'   AND n46_fecha_ini  = MDY(', MONTH(rm_par.n36_fecha_ini),
		                         ', ', DAY(rm_par.n36_fecha_ini),
		                         ', ', YEAR(rm_par.n36_fecha_ini), ') ',
		'   AND n46_fecha_fin  = MDY(', MONTH(rm_par.n36_fecha_fin),
		                         ', ', DAY(rm_par.n36_fecha_fin),
		                         ', ', YEAR(rm_par.n36_fecha_fin), ') ',
		'   AND n06_cod_rubro  = n45_cod_rubro ',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ',
		' HAVING SUM(n46_saldo) > 0 ',
		' UNION ',
		' SELECT ', vg_codcia, ' AS compania, "', vm_proceso,
			'" AS proceso, MDY(', MONTH(rm_par.n36_fecha_ini), ', ',
			DAY(rm_par.n36_fecha_ini), ', ',
			YEAR(rm_par.n36_fecha_ini), ') AS fecha_ini,',
			' MDY(', MONTH(rm_par.n36_fecha_fin), ', ',
			DAY(rm_par.n36_fecha_fin), ', ',
			YEAR(rm_par.n36_fecha_fin), ') AS fecha_fin,',
			r_n30.n30_cod_trab, ' AS cod_trab, n10_cod_rubro',
			' AS cod_rubd, 0 AS num_pre, n06_orden, ',
			'n06_det_tot, n06_imprime_0, SUM(n10_valor) AS saldo ',
		' FROM rolt010, rolt006 ',
		' WHERE n10_compania   = ', vg_codcia,
		'   AND n10_cod_liqrol = "', vm_proceso, '"',
		'   AND n10_cod_trab   = ', r_n30.n30_cod_trab, 
		'   AND n06_cod_rubro  = n10_cod_rubro ',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ',
		' INTO TEMP tmp_desctos  '	

	PREPARE stmnt FROM query
	EXECUTE stmnt

-- SE CALCULA EL TOTAL DE DIAS QUE HA TRABAJADO EN EL PERIODO
	LET total_ganado = rm_n03.n03_valor
	CALL retorna_fechas_calculo_trab(rm_par.n36_fecha_ini,
					 rm_par.n36_fecha_fin,
					 r_n30.n30_cod_trab)
			RETURNING fecha_ini, fecha_fin

	INITIALIZE r_n36.*, r_n37.* TO NULL

	LET r_n36.n36_compania  = vg_codcia
	LET r_n36.n36_proceso   = vm_proceso
	LET r_n36.n36_fecha_ini = rm_par.n36_fecha_ini
	LET r_n36.n36_fecha_fin = rm_par.n36_fecha_fin
	LET r_n36.n36_cod_trab  = r_n30.n30_cod_trab
	LET r_n36.n36_estado    = 'A'
	IF cod_trab IS NOT NULL AND arg_val(5) = 'F' THEN
		LET r_n36.n36_estado    = 'F'
	END IF
	LET r_n36.n36_cod_depto   = r_n30.n30_cod_depto
	LET r_n36.n36_ano_proceso = rm_par.n36_ano_proceso 
	LET r_n36.n36_mes_proceso = rm_par.n36_mes_proceso 
	LET r_n36.n36_fecha_ing   = r_n30.n30_fecha_ing
	LET r_n36.n36_ganado_real = 
		fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
				total_ganado)
	LET r_n36.n36_ganado_per  = 
		fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
				total_ganado)

	IF fecha_ini >= rm_par.n36_fecha_ini THEN
		CALL retorna_tiempo_entre_fechas(fecha_ini, fecha_fin, 'S')
			RETURNING anhos_trab, meses_trab, dias_trab
		IF anhos_trab IS NULL THEN
			EXIT PROGRAM
		END IF
		IF anhos_trab > 1 THEN
			CALL fl_mostrar_mensaje('Rango de fechas incorrecta.',
						'stop')
			EXIT PROGRAM
		END IF
		IF anhos_trab = 1 THEN
			LET r_n36.n36_valor_bruto = 
				fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
					total_ganado)    
		ELSE
			{-- FORMULA ORIGINAL
			LET r_n36.n36_valor_bruto = 
				fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
					((total_ganado / 12 * meses_trab) +
					 (total_ganado / rm_n90.n90_dias_anio
					* dias_trab)))
			--}
			{-- FORMULA CON NUMERO DE DIAS
			LET r_n36.n36_valor_bruto =
				fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
					((total_ganado / rm_n90.n90_dias_anio)
					* ((fecha_fin - fecha_ini) + 1)))
			--}
			-- FORMULA CON 360 DIAS
			IF ((fecha_fin - fecha_ini) + 1) < rm_n90.n90_dias_anio
			THEN
				LET num_m  = MONTH(fecha_fin)
				IF YEAR(fecha_ini) < YEAR(fecha_fin) THEN
					LET num_m  = num_m
					IF MONTH(fecha_ini) <> 12 THEN
						LET num_m  = num_m +
							(12 - MONTH(MDY(
							MONTH(fecha_ini), 01,
							YEAR(fecha_ini))
							+ 1 UNITS MONTH)) + 1
					END IF
				ELSE
					LET num_m  = (num_m -
						MONTH(MDY(
							MONTH(fecha_ini), 01,
							YEAR(fecha_ini))
							+ 1 UNITS MONTH)) + 1
				END IF
				LET dias_a = (num_m * rm_n00.n00_dias_mes)
				IF DAY(fecha_ini) > rm_n00.n00_dias_mes THEN
					LET dias_a = dias_a +
							rm_n00.n00_dias_mes
				ELSE
					LET ult_dia = DAY(MDY(MONTH(fecha_ini),
							01, YEAR(fecha_ini))
							+ 1 UNITS MONTH
							- 1 UNITS DAY)
					IF (ult_dia > rm_n00.n00_dias_mes) OR
					   (MONTH(fecha_ini) = 2)
					THEN
						LET ult_dia =rm_n00.n00_dias_mes
					END IF
					LET dias_a = dias_a +
						(ult_dia - DAY(fecha_ini)) + 1
				END IF
				LET factor = (total_ganado / 12
						/ rm_n00.n00_dias_mes)
				LET r_n36.n36_valor_bruto =
				fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
					(dias_a * factor))
--display r_n36.n36_cod_trab, ' ' , fecha_ini, ' ', fecha_fin, ' ', num_m, ' ', dias_a, ' ', factor, ' ', r_n36.n36_valor_bruto
--display ' '
			ELSE
				LET r_n36.n36_valor_bruto = 
				fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
					total_ganado)    
			END IF
			--
		END IF
	ELSE
		LET r_n36.n36_valor_bruto = 
			fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
				total_ganado)    
	END IF

	SELECT NVL(SUM(saldo), 0) INTO dsctos FROM tmp_desctos
	LET r_n36.n36_descuentos = 
		fl_retorna_precision_valor(r_n30.n30_mon_sueldo, dsctos)
	LET r_n36.n36_valor_neto  = r_n36.n36_valor_bruto - r_n36.n36_descuentos
	LET r_n36.n36_moneda      = r_n30.n30_mon_sueldo
	LET r_n36.n36_paridad     = 1
	LET r_n36.n36_tipo_pago   = r_n30.n30_tipo_pago
	LET r_n36.n36_bco_empresa = r_n30.n30_bco_empresa
	LET r_n36.n36_cta_empresa = r_n30.n30_cta_empresa
	LET r_n36.n36_cta_trabaj  = r_n30.n30_cta_trabaj
	LET r_n36.n36_usuario     = vg_usuario
	LET r_n36.n36_fecing      = CURRENT

	INSERT INTO rolt036 VALUES (r_n36.*)

	UPDATE tmp_desctos SET num_pre = NULL WHERE num_pre = 0

	INSERT INTO rolt037 SELECT * FROM tmp_desctos

	LET vm_num_nov = vm_num_nov + 1

	DROP TABLE tmp_desctos
END FOREACH

END FUNCTION



FUNCTION retorna_tiempo_entre_fechas(fecha_ini, fecha_fin, anho_comercial)
DEFINE fecha_ini		DATE
DEFINE fecha_fin		DATE
DEFINE anho_comercial		CHAR(1)

DEFINE anhos			SMALLINT
DEFINE meses			SMALLINT
DEFINE dias 			SMALLINT
DEFINE dias_mes			SMALLINT
DEFINE fecha			DATE

IF anho_comercial <> 'S' AND anho_comercial <> 'N' THEN
	CALL fl_mostrar_mensaje('Debe especificar si desea usar el mes comercial o no.', 'stop')
	RETURN NULL, NULL, NULL
END IF

IF fecha_ini > fecha_fin THEN
	CALL fl_mostrar_mensaje('Rango de fechas incorrecto.', 'stop')
	RETURN NULL, NULL, NULL
END IF

LET anhos = 0
LET meses = 0
LET dias  = 0

IF fecha_ini = fecha_fin THEN
	RETURN anhos, meses, dias
END IF

LET anhos = YEAR(fecha_fin)  - YEAR(fecha_ini) 
LET meses = MONTH(fecha_fin) - MONTH(fecha_ini)
IF meses < 0 THEN
	LET anhos = anhos - 1
	LET meses = meses + 12
END IF

LET dias_mes = 30 

IF anho_comercial = 'N' THEN
	LET fecha = MDY(MONTH(fecha_ini) + 1, 1, YEAR(fecha_ini))		
	LET fecha = fecha - 1
	LET dias_mes = DAY(fecha)
END IF
IF DAY(fecha_ini) > dias_mes THEN
	LET dias = 0
ELSE
	LET dias = dias_mes - DAY(fecha_ini)
END IF

IF anho_comercial = 'N' THEN
	LET fecha = MDY(MONTH(fecha_fin) + 1, 1, YEAR(fecha_fin))		
	LET fecha = fecha - 1
	LET dias_mes = DAY(fecha)
END IF
IF DAY(fecha_fin) < dias_mes THEN
	LET dias = dias + DAY(fecha_fin)
END IF
LET dias = dias + 1

IF dias >= dias_mes THEN
	LET dias  = dias  - dias_mes
	LET meses = meses + 1
	IF meses > 12 THEN
		LET meses = meses - 1
		LET anhos = anhos + 1
	END IF
	IF meses < 12 AND dias > 0 THEN
		LET meses = meses - 1
		IF meses = 0 THEN
			LET meses = 1
		END IF
	END IF
END IF

IF meses = 12 AND dias <> 0 THEN
	LET dias = 0
END IF

RETURN anhos, meses, dias

END FUNCTION



FUNCTION retorna_fechas_calculo_trab(fecha_ini_per, fecha_fin_per, cod_trab)
DEFINE fecha_ini_per		DATE
DEFINE fecha_fin_per		DATE
DEFINE cod_trab			SMALLINT

DEFINE fecha_ini_calc		DATE
DEFINE fecha_fin_calc		DATE

DEFINE r_n30		RECORD LIKE rolt030.*

	CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
	IF r_n30.n30_cod_trab IS NULL THEN
		CALL fl_mostrar_mensaje('No existe codigo de trabajador.', 
					'exclamation')
		RETURN NULL, NULL
	END IF

	IF r_n30.n30_fecha_reing IS NOT NULL THEN
		LET fecha_ini_calc = r_n30.n30_fecha_reing
	ELSE
		LET fecha_ini_calc = r_n30.n30_fecha_ing
	END IF
	IF r_n30.n30_fecha_sal IS NOT NULL THEN
		LET fecha_fin_calc = r_n30.n30_fecha_sal
		IF fecha_fin_calc <= r_n30.n30_fecha_reing THEN
			LET fecha_fin_calc = fecha_fin_per
		END IF
	ELSE
		LET fecha_fin_calc = fecha_fin_per
	END IF
	IF fecha_ini_calc < fecha_ini_per THEN
		LET fecha_ini_calc = fecha_ini_per
	END IF

	RETURN fecha_ini_calc, fecha_fin_calc
END FUNCTION

