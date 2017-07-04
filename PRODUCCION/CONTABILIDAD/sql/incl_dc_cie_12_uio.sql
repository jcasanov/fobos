SELECT b13_cuenta AS cta,
	CASE WHEN b13_valor_base >= 0
		THEN b13_valor_base
		ELSE 0.00
	END AS val_db,
	CASE WHEN b13_valor_base <= 0
		THEN b13_valor_base
		ELSE 0.00
	END AS val_cr
	FROM ctbt013
	WHERE b13_compania  = 1
	  AND b13_tipo_comp = "DC"
	  AND b13_num_comp  = "12121998"
	INTO TEMP t1;

BEGIN WORK;

	UPDATE ctbt011
		SET b11_db_mes_12 = b11_db_mes_12 +
				(SELECT val_db
					FROM t1
					WHERE cta = b11_cuenta),
		    b11_cr_mes_12 = b11_cr_mes_12 +
				(SELECT val_cr
					FROM t1
					WHERE cta = b11_cuenta)
		WHERE b11_compania  = 1
		  AND b11_cuenta   IN (SELECT cta FROM t1)
		  AND b11_ano       = 2012;

COMMIT WORK;

DROP TABLE t1;
