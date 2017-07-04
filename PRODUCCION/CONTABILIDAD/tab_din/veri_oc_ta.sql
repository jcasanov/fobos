SELECT b12_compania AS cia,
	b12_tipo_comp AS tp,
	b12_num_comp AS num,
	b12_origen AS origen,
	CASE WHEN a.b13_valor_base > 0
		THEN a.b13_valor_base
		ELSE 0.00
	END AS debito,
	CASE WHEN a.b13_valor_base < 0
		THEN a.b13_valor_base
		ELSE 0.00
	END AS credito
	FROM ctbt012, ctbt013 a
	WHERE b12_compania           = 1
	  AND b12_estado             = 'M'
	  AND YEAR(b12_fec_proceso) <= 2011
	  AND a.b13_compania         = b12_compania
	  AND a.b13_tipo_comp        = b12_tipo_comp
	  AND a.b13_num_comp         = b12_num_comp
	  AND a.b13_cuenta           = '11400102003'
	INTO TEMP t1;
SELECT b13_tipo_comp AS tp2,
	b13_num_comp AS num2,
	origen AS origen2,
	a.b13_cuenta AS cta,
	CASE WHEN a.b13_valor_base > 0
		THEN a.b13_valor_base
		ELSE 0.00
	END AS debito2,
	CASE WHEN a.b13_valor_base < 0
		THEN a.b13_valor_base
		ELSE 0.00
	END AS credito2
	FROM t1, ctbt013 a
	WHERE a.b13_compania     = cia
	  AND a.b13_tipo_comp    = tp
	  AND a.b13_num_comp     = num
	  AND a.b13_cuenta[1, 8] = '61010102'
	INTO TEMP t2;
SELECT origen, SUM(debito) AS tot_deb, SUM(credito) AS tot_cre,
	SUM(debito + credito) AS saldo
	FROM t1
	GROUP BY 1
	ORDER BY 1;
SELECT SUM(debito) AS tot_deb, SUM(credito) AS tot_cre,
	SUM(debito + credito) AS saldo
	FROM t1;
SELECT SUM(debito2) AS tot_deb, SUM(credito2) AS tot_cre,
	SUM(debito2 + credito2) AS saldo
	FROM t2;
SELECT cta, SUM(debito2) AS tot_deb, SUM(credito2) AS tot_cre,
	SUM(debito2 + credito2) AS saldo
	FROM t2
	GROUP BY 1
	ORDER BY 1;
DELETE FROM t1
	WHERE EXISTS
		(SELECT t2.tp2, t2.num2
			FROM t2
			WHERE t2.tp2  = t1.tp
			  AND t2.num2 = t1.num);
{--
SELECT tp, num, origen, debito, credito
	FROM t1
	ORDER BY 1, 2;
--}
SELECT SUM(debito) AS tot_deb, SUM(credito) AS tot_cre,
	SUM(debito + credito) AS saldo
	FROM t1;
DROP TABLE t1;
DROP TABLE t2;
