SELECT MDY(03, 01, 2010) fec_ini,
	MDY(03, DAY(MDY(03, 01, 2010) + 1 UNITS MONTH - 1 UNITS DAY),
	2010) fec_fin
	FROM dual
	INTO TEMP fec_act;

SELECT * FROM rolt033
	WHERE n33_compania    = 1
	  AND n33_cod_liqrol IN ("Q1", "Q2")
	  AND n33_fecha_ini  >= (SELECT fec_ini FROM fec_act)
	  AND n33_fecha_fin  <= (SELECT fec_fin FROM fec_act)
	  AND n33_det_tot     = "DI"
	  AND n33_cant_valor  = "V"
	  AND n33_valor       > 0
	INTO TEMP tmp_n33;

SELECT "1790008959001" ruc, "0009" sucursal,
	(SELECT YEAR(fec_fin) FROM fec_act) anio,
	LPAD((SELECT MONTH(fec_fin) FROM fec_act), 2, 0) mes,
	"INS" tipo, n30_num_doc_id cedula,
	(SUM(NVL((SELECT SUM(n33_valor)
		FROM tmp_n33
		WHERE n33_compania    = a.n32_compania
		  AND n33_cod_liqrol  = a.n32_cod_liqrol
		  AND n33_fecha_ini   = a.n32_fecha_ini
		  AND n33_fecha_fin   = a.n32_fecha_fin
		  AND n33_cod_trab    = a.n32_cod_trab
		  AND n33_cod_rubro  IN
			(SELECT n08_rubro_base
			FROM rolt008
			WHERE n08_cod_rubro =
				(SELECT n06_cod_rubro
				FROM rolt006
				WHERE n06_flag_ident = "AP"))), 0)) -
	CASE WHEN NVL(SUM((SELECT SUM(n33_valor)
			FROM tmp_n33
			WHERE n33_compania   = a.n32_compania
			  AND n33_fecha_ini  = a.n32_fecha_ini
			  AND n33_fecha_fin  = a.n32_fecha_fin
			  AND n33_cod_trab   = a.n32_cod_trab
			  AND n33_cod_rubro  IN
				(SELECT n06_cod_rubro
				FROM rolt006
				WHERE n06_flag_ident IN
					("VT", "VV", "OV", "VE", "SX")))), 0) >=
			NVL(SUM(a.n32_sueldo /
				(SELECT COUNT(*)
				 FROM rolt032 b
				 WHERE b.n32_compania    = a.n32_compania
				   AND b.n32_ano_proceso = a.n32_ano_proceso
				   AND b.n32_mes_proceso = a.n32_mes_proceso
				   AND b.n32_cod_trab    = a.n32_cod_trab)),0)
		THEN NVL(SUM(a.n32_sueldo /
			 (SELECT COUNT(*)
			 FROM rolt032 b
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
			  AND n33_cod_rubro  IN
				(SELECT n06_cod_rubro
				FROM rolt006
				WHERE n06_flag_ident IN
					("VT", "VV", "OV", "VE", "SX")))), 0)
	END) AS valor_ext,
	(SELECT n23_tipo_causa
		FROM rolt023
		WHERE n23_compania    = g02_compania
		  AND n23_codigo_arch = 2
		  AND n23_tipo_arch   = "INS"
		  AND n23_flag_ident  = "AP") causa,
	n30_cod_trab, n30_nombres
	FROM rolt032 a, rolt030, gent002
	WHERE a.n32_compania    = 1
	  AND a.n32_cod_liqrol IN ("Q1", "Q2")
	  AND a.n32_fecha_ini  >= (SELECT fec_ini FROM fec_act)
	  AND a.n32_fecha_fin  <= (SELECT fec_fin FROM fec_act)
	  AND a.n32_estado     <> "E"
	  AND n30_compania      = a.n32_compania
	  AND n30_cod_trab      = a.n32_cod_trab
	  AND g02_compania      = n30_compania
	  AND g02_localidad     = 1
	GROUP BY 1, 2, 3, 4, 5, 6, 8, 9, 10
	INTO TEMP t1;

DROP TABLE fec_act;
DROP TABLE tmp_n33;

DELETE FROM t1 WHERE valor_ext <= 0;

SELECT ruc, sucursal, anio, mes, tipo, cedula, valor_ext, causa
	FROM t1
	INTO TEMP t2;

SELECT n30_cod_trab n33_cod_trab, cedula, n30_nombres, valor_ext valor
	FROM t1
	INTO TEMP t3;

DROP TABLE t1;

SELECT * FROM t3
	INTO TEMP t1;

DROP TABLE t3;

SELECT COUNT(*) tot_reg FROM t1;

SELECT n33_cod_trab cod, cedula, n30_nombres[1, 32] empleados,
	ROUND(valor, 2) valor
	FROM t1
	ORDER BY n30_nombres;

DROP TABLE t1;
DROP TABLE t2;
