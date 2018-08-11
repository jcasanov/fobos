{--
SELECT MDY(12, 02, 2012) AS fecha FROM dual INTO TEMP t1;  -- fecha cualquiera

SELECT 1 AS fact_ds, 4 AS factor, 1 AS mes_ini, 3 AS dia_ini,
	(WEEKDAY(fecha - 1 UNITS DAY) + 1) AS diasem, fecha
	FROM t1
	INTO TEMP t2;
select * from t2;

DROP TABLE t1;

SELECT MDY(mes_ini, dia_ini,
	YEAR(fecha - diasem UNITS DAY + factor UNITS DAY)) AS fec_cal,
	5 AS fact1, 7 AS fact2, fecha, fact_ds
	FROM t2
	INTO TEMP t1;
select * from t1;

DROP TABLE t2;

SELECT ((fecha - fec_cal + (WEEKDAY(fec_cal) + fact_ds) + fact1)
	/ fact2) AS num_sem
	FROM t1;

DROP TABLE t1;

--
SELECT ROUND((fecha - MDY(1, 3, YEAR(fecha - WEEKDAY(fecha - 1 UNITS DAY)
		+ 4 UNITS DAY)) + WEEKDAY(MDY(1, 3,
		YEAR(fecha - WEEKDAY(fecha - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7) num_sem
	FROM t1;

DROP TABLE t1;
--

--}

DROP PROCEDURE fp_numero_semana;

CREATE PROCEDURE fp_numero_semana (fecha DATE) RETURNING INT;

	DEFINE num_sem_g	DECIMAL(10, 2);
	DEFINE num_sem_f	INT;

	ON EXCEPTION IN (-1213)
		RETURN 0;
	END EXCEPTION;
	LET num_sem_g = ((fecha - MDY(1, 3, YEAR(fecha
			- (WEEKDAY(fecha - 1 UNITS DAY) + 1) + 4 UNITS DAY))
			+ (WEEKDAY(MDY(1, 3, YEAR(fecha - (WEEKDAY(fecha
			- 1 UNITS DAY) + 1) + 4 UNITS DAY))) + 1) + 5) / 7);
	{--
	IF TRUNC(num_sem_g, 0) = num_sem_g THEN
		LET num_sem_f = num_sem_g;
	ELSE
		LET num_sem_f = TRUNC(num_sem_g, 0) + 1;
	END IF;
	--}
	LET num_sem_f = TRUNC(num_sem_g, 0);
	IF num_sem_f = 0 THEN
		LET num_sem_f = 1;
	END IF;
	IF num_sem_f > 52 THEN
		LET num_sem_f = 52;
	END IF;
	RETURN num_sem_f;

END PROCEDURE;
