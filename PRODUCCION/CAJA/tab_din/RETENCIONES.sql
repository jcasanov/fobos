SELECT CASE WHEN j14_localidad = 1 THEN "GYE (J T M)"
	    WHEN j14_localidad = 2 THEN "GYE CENTRO"
	    WHEN j14_localidad = 3 THEN "UIO-MATRIZ"
	    WHEN j14_localidad = 4 THEN "ACERO SUR"
	    WHEN j14_localidad = 5 THEN "ACERO KOHLER"
	END AS loc,
	YEAR(j14_fecha_emi) AS anio,
	CASE WHEN MONTH(j14_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(j14_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(j14_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(j14_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(j14_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(j14_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(j14_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(j14_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(j14_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j14_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j14_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j14_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS mes,
	r38_num_sri AS num_sri_f,
	(SELECT a.g37_autorizacion
		FROM gent037 a, gent039
		WHERE a.g37_compania   = r38_compania
		  AND a.g37_localidad  = r38_localidad
		  AND a.g37_tipo_doc   = r38_tipo_doc
		  AND a.g37_secuencia IN
			(SELECT MAX(b.g37_secuencia)
                                FROM gent037 b
                                WHERE b.g37_compania  = a.g37_compania
                                  AND b.g37_localidad = a.g37_localidad
                                  AND b.g37_tipo_doc  = a.g37_tipo_doc)
		  AND g39_compania     = a.g37_compania
		  AND g39_localidad    = a.g37_localidad
		  AND g39_tipo_doc     = a.g37_tipo_doc
		  AND g39_secuencia    = a.g37_secuencia
		  AND g39_num_sri_ini <= CAST(r38_num_sri[9, 21] AS INTEGER)
		  AND g39_num_sri_fin >= CAST(r38_num_sri[9, 21] AS INTEGER))
	AS aut_sri_f,
	DATE(r19_fecing) AS fec_fac,
	j14_num_ret_sri AS num_sri_r,
	j14_autorizacion AS aut_sri_r,
	j14_fecha_emi AS fec_ret,
	r19_cedruc AS ruc_emp,
	r19_nomcli AS raz_soc,
	j14_base_imp AS bas_ret,
	(j14_porc_ret / 100) AS porc_ret,
	j14_valor_ret AS val_ret
	FROM cajt014, rept019, rept038
	WHERE j14_compania         = 1
	  AND j14_localidad        = 1
	  AND YEAR(j14_fecha_emi) >= 2010
	  AND j14_tipo_fue         = "PR"
	  AND r19_compania         = j14_compania
	  AND r19_localidad        = j14_localidad
	  AND r19_cod_tran         = j14_cod_tran
	  AND r19_num_tran         = j14_num_tran
	  AND r38_compania         = r19_compania
	  AND r38_localidad        = r19_localidad
	  AND r38_tipo_fuente      = j14_tipo_fue
	  AND r38_cod_tran         = r19_cod_tran
	  AND r38_num_tran         = r19_num_tran
UNION
SELECT CASE WHEN j14_localidad = 1 THEN "GYE (J T M)"
	    WHEN j14_localidad = 2 THEN "GYE CENTRO"
	    WHEN j14_localidad = 3 THEN "UIO-MATRIZ"
	    WHEN j14_localidad = 4 THEN "ACERO SUR"
	    WHEN j14_localidad = 5 THEN "ACERO KOHLER"
	END AS loc,
	YEAR(j14_fecha_emi) AS anio,
	CASE WHEN MONTH(j14_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(j14_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(j14_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(j14_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(j14_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(j14_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(j14_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(j14_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(j14_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j14_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j14_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j14_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS mes,
	r38_num_sri AS num_sri_f,
	(SELECT a.g37_autorizacion
		FROM gent037 a, gent039
		WHERE a.g37_compania   = r38_compania
		  AND a.g37_localidad  = r38_localidad
		  AND a.g37_tipo_doc   = r38_tipo_doc
		  AND a.g37_secuencia IN
			(SELECT MAX(b.g37_secuencia)
                                FROM gent037 b
                                WHERE b.g37_compania  = a.g37_compania
                                  AND b.g37_localidad = a.g37_localidad
                                  AND b.g37_tipo_doc  = a.g37_tipo_doc)
		  AND g39_compania     = a.g37_compania
		  AND g39_localidad    = a.g37_localidad
		  AND g39_tipo_doc     = a.g37_tipo_doc
		  AND g39_secuencia    = a.g37_secuencia
		  AND g39_num_sri_ini <= CAST(r38_num_sri[9, 21] AS INTEGER)
		  AND g39_num_sri_fin >= CAST(r38_num_sri[9, 21] AS INTEGER))
	AS aut_sri_f,
	DATE(t23_fec_factura) AS fec_fac,
	j14_num_ret_sri AS num_sri_r,
	j14_autorizacion AS aut_sri_r,
	j14_fecha_emi AS fec_ret,
	t23_cedruc AS ruc_emp,
	t23_nom_cliente AS raz_soc,
	j14_base_imp AS bas_ret,
	(j14_porc_ret / 100) AS porc_ret,
	j14_valor_ret AS val_ret
	FROM cajt014, talt023, rept038
	WHERE j14_compania         = 1
	  AND j14_localidad        = 1
	  AND YEAR(j14_fecha_emi) >= 2010
	  AND j14_tipo_fue         = "OT"
	  AND t23_compania         = j14_compania
	  AND t23_localidad        = j14_localidad
	  AND t23_num_factura      = j14_num_tran
	  AND t23_estado          IN ("F", "D")
	  AND r38_compania         = t23_compania
	  AND r38_localidad        = t23_localidad
	  AND r38_tipo_fuente      = j14_tipo_fue
	  AND r38_cod_tran         = "FA"
	  AND r38_num_tran         = t23_num_factura
UNION
SELECT CASE WHEN j14_localidad = 1 THEN "GYE (J T M)"
	    WHEN j14_localidad = 2 THEN "GYE CENTRO"
	    WHEN j14_localidad = 3 THEN "UIO-MATRIZ"
	    WHEN j14_localidad = 4 THEN "ACERO SUR"
	    WHEN j14_localidad = 5 THEN "ACERO KOHLER"
	END AS loc,
	YEAR(j14_fecha_emi) AS anio,
	CASE WHEN MONTH(j14_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(j14_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(j14_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(j14_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(j14_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(j14_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(j14_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(j14_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(j14_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j14_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j14_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j14_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS mes,
	r38_num_sri AS num_sri_f,
	(SELECT a.g37_autorizacion
		FROM acero_gc@acgyede:gent037 a, acero_gc@acgyede:gent039
		WHERE a.g37_compania   = r38_compania
		  AND a.g37_localidad  = r38_localidad
		  AND a.g37_tipo_doc   = r38_tipo_doc
		  AND a.g37_secuencia IN
			(SELECT MAX(b.g37_secuencia)
                                FROM acero_gc@acgyede:gent037 b
                                WHERE b.g37_compania  = a.g37_compania
                                  AND b.g37_localidad = a.g37_localidad
                                  AND b.g37_tipo_doc  = a.g37_tipo_doc)
		  AND g39_compania     = a.g37_compania
		  AND g39_localidad    = a.g37_localidad
		  AND g39_tipo_doc     = a.g37_tipo_doc
		  AND g39_secuencia    = a.g37_secuencia
		  AND g39_num_sri_ini <= CAST(r38_num_sri[9, 21] AS INTEGER)
		  AND g39_num_sri_fin >= CAST(r38_num_sri[9, 21] AS INTEGER))
	AS aut_sri_f,
	DATE(r19_fecing) AS fec_fac,
	j14_num_ret_sri AS num_sri_r,
	j14_autorizacion AS aut_sri_r,
	j14_fecha_emi AS fec_ret,
	r19_cedruc AS ruc_emp,
	r19_nomcli AS raz_soc,
	j14_base_imp AS bas_ret,
	(j14_porc_ret / 100) AS porc_ret,
	j14_valor_ret AS val_ret
	FROM acero_gc@acgyede:cajt014, acero_gc@acgyede:rept019,
		acero_gc@acgyede:rept038
	WHERE j14_compania         = 1
	  AND j14_localidad        = 2
	  AND YEAR(j14_fecha_emi) >= 2010
	  AND j14_tipo_fue         = "PR"
	  AND r19_compania         = j14_compania
	  AND r19_localidad        = j14_localidad
	  AND r19_cod_tran         = j14_cod_tran
	  AND r19_num_tran         = j14_num_tran
	  AND r38_compania         = r19_compania
	  AND r38_localidad        = r19_localidad
	  AND r38_tipo_fuente      = j14_tipo_fue
	  AND r38_cod_tran         = r19_cod_tran
	  AND r38_num_tran         = r19_num_tran
UNION
SELECT CASE WHEN j14_localidad = 1 THEN "GYE (J T M)"
	    WHEN j14_localidad = 2 THEN "GYE CENTRO"
	    WHEN j14_localidad = 3 THEN "UIO-MATRIZ"
	    WHEN j14_localidad = 4 THEN "ACERO SUR"
	    WHEN j14_localidad = 5 THEN "ACERO KOHLER"
	END AS loc,
	YEAR(j14_fecha_emi) AS anio,
	CASE WHEN MONTH(j14_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(j14_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(j14_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(j14_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(j14_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(j14_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(j14_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(j14_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(j14_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j14_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j14_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j14_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS mes,
	r38_num_sri AS num_sri_f,
	(SELECT a.g37_autorizacion
		FROM acero_qm@acgyede:gent037 a, acero_qm@acgyede:gent039
		WHERE a.g37_compania   = r38_compania
		  AND a.g37_localidad  = r38_localidad
		  AND a.g37_tipo_doc   = r38_tipo_doc
		  AND a.g37_secuencia IN
			(SELECT MAX(b.g37_secuencia)
                                FROM acero_qm@acgyede:gent037 b
                                WHERE b.g37_compania  = a.g37_compania
                                  AND b.g37_localidad = a.g37_localidad
                                  AND b.g37_tipo_doc  = a.g37_tipo_doc)
		  AND g39_compania     = a.g37_compania
		  AND g39_localidad    = a.g37_localidad
		  AND g39_tipo_doc     = a.g37_tipo_doc
		  AND g39_secuencia    = a.g37_secuencia
		  AND g39_num_sri_ini <= CAST(r38_num_sri[9, 21] AS INTEGER)
		  AND g39_num_sri_fin >= CAST(r38_num_sri[9, 21] AS INTEGER))
	AS aut_sri_f,
	DATE(r19_fecing) AS fec_fac,
	j14_num_ret_sri AS num_sri_r,
	j14_autorizacion AS aut_sri_r,
	j14_fecha_emi AS fec_ret,
	r19_cedruc AS ruc_emp,
	r19_nomcli AS raz_soc,
	j14_base_imp AS bas_ret,
	(j14_porc_ret / 100) AS porc_ret,
	j14_valor_ret AS val_ret
	FROM acero_qm@acgyede:cajt014, acero_qm@acgyede:rept019,
		acero_qm@acgyede:rept038
	WHERE j14_compania         = 1
	  AND j14_localidad       IN (3, 4, 5)
	  AND YEAR(j14_fecha_emi) >= 2010
	  AND j14_tipo_fue         = "PR"
	  AND r19_compania         = j14_compania
	  AND r19_localidad        = j14_localidad
	  AND r19_cod_tran         = j14_cod_tran
	  AND r19_num_tran         = j14_num_tran
	  AND r38_compania         = r19_compania
	  AND r38_localidad        = r19_localidad
	  AND r38_tipo_fuente      = j14_tipo_fue
	  AND r38_cod_tran         = r19_cod_tran
	  AND r38_num_tran         = r19_num_tran
UNION
SELECT CASE WHEN j14_localidad = 1 THEN "GYE (J T M)"
	    WHEN j14_localidad = 2 THEN "GYE CENTRO"
	    WHEN j14_localidad = 3 THEN "UIO-MATRIZ"
	    WHEN j14_localidad = 4 THEN "ACERO SUR"
	    WHEN j14_localidad = 5 THEN "ACERO KOHLER"
	END AS loc,
	YEAR(j14_fecha_emi) AS anio,
	CASE WHEN MONTH(j14_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(j14_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(j14_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(j14_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(j14_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(j14_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(j14_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(j14_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(j14_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j14_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j14_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j14_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS mes,
	r38_num_sri AS num_sri_f,
	(SELECT a.g37_autorizacion
		FROM acero_qm@acgyede:gent037 a, acero_qm@acgyede:gent039
		WHERE a.g37_compania   = r38_compania
		  AND a.g37_localidad  = r38_localidad
		  AND a.g37_tipo_doc   = r38_tipo_doc
		  AND a.g37_secuencia IN
			(SELECT MAX(b.g37_secuencia)
                                FROM acero_qm@acgyede:gent037 b
                                WHERE b.g37_compania  = a.g37_compania
                                  AND b.g37_localidad = a.g37_localidad
                                  AND b.g37_tipo_doc  = a.g37_tipo_doc)
		  AND g39_compania     = a.g37_compania
		  AND g39_localidad    = a.g37_localidad
		  AND g39_tipo_doc     = a.g37_tipo_doc
		  AND g39_secuencia    = a.g37_secuencia
		  AND g39_num_sri_ini <= CAST(r38_num_sri[9, 21] AS INTEGER)
		  AND g39_num_sri_fin >= CAST(r38_num_sri[9, 21] AS INTEGER))
	AS aut_sri_f,
	DATE(t23_fec_factura) AS fec_fac,
	j14_num_ret_sri AS num_sri_r,
	j14_autorizacion AS aut_sri_r,
	j14_fecha_emi AS fec_ret,
	t23_cedruc AS ruc_emp,
	t23_nom_cliente AS raz_soc,
	j14_base_imp AS bas_ret,
	(j14_porc_ret / 100) AS porc_ret,
	j14_valor_ret AS val_ret
	FROM acero_qm@acgyede:cajt014, acero_qm@acgyede:talt023,
		acero_qm@acgyede:rept038
	WHERE j14_compania         = 1
	  AND j14_localidad        = 3
	  AND YEAR(j14_fecha_emi) >= 2010
	  AND j14_tipo_fue         = "OT"
	  AND t23_compania         = j14_compania
	  AND t23_localidad        = j14_localidad
	  AND t23_num_factura      = j14_num_tran
	  AND t23_estado          IN ("F", "D")
	  AND r38_compania         = t23_compania
	  AND r38_localidad        = t23_localidad
	  AND r38_tipo_fuente      = j14_tipo_fue
	  AND r38_cod_tran         = "FA"
	  AND r38_num_tran         = t23_num_factura
UNION
SELECT CASE WHEN j14_localidad = 1 THEN "GYE (J T M)"
	    WHEN j14_localidad = 2 THEN "GYE CENTRO"
	    WHEN j14_localidad = 3 THEN "UIO-MATRIZ"
	    WHEN j14_localidad = 4 THEN "ACERO SUR"
	    WHEN j14_localidad = 5 THEN "ACERO KOHLER"
	END AS loc,
	YEAR(j14_fecha_emi) AS anio,
	CASE WHEN MONTH(j14_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(j14_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(j14_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(j14_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(j14_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(j14_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(j14_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(j14_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(j14_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j14_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j14_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j14_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS mes,
	r38_num_sri AS num_sri_f,
	(SELECT a.g37_autorizacion
		FROM acero_qs@acgyede:gent037 a, acero_qs@acgyede:gent039
		WHERE a.g37_compania   = r38_compania
		  AND a.g37_localidad  = r38_localidad
		  AND a.g37_tipo_doc   = r38_tipo_doc
		  AND a.g37_secuencia IN
			(SELECT MAX(b.g37_secuencia)
                                FROM acero_qs@acgyede:gent037 b
                                WHERE b.g37_compania  = a.g37_compania
                                  AND b.g37_localidad = a.g37_localidad
                                  AND b.g37_tipo_doc  = a.g37_tipo_doc)
		  AND g39_compania     = a.g37_compania
		  AND g39_localidad    = a.g37_localidad
		  AND g39_tipo_doc     = a.g37_tipo_doc
		  AND g39_secuencia    = a.g37_secuencia
		  AND g39_num_sri_ini <= CAST(r38_num_sri[9, 21] AS INTEGER)
		  AND g39_num_sri_fin >= CAST(r38_num_sri[9, 21] AS INTEGER))
	AS aut_sri_f,
	DATE(r19_fecing) AS fec_fac,
	j14_num_ret_sri AS num_sri_r,
	j14_autorizacion AS aut_sri_r,
	j14_fecha_emi AS fec_ret,
	r19_cedruc AS ruc_emp,
	r19_nomcli AS raz_soc,
	j14_base_imp AS bas_ret,
	(j14_porc_ret / 100) AS porc_ret,
	j14_valor_ret AS val_ret
	FROM acero_qs@acgyede:cajt014, acero_qs@acgyede:rept019,
		acero_qs@acgyede:rept038
	WHERE j14_compania         = 1
	  AND j14_localidad        = 4
	  AND YEAR(j14_fecha_emi) >= 2010
	  AND j14_tipo_fue         = "PR"
	  AND r19_compania         = j14_compania
	  AND r19_localidad        = j14_localidad
	  AND r19_cod_tran         = j14_cod_tran
	  AND r19_num_tran         = j14_num_tran
	  AND r38_compania         = r19_compania
	  AND r38_localidad        = r19_localidad
	  AND r38_tipo_fuente      = j14_tipo_fue
	  AND r38_cod_tran         = r19_cod_tran
	  AND r38_num_tran         = r19_num_tran;
