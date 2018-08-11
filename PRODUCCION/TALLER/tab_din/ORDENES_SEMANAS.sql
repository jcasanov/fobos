SELECT g02_nombre AS local,
	YEAR(t23_fec_cierre) AS anio,
	fp_numero_semana(DATE(t23_fec_cierre)) AS num_sem,
	"ORDENES CERRADAS" AS tipo,
	t23_orden AS orden
	FROM acero_gm@idsgye01:talt023, acero_gm@idsgye01:gent002
	WHERE t23_compania  = 1
	  AND t23_localidad = 1
	  AND t23_estado    = "C"
	  AND g02_compania  = t23_compania
	  AND g02_localidad = t23_localidad
UNION ALL
SELECT g02_nombre AS local,
	YEAR(t23_fec_cierre) AS anio,
	fp_numero_semana(DATE(t23_fec_cierre)) AS num_sem,
	"ORDENES CERRADAS" AS tipo,
	t23_orden AS orden
	FROM acero_qm@idsuio01:talt023, acero_qm@idsuio01:gent002
	WHERE t23_compania  = 1
	  AND t23_localidad = 3
	  AND t23_estado    = "C"
	  AND g02_compania  = t23_compania
	  AND g02_localidad = t23_localidad
UNION ALL
SELECT g02_nombre AS local,
	YEAR(CASE WHEN NVL(DATE(t23_fec_cierre), 0)  <> 0 THEN t23_fec_cierre
	     WHEN NVL(DATE(t23_fec_factura), 0) <> 0 THEN t23_fec_factura
	     WHEN NVL(DATE(t23_fec_elimin), 0)  <> 0 THEN t23_fec_elimin
	END - 1 UNITS DAY) AS anio,
	fp_numero_semana(
	CASE WHEN NVL(DATE(t23_fec_cierre), 0)  <> 0 THEN DATE(t23_fec_cierre)
	     WHEN NVL(DATE(t23_fec_factura), 0) <> 0 THEN DATE(t23_fec_factura)
	     WHEN NVL(DATE(t23_fec_elimin), 0)  <> 0 THEN DATE(t23_fec_elimin)
	END - 1 UNITS DAY) AS num_sem,
	"ORDENES ABIERTAS" AS tipo,
	t23_orden AS orden
	FROM acero_qm@idsuio01:talt023, acero_qm@idsuio01:gent002
	WHERE t23_compania   = 1
	  AND t23_localidad  = 3
	  AND t23_estado    IN ("F", "C", "E")
	  AND g02_compania   = t23_compania
	  AND g02_localidad  = t23_localidad
UNION ALL
SELECT g02_nombre AS local,
	YEAR(CASE WHEN NVL(DATE(t23_fec_cierre), 0)  <> 0 THEN t23_fec_cierre
	     WHEN NVL(DATE(t23_fec_factura), 0) <> 0 THEN t23_fec_factura
	     WHEN NVL(DATE(t23_fec_elimin), 0)  <> 0 THEN t23_fec_elimin
	END - 1 UNITS DAY) AS anio,
	fp_numero_semana(
	CASE WHEN NVL(DATE(t23_fec_cierre), 0)  <> 0 THEN DATE(t23_fec_cierre)
	     WHEN NVL(DATE(t23_fec_factura), 0) <> 0 THEN DATE(t23_fec_factura)
	     WHEN NVL(DATE(t23_fec_elimin), 0)  <> 0 THEN DATE(t23_fec_elimin)
	END - 1 UNITS DAY) AS num_sem,
	"ORDENES ABIERTAS" AS tipo,
	t23_orden AS orden
	FROM acero_gm@idsgye01:talt023, acero_gm@idsgye01:gent002
	WHERE t23_compania   = 1
	  AND t23_localidad  = 1
	  AND t23_estado    IN ("F", "C", "E")
	  AND g02_compania   = t23_compania
	  AND g02_localidad  = t23_localidad
UNION ALL
SELECT g02_nombre AS local,
	YEAR(TODAY) AS anio,
	fp_numero_semana(TODAY) AS num_sem,
	"ORDENES ACTIVAS" AS tipo,
	t23_orden AS orden
	FROM acero_gm@idsgye01:talt023, acero_gm@idsgye01:gent002
	WHERE t23_compania  = 1
	  AND t23_localidad = 1
	  AND t23_estado    = "A"
	  AND g02_compania  = t23_compania
	  AND g02_localidad = t23_localidad
UNION ALL
SELECT g02_nombre AS local,
	YEAR(TODAY) AS anio,
	fp_numero_semana(TODAY) AS num_sem,
	"ORDENES ACTIVAS" AS tipo,
	t23_orden AS orden
	FROM acero_qm@idsuio01:talt023, acero_qm@idsuio01:gent002
	WHERE t23_compania  = 1
	  AND t23_localidad = 3
	  AND t23_estado    = "A"
	  AND g02_compania  = t23_compania
	  AND g02_localidad = t23_localidad
