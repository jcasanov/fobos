DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE rm_b00		RECORD LIKE ctbt000.*
DEFINE rm_n45		RECORD LIKE rolt045.*



MAIN

	IF num_args() <> 1 THEN
		DISPLAY 'Parametros Incorrectos. FALTA LA BASE DE DATOS'
		EXIT PROGRAM
	END IF
	LET codcia = 1
	CALL fl_activar_base_datos(arg_val(1))
	CALL genera_anticipo()
	DISPLAY 'Anticipos Generados. OK'

END MAIN



FUNCTION genera_anticipo()
DEFINE r_emp		RECORD
				cod_t		LIKE rolt030.n30_cod_trab,
				empleado	LIKE rolt030.n30_nombres,
				valor_ant	DECIMAL(12,2)
			END RECORD
DEFINE r_ctb		RECORD
				b12_compania	LIKE ctbt012.b12_compania,
				b12_tipo_comp	LIKE ctbt012.b12_tipo_comp,
				b12_num_comp	LIKE ctbt012.b12_num_comp
			END RECORD
DEFINE r_n45		RECORD LIKE rolt045.*
DEFINE cod_lq		LIKE rolt032.n32_cod_liqrol
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE cod_lq2		LIKE rolt032.n32_cod_liqrol
DEFINE fecha_ini2	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin2	LIKE rolt032.n32_fecha_fin
DEFINE cuantos		INTEGER
DEFINE i, j		SMALLINT

DISPLAY 'Carga Empleados en Temporal...'
SELECT NVL(MAX(n32_fecha_ini), TODAY)
	INTO fecha_ini
	FROM rolt032
	WHERE n32_compania    = codcia
	  AND n32_cod_liqrol IN("Q1", "Q2")
	  AND n32_estado     <> 'E'
SELECT NVL(MAX(n32_fecha_fin), TODAY)
	INTO fecha_fin
	FROM rolt032
	WHERE n32_compania    = codcia
	  AND n32_cod_liqrol IN("Q1", "Q2")
	  AND n32_estado     <> 'E'
IF DAY(fecha_ini) = 1 THEN
	LET cod_lq = 'Q1'
ELSE
	LET cod_lq = 'Q2'
END IF
{--
let cod_lq    = 'Q1'
let fecha_ini = mdy(03,01,2012)
let fecha_fin = mdy(03,15,2012)
--}
SELECT n32_cod_trab cod_trab,
	(n33_valor - (n33_valor * n13_porc_trab / 100)) valor
	FROM rolt032, rolt033, rolt030, rolt013
	WHERE n32_compania    = codcia
	  AND n32_cod_liqrol  = cod_lq
	  AND n32_fecha_ini   = fecha_ini
	  AND n32_fecha_fin   = fecha_fin
	  AND n33_compania    = n32_compania
	  AND n33_cod_liqrol  = n32_cod_liqrol
	  AND n33_fecha_ini   = n32_fecha_ini
	  AND n33_fecha_fin   = n32_fecha_fin
	  AND n33_cod_trab    = n32_cod_trab
	  AND n33_cod_rubro  IN (SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident = 'OV')
	  AND n33_valor       > 0
	  AND n30_compania    = n33_compania
	  AND n30_cod_trab    = n33_cod_trab
	  AND n13_cod_seguro  = n30_cod_seguro
	INTO TEMP tmp_emp
SELECT COUNT(*) INTO cuantos FROM tmp_emp
IF cuantos = 0 THEN
	DISPLAY 'No se ha encontrado ningun empleado con otros ing. vac. para descontar.'
	DROP TABLE tmp_emp
	EXIT PROGRAM
END IF
SELECT b12_compania cia, b12_tipo_comp tp, b12_num_comp num
	FROM ctbt012
	WHERE b12_compania = 999
	INTO TEMP tmp_ctb
DISPLAY ' '
DISPLAY 'Creando Anticipos por Empleado. Por favor espere... '
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_emp CURSOR WITH HOLD FOR
	SELECT cod_trab, n30_nombres, valor
		FROM tmp_emp, rolt030
		WHERE n30_compania = codcia
		  AND n30_cod_trab = cod_trab
		ORDER BY 2
LET i = 1
FOREACH q_emp INTO r_emp.*
	DISPLAY '  Anticipo Empleado: ', r_emp.cod_t USING "<<#&&", ' - ',
		r_emp.empleado[1, 40] CLIPPED, '. Valor: ',
		r_emp.valor_ant USING "#,##&.##", '. Espere...'
	INITIALIZE r_n45.* TO NULL
	SELECT * INTO r_n45.*
		FROM rolt045
		WHERE n45_compania  = codcia
		  AND n45_cod_rubro = 73
		  AND n45_cod_trab  = r_emp.cod_t
		  AND n45_estado    = 'A'
	IF r_n45.n45_compania IS NOT NULL THEN
		CONTINUE FOREACH
	END IF
	CALL datos_defaults_cab(r_emp.cod_t, r_emp.valor_ant, fecha_fin, i)
	CALL datos_defaults_det(cod_lq, fecha_ini, fecha_fin, r_emp.valor_ant)
		RETURNING cod_lq2, fecha_ini2, fecha_fin2
	CALL datos_defaults_res(cod_lq, r_emp.valor_ant)
	CALL control_contabilizacion()
	LET i = i + 1
END FOREACH
LET i = i - 1
IF i = 0 THEN
	DROP TABLE tmp_ctb
	DROP TABLE tmp_emp
	ROLLBACK WORK
	DISPLAY 'No se proceso ningun anticipo.'
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
COMMIT WORK
DECLARE q_ctb CURSOR WITH HOLD FOR SELECT * FROM tmp_ctb ORDER BY 2, 3
FOREACH q_ctb INTO r_ctb.*
	CALL fl_mayoriza_comprobante(r_ctb.b12_compania, r_ctb.b12_tipo_comp,
					r_ctb.b12_num_comp, 'M')
END FOREACH
DROP TABLE tmp_ctb
DROP TABLE tmp_emp
DISPLAY 'Se generaron ', i USING "<<<<&", ' anticipos para el rol: ', cod_lq2,
	' ', fecha_ini2 USING "dd-mm-yyyy", ' ', fecha_fin2 USING "dd-mm-yyyy",
	'. OK'
DISPLAY ' '

END FUNCTION



FUNCTION datos_defaults_cab(cod_trab, valor_ant, fecha_fin, i)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE valor_ant	DECIMAL(12,2)
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE i	 	SMALLINT
DEFINE r_n45		RECORD LIKE rolt045.*

INITIALIZE rm_n45.* TO NULL
LET rm_n45.n45_compania      = codcia
LET rm_n45.n45_cod_rubro     = 73
LET rm_n45.n45_cod_trab      = cod_trab
LET rm_n45.n45_estado        = 'A'
LET rm_n45.n45_referencia    = 'DIF. AJ SUELDO ',UPSHIFT(fecha_fin USING "mmm"),
				'/', fecha_fin USING "yy", ' (VACAC.)'
SQL
	SELECT EXTEND($fecha_fin + 1 UNITS DAY, YEAR TO SECOND) + 17 UNITS HOUR
		+ 00 UNITS MINUTE + $i UNITS SECOND  
		INTO $rm_n45.n45_fecha
		FROM dual
END SQL
LET rm_n45.n45_val_prest     = valor_ant
LET rm_n45.n45_valor_int     = 0
LET rm_n45.n45_sal_prest_ant = 0
LET rm_n45.n45_descontado    = 0
LET rm_n45.n45_mes_gracia    = 0
LET rm_n45.n45_porc_int      = 0
LET rm_n45.n45_moneda        = 'DO'
LET rm_n45.n45_paridad       = 1
LET rm_n45.n45_tipo_pago     = 'E'
LET rm_n45.n45_usuario       = 'FOBOS'
LET rm_n45.n45_fecing        = CURRENT
WHENEVER ERROR CONTINUE
WHILE TRUE
	LET rm_n45.n45_num_prest = NULL
	SELECT NVL(MAX(n45_num_prest), 0) + 1
		INTO rm_n45.n45_num_prest
		FROM rolt045
		WHERE n45_compania = codcia
	IF rm_n45.n45_num_prest IS NULL THEN
		LET rm_n45.n45_num_prest = 1
	END IF
	CALL fl_lee_cab_prestamo_roles(codcia, rm_n45.n45_num_prest)
		RETURNING r_n45.*
	IF r_n45.n45_num_prest IS NULL THEN
		EXIT WHILE
	END IF
END WHILE
WHENEVER ERROR STOP
INSERT INTO rolt045 VALUES(rm_n45.*)

END FUNCTION



FUNCTION datos_defaults_det(cod_lq, fecha_ini, fecha_fin, valor_ant)
DEFINE cod_lq		LIKE rolt032.n32_cod_liqrol
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE valor_ant	DECIMAL(12,2)
DEFINE r_n46		RECORD LIKE rolt046.*

LET r_n46.n46_compania   = rm_n45.n45_compania
LET r_n46.n46_num_prest  = rm_n45.n45_num_prest
LET r_n46.n46_secuencia  = 1
LET r_n46.n46_fecha_ini  = fecha_fin + 1 UNITS DAY
IF cod_lq = 'Q2' THEN
	LET r_n46.n46_cod_liqrol = 'Q1'
	LET r_n46.n46_fecha_fin  = MDY(MONTH(fecha_fin), 15, YEAR(fecha_fin))
					+ 1 UNITS MONTH
ELSE
	LET r_n46.n46_cod_liqrol = 'Q2'
	LET r_n46.n46_fecha_fin  = fecha_ini + 1 UNITS MONTH - 1 UNITS DAY
END IF
LET r_n46.n46_valor      = valor_ant
LET r_n46.n46_saldo      = valor_ant
INSERT INTO rolt046 VALUES(r_n46.*)
RETURN r_n46.n46_cod_liqrol, r_n46.n46_fecha_ini, r_n46.n46_fecha_fin

END FUNCTION



FUNCTION datos_defaults_res(cod_lq, valor_ant)
DEFINE cod_lq		LIKE rolt032.n32_cod_liqrol
DEFINE valor_ant	DECIMAL(12,2)
DEFINE r_n58		RECORD LIKE rolt058.*

LET r_n58.n58_compania   = rm_n45.n45_compania
LET r_n58.n58_num_prest  = rm_n45.n45_num_prest
LET r_n58.n58_proceso    = 'Q1'
IF cod_lq = 'Q2' THEN
	LET r_n58.n58_proceso = 'Q1'
ELSE
	LET r_n58.n58_proceso = 'Q2'
END IF
LET r_n58.n58_div_act    = 1
LET r_n58.n58_num_div    = 1
LET r_n58.n58_valor_div  = valor_ant
LET r_n58.n58_valor_dist = valor_ant
LET r_n58.n58_saldo_dist = valor_ant
LET r_n58.n58_usuario    = 'CATAGARC'
LET r_n58.n58_fecing     = rm_n45.n45_fecha
INSERT INTO rolt058 VALUES(r_n58.*)

END FUNCTION



FUNCTION control_contabilizacion()
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_n59		RECORD LIKE rolt059.*
DEFINE resp		CHAR(6)

CALL lee_prest_cont(codcia, rm_n45.n45_num_prest) RETURNING r_n59.*
IF rm_n45.n45_estado <> 'A' AND rm_n45.n45_estado <> 'R' THEN
	DISPLAY 'Solo puede contabilizar un anticipo cuando esta Activo o ',
		'Redistribuido.'
	ROLLBACK WORK
	EXIT PROGRAM
END IF
IF rm_n45.n45_descontado > 0 THEN
	DISPLAY 'No puede contabilizar un anticipo que ya se comenzo a ',
		'descontar.'
	ROLLBACK WORK
	EXIT PROGRAM
END IF
WHENEVER ERROR CONTINUE
DECLARE q_cont CURSOR FOR
	SELECT * FROM rolt045
		WHERE n45_compania  = codcia
		  AND n45_num_prest = rm_n45.n45_num_prest
	FOR UPDATE
OPEN q_cont
FETCH q_cont INTO rm_n45.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	DISPLAY 'Este registro no existe. Ha ocurrido un error ',
		'interno de la base de datos.'
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	DISPLAY 'Registro Bloqueado otro usuario'
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
CALL generar_contabilizacion() RETURNING r_b12.*
IF r_b12.b12_compania IS NULL THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF
INSERT INTO tmp_ctb
	VALUES (r_b12.b12_compania, r_b12.b12_tipo_comp,
		r_b12.b12_num_comp)
DISPLAY '  Contabilizacion del Anticipo ', rm_n45.n45_num_prest USING "<<#&&",
	' Generada Ok.'
DISPLAY ' '

END FUNCTION



FUNCTION generar_contabilizacion()
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n45		RECORD LIKE rolt045.*
DEFINE r_n56		RECORD LIKE rolt056.*
DEFINE r_n59		RECORD LIKE rolt059.*
DEFINE glosa		LIKE ctbt012.b12_glosa
DEFINE num_che		LIKE ctbt012.b12_num_cheque
DEFINE sec		LIKE ctbt013.b13_secuencia
DEFINE val_prest	LIKE rolt045.n45_val_prest
DEFINE valor_cuad	DECIMAL(14,2)

INITIALIZE r_b12.*, r_n56.*, r_n59.* TO NULL
CALL fl_lee_trabajador_roles(codcia, rm_n45.n45_cod_trab) RETURNING r_n30.*
CALL fl_lee_rubro_roles(rm_n45.n45_cod_rubro) RETURNING r_n06.*
SELECT * INTO r_n56.*
	FROM rolt056
	WHERE n56_compania  = codcia
	  AND n56_proceso   = r_n06.n06_flag_ident
	  AND n56_cod_depto = r_n30.n30_cod_depto
	  AND n56_cod_trab  = rm_n45.n45_cod_trab
	  AND n56_estado    = "A"
IF r_n56.n56_compania IS NULL THEN
	CALL fl_lee_proceso_roles(r_n06.n06_flag_ident) RETURNING r_n03.*
	DISPLAY 'No existen auxiliares contable para este trabajador en el ',
		'proceso de ', r_n03.n03_nombre CLIPPED, '.'
	RETURN r_b12.*
END IF
IF NOT validacion_contable(DATE(rm_n45.n45_fecha)) THEN
	RETURN r_b12.*
END IF
LET r_b12.b12_compania 	  = codcia
LET r_b12.b12_tipo_comp   = "DC"
IF rm_n45.n45_tipo_pago = 'C' THEN
	LET r_b12.b12_tipo_comp = "EG"
END IF
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(codcia,
				r_b12.b12_tipo_comp, YEAR(rm_n45.n45_fecha),
				MONTH(rm_n45.n45_fecha)) 
IF r_b12.b12_num_comp <= 0 THEN
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*
END IF
LET r_b12.b12_estado 	  = 'A'
LET r_b12.b12_glosa       = rm_n45.n45_referencia CLIPPED, ' ',
				r_n30.n30_nombres[1, 25] CLIPPED,
				', ANTICIPOS DE EMPLEADOS ',
				DATE(rm_n45.n45_fecha) USING "dd-mm-yyyy"
IF rm_n45.n45_sal_prest_ant > 0 THEN
	LET r_b12.b12_glosa = r_b12.b12_glosa CLIPPED, ' (REDISTRIBUIDO).'
END IF
LET r_b12.b12_glosa = r_b12.b12_glosa CLIPPED, ' ANT. ',
			rm_n45.n45_num_prest USING "<<&&", ' '
IF rm_n45.n45_sal_prest_ant > 0 THEN
	LET r_b12.b12_glosa = r_b12.b12_glosa CLIPPED, ' PA-',
				rm_n45.n45_prest_tran USING "<<&&"
END IF
LET r_b12.b12_origen      = 'A'
CALL fl_lee_moneda(r_n30.n30_mon_sueldo) RETURNING r_g13.*
IF r_g13.g13_moneda = 'DO' THEN
	LET r_g14.g14_tasa = 1
ELSE
	CALL fl_lee_factor_moneda(r_g13.g13_moneda, 'DO')
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		DISPLAY 'La paridad para esta moneda no existe.'
		INITIALIZE r_b12.* TO NULL
		RETURN r_b12.*
	END IF
END IF
LET r_b12.b12_moneda      = r_g13.g13_moneda
LET r_b12.b12_paridad     = r_g14.g14_tasa
LET r_b12.b12_fec_proceso = DATE(rm_n45.n45_fecha)
LET r_b12.b12_modulo      = 'RO'
LET r_b12.b12_usuario     = rm_n45.n45_usuario
LET r_b12.b12_fecing      = CURRENT
INSERT INTO ctbt012 VALUES (r_b12.*) 
LET val_prest = rm_n45.n45_val_prest + rm_n45.n45_valor_int
IF rm_n45.n45_val_prest = 0 THEN
	LET val_prest = rm_n45.n45_sal_prest_ant
END IF
CALL fl_lee_cab_prestamo_roles(codcia, rm_n45.n45_prest_tran)
	RETURNING r_n45.*
IF r_n45.n45_estado = 'A' OR r_n45.n45_estado = 'R' OR r_n45.n45_estado = 'T'
THEN
	CALL lee_prest_cont(codcia, r_n45.n45_num_prest) RETURNING r_n59.*
	IF r_n59.n59_compania IS NULL THEN
		LET val_prest = val_prest + r_n45.n45_val_prest
				+ r_n45.n45_valor_int
	END IF
END IF
LET sec = 1
IF rm_n45.n45_tipo_pago = 'T' OR rm_n45.n45_tipo_pago = 'R' THEN
	CALL generar_detalle_contable(r_b12.*, rm_n45.n45_cta_trabaj, val_prest,
					'D', sec, 0, 'S')
	IF rm_n45.n45_val_prest = 0 THEN
		LET r_n56.n56_aux_banco = rm_n45.n45_cta_trabaj
	END IF
ELSE
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_val_vac, val_prest,
					'D', sec, 0, 'S')
END IF
IF rm_n45.n45_sal_prest_ant > 0 AND rm_n45.n45_val_prest > 0 THEN
	LET sec = sec + 1
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_val_vac,
				rm_n45.n45_sal_prest_ant, 'D', sec, 0, 'S')
	LET sec = sec + 1
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_val_vac,
				rm_n45.n45_sal_prest_ant, 'H', sec, 1, 'N')
END IF
IF rm_n45.n45_valor_int > 0 THEN
	LET sec = sec + 1
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_otr_egr,
					rm_n45.n45_valor_int, 'H', sec, 0, 'S')
END IF
LET sec = sec + 1
CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_banco, (val_prest -
				rm_n45.n45_valor_int), 'H', sec, 1, 'S')
SELECT NVL(SUM(b13_valor_base), 0)
	INTO valor_cuad
	FROM ctbt013
	WHERE b13_compania  = codcia
	  AND b13_tipo_comp = r_b12.b12_tipo_comp
	  AND b13_num_comp  = r_b12.b12_num_comp
IF valor_cuad <> 0 THEN
	DISPLAY 'Se ha generado un error en la contabilizacion. POR FAVOR ',
		'LLAME AL ADMINISTRADOR.'
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*
END IF
INITIALIZE r_n59.* TO NULL
LET r_n59.n59_compania  = rm_n45.n45_compania
LET r_n59.n59_num_prest = rm_n45.n45_num_prest
LET r_n59.n59_tipo_comp = r_b12.b12_tipo_comp
LET r_n59.n59_num_comp  = r_b12.b12_num_comp
INSERT INTO rolt059 VALUES(r_n59.*)
RETURN r_b12.*

END FUNCTION



FUNCTION validacion_contable(fecha)
DEFINE fecha		DATE
DEFINE resp 		VARCHAR(6)

CALL fl_lee_compania_contabilidad(codcia) RETURNING rm_b00.*
IF YEAR(fecha) < YEAR(rm_b00.b00_fecha_cm) OR
  (YEAR(fecha) = YEAR(rm_b00.b00_fecha_cm) AND
   MONTH(fecha) <= MONTH(rm_b00.b00_fecha_cm))
THEN
	DISPLAY 'El Mes en Contabilidad esta cerrado. Reapertúrelo para ',
		'que se pueda generar la contabilización del Anticipo.'
	RETURN 0
END IF
IF fecha_bloqueada(codcia, MONTH(fecha), YEAR(fecha)) THEN
	DISPLAY 'No puede generar contabilización del Anticipo de un mes ',
		'bloqueado en CONTABILIDAD.'
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION fecha_bloqueada(codcia, mes, ano)
DEFINE codcia 		LIKE ctbt006.b06_compania
DEFINE mes, ano		SMALLINT
DEFINE r_b06		RECORD LIKE ctbt006.*

INITIALIZE r_b06.* TO NULL 
SELECT * INTO r_b06.*
	FROM ctbt006
	WHERE b06_compania = codcia
	  AND b06_ano      = ano
	  AND b06_mes      = mes
IF r_b06.b06_mes IS NOT NULL THEN
	DISPLAY 'Mes contable esta bloqueado.'
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION generar_detalle_contable(r_b12, cuenta, valor, tipo, sec, flag_bco,
					flag)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE valor		LIKE ctbt013.b13_valor_base
DEFINE tipo		CHAR(1)
DEFINE sec		LIKE ctbt013.b13_secuencia
DEFINE flag_bco		SMALLINT
DEFINE flag		CHAR(1)
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_b13		RECORD LIKE ctbt013.*

INITIALIZE r_b13.* TO NULL
LET r_b13.b13_compania    = r_b12.b12_compania
LET r_b13.b13_tipo_comp   = r_b12.b12_tipo_comp
LET r_b13.b13_num_comp    = r_b12.b12_num_comp
LET r_b13.b13_secuencia   = sec
IF flag_bco THEN
	IF rm_n45.n45_tipo_pago <> 'E' THEN
		CALL fl_lee_banco_compania(codcia, rm_n45.n45_bco_empresa,
						rm_n45.n45_cta_empresa)
			RETURNING r_g09.*
		IF rm_n45.n45_val_prest > 0 AND flag = 'S' THEN
			LET cuenta = r_g09.g09_aux_cont
		END IF
	END IF
	IF rm_n45.n45_val_prest > 0 THEN
		CASE rm_n45.n45_tipo_pago
			WHEN 'C' IF flag = 'S' THEN
					LET r_b13.b13_tipo_doc = 'CHE'
				 END IF
			WHEN 'T' --LET r_b13.b13_tipo_doc = 'DEP'
		END CASE
	END IF
END IF
LET r_b13.b13_cuenta      = cuenta
LET r_b13.b13_glosa       = 'LIQ.ANT.EMP. ',
				rm_n45.n45_cod_trab USING "<<<&&", ' AN-',
				rm_n45.n45_num_prest USING "<<<&&",
				' RUBRO: ', rm_n45.n45_cod_rubro USING "<<<&&",
				' ', DATE(rm_n45.n45_fecha) USING "dd-mm-yyyy"
LET r_b13.b13_valor_base  = 0
LET r_b13.b13_valor_aux   = 0
CASE tipo
	WHEN 'D'
		LET r_b13.b13_valor_base = valor
	WHEN 'H'
		LET r_b13.b13_valor_base = valor * (-1)
END CASE
LET r_b13.b13_fec_proceso = r_b12.b12_fec_proceso
INSERT INTO ctbt013 VALUES (r_b13.*)

END FUNCTION



FUNCTION lee_prest_cont(codcia, num_prest)
DEFINE codcia		LIKE rolt059.n59_compania
DEFINE num_prest	LIKE rolt059.n59_num_prest
DEFINE r_n59		RECORD LIKE rolt059.*

INITIALIZE r_n59.* TO NULL
SELECT * INTO r_n59.*
	FROM rolt059
	WHERE n59_compania  = codcia
	  AND n59_num_prest = num_prest
RETURN r_n59.*

END FUNCTION
