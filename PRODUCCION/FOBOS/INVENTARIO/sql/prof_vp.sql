SELECT r21_compania AS cia,
	r21_localidad AS loc,
	r21_numprof AS numprof,
	r21_dias_prof AS dias_f,
	r21_fecing AS fecing
	FROM rept021
	WHERE r21_compania      = 1
	  AND r21_localidad     = 1
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
SELECT * FROM t1
	WHERE EXISTS
		(SELECT 1 FROM rept022
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
					  AND r02_tipo_ident = "P"))
	INTO TEMP tmp_prof;
DROP TABLE t1;
SELECT COUNT(*) cuantos
	FROM tmp_prof;
SELECT * FROM tmp_prof
	ORDER BY 5 DESC;
DROP TABLE tmp_prof;
