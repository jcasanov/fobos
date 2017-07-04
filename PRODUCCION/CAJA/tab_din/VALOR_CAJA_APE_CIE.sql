SELECT (SELECT LPAD(a.j04_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = a.j04_compania
		  AND g02_localidad = a.j04_localidad) AS local,
	YEAR(a.j04_fecha_aper) AS anio,
	CASE WHEN MONTH(a.j04_fecha_aper) = 01 THEN "ENERO"
	     WHEN MONTH(a.j04_fecha_aper) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.j04_fecha_aper) = 03 THEN "MARZO"
	     WHEN MONTH(a.j04_fecha_aper) = 04 THEN "ABRIL"
	     WHEN MONTH(a.j04_fecha_aper) = 05 THEN "MAYO"
	     WHEN MONTH(a.j04_fecha_aper) = 06 THEN "JUNIO"
	     WHEN MONTH(a.j04_fecha_aper) = 07 THEN "JULIO"
	     WHEN MONTH(a.j04_fecha_aper) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.j04_fecha_aper) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.j04_fecha_aper) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.j04_fecha_aper) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.j04_fecha_aper) = 12 THEN "DICIEMBRE"
	END AS mes,
	TO_CHAR(a.j04_fecha_aper, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(a.j04_fecha_aper)), 2, 0) AS num_sem,
	a.j04_fecha_aper AS fec_ape,
	a.j04_codigo_caja AS cod_caj,
	j02_nombre_caja AS nom_caj,
	(b.j05_ef_apertura + b.j05_ef_ing_dia - b.j05_ef_egr_dia) AS tot_ef,
	(b.j05_ch_apertura + b.j05_ch_ing_dia - b.j05_ch_egr_dia) AS tot_ch,
	((b.j05_ef_apertura + b.j05_ef_ing_dia - b.j05_ef_egr_dia) +
	 (b.j05_ch_apertura + b.j05_ch_ing_dia - b.j05_ch_egr_dia)) AS tot
	FROM cajt004 a, cajt005 b, cajt002
	WHERE a.j04_compania    = 1
	  AND a.j04_fecha_aper  =
		(SELECT MAX(c.j04_fecha_aper)
			FROM cajt004 c
			WHERE c.j04_compania    = a.j04_compania
			  AND c.j04_localidad   = a.j04_localidad
			  AND c.j04_codigo_caja = a.j04_codigo_caja)
	  AND a.j04_secuencia   =
		(SELECT MAX(c.j04_secuencia)
			FROM cajt004 c
			WHERE c.j04_compania    = a.j04_compania
			  AND c.j04_localidad   = a.j04_localidad
			  AND c.j04_codigo_caja = a.j04_codigo_caja
			  AND c.j04_fecha_aper  = a.j04_fecha_aper)
	  AND b.j05_compania    = a.j04_compania
	  AND b.j05_localidad   = a.j04_localidad
	  AND b.j05_codigo_caja = a.j04_codigo_caja
	  AND b.j05_fecha_aper  = a.j04_fecha_aper
	  AND b.j05_secuencia   = a.j04_secuencia
	  AND ((b.j05_ef_apertura + b.j05_ef_ing_dia - b.j05_ef_egr_dia) +
	 	(b.j05_ch_apertura + b.j05_ch_ing_dia - b.j05_ch_egr_dia)) <> 0
	  AND j02_compania      = a.j04_compania
	  AND j02_localidad     = a.j04_localidad
	  AND j02_codigo_caja   = a.j04_codigo_caja;
