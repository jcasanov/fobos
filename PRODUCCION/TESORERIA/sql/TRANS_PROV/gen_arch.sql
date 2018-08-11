SELECT "BZDET" AS tip_arch, LPAD(p01_codprov, 18, 0) AS codprov,
	p01_tipo_doc AS tip_d_id, RPAD(p01_num_doc, 14, " ") AS num_d_id,
	RPAD(p01_nomprov[1, 60], 60, " ") AS nomprov, "COB" AS for_pag,
	"001" AS codpais, RPAD(p02_cod_bco_tra, 2, " ") AS cod_bco,
	CASE WHEN p02_tip_cta_prov = "C" THEN "03"
	     WHEN p02_tip_cta_prov = "A" THEN "04"
		ELSE "  "
	END AS tip_cta,
	LPAD(p02_cta_prov, 10, 0) AS numcta, "1" AS codmon,
	REPLACE(REPLACE(LPAD(p23_valor_cap, 16, 0), ".", ""),
		"-", "0") AS val_pago, "+@." AS concep,
	LPAD(REPLACE(TRIM(c13_num_guia), "-", ""), 15, 0) AS num_com,
	NVL((SELECT LPAD(REPLACE(p29_num_sri, "-", ""), 15 +
			(15 - LENGTH(REPLACE(p29_num_sri, "-", ""))), 0)
		FROM cxpt028, cxpt027, cxpt029
		WHERE p28_compania  = p20_compania
		  AND p28_localidad = p20_localidad
		  AND p28_codprov   = p20_codprov
		  AND p28_tipo_doc  = p20_tipo_doc
		  AND p28_num_doc   = p20_num_doc
		  AND p28_dividendo = 1
		  AND p28_secuencia = 1
		  AND p28_tipo_ret  = "F"
		  AND p27_compania  = p28_compania
		  AND p27_localidad = p28_localidad
		  AND p27_num_ret   = p28_num_ret
		  AND p27_estado    = "A"
		  AND p29_compania  = p27_compania
		  AND p29_localidad = p27_localidad
		  AND p29_num_ret   = p27_num_ret), 0) AS numcompret,
	NVL((SELECT LPAD(REPLACE(p29_num_sri, "-", ""), 15, 0)
		FROM cxpt028, cxpt027, cxpt029
		WHERE p28_compania  = p20_compania
		  AND p28_localidad = p20_localidad
		  AND p28_codprov   = p20_codprov
		  AND p28_tipo_doc  = p20_tipo_doc
		  AND p28_num_doc   = p20_num_doc
		  AND p28_dividendo = 1
		  AND p28_secuencia = 1
		  AND p28_tipo_ret  = "I"
		  AND p27_compania  = p28_compania
		  AND p27_localidad = p28_localidad
		  AND p27_num_ret   = p28_num_ret
		  AND p27_estado    = "A"
		  AND p29_compania  = p27_compania
		  AND p29_localidad = p27_localidad
		  AND p29_num_ret   = p27_num_ret), 0) AS numcompiva,
	LPAD(REPLACE(TRIM(c13_factura), "-", ""), 15 +
	(20 - LENGTH(REPLACE(TRIM(c13_factura), "-", ""))), 0) AS num_fac,
	"       +@." AS cod_gr,
	"                                               +@." AS des_gr,
	RPAD(p01_direccion1[1, 60], 61, " ") AS dirprov,
	RPAD(p01_telefono1, 10 + (20 - LENGTH(p01_telefono1)), " ") AS telprov,
	"PRO" AS cod_serv, LPAD(c13_num_aut, 10, " ") AS autoriz,
	LPAD(REPLACE(TO_CHAR(c13_fecha_cadu, "%Y/%m/%d") || "", "/", ""),
	10, " ") AS fec_validez, "       +@." AS referen, "N" AS cont_hor_ate,
	04607 AS codempbco, "   +@." AS codsub_empbco, "RPA" AS sub_mot_pag
	FROM cxpt022, cxpt023, cxpt020, cxpt002, cxpt001, ordt010, ordt013
	WHERE p22_compania   = 1
	  AND p22_localidad  = 3
	  AND p22_tipo_trn   = "PG"
	  AND p22_orden_pago = 31540
	  AND p23_compania   = p22_compania
	  AND p23_localidad  = p22_localidad
	  AND p23_codprov    = p22_codprov
	  AND p23_tipo_trn   = p22_tipo_trn
	  AND p23_num_trn    = p22_num_trn
	  AND p20_compania   = p23_compania
	  AND p20_localidad  = p23_localidad
	  AND p20_codprov    = p23_codprov
	  AND p20_tipo_doc   = p23_tipo_doc
	  AND p20_num_doc    = p23_num_doc
	  AND p20_dividendo  = p23_div_doc
	  AND p02_compania   = p20_compania
	  AND p02_localidad  = p20_localidad
	  AND p02_codprov    = p20_codprov
	  AND p01_codprov    = p02_codprov
	  AND c10_compania   = p20_compania
	  AND c10_localidad  = p20_localidad
	  AND c10_numero_oc  = p20_numero_oc
	  AND c13_compania   = c10_compania
	  AND c13_localidad  = c10_localidad
	  AND c13_numero_oc  = c10_numero_oc
	  AND c13_estado     = "A";
