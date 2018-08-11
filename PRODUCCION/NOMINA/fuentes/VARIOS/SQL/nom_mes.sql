SELECT * FROM rolt033
        WHERE n33_compania    = 1
          AND n33_cod_liqrol IN ("Q1", "Q2")
          AND n33_fecha_ini  >= "07/01/2011"
          AND n33_fecha_fin  <= "07/31/2011"
          AND n33_cant_valor  = "V"
          AND n33_valor       > 0
        INTO TEMP tmp_n33;
SELECT a.n32_ano_proceso AS anio, a.n32_mes_proceso AS mes,
	n30_cod_trab, n30_nombres,
	CASE WHEN NVL(SUM((SELECT SUM(n33_valor)
			FROM tmp_n33
			WHERE n33_compania   = a.n32_compania
			  AND n33_fecha_ini  = a.n32_fecha_ini
			  AND n33_fecha_fin  = a.n32_fecha_fin
			  AND n33_cod_trab   = a.n32_cod_trab
			  AND n33_cod_rubro IN
				(SELECT n06_cod_rubro
				FROM rolt006
				WHERE n06_flag_ident IN ("VT", "VV",
					"OV", "VE", "SX")))), 0) >=
					NVL(SUM(a.n32_sueldo /
					(SELECT COUNT(*)
					FROM rolt032 b
				WHERE b.n32_compania    = a.n32_compania
				  AND b.n32_ano_proceso = a.n32_ano_proceso
				  AND b.n32_mes_proceso = a.n32_mes_proceso
				  AND b.n32_cod_trab    = a.n32_cod_trab)),0)
 THEN NVL(SUM(a.n32_sueldo / (SELECT COUNT(*) FROM rolt032 b
 WHERE b.n32_compania    = a.n32_compania
   AND b.n32_ano_proceso = a.n32_ano_proceso
   AND b.n32_mes_proceso = a.n32_mes_proceso
   AND b.n32_cod_trab    = a.n32_cod_trab)), 0)
 ELSE NVL(SUM((SELECT SUM(n33_valor)
 FROM tmp_n33
 WHERE n33_compania   = a.n32_compania
   AND n33_fecha_ini  = a.n32_fecha_ini
   AND n33_fecha_fin  = a.n32_fecha_fin
   AND n33_cod_trab   = a.n32_cod_trab
   AND n33_cod_rubro IN
 (SELECT n06_cod_rubro FROM rolt006
 WHERE n06_flag_ident IN ("VT", "VV", "OV", "VE", "SX")))), 0) END AS val1,
(SUM(NVL((SELECT SUM(n33_valor) FROM tmp_n33
 WHERE n33_compania    = a.n32_compania
   AND n33_cod_liqrol  = a.n32_cod_liqrol
   AND n33_fecha_ini   = a.n32_fecha_ini
   AND n33_fecha_fin   = a.n32_fecha_fin
   AND n33_cod_trab    = a.n32_cod_trab
   AND n33_cod_rubro  IN
 (SELECT n08_rubro_base FROM rolt008
 WHERE n08_cod_rubro = 
(SELECT n06_cod_rubro FROM rolt006 WHERE n06_flag_ident = "AP"))), 0)) -
 CASE WHEN NVL(SUM((SELECT SUM(n33_valor) FROM tmp_n33
 WHERE n33_compania   = a.n32_compania
   AND n33_fecha_ini  = a.n32_fecha_ini
   AND n33_fecha_fin  = a.n32_fecha_fin
   AND n33_cod_trab   = a.n32_cod_trab
   AND n33_cod_rubro
 IN (SELECT n06_cod_rubro FROM rolt006
 WHERE n06_flag_ident IN ("VT", "VV", "OV", "VE", "SX")))), 0) >=
 NVL(SUM(a.n32_sueldo / (SELECT COUNT(*) FROM rolt032 b
 WHERE b.n32_compania    = a.n32_compania
   AND b.n32_ano_proceso = a.n32_ano_proceso
   AND b.n32_mes_proceso = a.n32_mes_proceso
   AND b.n32_cod_trab    = a.n32_cod_trab)),0)
 THEN NVL(SUM(a.n32_sueldo / (SELECT COUNT(*) FROM rolt032 b
		 WHERE b.n32_compania    = a.n32_compania
  AND b.n32_ano_proceso = a.n32_ano_proceso
  AND b.n32_mes_proceso = a.n32_mes_proceso
  AND b.n32_cod_trab    = a.n32_cod_trab)), 0)
 ELSE NVL(SUM((SELECT SUM(n33_valor) FROM tmp_n33
 WHERE n33_compania   = a.n32_compania
  AND n33_fecha_ini  = a.n32_fecha_ini
   AND n33_fecha_fin  = a.n32_fecha_fin
   AND n33_cod_trab   = a.n32_cod_trab 
  AND n33_cod_rubro IN
 (SELECT n06_cod_rubro FROM rolt006
 WHERE n06_flag_ident IN ("VT", "VV", "OV", "VE", "SX")))), 0) END) AS val2,
 SUM(NVL((SELECT SUM(n33_valor) FROM tmp_n33
 WHERE n33_compania    = a.n32_compania
   AND n33_cod_liqrol  = a.n32_cod_liqrol
   AND n33_fecha_ini   = a.n32_fecha_ini
   AND n33_fecha_fin   = a.n32_fecha_fin
   AND n33_cod_trab    = a.n32_cod_trab
   AND n33_cod_rubro  IN
 (SELECT n08_rubro_base FROM rolt008
 WHERE n08_cod_rubro =
 (SELECT n06_cod_rubro FROM rolt006
 WHERE n06_flag_ident = "AP"))), 0)) AS val3,
 n30_estado, SUM(NVL((SELECT SUM(n33_valor) FROM tmp_n33
 WHERE n33_compania    = a.n32_compania
   AND n33_cod_liqrol  = a.n32_cod_liqrol
   AND n33_fecha_ini   = a.n32_fecha_ini
   AND n33_fecha_fin   = a.n32_fecha_fin
   AND n33_cod_trab    = a.n32_cod_trab
   AND n33_cod_rubro  IN (SELECT n06_cod_rubro FROM rolt006
 WHERE n06_flag_ident = "AP")
   AND n33_det_tot     = "DE"), 0)) AS val4,
 SUM(NVL((SELECT SUM(n33_valor) FROM tmp_n33
 WHERE n33_compania    = a.n32_compania
   AND n33_cod_liqrol  = a.n32_cod_liqrol
   AND n33_fecha_ini   = a.n32_fecha_ini
   AND n33_fecha_fin   = a.n32_fecha_fin
   AND n33_cod_trab    = a.n32_cod_trab
   AND n33_cod_rubro  IN
 (SELECT n08_rubro_base FROM rolt008
 WHERE n08_cod_rubro =
 (SELECT n06_cod_rubro FROM rolt006 WHERE n06_flag_ident = "AP"))), 0) *
 (SELECT n13_porc_cia / 100 FROM rolt013
	 WHERE n13_cod_seguro = n30_cod_seguro)) AS val5,
 (SUM(NVL((SELECT SUM(n33_valor) FROM tmp_n33
 WHERE n33_compania    = a.n32_compania
   AND n33_cod_liqrol  = a.n32_cod_liqrol
   AND n33_fecha_ini   = a.n32_fecha_ini
   AND n33_fecha_fin   = a.n32_fecha_fin
   AND n33_cod_trab    = a.n32_cod_trab
   AND n33_cod_rubro  IN
 (SELECT n06_cod_rubro FROM rolt006 WHERE n06_flag_ident = "AP")
   AND n33_det_tot     = "DE"), 0)) +
	SUM(NVL((SELECT SUM(n33_valor) FROM tmp_n33
	 WHERE n33_compania    = a.n32_compania
	   AND n33_cod_liqrol  = a.n32_cod_liqrol
	   AND n33_fecha_ini   = a.n32_fecha_ini
	   AND n33_fecha_fin   = a.n32_fecha_fin
	   AND n33_cod_trab    = a.n32_cod_trab
	   AND n33_cod_rubro  IN
		 (SELECT n08_rubro_base FROM rolt008
			 WHERE n08_cod_rubro =
				 (SELECT n06_cod_rubro FROM rolt006
					 WHERE n06_flag_ident = "AP"))), 0) *
		 (SELECT n13_porc_cia / 100 FROM rolt013
			 WHERE n13_cod_seguro = n30_cod_seguro))) AS val6,
		NVL(SUM(n32_tot_ing), 0) val7, NVL(SUM(n32_tot_egr), 0) val8,
	 NVL(SUM(n32_tot_neto), 0) val9
	FROM rolt032 a, rolt030
	WHERE a.n32_compania    = 1
	  AND a.n32_cod_liqrol IN ("Q1", "Q2")
	  AND a.n32_fecha_ini  >= "07/01/2011"
	  AND a.n32_fecha_fin  <= "07/31/2011"
	  AND a.n32_estado     <> "E"
	  AND n30_compania      = a.n32_compania
	  AND n30_cod_trab      = a.n32_cod_trab
and n30_cod_trab = 143
	GROUP BY 1, 2, 3, 4, 8;
drop table tmp_n33;
