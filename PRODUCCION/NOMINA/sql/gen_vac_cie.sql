SELECT a.n32_compania cia, a.n32_cod_trab cod_trab, MDY(MONTH(n30_fecha_ing),
	DAY(n30_fecha_ing), YEAR(TODAY) - 1) per_ini, MDY(MONTH(n30_fecha_ing),
	DAY(n30_fecha_ing), YEAR(TODAY)) per_fin, 1 sec, a.n32_fecha_ini -
	1 UNITS YEAR fec_ini_re, (((a.n32_fecha_ini - 1 UNITS YEAR) +
	1 UNITS YEAR) - 1 UNITS DAY) fec_fin_re, 'G' tipo, 'A' est,
	n30_cod_depto dp, n30_fecha_ing fec_ing, n00_dias_vacac d_v,
	CASE WHEN (MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing), YEAR(TODAY)))
	    >= (n30_fecha_ing + (n00_ano_adi_vac - 1) UNITS YEAR - 1 UNITS DAY)
		THEN
		CASE WHEN (n00_dias_vacac + ((YEAR(MDY(MONTH(n30_fecha_ing),
			DAY(n30_fecha_ing), YEAR(TODAY))) -
			YEAR(n30_fecha_ing + (n00_ano_adi_vac - 1) UNITS YEAR -
			1 UNITS DAY)) * n00_dias_adi_va)) > n00_max_vacac
			THEN n00_max_vacac - n00_dias_vacac
			ELSE ((YEAR(MDY(MONTH(n30_fecha_ing),
				DAY(n30_fecha_ing), YEAR(TODAY))) -
				YEAR(n30_fecha_ing + (n00_ano_adi_vac - 1)
				UNITS YEAR - 1 UNITS DAY)) * n00_dias_adi_va)
		END
		ELSE 0
	END d_a,
	0 d_g, '' fec_ini_v, '' fec_fin_v, n30_mon_sueldo mo, 1 par, 'E' pago,
	'' bco, '' cta, '' cta_t, 'S' goza, 'FOBOS' usua, EXTEND(CURRENT,
	YEAR TO SECOND) fec_i
	FROM rolt032 a, rolt030, rolt000
	WHERE a.n32_compania   = 1
	  AND a.n32_cod_liqrol IN('Q1', 'Q2')
	  AND a.n32_estado     = 'C'
	  AND a.n32_fecha_fin  = (SELECT MAX(b.n32_fecha_fin)
					FROM rolt032 b
					WHERE b.n32_compania = a.n32_compania
		  			  AND b.n32_estado   = 'C')
	  AND n30_compania     = a.n32_compania
	  AND n30_cod_trab     = a.n32_cod_trab
	  AND EXTEND(n30_fecha_ing, MONTH TO DAY)
		BETWEEN EXTEND(a.n32_fecha_ini, MONTH TO DAY)
		    AND EXTEND(a.n32_fecha_fin, MONTH TO DAY)
	  AND NOT EXISTS(SELECT * FROM rolt039
			 WHERE n39_compania     = a.n32_compania
			   AND n39_cod_trab     = a.n32_cod_trab
			   AND n39_perini_real >= a.n32_fecha_ini - 1 UNITS YEAR
			   AND n39_perfin_real <= a.n32_fecha_fin)
	  AND n00_serial       = n30_compania
	INTO TEMP t1;
select count(*) from t1;
SELECT cia, cod_trab, per_ini, per_fin, sec, fec_ini_re, fec_fin_re, tipo, est,
	dp, fec_ing, d_v, d_a, d_g, fec_ini_v, fec_fin_v, mo, par,
	NVL(SUM(n32_tot_gan), 0) tot_gan,(NVL(SUM(n32_tot_gan),0) / (360 / d_v))
	val_vac,(((NVL(SUM(n32_tot_gan),0) / (360 / d_v)) / d_v) * d_a) val_adi,
	0.00 ot_i, 0.00 iess, 0.00 ot_e, 0.00 neto, pago, bco, cta, cta_t,goza,
	usua, fec_i, n13_porc_trab porc
	FROM t1, rolt032, rolt030, rolt013
	WHERE n32_compania    = cia
	  AND n32_cod_liqrol IN('Q1', 'Q2')
	  AND n32_fecha_ini  >= fec_ini_re
	  AND n32_fecha_fin  <= fec_fin_re
	  AND n32_cod_trab    = cod_trab
	  AND n32_estado      = 'C'
	  AND n30_compania    = n32_compania
	  AND n30_cod_trab    = n32_cod_trab
	  AND n13_cod_seguro  = n30_cod_seguro
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,18,
		22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33
	INTO TEMP t2;
drop table t1;
--select * from t2;
SELECT cia, cod_trab, per_ini, per_fin, sec, fec_ini_re, fec_fin_re, tipo, est,
	dp, fec_ing, d_v, d_a, d_g, fec_ini_v, fec_fin_v, mo, par, tot_gan,
	round(val_vac, 2) val_vac, round(val_adi, 2) val_adi, ot_i,
	round((((val_vac + val_adi) * porc) / 100), 2) iess, ot_e,
	round((round(val_vac, 2) + round(val_adi, 2) + ot_i - round((((val_vac
	+ val_adi) * porc) / 100), 2) - ot_e), 2) neto, pago, bco, cta, cta_t,
	goza, usua, fec_i
	FROM t2
	INTO TEMP tmp_rol;
drop table t2;
select * from tmp_rol;
drop table tmp_rol;
