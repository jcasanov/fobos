SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(r19_fecing) AS anio,
	CASE WHEN MONTH(r19_fecing) = 01 THEN "01 ENERO"
	     WHEN MONTH(r19_fecing) = 02 THEN "02 FEBRERO"
	     WHEN MONTH(r19_fecing) = 03 THEN "03 MARZO"
	     WHEN MONTH(r19_fecing) = 04 THEN "04 ABRIL"
	     WHEN MONTH(r19_fecing) = 05 THEN "05 MAYO"
	     WHEN MONTH(r19_fecing) = 06 THEN "06 JUNIO"
	     WHEN MONTH(r19_fecing) = 07 THEN "07 JULIO"
	     WHEN MONTH(r19_fecing) = 08 THEN "08 AGOSTO"
	     WHEN MONTH(r19_fecing) = 09 THEN "09 SEPTIEMBRE"
	     WHEN MONTH(r19_fecing) = 10 THEN "10 OCTUBRE"
	     WHEN MONTH(r19_fecing) = 11 THEN "11 NOVIEMBRE"
	     WHEN MONTH(r19_fecing) = 12 THEN "12 DICIEMBRE"
	END AS meses,
	r19_cod_tran AS cod_tr,
	r19_num_tran AS num_tr,
	r19_codcli AS codcli,
	r19_nomcli AS nomcli,
	(SELECT r01_nombres
		FROM rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS vendedor,
	CASE WHEN r19_cont_cred = 'C'
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS forma_pago,
	DATE(r19_fecing) AS fecha_fact,
	(r19_tot_bruto - r19_tot_dscto) AS subtotal,
	r19_tot_dscto AS descuento,
	r19_tot_neto AS neto_fact,
	r19_tot_neto AS saldo_fact,
	"" AS tip_pag,
	0 AS num_pag,
	DATE(r19_fecing) AS fecha_pago,
	r19_tot_neto AS valor_pago,
	r19_tipo_dev AS cod_df,
	r19_num_dev AS num_df
	FROM rept019, cajt010, cajt011
	WHERE r19_compania      = 1
	  AND r19_localidad     = 1
	  AND r19_cod_tran      = 'FA'
	  AND r19_codcli       <> 101
	  AND r19_cont_cred     = 'C'
	  AND YEAR(r19_fecing) >= 2007
	  AND j10_compania      = r19_compania
	  AND j10_localidad     = r19_localidad
	  AND j10_tipo_fuente   = 'PR'
	  AND j10_tipo_destino  = r19_cod_tran
	  AND j10_num_destino   = r19_num_tran
	  AND j11_compania      = j10_compania
	  AND j11_localidad     = j10_localidad
	  AND j11_tipo_fuente   = j10_tipo_fuente
	  AND j11_num_fuente    = j10_num_fuente
	  AND j11_codigo_pago  <> 'TJ'
UNION
SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(r19_fecing) AS anio,
	CASE WHEN MONTH(r19_fecing) = 01 THEN "01 ENERO"
	     WHEN MONTH(r19_fecing) = 02 THEN "02 FEBRERO"
	     WHEN MONTH(r19_fecing) = 03 THEN "03 MARZO"
	     WHEN MONTH(r19_fecing) = 04 THEN "04 ABRIL"
	     WHEN MONTH(r19_fecing) = 05 THEN "05 MAYO"
	     WHEN MONTH(r19_fecing) = 06 THEN "06 JUNIO"
	     WHEN MONTH(r19_fecing) = 07 THEN "07 JULIO"
	     WHEN MONTH(r19_fecing) = 08 THEN "08 AGOSTO"
	     WHEN MONTH(r19_fecing) = 09 THEN "09 SEPTIEMBRE"
	     WHEN MONTH(r19_fecing) = 10 THEN "10 OCTUBRE"
	     WHEN MONTH(r19_fecing) = 11 THEN "11 NOVIEMBRE"
	     WHEN MONTH(r19_fecing) = 12 THEN "12 DICIEMBRE"
	END AS meses,
	r19_cod_tran AS cod_tr,
	r19_num_tran AS num_tr,
	r19_codcli AS codcli,
	r19_nomcli AS nomcli,
	(SELECT r01_nombres
		FROM rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS vendedor,
	CASE WHEN r19_cont_cred = 'C'
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS forma_pago,
	DATE(r19_fecing) AS fecha_fact,
	(r19_tot_bruto - r19_tot_dscto) AS subtotal,
	r19_tot_dscto AS descuento,
	r19_tot_neto AS neto_fact,
	NVL((z20_saldo_cap + z20_saldo_int), 0) saldo_fact,
	z22_tipo_trn AS tip_pag,
	z22_num_trn AS num_pag,
	DATE(z22_fecing) AS fecha_pago,
	(z23_valor_cap + z23_valor_int) AS valor_pago,
	r19_tipo_dev AS cod_df,
	r19_num_dev AS num_df
	FROM rept019, cxct020, cxct023, cxct022
	WHERE r19_compania      = 1
	  AND r19_localidad     = 1
	  AND r19_cod_tran      = 'FA'
	  AND r19_codcli       <> 101
	  AND YEAR(r19_fecing) >= 2007
	  AND z20_compania      = r19_compania
	  AND z20_localidad     = r19_localidad
	  AND z20_cod_tran      = r19_cod_tran
	  AND z20_num_tran      = r19_num_tran
	  AND z23_compania      = z20_compania
	  AND z23_localidad     = z20_localidad
	  AND z23_codcli        = z20_codcli
	  AND z23_tipo_doc      = z20_tipo_doc
	  AND z23_num_doc       = z20_num_doc
	  AND z23_div_doc       = z20_dividendo
	  AND z22_compania      = z23_compania
	  AND z22_localidad     = z23_localidad
	  AND z22_codcli        = z23_codcli
	  AND z22_tipo_trn      = z23_tipo_trn
	  AND z22_num_trn       = z23_num_trn
UNION
SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(r19_fecing) AS anio,
	CASE WHEN MONTH(r19_fecing) = 01 THEN "01 ENERO"
	     WHEN MONTH(r19_fecing) = 02 THEN "02 FEBRERO"
	     WHEN MONTH(r19_fecing) = 03 THEN "03 MARZO"
	     WHEN MONTH(r19_fecing) = 04 THEN "04 ABRIL"
	     WHEN MONTH(r19_fecing) = 05 THEN "05 MAYO"
	     WHEN MONTH(r19_fecing) = 06 THEN "06 JUNIO"
	     WHEN MONTH(r19_fecing) = 07 THEN "07 JULIO"
	     WHEN MONTH(r19_fecing) = 08 THEN "08 AGOSTO"
	     WHEN MONTH(r19_fecing) = 09 THEN "09 SEPTIEMBRE"
	     WHEN MONTH(r19_fecing) = 10 THEN "10 OCTUBRE"
	     WHEN MONTH(r19_fecing) = 11 THEN "11 NOVIEMBRE"
	     WHEN MONTH(r19_fecing) = 12 THEN "12 DICIEMBRE"
	END AS meses,
	r19_cod_tran AS cod_tr,
	r19_num_tran AS num_tr,
	r19_codcli AS codcli,
	r19_nomcli AS nomcli,
	(SELECT r01_nombres
		FROM rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS vendedor,
	CASE WHEN r19_cont_cred = 'C'
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS forma_pago,
	DATE(r19_fecing) AS fecha_fact,
	(r19_tot_bruto - r19_tot_dscto) AS subtotal,
	r19_tot_dscto AS descuento,
	r19_tot_neto AS neto_fact,
	r19_tot_neto AS saldo_fact,
	z22_tipo_trn AS tip_pag,
	z22_num_trn AS num_pag,
	DATE(z22_fecing) AS fecha_pago,
	(z23_valor_cap + z23_valor_int) AS valor_pago,
	r19_tipo_dev AS cod_df,
	r19_num_dev AS num_df
	FROM rept019, cxct021, cxct023, cxct022
	WHERE r19_compania      = 1
	  AND r19_localidad     = 1
	  AND r19_cod_tran     IN ('DF', 'AF')
	  AND r19_codcli       <> 101
	  AND YEAR(r19_fecing) >= 2007
	  AND z21_compania      = r19_compania
	  AND z21_localidad     = r19_localidad
	  AND z21_cod_tran      = r19_cod_tran
	  AND z21_num_tran      = r19_num_tran
	  AND z23_compania      = z21_compania
	  AND z23_localidad     = z21_localidad
	  AND z23_codcli        = z21_codcli
	  AND z23_tipo_favor    = z21_tipo_doc
	  AND z23_doc_favor     = z21_num_doc
	  AND z22_compania      = z23_compania
	  AND z22_localidad     = z23_localidad
	  AND z22_codcli        = z23_codcli
	  AND z22_tipo_trn      = z23_tipo_trn
	  AND z22_num_trn       = z23_num_trn
	ORDER BY 2 ASC, 3 ASC, 10 ASC, 17 DESC;
{
	into temp t1;
select localidad, anio, meses, cod_tr, num_tr, codcli, nomcli, vendedor,
	forma_pago, fecha_fact, subtotal, descuento, neto_fact,
	count(*) tot_reg
	-- tip_pag, num_pag, fecha_pago, valor_pago
	from t1
	where forma_pago = 'CONTADO'
	group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
	having count(*) > 1;
drop table t1;
}
