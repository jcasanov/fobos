SET ISOLATION TO DIRTY READ;

SELECT r21_compania AS cia,
	r21_localidad AS loc,
	r21_numprof AS numprof
	FROM rept021
	WHERE r21_compania      = 1
	  AND r21_localidad     = 2
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

SELECT UNIQUE r22_item item
	FROM t1, rept022
	WHERE r22_compania  = cia
	  AND r22_localidad = loc
	  AND r22_numprof   = numprof
	INTO TEMP tmp_ite;

DROP TABLE t1;

BEGIN WORK;

	INSERT INTO rept009
		(r09_compania, r09_tipo_ident, r09_descripcion, r09_estado,
		 r09_usuario, r09_fecing)
		VALUES (1, "P", "VENTAS PERDIDAS", "A", "FOBOS", CURRENT);

	INSERT INTO rept002
		(r02_compania, r02_codigo, r02_nombre, r02_estado, r02_tipo,
		 r02_area, r02_factura, r02_localidad, r02_tipo_ident,
		 r02_usuario, r02_fecing)
		VALUES (1, "VP", "VENTAS PERDIDAS", "A", "L", "R", "N", 2, "P",
			"FOBOS", CURRENT);

	INSERT INTO rept011
		(r11_compania, r11_bodega, r11_item, r11_ubicacion,
		 r11_stock_ant, r11_stock_act, r11_ing_dia, r11_egr_dia)
		SELECT 1, "VP", item, "S/N", 0.00, 0.00, 0.00, 0.00
			FROM tmp_ite;

COMMIT WORK;

DROP TABLE tmp_ite;
