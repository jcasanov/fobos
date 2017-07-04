SELECT YEAR(t20_fecing) AS anio,
	CASE WHEN MONTH(t20_fecing) = 01 THEN "01_ENERO"
	     WHEN MONTH(t20_fecing) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(t20_fecing) = 03 THEN "03_MARZO"
	     WHEN MONTH(t20_fecing) = 04 THEN "04_ABRIL"
	     WHEN MONTH(t20_fecing) = 05 THEN "05_MAYO"
	     WHEN MONTH(t20_fecing) = 06 THEN "06_JUNIO"
	     WHEN MONTH(t20_fecing) = 07 THEN "07_JULIO"
	     WHEN MONTH(t20_fecing) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(t20_fecing) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(t20_fecing) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(t20_fecing) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(t20_fecing) = 12 THEN "12_DICIEMBRE"
	END AS mes,
	t20_cod_cliente AS codcli,
	t20_cedruc AS cedruc,
	t20_nom_cliente AS nomcli,
	t20_dir_cliente AS dircli,
	t20_tel_cliente AS telcli,
	t20_numpre AS numpre,
	t20_motivo AS motivo,
	t20_total_mo AS mano_ob,
	t20_total_rp AS mater,
	t20_total_impto AS impto,
	t20_total_neto AS total,
	t20_user_aprob AS user_ap,
	t20_fecha_aprob AS fecha_ap,
	t20_usu_elimin AS user_eli,
	t20_fec_elimin AS fecha_eli,
	CASE WHEN t20_estado = "A" THEN "ACTIVO"
	     WHEN t20_estado = "P" THEN "APROBADO"
	     WHEN t20_estado = "E" THEN "ELIMINADO"
	END AS estado,
	NVL(CASE WHEN t20_estado = "P"
		THEN (SELECT t23_orden
			FROM talt023
			WHERE t23_compania  = t20_compania
			  AND t23_localidad = t20_localidad
			  AND t23_numpre    = t20_numpre
			  AND t23_estado    NOT IN ("D", "E"))
	END, "") AS num_ot,
	NVL(CASE WHEN t20_estado = "P"
		THEN (SELECT t23_num_factura
			FROM talt023
			WHERE t23_compania  = t20_compania
			  AND t23_localidad = t20_localidad
			  AND t23_numpre    = t20_numpre
			  AND t23_estado    NOT IN ("D", "E"))
	END, "") AS num_fac,
	NVL(CASE WHEN t20_estado = "P"
		THEN (SELECT DATE(t23_fec_factura)
			FROM talt023
			WHERE t23_compania  = t20_compania
			  AND t23_localidad = t20_localidad
			  AND t23_numpre    = t20_numpre
			  AND t23_estado    NOT IN ("D", "E"))
	END, "") AS fec_fact,
	DATE(t20_fecing) AS fecha
	FROM talt020
	WHERE t20_compania  = 1
	  AND t20_localidad = 1
	ORDER BY 1, 2, 5;