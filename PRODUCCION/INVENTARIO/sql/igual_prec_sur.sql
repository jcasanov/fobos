SET ISOLATION TO DIRTY READ;

SELECT a.r10_compania AS cia, a.r10_codigo AS codigo, a.r10_precio_mb AS prec_l,
	a.r10_fec_camprec AS fec_c_p
	FROM acero_qs@idsuio02:rept010 a
	WHERE a.r10_compania = 1
	  AND NOT EXISTS
		(SELECT 1 FROM acero_qm@idsuio01:rept010 b
			WHERE b.r10_compania  = a.r10_compania
			  AND b.r10_codigo    = a.r10_codigo
			  AND b.r10_precio_mb = a.r10_precio_mb)
	INTO TEMP t1;

UNLOAD TO "item_prec_dif_sur.unl"
	SELECT * FROM t1;

SELECT r87_compania AS cia, 4 AS loc, r87_item AS item, r87_secuencia AS secu,
	r87_precio_act AS prec_act, r87_precio_ant AS prec_ant,
	r87_usu_camprec AS usu_cam, r87_fec_camprec AS fec_cam
	FROM acero_qm@idsuio01:rept087
	WHERE r87_compania = 1
	  AND EXISTS
		(SELECT 1 FROM t1
			WHERE cia      = r87_compania
			  AND codigo   = r87_item
			  AND fec_c_p <= r87_fec_camprec)
	INTO TEMP tmp_r87;

SELECT r10_codigo AS item, r10_precio_mb AS prec_n, r10_precio_ant AS prec_a,
	r10_fec_camprec AS fec_c_p
	FROM acero_qm@idsuio01:rept010
	WHERE r10_compania  = 1
	  AND r10_codigo   IN (SELECT codigo FROM t1)
	INTO TEMP tmp_r10;

DROP TABLE t1;

BEGIN WORK;

	UPDATE acero_qs@idsuio02:rept010
		SET r10_precio_mb   = (SELECT prec_n
					FROM tmp_r10
					WHERE item = r10_codigo),
		    r10_fec_camprec = (SELECT fec_c_p
					FROM tmp_r10
					WHERE item = r10_codigo),
		    r10_precio_ant  = (SELECT prec_a
					FROM tmp_r10
					WHERE item = r10_codigo)
	WHERE r10_compania  = 1
	  AND r10_codigo   IN (SELECT item FROM tmp_r10);

	INSERT INTO acero_qs@idsuio02:rept087
		SELECT * FROM tmp_r87;

--ROLLBACK WORK;
COMMIT WORK;

DROP TABLE tmp_r10;
DROP TABLE tmp_r87;
