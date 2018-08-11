SELECT YEAR(t23_fec_factura) AS anio,
	CASE WHEN MONTH(t23_fec_factura) = 01 THEN "01_ENERO"
	     WHEN MONTH(t23_fec_factura) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(t23_fec_factura) = 03 THEN "03_MARZO"
	     WHEN MONTH(t23_fec_factura) = 04 THEN "04_ABRIL"
	     WHEN MONTH(t23_fec_factura) = 05 THEN "05_MAYO"
	     WHEN MONTH(t23_fec_factura) = 06 THEN "06_JUNIO"
	     WHEN MONTH(t23_fec_factura) = 07 THEN "07_JULIO"
	     WHEN MONTH(t23_fec_factura) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(t23_fec_factura) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(t23_fec_factura) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(t23_fec_factura) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(t23_fec_factura) = 12 THEN "12_DICIEMBRE"
	END AS mes,
	NVL(t23_cod_cliente, "") AS codcli,
	NVL(t23_cedruc, "") AS cedruc,
	t23_nom_cliente AS nomcli,
	t23_dir_cliente AS dircli,
	t23_tel_cliente AS telcli,
	t23_orden AS num_ot,
	NVL(t23_numpre, "") AS numpre,
	NVL(t23_num_factura, "") AS num_f,
	NVL(TO_CHAR(DATE(t23_fec_factura), "%Y-%m-%d"), "") AS fecha,
	NVL(t24_mecanico, "") AS cod_te,
	t03_nombres AS tecn,
	t03_iniciales AS ini_t,
	t24_codtarea AS codt,
	t24_descripcion AS descrip,
	t24_valor_tarea AS val_mo,
	CASE WHEN t23_cont_cred = 'C'
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS cont_cred,
	CASE WHEN t23_estado = "A" THEN "04_ACTIVA"
	     WHEN t23_estado = "C" THEN "03_CERRADA"
	     WHEN t23_estado = "F" OR t23_estado = "D" THEN "01_FACTURADA"
	     WHEN t23_estado = "E" THEN "05_ELIMINADA"
	END AS estado
	FROM talt023, talt024, talt003
	WHERE t23_compania   = 1
	  AND t23_localidad  = 1
	  AND t23_estado    IN ("F", "D")
	  AND t24_compania   = t23_compania
	  AND t24_localidad  = t23_localidad
	  AND t24_orden      = t23_orden
	  AND t03_compania   = t24_compania
	  AND t03_mecanico   = t24_mecanico
UNION
SELECT YEAR(t28_fec_anula) AS anio,
	CASE WHEN MONTH(t28_fec_anula) = 01 THEN "01_ENERO"
	     WHEN MONTH(t28_fec_anula) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(t28_fec_anula) = 03 THEN "03_MARZO"
	     WHEN MONTH(t28_fec_anula) = 04 THEN "04_ABRIL"
	     WHEN MONTH(t28_fec_anula) = 05 THEN "05_MAYO"
	     WHEN MONTH(t28_fec_anula) = 06 THEN "06_JUNIO"
	     WHEN MONTH(t28_fec_anula) = 07 THEN "07_JULIO"
	     WHEN MONTH(t28_fec_anula) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(t28_fec_anula) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(t28_fec_anula) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(t28_fec_anula) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(t28_fec_anula) = 12 THEN "12_DICIEMBRE"
	END AS mes,
	NVL(t23_cod_cliente, "") AS codcli,
	NVL(t23_cedruc, "") AS cedruc,
	t23_nom_cliente AS nomcli,
	t23_dir_cliente AS dircli,
	t23_tel_cliente AS telcli,
	t23_orden AS num_ot,
	NVL(t23_numpre, "") AS numpre,
	NVL(t28_num_dev, "") AS num_f,
	NVL(TO_CHAR(DATE(t28_fec_anula), "%Y-%m-%d"), "") AS fecha,
	NVL(t24_mecanico, "") AS cod_te,
	t03_nombres AS tecn,
	t03_iniciales AS ini_t,
	t24_codtarea AS codt,
	t24_descripcion AS descrip,
	t24_valor_tarea * (-1) AS val_mo,
	CASE WHEN t23_cont_cred = 'C'
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS cont_cred,
	CASE WHEN t23_estado = "A" THEN "04_ACTIVA"
	     WHEN t23_estado = "C" THEN "03_CERRADA"
	     WHEN t23_estado = "F" THEN "01_FACTURADA"
	     WHEN t23_estado = "D" THEN "02_DEVUELTA"
	     WHEN t23_estado = "E" THEN "05_ELIMINADA"
	END AS estado
	FROM talt023, talt028, talt024, talt003
	WHERE t23_compania   = 1
	  AND t23_localidad  = 1
	  AND t23_estado     = "D"
	  AND t28_compania   = t23_compania
	  AND t28_localidad  = t23_localidad
	  AND t28_ot_ant     = t23_orden
	  AND t24_compania   = t23_compania
	  AND t24_localidad  = t23_localidad
	  AND t24_orden      = t23_orden
	  AND t03_compania   = t24_compania
	  AND t03_mecanico   = t24_mecanico
UNION
SELECT YEAR(t23_fecing) AS anio,
	CASE WHEN MONTH(t23_fecing) = 01 THEN "01_ENERO"
	     WHEN MONTH(t23_fecing) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(t23_fecing) = 03 THEN "03_MARZO"
	     WHEN MONTH(t23_fecing) = 04 THEN "04_ABRIL"
	     WHEN MONTH(t23_fecing) = 05 THEN "05_MAYO"
	     WHEN MONTH(t23_fecing) = 06 THEN "06_JUNIO"
	     WHEN MONTH(t23_fecing) = 07 THEN "07_JULIO"
	     WHEN MONTH(t23_fecing) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(t23_fecing) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(t23_fecing) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(t23_fecing) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(t23_fecing) = 12 THEN "12_DICIEMBRE"
	END AS mes,
	NVL(t23_cod_cliente, "") AS codcli,
	NVL(t23_cedruc, "") AS cedruc,
	t23_nom_cliente AS nomcli,
	t23_dir_cliente AS dircli,
	t23_tel_cliente AS telcli,
	t23_orden AS num_ot,
	NVL(t23_numpre, "") AS numpre,
	NVL(t23_num_factura, "") AS num_f,
	NVL(TO_CHAR(DATE(t23_fecing), "%Y-%m-%d"), "") AS fecha,
	NVL(t24_mecanico, "") AS cod_te,
	NVL(t03_nombres, "") AS tecn,
	NVL(t03_iniciales, "") AS ini_t,
	NVL(t24_codtarea, "") AS codt,
	NVL(t24_descripcion, "") AS descrip,
	NVL(CASE WHEN t23_estado <> "E"
		THEN t24_valor_tarea
		ELSE t24_valor_tarea * (-1)
	END, 0.00) AS val_mo,
	CASE WHEN t23_cont_cred = 'C'
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS cont_cred,
	CASE WHEN t23_estado = "A" THEN "04_ACTIVA"
	     WHEN t23_estado = "C" THEN "03_CERRADA"
	     WHEN t23_estado = "F" THEN "01_FACTURADA"
	     WHEN t23_estado = "D" THEN "02_DEVUELTA"
	     WHEN t23_estado = "E" THEN "05_ELIMINADA"
	END AS estado
	FROM talt023, OUTER (talt024, talt003)
	WHERE t23_compania   = 1
	  AND t23_localidad  = 1
	  AND t23_estado    IN ("A", "C", "E")
	  AND t24_compania   = t23_compania
	  AND t24_localidad  = t23_localidad
	  AND t24_orden      = t23_orden
	  AND t03_compania   = t24_compania
	  AND t03_mecanico   = t24_mecanico
	ORDER BY 1, 2, 5;
