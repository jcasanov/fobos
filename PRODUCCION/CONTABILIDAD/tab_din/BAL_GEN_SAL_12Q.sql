SELECT b10_compania AS cia, b10_cuenta AS cta, "DO" AS mon, b10_nivel AS nivel
	FROM ctbt010
	WHERE b10_compania = 1
	  AND b10_tipo_cta = "B"
	INTO TEMP tmp_cta;

SELECT * FROM ctbt013
	WHERE b13_compania          = 1
	  AND YEAR(b13_fec_proceso) = 2012
	  AND EXISTS
		(SELECT 1 FROM tmp_cta
			WHERE cia = b13_compania
			  AND cta = b13_cuenta)
	INTO TEMP tmp_b13;

SELECT cia, b13_cuenta AS cta_mov, mon, 2013 AS anio, 6 AS nive,
	ROUND(SUM(CASE WHEN b13_valor_base >= 0 THEN
			b13_valor_base
		ELSE 0.00
		END), 2) AS val_db,
	ROUND(SUM(CASE WHEN b13_valor_base < 0 THEN
			b13_valor_base * (-1)
		ELSE 0.00
		END), 2) AS val_cr
	FROM tmp_b13, ctbt012, tmp_cta
	WHERE b12_compania  = b13_compania
	  AND b12_tipo_comp = b13_tipo_comp
	  AND b12_num_comp  = b13_num_comp
	  AND b12_estado    = "M"
	  AND NOT EXISTS
		(SELECT 1 FROM ctbt050
			WHERE b50_compania  = b12_compania
			  AND b50_tipo_comp = b12_tipo_comp
			  AND b50_num_comp  = b12_num_comp)
	  AND cia               = b13_compania
	  AND cta               = b13_cuenta
	GROUP BY 1, 2, 3, 4, 5
	INTO TEMP tmp_mov;

DROP TABLE tmp_b13;

INSERT INTO tmp_mov
	(cia, cta_mov, mon, anio, nive, val_db, val_cr)
	SELECT a.cia, a.cta AS cta_mov, a.mon, b.anio, a.nivel AS nive,
		SUM(b.val_db) AS val_db,
		SUM(b.val_cr) AS val_cr
		FROM tmp_cta a, tmp_mov b
		WHERE a.nivel         = 5
		  AND b.cia           = a.cia
		  AND b.cta_mov[1, 8] = a.cta
		  AND b.nive          = 6
		GROUP BY 1, 2, 3, 4, 5;

INSERT INTO tmp_mov
	(cia, cta_mov, mon, anio, nive, val_db, val_cr)
	SELECT a.cia, a.cta AS cta_mov, a.mon, b.anio, a.nivel AS nive,
		SUM(b.val_db) AS val_db,
		SUM(b.val_cr) AS val_cr
		FROM tmp_cta a, tmp_mov b
		WHERE a.nivel         = 4
		  AND b.cia           = a.cia
		  AND b.cta_mov[1, 6] = a.cta[1, 6]
		  AND b.nive          = 6
		GROUP BY 1, 2, 3, 4, 5;

INSERT INTO tmp_mov
	(cia, cta_mov, mon, anio, nive, val_db, val_cr)
	SELECT a.cia, a.cta AS cta_mov, a.mon, b.anio, a.nivel AS nive,
		SUM(b.val_db) AS val_db,
		SUM(b.val_cr) AS val_cr
		FROM tmp_cta a, tmp_mov b
		WHERE a.nivel         = 3
		  AND b.cia           = a.cia
		  AND b.cta_mov[1, 4] = a.cta[1, 4]
		  AND b.nive          = 6
		GROUP BY 1, 2, 3, 4, 5;

INSERT INTO tmp_mov
	(cia, cta_mov, mon, anio, nive, val_db, val_cr)
	SELECT a.cia, a.cta AS cta_mov, a.mon, b.anio, a.nivel AS nive,
		SUM(b.val_db) AS val_db,
		SUM(b.val_cr) AS val_cr
		FROM tmp_cta a, tmp_mov b
		WHERE a.nivel         = 2
		  AND b.cia           = a.cia
		  AND b.cta_mov[1, 2] = a.cta[1, 2]
		  AND b.nive          = 6
		GROUP BY 1, 2, 3, 4, 5;

INSERT INTO tmp_mov
	(cia, cta_mov, mon, anio, nive, val_db, val_cr)
	SELECT a.cia, a.cta AS cta_mov, a.mon, b.anio, a.nivel AS nive,
		SUM(b.val_db) AS val_db,
		SUM(b.val_cr) AS val_cr
		FROM tmp_cta a, tmp_mov b
		WHERE a.nivel         = 1
		  AND b.cia           = a.cia
		  AND b.cta_mov[1, 1] = a.cta[1, 1]
		  AND b.nive          = 6
		GROUP BY 1, 2, 3, 4, 5;

DROP TABLE tmp_cta;

INSERT INTO t_bal_gen
	SELECT cia, cta_mov, mon, anio,
		val_db + NVL((SELECT b11_db_ano_ant
				FROM t_bal_gen
				WHERE b11_compania = cia
				  AND b11_cuenta   = cta_mov
				  AND b11_moneda   = "DO"
				  AND b11_ano      = 2012), 0.00),
		val_cr + NVL((SELECT b11_cr_ano_ant
				FROM t_bal_gen
				WHERE b11_compania = cia
				  AND b11_cuenta   = cta_mov
				  AND b11_moneda   = "DO"
				  AND b11_ano      = 2012), 0.00)
		FROM tmp_mov;

DROP TABLE tmp_mov;
