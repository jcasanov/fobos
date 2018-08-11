DATABASE aceros



DEFINE codcia		LIKE gent001.g01_compania
DEFINE vm_anio		LIKE rolt080.n80_ano
DEFINE vm_mes		LIKE rolt080.n80_mes
DEFINE vm_cod_liqrol	LIKE rolt032.n32_cod_liqrol
DEFINE base		CHAR(20)



MAIN

	IF num_args() <> 4 THEN
		DISPLAY 'Numeros Parametros Incorrectos. Falta la BASE AÑO MES y COD_LIQROL a Arreglar.'
		EXIT PROGRAM
	END IF
	LET base          = arg_val(1)
	LET codcia        = 1
	LET vm_anio       = arg_val(2)
	LET vm_mes        = arg_val(3)
	LET vm_cod_liqrol = arg_val(4)
	CALL validar_parametros()
	CALL activar_base()
	BEGIN WORK
		CALL ejecuta_proceso()
	COMMIT WORK
	DISPLAY 'Reproceso Fondo de Censatía Terminado OK.'

END MAIN



FUNCTION validar_parametros()

IF vm_anio > YEAR(TODAY) THEN
	DISPLAY 'El año no puede ser mayor que el año vigente.'
	EXIT PROGRAM
END IF
IF vm_mes < 1 OR vm_mes > 12 THEN
	DISPLAY 'El mes debe estar entre 1 a 12.'
	EXIT PROGRAM
END IF
IF vm_anio = YEAR(TODAY) THEN
	IF vm_mes > MONTH(TODAY) THEN
		DISPLAY 'El mes no puede ser mayor que el mes vigente.'
		EXIT PROGRAM
	END IF
END IF
IF vm_cod_liqrol <> 'Q1' AND vm_cod_liqrol <> 'Q2' THEN
	DISPLAY 'El codigo de rol debe ser Q1 o Q2.'
	EXIT PROGRAM
END IF

END FUNCTION



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



FUNCTION ejecuta_proceso()
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n33		RECORD LIKE rolt033.*
DEFINE r_n80		RECORD LIKE rolt080.*
DEFINE r_n80_ant	RECORD LIKE rolt080.*
DEFINE r_n80_sig	RECORD LIKE rolt080.*
DEFINE cod_liqrol	LIKE rolt032.n32_cod_liqrol
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE anio		LIKE rolt080.n80_ano
DEFINE mes		LIKE rolt080.n80_mes
DEFINE aporte_patr	LIKE rolt080.n80_sac_patr
DEFINE query		CHAR(800)
DEFINE i		SMALLINT

INITIALIZE r_n01.* TO NULL
SELECT * INTO r_n01.* FROM rolt001 WHERE n01_compania = codcia
IF r_n01.n01_compania IS NULL THEN
	ROLLBACK WORK
	DISPLAY 'No existe registro de configuraciones de roles para esta cia.'
	EXIT PROGRAM
END IF
DISPLAY 'Iniciando Reproceso Fondo de Censatía. Por favor espere ...'
DISPLAY ' '
DECLARE q_n80 CURSOR FOR
	SELECT * FROM rolt080
		WHERE n80_compania = codcia
		  AND n80_ano      = vm_anio
		  AND n80_mes      = vm_mes
CASE vm_cod_liqrol
	WHEN 'Q1'
		LET fecha_ini  = MDY(vm_mes, 01, vm_anio)
		LET fecha_fin  = MDY(vm_mes, 15, vm_anio)
		LET cod_liqrol = 'Q2'
	WHEN 'Q2'
		LET fecha_ini  = MDY(vm_mes, 16, vm_anio)
		LET mes        = vm_mes + 1
		LET anio       = vm_anio
		IF mes > 12 THEN
			LET mes  = 1
			LET anio = anio + 1
		END IF
		LET fecha_fin  = MDY(mes, 01, anio) - 1 UNITS DAY
		LET cod_liqrol = 'Q1'
END CASE
FOREACH q_n80 INTO r_n80.*
	INITIALIZE r_n32.* TO NULL
	SELECT * INTO r_n32.* FROM rolt032
		WHERE n32_compania   = codcia
		  AND n32_cod_liqrol = vm_cod_liqrol
		  AND n32_fecha_ini  = fecha_ini
		  AND n32_fecha_fin  = fecha_fin
		  AND n32_cod_trab   = r_n80.n80_cod_trab
	IF r_n32.n32_compania IS NULL THEN
		CONTINUE FOREACH
	END IF
	INITIALIZE r_n33.* TO NULL
	SELECT * INTO r_n33.* FROM rolt033
		WHERE n33_compania   = r_n32.n32_compania
		  AND n33_cod_liqrol = r_n32.n32_cod_liqrol
		  AND n33_fecha_ini  = r_n32.n32_fecha_ini
		  AND n33_fecha_fin  = r_n32.n32_fecha_fin
		  AND n33_cod_trab   = r_n32.n32_cod_trab
		  AND n33_cod_rubro  = (SELECT n06_cod_rubro FROM rolt006
						WHERE n06_estado     = 'A'
						  AND n06_det_tot    = 'DE'
						  AND n06_flag_ident = 'FC') 
	IF r_n33.n33_compania IS NULL THEN
		CONTINUE FOREACH
	END IF
	SELECT * INTO r_n30.* FROM rolt030
		WHERE n30_compania = r_n33.n33_compania
		  AND n30_cod_trab = r_n33.n33_cod_trab
	DISPLAY 'Actualizando FC del Empleado ', r_n30.n30_nombres CLIPPED
	LET aporte_patr = (r_n33.n33_valor * (r_n01.n01_porc_aporte / 100)) /
				factor_aporte_trab()
	LET query = "UPDATE rolt080 SET ",
			" n80_", DOWNSHIFT(r_n32.n32_cod_liqrol), "_trab = ",
						r_n33.n33_valor, ", ",
			" n80_", DOWNSHIFT(r_n32.n32_cod_liqrol), "_patr = ",
						aporte_patr, ", ",
			" n80_sac_trab = n80_san_trab + ", r_n33.n33_valor," +",
				" n80_", DOWNSHIFT(cod_liqrol), "_trab, ",
			" n80_sac_patr = n80_san_patr + ", aporte_patr, " + ",
				" n80_", DOWNSHIFT(cod_liqrol), "_patr ",
			" WHERE n80_compania = ", codcia,
			"   AND n80_ano      = ", YEAR(r_n32.n32_fecha_ini),
			"   AND n80_mes      = ", MONTH(r_n32.n32_fecha_ini),
			"   AND n80_cod_trab = ", r_n32.n32_cod_trab
	PREPARE up_n80 FROM query
	EXECUTE up_n80
	DISPLAY '    Actualizado año ', vm_anio USING "&&&&", ' el mes ',
		vm_mes USING "&&"
	LET i = i + 1
	DECLARE q_n80_sig CURSOR FOR
		SELECT * FROM rolt080
			WHERE n80_compania = codcia
			  AND EXTEND(MDY(n80_mes, 01, n80_ano), YEAR TO MONTH) >
				EXTEND(MDY(vm_mes, 01, vm_anio), YEAR TO MONTH)
			  AND n80_cod_trab = r_n80.n80_cod_trab
	FOREACH q_n80_sig INTO r_n80_sig.*
		LET anio = r_n80_sig.n80_ano
		LET mes  = r_n80_sig.n80_mes - 1
		IF mes < 1 THEN
			LET anio = anio - 1
			LET mes  = 12
		END IF
		INITIALIZE r_n80_ant.* TO NULL
		SELECT * INTO r_n80_ant.* FROM rolt080
			WHERE n80_compania = codcia
			  AND n80_ano      = anio
			  AND n80_mes      = mes
			  AND n80_cod_trab = r_n80_sig.n80_cod_trab
		IF r_n80_ant.n80_compania IS NULL THEN
			CONTINUE FOREACH
		END IF
		UPDATE rolt080
			SET n80_san_trab = r_n80_ant.n80_sac_trab,
			    n80_san_patr = r_n80_ant.n80_sac_patr
			WHERE n80_compania = r_n80_sig.n80_compania
			  AND n80_ano      = r_n80_sig.n80_ano
			  AND n80_mes      = r_n80_sig.n80_mes
			  AND n80_cod_trab = r_n80_sig.n80_cod_trab
		UPDATE rolt080
			SET n80_sac_trab = n80_san_trab + n80_q1_trab +
						n80_q2_trab,
			    n80_sac_patr = n80_san_patr + n80_q1_patr +
						n80_q2_patr
			WHERE n80_compania = r_n80_sig.n80_compania
			  AND n80_ano      = r_n80_sig.n80_ano
			  AND n80_mes      = r_n80_sig.n80_mes
			  AND n80_cod_trab = r_n80_sig.n80_cod_trab
		DISPLAY '    Actualizado año ', r_n80_sig.n80_ano USING "&&&&",
			' el mes ', r_n80_sig.n80_mes USING "&&"
	END FOREACH
	DISPLAY ' '
END FOREACH
DISPLAY 'Se actualizaron un total de ', i USING "<<<&", ' empleados.'
DISPLAY ' '

END FUNCTION



FUNCTION factor_aporte_trab()
DEFINE r_n07		RECORD LIKE rolt007.*

INITIALIZE r_n07.* TO NULL
SELECT rolt007.* INTO r_n07.* FROM rolt006, rolt007
	WHERE n06_flag_ident = 'FC'
	  AND n06_det_tot    = 'DE'
	  AND n06_estado     = 'A'
	  AND n07_cod_rubro  = n06_cod_rubro

RETURN r_n07.n07_factor

END FUNCTION
