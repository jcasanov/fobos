SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS GYE"
	END AS loc,
	n30_cod_trab AS codi,
	CASE WHEN n30_tipo_doc_id = "C"
		THEN "CEDULA"
		ELSE "PASAPORTE"
	END AS tip,
	n30_num_doc_id AS cedula,
	n30_nombres AS empl,
	n30_sueldo_mes AS sueld,
	(SELECT g34_nombre
		FROM acero_gm@idsgye01:gent034
		WHERE g34_compania  = n30_compania
		  AND g34_cod_depto = n30_cod_depto) AS depto,
	(SELECT g35_nombre
		FROM acero_gm@idsgye01:gent035
		WHERE g35_compania  = n30_compania
		  AND g35_cod_cargo = n30_cod_cargo) AS carg_int,
	(SELECT n17_descripcion
		FROM acero_gm@idsgye01:rolt017
		WHERE n17_compania  = n30_compania
		  AND n17_ano_sect  = n30_ano_sect
		  AND n17_sectorial = n30_sectorial) AS carg_iess,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	n30_fecha_nacim AS fec_nac,
	TRUNC(fp_dias360(NVL(n30_fecha_reing, n30_fecha_ing), TODAY, 1) /
			n90_dias_ano_ant, 0) AS anio_ser,
	TRUNC(MOD(fp_dias360(NVL(n30_fecha_reing, n30_fecha_ing), TODAY, 1),
			n90_dias_ano_ant) / n00_dias_mes, 0) AS mes_ser,
	MOD(MOD(fp_dias360(NVL(n30_fecha_reing, n30_fecha_ing), TODAY, 1),
			n90_dias_ano_ant), n00_dias_mes) AS dias_ser,
	((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) AS dias_trab,
	TRUNC(((TODAY - n30_fecha_nacim) + 1) / n90_dias_anio, 0) AS anio_eda,
	TRUNC(MOD((TODAY - n30_fecha_nacim) + 1, n90_dias_anio) /
			n00_dias_mes, 0) AS mes_eda,
	MOD(MOD((TODAY - n30_fecha_nacim) + 1, n90_dias_anio),
			n00_dias_mes) AS dias_eda,
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) >
			(n90_dias_ano_ant + n00_dias_mes)
		THEN
		NVL((SELECT SUM(a.n32_tot_gan)
		FROM acero_gm@idsgye01:rolt032 a
		WHERE a.n32_compania    = n30_compania
		  AND a.n32_cod_liqrol IN ("Q1", "Q2")
		  AND EXTEND(a.n32_fecha_fin, YEAR TO MONTH) =
			EXTEND((SELECT MAX(b.n32_fecha_fin)
					FROM acero_gm@idsgye01:rolt032 b
					WHERE b.n32_compania   = 1
					  AND b.n32_cod_liqrol = "Q2"
					  AND b.n32_estado     = "C"),
				YEAR TO MONTH)
		  AND a.n32_cod_trab    = n30_cod_trab
		  AND a.n32_estado      = "C"), 0.00)
		ELSE 0.00
	END AS val_bas,
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) >
			(n90_dias_ano_ant + n00_dias_mes)
		THEN
		NVL(ROUND(((SELECT SUM(a.n32_tot_gan)
		FROM acero_gm@idsgye01:rolt032 a
		WHERE a.n32_compania    = n30_compania
		  AND a.n32_cod_liqrol IN ("Q1", "Q2")
		  AND EXTEND(a.n32_fecha_fin, YEAR TO MONTH) =
			EXTEND((SELECT MAX(b.n32_fecha_fin)
					FROM acero_gm@idsgye01:rolt032 b
					WHERE b.n32_compania   = 1
					  AND b.n32_cod_liqrol = "Q2"
					  AND b.n32_estado     = "C"),
				YEAR TO MONTH)
		  AND a.n32_cod_trab    = n30_cod_trab
		  AND a.n32_estado      = "C") / n00_dias_mes) *
		(n00_dias_mes -
		CASE WHEN (TRUNC(fp_dias360(NVL(n30_fecha_reing, n30_fecha_ing),
					TODAY, 1) / n90_dias_ano_ant, 0) =
				n90_dias_ano_ant) AND
			TRUNC(MOD(fp_dias360(NVL(n30_fecha_reing,n30_fecha_ing),
					TODAY, 1), n90_dias_ano_ant) /
					n00_dias_mes, 0) <= 1
			THEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) - 1
			ELSE 0
		END) *
		(SELECT n07_factor / 100
			FROM acero_gm@idsgye01:rolt007,
				acero_gm@idsgye01:rolt006
			WHERE n06_cod_rubro  = n07_cod_rubro
			  AND n06_flag_ident = "FM"), 2), 0.00)
		ELSE 0.00
	END AS val_fr,
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) >
			(n90_dias_ano_ant + n00_dias_mes)
		THEN "SI"
		ELSE "NO"
	END AS tiene_de_fr,
	CASE WHEN n30_fon_res_anio = "S"
		THEN "ACUMULA EN IESS"
		ELSE "COBRA EN ROL"
	END AS paga_iess,
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) >
			(n90_dias_ano_ant + n00_dias_mes)
		THEN 1
		ELSE 0
	END AS num_reg
	FROM acero_gm@idsgye01:rolt030, acero_gm@idsgye01:rolt090,
		acero_gm@idsgye01:rolt000
	WHERE n30_compania = 1
	  AND n30_estado   = "A"
	  AND n90_compania = n30_compania
	  AND n00_serial   = n90_compania
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS UIO"
	END AS loc,
	n30_cod_trab AS codi,
	CASE WHEN n30_tipo_doc_id = "C"
		THEN "CEDULA"
		ELSE "PASAPORTE"
	END AS tip,
	n30_num_doc_id AS cedula,
	n30_nombres AS empl,
	n30_sueldo_mes AS sueld,
	(SELECT g34_nombre
		FROM acero_qm@idsuio01:gent034
		WHERE g34_compania  = n30_compania
		  AND g34_cod_depto = n30_cod_depto) AS depto,
	(SELECT g35_nombre
		FROM acero_qm@idsuio01:gent035
		WHERE g35_compania  = n30_compania
		  AND g35_cod_cargo = n30_cod_cargo) AS carg_int,
	(SELECT n17_descripcion
		FROM acero_qm@idsuio01:rolt017
		WHERE n17_compania  = n30_compania
		  AND n17_ano_sect  = n30_ano_sect
		  AND n17_sectorial = n30_sectorial) AS carg_iess,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	n30_fecha_nacim AS fec_nac,
	TRUNC(fp_dias360(NVL(n30_fecha_reing, n30_fecha_ing), TODAY, 1) /
			n90_dias_ano_ant, 0) AS anio_ser,
	TRUNC(MOD(fp_dias360(NVL(n30_fecha_reing, n30_fecha_ing), TODAY, 1),
			n90_dias_ano_ant) / n00_dias_mes, 0) AS mes_ser,
	MOD(MOD(fp_dias360(NVL(n30_fecha_reing, n30_fecha_ing), TODAY, 1),
			n90_dias_ano_ant), n00_dias_mes) AS dias_ser,
	((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) AS dias_trab,
	TRUNC(((TODAY - n30_fecha_nacim) + 1) / n90_dias_anio, 0) AS anio_eda,
	TRUNC(MOD((TODAY - n30_fecha_nacim) + 1, n90_dias_anio) /
			n00_dias_mes, 0) AS mes_eda,
	MOD(MOD((TODAY - n30_fecha_nacim) + 1, n90_dias_anio),
			n00_dias_mes) AS dias_eda,
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) >
			(n90_dias_ano_ant + n00_dias_mes)
		THEN
		NVL((SELECT SUM(a.n32_tot_gan)
		FROM acero_qm@idsuio01:rolt032 a
		WHERE a.n32_compania    = n30_compania
		  AND a.n32_cod_liqrol IN ("Q1", "Q2")
		  AND EXTEND(a.n32_fecha_fin, YEAR TO MONTH) =
			EXTEND((SELECT MAX(b.n32_fecha_fin)
					FROM acero_qm@idsuio01:rolt032 b
					WHERE b.n32_compania   = 1
					  AND b.n32_cod_liqrol = "Q2"
					  AND b.n32_estado     = "C"),
				YEAR TO MONTH)
		  AND a.n32_cod_trab    = n30_cod_trab
		  AND a.n32_estado      = "C"), 0.00)
		ELSE 0.00
	END AS val_bas,
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) >
			(n90_dias_ano_ant + n00_dias_mes)
		THEN
		NVL(ROUND(((SELECT SUM(a.n32_tot_gan)
		FROM acero_qm@idsuio01:rolt032 a
		WHERE a.n32_compania    = n30_compania
		  AND a.n32_cod_liqrol IN ("Q1", "Q2")
		  AND EXTEND(a.n32_fecha_fin, YEAR TO MONTH) =
			EXTEND((SELECT MAX(b.n32_fecha_fin)
					FROM acero_qm@idsuio01:rolt032 b
					WHERE b.n32_compania   = 1
					  AND b.n32_cod_liqrol = "Q2"
					  AND b.n32_estado     = "C"),
				YEAR TO MONTH)
		  AND a.n32_cod_trab    = n30_cod_trab
		  AND a.n32_estado      = "C") / n00_dias_mes) *
		(n00_dias_mes -
		CASE WHEN (TRUNC(fp_dias360(NVL(n30_fecha_reing, n30_fecha_ing),
					TODAY, 1) / n90_dias_ano_ant, 0) =
				n90_dias_ano_ant) AND
			TRUNC(MOD(fp_dias360(NVL(n30_fecha_reing,n30_fecha_ing),
					TODAY, 1), n90_dias_ano_ant) /
					n00_dias_mes, 0) <= 1
			THEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) - 1
			ELSE 0
		END) *
		(SELECT n07_factor / 100
			FROM acero_qm@idsuio01:rolt007,
				acero_qm@idsuio01:rolt006
			WHERE n06_cod_rubro  = n07_cod_rubro
			  AND n06_flag_ident = "FM"), 2), 0.00)
		ELSE 0.00
	END AS val_fr,
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) >
			(n90_dias_ano_ant + n00_dias_mes)
		THEN "SI"
		ELSE "NO"
	END AS tiene_de_fr,
	CASE WHEN n30_fon_res_anio = "S"
		THEN "ACUMULA EN IESS"
		ELSE "COBRA EN ROL"
	END AS paga_iess,
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) >
			(n90_dias_ano_ant + n00_dias_mes)
		THEN 1
		ELSE 0
	END AS num_reg
	FROM acero_qm@idsuio01:rolt030, acero_qm@idsuio01:rolt090,
		acero_qm@idsuio01:rolt000
	WHERE n30_compania = 1
	  AND n30_estado   = "A"
	  AND n90_compania = n30_compania
	  AND n00_serial   = n90_compania
	ORDER BY n30_nombres ASC;
