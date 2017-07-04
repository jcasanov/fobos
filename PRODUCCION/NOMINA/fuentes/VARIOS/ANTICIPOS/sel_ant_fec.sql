SELECT n45_cod_trab cod_trab, n30_nombres empleado, n46_cod_liqrol lq,
	n46_saldo saldo
	FROM rolt045, rolt046, rolt030
	WHERE n45_compania          = 1
	  AND n45_estado           IN ("A", "R", "P")
	  AND n46_compania          = n45_compania
	  AND n46_num_prest         = n45_num_prest
	  AND n46_cod_liqrol[1, 1] IN ("Q", "M", "S")
	  AND EXTEND(n46_fecha_fin, YEAR TO MONTH)
			BETWEEN EXTEND(DATE("04/01/2007"), YEAR TO MONTH)
			    AND EXTEND(DATE("04/01/2007"), YEAR TO MONTH)
	  AND n30_compania          = n45_compania
	  AND n30_cod_trab          = n45_cod_trab
UNION ALL
	SELECT n45_cod_trab cod_trab, n30_nombres empleado, n46_cod_liqrol lq,
		n46_saldo saldo
		FROM rolt045, rolt046, rolt030
		WHERE n45_compania          = 1
		  AND n45_estado           IN ("A", "R", "P")
		  AND n46_compania          = n45_compania
		  AND n46_num_prest         = n45_num_prest
		  AND n46_cod_liqrol[1, 1] NOT IN ("Q", "M", "S")
		  AND EXTEND(n46_fecha_fin, YEAR TO MONTH)
			BETWEEN EXTEND(DATE("04/01/2006"), YEAR TO MONTH)
			    AND EXTEND(DATE("04/01/2007"), YEAR TO MONTH)
		  AND n30_compania          = n45_compania
		  AND n30_cod_trab          = n45_cod_trab
	 INTO TEMP t1;
SELECT UNIQUE lq cod, n03_nombre nom_pro
	FROM rolt003, t1
	WHERE n03_proceso = lq
	INTO TEMP t2;
SELECT UNIQUE cod_trab cod_t, empleado nombre FROM t1 INTO TEMP t3;
SELECT UNIQUE cod_t, nombre, cod, nom_pro FROM t2, t3 INTO TEMP tmp_pro;
DROP TABLE t2;
DROP TABLE t3;
SELECT cod_t cod_trab, nombre empleado, cod lq, nom_pro, NVL(saldo, 0) saldo
	FROM tmp_pro, OUTER t1
	WHERE cod   = lq
	  AND cod_t = cod_trab
	INTO TEMP tmp_ant;
DROP TABLE t1;
DROP TABLE tmp_pro;
select count(*) tot_reg from tmp_ant;
select count(unique cod_trab) tot_emp from tmp_ant;
SELECT cod_trab, empleado, lq, NVL(saldo, 0) saldo
	from tmp_ant order by empleado;
drop table tmp_ant;
