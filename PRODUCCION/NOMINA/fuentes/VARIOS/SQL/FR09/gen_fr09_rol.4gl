DATABASE aceros


DEFINE base, serv	CHAR(40)
DEFINE codcia		LIKE rolt001.n01_compania



MAIN

	IF num_args() <> 3 THEN
		DISPLAY 'Parametros Incorrectos. Son: BASE SERVIDOR COMPANIA.'
		EXIT PROGRAM
	END IF
	LET base   = arg_val(1)
	LET serv   = arg_val(2)
	LET codcia = arg_val(3)
	CALL activar_base(base, serv)
	BEGIN WORK
		IF NOT reprocesar_fondo_reserva() THEN
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
	COMMIT WORK
	DISPLAY 'Proceso Terminado OK.'

END MAIN



FUNCTION activar_base(b, s)
DEFINE b, s		CHAR(20)
DEFINE base, base1	CHAR(20)
DEFINE r_g51		RECORD LIKE gent051.*

LET base  = b
LET base1 = base CLIPPED, '@', s
CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base1
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base1
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051 WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base, ' en la tabla gent051.'
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION reprocesar_fondo_reserva()
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE empleado		LIKE rolt030.n30_nombres
DEFINE fec_ing		LIKE rolt030.n30_fecha_ing
DEFINE fec_rei		LIKE rolt030.n30_fecha_reing
DEFINE fec_sal		LIKE rolt030.n30_fecha_sal
DEFINE fec_fin		LIKE rolt038.n38_fecha_fin
DEFINE valor		LIKE rolt033.n33_valor
DEFINE fec_rol		LIKE rolt032.n32_fecing
DEFINE i, resul		SMALLINT

DISPLAY 'Iniciando reproceso FR-2009 del ROL a la tabla rolt038. Espere...'
DECLARE q_n33 CURSOR WITH HOLD FOR
	SELECT n33_cod_trab, n30_nombres, n30_fecha_ing, n30_fecha_reing,
		n30_fecha_sal, MDY(MONTH(n33_fecha_fin), 01,
		YEAR(n33_fecha_fin)) - 1 UNITS DAY, n33_valor, n32_fecing
		FROM rolt033, rolt030, rolt032
		WHERE  n33_compania    = codcia
		  AND  n33_cod_liqrol IN ("Q1", "Q2")
		  AND  n33_det_tot     = "DI"
		  AND  n33_cant_valor  = 'V'
		  AND  n33_valor       > 0
		  AND n33_cod_rubro   = (SELECT n06_cod_rubro
						FROM rolt006
						WHERE n06_flag_ident = "FM")
		   --OR  n33_cod_rubro   = 35)
		  AND NOT EXISTS
			(SELECT 1 FROM rolt038
				WHERE n38_compania  = n33_compania
				  AND n38_cod_trab  = n33_cod_trab
				  AND EXTEND(n38_fecha_fin, YEAR TO MONTH) =
					EXTEND(n33_fecha_fin - 1 UNITS MONTH,
						YEAR TO MONTH)
				  AND n38_pago_iess = "N")
		  AND  n30_compania    = n33_compania
		  AND  n30_cod_trab    = n33_cod_trab
		  AND  n32_compania    = n33_compania
		  AND  n32_cod_liqrol  = n33_cod_liqrol
		  AND  n32_fecha_ini   = n33_fecha_ini
		  AND  n32_fecha_fin   = n33_fecha_fin
		  AND  n32_cod_trab    = n33_cod_trab
		ORDER BY 6, 2
LET i     = 0
LET resul = 0
DISPLAY '  Procesando Registros: '
FOREACH q_n33 INTO cod_trab, empleado, fec_ing, fec_rei, fec_sal, fec_fin,
			valor, fec_rol
	DISPLAY '    ', cod_trab USING "<<<&&&", ' ', empleado CLIPPED,
		' Fec.: ', fec_fin USING "dd-mm-yyyy", " ",
		valor USING "#,##&.##"
	CALL calcular_fondo_reserva_mensual(cod_trab, fec_ing, fec_rei, fec_sal,
						fec_fin, valor, fec_rol)
		RETURNING resul
	IF NOT resul THEN
		EXIT FOREACH
	END IF
	LET i = i + 1
END FOREACH
IF resul THEN
	DISPLAY '  Registros Procesados: ', i USING "<<<<&", ' Ok. '
	LET resul = 1
ELSE
	DISPLAY '  No se Proceso Ningun Registro.'
END IF
RETURN resul

END FUNCTION



FUNCTION calcular_fondo_reserva_mensual(cod_trab, fec_ing, fec_rei, fec_sal,
					fec_fin, valor, fec_rol)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE fec_ing		LIKE rolt030.n30_fecha_ing
DEFINE fec_rei		LIKE rolt030.n30_fecha_reing
DEFINE fec_sal		LIKE rolt030.n30_fecha_sal
DEFINE fec_fin		LIKE rolt038.n38_fecha_fin
DEFINE valor		LIKE rolt033.n33_valor
DEFINE fec_rol		LIKE rolt032.n32_fecing
DEFINE r_n00		RECORD LIKE rolt000.*
DEFINE r_n38		RECORD LIKE rolt038.*
DEFINE r_n90		RECORD LIKE rolt090.*
DEFINE tot_gan, val1	LIKE rolt032.n32_tot_gan
DEFINE query		VARCHAR(250)
DEFINE dias_fon, dias	INTEGER
DEFINE fecha, fec	DATE

LET dias_fon = (fec_fin - fec_ing) + 1
IF fec_rei IS NOT NULL THEN
	LET dias_fon = (fec_fin - fec_rei) + 1
	IF fec_sal IS NOT NULL THEN
		LET dias_fon = dias_fon + ((fec_sal - fec_ing) + 1)
	END IF
END IF
INITIALIZE r_n00.*, r_n90.* TO NULL
SELECT * INTO r_n00.* FROM rolt000 WHERE n00_serial   = codcia
SELECT * INTO r_n90.* FROM rolt090 WHERE n90_compania = codcia
IF dias_fon < r_n90.n90_dias_anio THEN
	IF cod_trab <> 395 then
		DISPLAY '  Dias trabajados: ', dias_fon USING "<<<&"
		RETURN 0
	END IF
END IF
CALL tot_gan_mes(codcia, cod_trab, fec_fin) RETURNING tot_gan
LET dias_fon = dias_fon - r_n90.n90_dias_anio
IF dias_fon > 0 AND dias_fon < r_n90.n90_dias_anio THEN
	LET fecha = fec_fin
	LET fec   = MDY(MONTH(fec_ing), DAY(fec_ing), YEAR(fecha))
	IF fec_rei IS NOT NULL THEN
		LET fec = MDY(MONTH(fec_rei), DAY(fec_rei), YEAR(fecha))
		IF fec_sal IS NOT NULL THEN
			LET fec = MDY(MONTH(fec_ing), DAY(fec_ing), YEAR(fecha))
		END IF
	END IF
	IF EXTEND(fec, YEAR TO MONTH) >= EXTEND(fecha, YEAR TO MONTH) THEN
		LET dias_fon = (fecha - (MDY(MONTH(fecha), DAY(fec),
				YEAR(fecha)))) + 1
		IF dias_fon < r_n00.n00_dias_mes THEN
			LET dias = DAY(fecha)
			IF MONTH(fecha) = 2 THEN
				LET dias = r_n00.n00_dias_mes
			END IF
			LET tot_gan = ((tot_gan / dias) * dias_fon)
		END IF
	END IF
END IF
IF dias_fon > r_n00.n00_dias_mes THEN
	LET dias_fon = r_n00.n00_dias_mes
END IF
INITIALIZE r_n38.* TO NULL
LET r_n38.n38_compania  = codcia
LET r_n38.n38_fecha_fin = fec_fin
LET r_n38.n38_fecha_ini = MDY(MONTH(fec_fin), 01, YEAR(fec_fin))
LET r_n38.n38_cod_trab  = cod_trab
DELETE FROM rolt038
	WHERE n38_compania  = r_n38.n38_compania
	  AND n38_fecha_ini = r_n38.n38_fecha_ini
	  AND n38_fecha_fin = r_n38.n38_fecha_fin
	  AND n38_cod_trab  = r_n38.n38_cod_trab
	  AND n38_pago_iess = "N"
LET r_n38.n38_estado    = 'P'
LET r_n38.n38_fecha_ing = fec_ing
IF fec_rei IS NOT NULL THEN
	LET r_n38.n38_fecha_ing = fec_rei
END IF
LET r_n38.n38_ganado_per  = tot_gan
SELECT ROUND((tot_gan * 8.33 / 100), 2) INTO val1 FROM dual
IF val1 <> valor THEN
	IF cod_trab <> 395 then
		DISPLAY '   ERROR: BASE DIFERENTE - EMP: ',
			cod_trab USING "<<<&&&",
			'  TG = ', tot_gan USING "#,##&.##",
			'  FR = ', valor USING "#,##&.##"
		RETURN 0
	END IF
END IF
LET r_n38.n38_valor_fondo = valor
LET r_n38.n38_moneda      = 'DO'
LET r_n38.n38_paridad     = 1
LET r_n38.n38_pago_iess   = 'N'
LET r_n38.n38_usuario     = 'FOBOS'
LET r_n38.n38_fecing      = fec_rol
INSERT INTO rolt038 VALUES (r_n38.*)
RETURN 1

END FUNCTION



FUNCTION tot_gan_mes(codcia, cod_trab, fecha_fin)
DEFINE codcia 		LIKE rolt032.n32_compania
DEFINE cod_trab		LIKE rolt032.n32_cod_trab
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE valor		DECIMAL(12,2)

LET fecha_ini = MDY(MONTH(fecha_fin), 01, YEAR(fecha_fin))
SELECT NVL(SUM(n32_tot_gan), 0)
	INTO valor
	FROM rolt032
	WHERE n32_compania    = codcia
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_fecha_ini  >= fecha_ini
	  AND n32_fecha_fin  <= fecha_fin
	  AND n32_cod_trab    = cod_trab
RETURN valor

END FUNCTION
