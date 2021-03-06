--------------------------------------------------------------------------------
-- Titulo           : rolp206.4gl - Generaci�n novedades procesos decimos
-- Elaboracion      : 21-ago-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp206 base modulo compania [cod_trab] [flag] 
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_proceso	LIKE rolt003.n03_proceso
DEFINE rm_n00		RECORD LIKE rolt000.*  
DEFINE rm_n03		RECORD LIKE rolt003.*
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
CALL startlog('../logs/rolp206.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 5 THEN   -- Validar # par�metros correcto
	CALL fgl_winmessage(vg_producto, 'N�mero de par�metros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp206'
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
OPEN WINDOW w_206 AT 3,2 WITH 9 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_206 FROM '../forms/rolf206_1'
DISPLAY FORM f_206
LET vm_proceso = 'DT'
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
		'No existe configuraci�n general para este m�dulo.',
		'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_proceso_roles(vm_proceso) RETURNING rm_n03.*
IF rm_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('Proceso no esta configurado.', 'stop')
	EXIT PROGRAM
END IF 

INITIALIZE r_n05.* TO NULL
SELECT * INTO r_n05.* FROM rolt005 
	WHERE n05_compania = vg_codcia 
          AND n05_activo   = 'S' 
IF (num_args() <> 5 AND r_n05.n05_proceso <> vm_proceso) OR 
   (num_args() =  5 AND r_n05.n05_proceso <> 'AF') THEN
	CALL fl_mostrar_mensaje('Est� activo el proceso: ' || 
				 r_n05.n05_proceso, 'stop')
	EXIT PROGRAM
END IF
INITIALIZE r_n05.* TO NULL
SELECT * INTO r_n05.* FROM rolt005 WHERE n05_compania = vg_codcia 
	 AND  n05_proceso  = vm_proceso
         --                            AND n05_activo   = 'S' 

INITIALIZE rm_par.* TO NULL
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe configuraci�n para esta compa��a.',
		'stop')
	EXIT PROGRAM
END IF
IF r_n01.n01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto,
		'Compa��a no est� activa.', 'stop')
	EXIT PROGRAM
END IF
LET rm_par.n36_ano_proceso = r_n01.n01_ano_proceso
LET rm_par.n36_mes_proceso = r_n01.n01_mes_proceso
LET rm_par.n_mes           = 
	fl_justifica_titulo('I', 
		fl_retorna_nombre_mes(rm_par.n36_mes_proceso), 12)

LET fecha_proceso = MDY(rm_n03.n03_mes_ini, rm_n03.n03_dia_ini, 
                        r_n01.n01_ano_proceso)
IF fecha_proceso > MDY(r_n01.n01_mes_proceso, day(current), r_n01.n01_ano_proceso) THEN
	IF r_n05.n05_proceso <> 'AF' THEN
		CALL fl_mostrar_mensaje('Este proceso debe realizarse despues del ' || 
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
	LET mensaje = 'El d�cimo tercero del periodo: ', 
		       rm_par.n36_fecha_ini USING 'dd-mm-yyyy', ' - ',
		       rm_par.n36_fecha_fin USING 'dd-mm-yyyy',
                     ' ya fue procesado.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	RETURN
END IF 


IF r_n05.n05_proceso IS NOT NULL THEN
	IF r_n05.n05_proceso = vm_proceso AND r_n05.n05_activo = 'S' THEN
		CALL fl_hacer_pregunta('Desea regenerar las novedades ya existentes para este periodo?. Se perderan los datos ya generados.', 'No') RETURNING resp
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

DEFINE total_ganado	LIKE rolt036.n36_ganado_real

DEFINE estado		CHAR(1)

LET estado = 'A'
INITIALIZE cod_trab TO NULL
IF num_args() = 5 AND arg_val(5) = 'F' THEN
	LET estado   = 'F'
	LET cod_trab = arg_val(4)
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
	SELECT * FROM rolt032
		WHERE n32_compania   = vg_codcia
		  AND n32_fecha_ini >= rm_par.n36_fecha_ini
		  AND n32_fecha_fin <= rm_par.n36_fecha_fin 
		  AND n32_cod_trab   = r_n30.n30_cod_trab
		  AND n32_estado     IN ('C', 'F')
		INTO TEMP tmp_cabecera

	SELECT NVL(SUM(n32_tot_gan), 0) INTO total_ganado FROM tmp_cabecera

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
	
	INITIALIZE r_n36.*, r_n37.* TO NULL

	LET r_n36.n36_compania  = vg_codcia
	LET r_n36.n36_proceso   = vm_proceso
	LET r_n36.n36_fecha_ini = rm_par.n36_fecha_ini
	LET r_n36.n36_fecha_fin = rm_par.n36_fecha_fin
	LET r_n36.n36_cod_trab  = r_n30.n30_cod_trab
	LET r_n36.n36_estado    = 'A'
	IF cod_trab IS NOT NULL AND arg_val(5) = 'F' THEN
		LET r_n36.n36_estado = 'F'
	END IF
	LET r_n36.n36_cod_depto = r_n30.n30_cod_depto
	LET r_n36.n36_ano_proceso = rm_par.n36_ano_proceso 
	LET r_n36.n36_mes_proceso = rm_par.n36_mes_proceso 
	LET r_n36.n36_fecha_ing   = r_n30.n30_fecha_ing
	LET r_n36.n36_ganado_real = 
		fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
					   total_ganado)
	LET r_n36.n36_ganado_per  = 
		fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
					   total_ganado)
	LET r_n36.n36_valor_bruto = 
		fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
					   total_ganado / rm_n03.n03_valor)

	SELECT NVL(SUM(saldo), 0) INTO dsctos FROM tmp_desctos
	LET r_n36.n36_descuentos  = 
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
	DROP TABLE tmp_cabecera
END FOREACH

END FUNCTION
