SELECT (SELECT LPAD(1, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = b12_compania
		  AND g02_localidad = 1) AS local,
	YEAR(b12_fec_proceso) AS anio,
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
	b12_tipo_comp AS tipo_comp,
	b12_num_comp AS num_comp,
	b12_glosa AS glo_cab,
	b13_glosa AS glo_det,
	b12_fecing AS fecha_cont,
	NVL(b12_fec_modifi, "") AS fecha_modif,
	b13_cuenta AS cuenta,
	b10_descripcion AS nombre_cuenta,
	NVL((SELECT p01_nomprov
		FROM cxpt001
		WHERE p01_codprov = b13_codprov), "") AS prov,
	NVL((SELECT p01_num_doc
		FROM cxpt001
		WHERE p01_codprov = b13_codprov), "") AS cedruc,
	(b13_valor_base * (-1)) AS valor_ret,
	CASE WHEN b12_origen = "A"
		THEN "AUTOMATICO"
		ELSE "MANUAL"
	END AS orig,
	NVL((SELECT UNIQUE p28_num_doc
		FROM cxpt027, cxpt028
		WHERE p27_compania     = b12_compania
		  AND p27_tip_contable = b12_tipo_comp
		  AND p27_num_contable = b12_num_comp
		  AND p27_estado       = "A"
		  AND p27_compania     = p28_compania
		  AND p27_localidad    = p28_localidad
		  AND p27_num_ret      = p28_num_ret), "") AS fact,
	NVL((SELECT DATE(p27_fecing)
		FROM cxpt027
		WHERE p27_compania     = b12_compania
		  AND p27_tip_contable = b12_tipo_comp
		  AND p27_num_contable = b12_num_comp
		  AND p27_estado       = "A"), "") AS fec_rec,
	NVL((SELECT UNIQUE c13_num_aut
		FROM cxpt027, cxpt028, cxpt020, ordt013
		WHERE p27_compania     = b12_compania
		  AND p27_tip_contable = b12_tipo_comp
		  AND p27_num_contable = b12_num_comp
		  AND p27_estado       = "A"
		  AND p27_compania     = p28_compania
		  AND p27_localidad    = p28_localidad
		  AND p27_num_ret      = p28_num_ret
		  AND p20_compania     = p28_compania
		  AND p20_localidad    = p28_localidad
		  AND p20_codprov      = p28_codprov
		  AND p20_tipo_doc     = p28_tipo_doc
		  AND p20_num_doc      = p28_num_doc
		  AND p20_dividendo    = p28_dividendo
		  AND c13_compania     = p20_compania
		  AND c13_localidad    = p20_localidad
		  AND c13_numero_oc    = p20_numero_oc
		  AND c13_estado       = "A"), "") AS num_aut,
	NVL((SELECT UNIQUE p20_valor_fact - p20_valor_impto
		FROM cxpt027, cxpt028, cxpt020
		WHERE p27_compania     = b12_compania
		  AND p27_tip_contable = b12_tipo_comp
		  AND p27_num_contable = b12_num_comp
		  AND p27_estado       = "A"
		  AND p27_compania     = p28_compania
		  AND p27_localidad    = p28_localidad
		  AND p27_num_ret      = p28_num_ret
		  AND p20_compania     = p28_compania
		  AND p20_localidad    = p28_localidad
		  AND p20_codprov      = p28_codprov
		  AND p20_tipo_doc     = p28_tipo_doc
		  AND p20_num_doc      = p28_num_doc
		  AND p20_dividendo    = p28_dividendo), "") AS val_rec,
	NVL((SELECT UNIQUE p20_valor_impto
		FROM cxpt027, cxpt028, cxpt020
		WHERE p27_compania     = b12_compania
		  AND p27_tip_contable = b12_tipo_comp
		  AND p27_num_contable = b12_num_comp
		  AND p27_estado       = "A"
		  AND p27_compania     = p28_compania
		  AND p27_localidad    = p28_localidad
		  AND p27_num_ret      = p28_num_ret
		  AND p20_compania     = p28_compania
		  AND p20_localidad    = p28_localidad
		  AND p20_codprov      = p28_codprov
		  AND p20_tipo_doc     = p28_tipo_doc
		  AND p20_num_doc      = p28_num_doc
		  AND p20_dividendo    = p28_dividendo), "") AS val_iva,
	NVL((SELECT MAX(p20_fecha_vcto)
		FROM cxpt027, cxpt028, cxpt020
		WHERE p27_compania     = b12_compania
		  AND p27_tip_contable = b12_tipo_comp
		  AND p27_num_contable = b12_num_comp
		  AND p27_estado       = "A"
		  AND p27_compania     = p28_compania
		  AND p27_localidad    = p28_localidad
		  AND p27_num_ret      = p28_num_ret
		  AND p20_compania     = p28_compania
		  AND p20_localidad    = p28_localidad
		  AND p20_codprov      = p28_codprov
		  AND p20_tipo_doc     = p28_tipo_doc
		  AND p20_num_doc      = p28_num_doc
		  AND p20_dividendo    = p28_dividendo), "") AS fec_vcto,
	NVL((SELECT UNIQUE s23_sustento_sri
		FROM srit023
		WHERE s23_compania  = b10_compania
		  AND s23_aux_cont  = b10_cuenta), "") AS cod_sus
	FROM ctbt012, ctbt013, ctbt010
	WHERE b12_compania           = 1
	  AND b12_estado             = "M"
	  AND YEAR(b12_fec_proceso)  > 2012
	  AND b13_compania           = b12_compania 
	  AND b13_tipo_comp          = b12_tipo_comp 
	  AND b13_num_comp           = b12_num_comp 
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
	  AND b10_cuenta            IN
		(SELECT c02_aux_cont
			FROM ordt002
			WHERE c02_compania = b13_compania
			  AND c02_estado   = "A")
UNION
SELECT (SELECT LPAD(3, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm:gent002
		WHERE g02_compania  = b12_compania
		  AND g02_localidad = 3) AS local,
	YEAR(b12_fec_proceso) AS anio,
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
	b12_tipo_comp AS tipo_comp,
	b12_num_comp AS num_comp,
	b12_glosa AS glo_cab,
	b13_glosa AS glo_det,
	b12_fecing AS fecha_cont,
	NVL(b12_fec_modifi, "") AS fecha_modif,
	b13_cuenta AS cuenta,
	b10_descripcion AS nombre_cuenta,
	NVL((SELECT p01_nomprov
		FROM acero_qm:cxpt001
		WHERE p01_codprov = b13_codprov), "") AS prov,
	NVL((SELECT p01_num_doc
		FROM acero_qm:cxpt001
		WHERE p01_codprov = b13_codprov), "") AS cedruc,
	(b13_valor_base * (-1)) AS valor_ret,
	CASE WHEN b12_origen = "A"
		THEN "AUTOMATICO"
		ELSE "MANUAL"
	END AS orig,
	NVL((SELECT UNIQUE p28_num_doc
		FROM acero_qm:cxpt027, acero_qm:cxpt028
		WHERE p27_compania     = b12_compania
		  AND p27_tip_contable = b12_tipo_comp
		  AND p27_num_contable = b12_num_comp
		  AND p27_estado       = "A"
		  AND p27_compania     = p28_compania
		  AND p27_localidad    = p28_localidad
		  AND p27_num_ret      = p28_num_ret), "") AS fact,
	NVL((SELECT DATE(p27_fecing)
		FROM acero_qm:cxpt027
		WHERE p27_compania     = b12_compania
		  AND p27_tip_contable = b12_tipo_comp
		  AND p27_num_contable = b12_num_comp
		  AND p27_estado       = "A"), "") AS fec_rec,
	NVL((SELECT UNIQUE c13_num_aut
		FROM acero_qm:cxpt027, acero_qm:cxpt028, acero_qm:cxpt020,
			acero_qm:ordt013
		WHERE p27_compania     = b12_compania
		  AND p27_tip_contable = b12_tipo_comp
		  AND p27_num_contable = b12_num_comp
		  AND p27_estado       = "A"
		  AND p27_compania     = p28_compania
		  AND p27_localidad    = p28_localidad
		  AND p27_num_ret      = p28_num_ret
		  AND p20_compania     = p28_compania
		  AND p20_localidad    = p28_localidad
		  AND p20_codprov      = p28_codprov
		  AND p20_tipo_doc     = p28_tipo_doc
		  AND p20_num_doc      = p28_num_doc
		  AND p20_dividendo    = p28_dividendo
		  AND c13_compania     = p20_compania
		  AND c13_localidad    = p20_localidad
		  AND c13_numero_oc    = p20_numero_oc
		  AND c13_estado       = "A"), "") AS num_aut,
	NVL((SELECT UNIQUE p20_valor_fact - p20_valor_impto
		FROM acero_qm:cxpt027, acero_qm:cxpt028, acero_qm:cxpt020
		WHERE p27_compania     = b12_compania
		  AND p27_tip_contable = b12_tipo_comp
		  AND p27_num_contable = b12_num_comp
		  AND p27_estado       = "A"
		  AND p27_compania     = p28_compania
		  AND p27_localidad    = p28_localidad
		  AND p27_num_ret      = p28_num_ret
		  AND p20_compania     = p28_compania
		  AND p20_localidad    = p28_localidad
		  AND p20_codprov      = p28_codprov
		  AND p20_tipo_doc     = p28_tipo_doc
		  AND p20_num_doc      = p28_num_doc
		  AND p20_dividendo    = p28_dividendo), "") AS val_rec,
	NVL((SELECT UNIQUE p20_valor_impto
		FROM acero_qm:cxpt027, acero_qm:cxpt028, acero_qm:cxpt020
		WHERE p27_compania     = b12_compania
		  AND p27_tip_contable = b12_tipo_comp
		  AND p27_num_contable = b12_num_comp
		  AND p27_estado       = "A"
		  AND p27_compania     = p28_compania
		  AND p27_localidad    = p28_localidad
		  AND p27_num_ret      = p28_num_ret
		  AND p20_compania     = p28_compania
		  AND p20_localidad    = p28_localidad
		  AND p20_codprov      = p28_codprov
		  AND p20_tipo_doc     = p28_tipo_doc
		  AND p20_num_doc      = p28_num_doc
		  AND p20_dividendo    = p28_dividendo), "") AS val_iva,
	NVL((SELECT MAX(p20_fecha_vcto)
		FROM acero_qm:cxpt027, acero_qm:cxpt028, acero_qm:cxpt020
		WHERE p27_compania     = b12_compania
		  AND p27_tip_contable = b12_tipo_comp
		  AND p27_num_contable = b12_num_comp
		  AND p27_estado       = "A"
		  AND p27_compania     = p28_compania
		  AND p27_localidad    = p28_localidad
		  AND p27_num_ret      = p28_num_ret
		  AND p20_compania     = p28_compania
		  AND p20_localidad    = p28_localidad
		  AND p20_codprov      = p28_codprov
		  AND p20_tipo_doc     = p28_tipo_doc
		  AND p20_num_doc      = p28_num_doc
		  AND p20_dividendo    = p28_dividendo), "") AS fec_vcto,
	NVL((SELECT UNIQUE s23_sustento_sri
		FROM acero_qm:srit023
		WHERE s23_compania  = b10_compania
		  AND s23_aux_cont  = b10_cuenta), "") AS cod_sus
	FROM acero_qm:ctbt012, acero_qm:ctbt013, acero_qm:ctbt010
	WHERE b12_compania           = 1
	  AND b12_estado             = "M"
	  AND YEAR(b12_fec_proceso)  > 2012
	  AND b13_compania           = b12_compania 
	  AND b13_tipo_comp          = b12_tipo_comp 
	  AND b13_num_comp           = b12_num_comp 
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
	  AND b10_cuenta            IN
		(SELECT c02_aux_cont
			FROM acero_qm:ordt002
			WHERE c02_compania = b13_compania
			  AND c02_estado   = "A");
