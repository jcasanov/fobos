SELECT r21_compania AS cia,
	r21_localidad AS loc,
	r21_numprof AS numprof,
	r21_dias_prof AS dias_f,
	r21_fecing AS fecing
	FROM rept021
	WHERE r21_compania      = 1
	  AND r21_localidad     = 4
	  AND r21_cod_tran     IS NULL
	  AND r21_num_presup   IS NULL
	  AND r21_num_ot       IS NULL
	  AND DATE(r21_fecing) BETWEEN TODAY -
		(SELECT r00_expi_prof * 2
			FROM rept000
			WHERE r00_compania = r21_compania) UNITS DAY
				   AND TODAY -
		(SELECT r00_expi_prof + 1
			FROM rept000
			WHERE r00_compania = r21_compania) UNITS DAY
	  AND YEAR(r21_fecing) >= 2014
	INTO TEMP t1;
SELECT COUNT(*) cuantos FROM t1;
SELECT t1.*, r22_item AS item
	FROM t1, rept022
	WHERE r22_compania  = cia
	  AND r22_localidad = loc
	  AND r22_numprof   = numprof
	  AND r22_bodega    NOT IN
		(SELECT r02_codigo
			FROM rept002
			WHERE r02_compania   = r22_compania
			  AND r02_localidad  = r22_localidad
			  AND r02_estado     = "A"
			  AND r02_area       = "R"
			  AND r02_tipo_ident = "P")
	INTO TEMP tmp_prof;
DROP TABLE t1;
SELECT 1 AS cia,
	(SELECT r02_codigo
		FROM rept002
		WHERE r02_compania   = 1
		  AND r02_localidad  = 4
		  AND r02_estado     = "A"
		  AND r02_area       = "R"
		  AND r02_tipo_ident = "P") AS bod,
	item, "S/N" AS ubic, 0.00 AS sto_ant, 0.00 AS sto_act, 0.00 AS ing_d,
	0.00 AS egr_d
	FROM tmp_prof
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
	INTO TEMP t1;
select cia, bod, item from t1;
SELECT * FROM t1
	WHERE NOT EXISTS
		(SELECT 1 FROM rept011
			WHERE r11_compania = cia
			  AND r11_bodega   = bod
			  AND r11_item     = item)
	INTO TEMP tmp_ite;
DROP TABLE t1;
select cia, bod, item from tmp_ite;
SELECT COUNT(*) cuantos FROM tmp_ite;
BEGIN WORK;
INSERT INTO rept011
	(r11_compania, r11_bodega, r11_item, r11_ubicacion,
	 r11_stock_ant, r11_stock_act, r11_ing_dia, r11_egr_dia)
	SELECT b.* FROM tmp_ite b
		WHERE NOT EXISTS
			(SELECT 1 FROM rept011 a
				WHERE a.r11_compania = b.cia
				  AND a.r11_bodega   = b.bod
				  AND a.r11_item     = b.item);
ROLLBACK WORK;
--COMMIT WORK;
DROP TABLE tmp_ite;
SELECT r02_codigo AS bod
	FROM rept002
	WHERE r02_compania   = 1
	  AND r02_localidad  = 4
	  AND r02_estado     = "A"
	  AND r02_area       = "R"
	  AND r02_tipo_ident = "P"
	INTO TEMP tmp_bod;
UPDATE rept022
	SET r22_bodega = (SELECT bod FROM tmp_bod)
	WHERE r22_compania   = 1
	  AND r22_localidad  = 4
	  AND r22_numprof   IN
		(SELECT UNIQUE numprof
			FROM tmp_prof
			WHERE cia = r22_compania
			  AND loc = r22_localidad);
DROP TABLE tmp_bod;
SELECT COUNT(UNIQUE numprof) cuantos FROM tmp_prof;
DROP TABLE tmp_prof;
