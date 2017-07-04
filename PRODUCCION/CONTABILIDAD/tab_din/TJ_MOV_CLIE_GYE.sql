SELECT YEAR(j10_fecha_pro) AS anio,
	CASE WHEN MONTH(j10_fecha_pro) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecha_pro) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecha_pro) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecha_pro) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecha_pro) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecha_pro) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecha_pro) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecha_pro) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecha_pro) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecha_pro) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 12 THEN "DICIEMBRE"
	END AS mes,
	NVL(TO_CHAR(j10_fecha_pro, "%Y-%m-%d"), "") AS fec_pro,
	CASE WHEN j10_tipo_fuente = "PR" THEN "FACTURA INVENTARIO"
	     WHEN j10_tipo_fuente = "OT" THEN "FACTURA TALLER"
	     WHEN j10_tipo_fuente = "SC" THEN "SOLICITUD COBRO"
	     WHEN j10_tipo_fuente = "OI" THEN "OTROS INGRESOS"
	END AS tip_fue,
	j10_codcli AS codcli,
	j10_nomcli AS nomcli,
	j10_codigo_caja AS codcaj,
	(SELECT j02_nombre_caja
		FROM cajt002
		WHERE j02_compania    = j10_compania
		  AND j02_localidad   = j10_localidad
		  AND j02_codigo_caja = j10_codigo_caja) AS nomcaj,
	j10_tipo_destino AS codtran,
	CAST(j10_num_destino AS INTEGER) AS numtran,
	"REGISTRO DESDE CAJA" AS refer,
	NVL(j10_tip_contable || "-" || j10_num_contable,
		NVL((SELECT r40_tipo_comp || "-" || r40_num_comp
			FROM rept040, ctbt012
			WHERE r40_compania  = j10_compania
			  AND r40_localidad = j10_localidad
			  AND r40_cod_tran  = j10_tipo_destino
			  AND r40_num_tran  = j10_num_destino
			  AND b12_compania  = r40_compania
			  AND b12_tipo_comp = r40_tipo_comp
			  AND b12_num_comp  = r40_num_comp
			  AND b12_subtipo   = 8),
		(SELECT t50_tipo_comp || "-" || t50_num_comp
			FROM talt050, ctbt012
			WHERE t50_compania  = j10_compania
			  AND t50_localidad = j10_localidad
			  AND t50_orden     = j10_num_fuente
			  AND t50_factura   = j10_num_destino
			  AND b12_compania  = t50_compania
			  AND b12_tipo_comp = t50_tipo_comp
			  AND b12_num_comp  = t50_num_comp
			  AND b12_subtipo   = 41))) AS diari,
	j11_cod_bco_tarj AS cod_tj,
	(SELECT g10_nombre
		FROM acero_gm@idsgye01:gent010
		WHERE g10_compania = j11_compania
		  AND g10_tarjeta  = j11_cod_bco_tarj
		  AND g10_cod_tarj = j11_codigo_pago) AS nom_tj,
	j11_num_cta_tarj AS num_tj,
	NVL(SUM(j11_valor), 0.00) AS val_deb,
	0.00 AS val_cre,
	NVL(SUM(j11_valor), 0.00) AS sald
	FROM acero_gm@idsgye01:cajt011,
		acero_gm@idsgye01:cajt010
	WHERE j11_compania     = 1
	  AND j11_localidad   IN (1, 2)
	  AND j11_codigo_pago  = "TJ"
	  AND j10_compania     = j11_compania
	  AND j10_localidad    = j11_localidad
	  AND j10_tipo_fuente  = j11_tipo_fuente
	  AND j10_num_fuente   = j11_num_fuente
	  AND j10_estado       = "P"
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 17
UNION
SELECT YEAR(b12_fec_proceso) AS anio,
	CASE WHEN MONTH(b12_fec_proceso) = 01 THEN "ENERO"
	     WHEN MONTH(b12_fec_proceso) = 02 THEN "FEBRERO"
	     WHEN MONTH(b12_fec_proceso) = 03 THEN "MARZO"
	     WHEN MONTH(b12_fec_proceso) = 04 THEN "ABRIL"
	     WHEN MONTH(b12_fec_proceso) = 05 THEN "MAYO"
	     WHEN MONTH(b12_fec_proceso) = 06 THEN "JUNIO"
	     WHEN MONTH(b12_fec_proceso) = 07 THEN "JULIO"
	     WHEN MONTH(b12_fec_proceso) = 08 THEN "AGOSTO"
	     WHEN MONTH(b12_fec_proceso) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(b12_fec_proceso) = 10 THEN "OCTUBRE"
	     WHEN MONTH(b12_fec_proceso) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(b12_fec_proceso) = 12 THEN "DICIEMBRE"
	END AS mes,
	NVL(TO_CHAR(b12_fec_proceso, "%Y-%m-%d"), "") AS fec_pro,
	CASE WHEN z22_tipo_trn = "PG"
		THEN "PAGOS"
		ELSE "AJUSTES"
	END AS tip_fue,
	CASE WHEN z20_tipo_doc = "FA" AND z20_areaneg = 1
		THEN (SELECT CAST(r19_codcli AS SMALLINT)
			FROM acero_gm@idsgye01:rept019
			WHERE r19_compania  = z20_compania
			  AND r19_localidad = z20_localidad
			  AND r19_cod_tran  = z20_cod_tran
			  AND r19_num_tran  = z20_num_tran)
	     WHEN z20_tipo_doc = "FA" AND z20_areaneg = 2
		THEN (SELECT CAST(t23_cod_cliente AS SMALLINT)
			FROM acero_gm@idsgye01:talt023
			WHERE t23_compania    = z20_compania
			  AND t23_localidad   = z20_localidad
			  AND t23_num_factura = z20_num_tran)
		ELSE 0
	END AS codcli,
	CASE WHEN z20_tipo_doc = "FA" AND z20_areaneg = 1
		THEN (SELECT r19_nomcli
			FROM acero_gm@idsgye01:rept019
			WHERE r19_compania  = z20_compania
			  AND r19_localidad = z20_localidad
			  AND r19_cod_tran  = z20_cod_tran
			  AND r19_num_tran  = z20_num_tran)
	     WHEN z20_tipo_doc = "FA" AND z20_areaneg = 2
		THEN (SELECT t23_nom_cliente
			FROM acero_gm@idsgye01:talt023
			WHERE t23_compania    = z20_compania
			  AND t23_localidad   = z20_localidad
			  AND t23_num_factura = z20_num_tran)
		ELSE ""
	END AS nomcli,
	0 AS codcaj,
	z22_usuario AS nomcaj,
	z22_tipo_trn AS codtran,
	z22_num_trn AS numtran,
	z22_referencia AS refer,
	(z40_tipo_comp || "-" || z40_num_comp) AS diari,
	CAST(z20_codcli AS SMALLINT) AS cod_tj,
	z01_nomcli AS nom_tj,
	"" AS num_tj,
	0.00 AS val_deb,
	NVL(SUM((a.z23_valor_cap + a.z23_valor_int)), 0.00) AS val_cre,
	NVL(SUM((a.z23_valor_cap + a.z23_valor_int)), 0.00) AS sald
	FROM acero_gm@idsgye01:gent010,
		acero_gm@idsgye01:cxct020,
		acero_gm@idsgye01:cxct001,
		acero_gm@idsgye01:cxct023 a,
		acero_gm@idsgye01:cxct022 b,
		acero_gm@idsgye01:cxct040,
		acero_gm@idsgye01:ctbt012
	WHERE g10_compania    = 1
	  AND z20_compania    = g10_compania
	  AND z20_codcli      = g10_codcobr
	  AND z01_codcli      = z20_codcli
	  AND a.z23_compania  = z20_compania
	  AND a.z23_localidad = z20_localidad
	  AND a.z23_codcli    = z20_codcli
	  AND a.z23_tipo_doc  = z20_tipo_doc
	  AND a.z23_num_doc   = z20_num_doc
	  AND a.z23_div_doc   = z20_dividendo
	  AND b.z22_compania  = a.z23_compania
	  AND b.z22_localidad = a.z23_localidad
	  AND b.z22_codcli    = a.z23_codcli
	  AND b.z22_tipo_trn  = a.z23_tipo_trn
	  AND b.z22_num_trn   = a.z23_num_trn
	  AND z40_compania    = b.z22_compania
	  AND z40_localidad   = b.z22_localidad
	  AND z40_codcli      = b.z22_codcli
	  AND z40_tipo_doc    = b.z22_tipo_trn
	  AND z40_num_doc     = b.z22_num_trn
	  AND b12_compania    = z40_compania
	  AND b12_tipo_comp   = z40_tipo_comp
	  AND b12_num_comp    = z40_num_comp
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16;
