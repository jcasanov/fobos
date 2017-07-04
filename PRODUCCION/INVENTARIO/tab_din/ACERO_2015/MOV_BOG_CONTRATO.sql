SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(r19_fecing) AS anio,
	CASE WHEN MONTH(r19_fecing) = 01 THEN "01 ENERO"
	     WHEN MONTH(r19_fecing) = 02 THEN "02 FEBRERO"
	     WHEN MONTH(r19_fecing) = 03 THEN "03 MARZO"
	     WHEN MONTH(r19_fecing) = 04 THEN "04 ABRIL"
	     WHEN MONTH(r19_fecing) = 05 THEN "05 MAYO"
	     WHEN MONTH(r19_fecing) = 06 THEN "06 JUNIO"
	     WHEN MONTH(r19_fecing) = 07 THEN "07 JULIO"
	     WHEN MONTH(r19_fecing) = 08 THEN "08 AGOSTO"
	     WHEN MONTH(r19_fecing) = 09 THEN "09 SEPTIEMBRE"
	     WHEN MONTH(r19_fecing) = 10 THEN "10 OCTUBRE"
	     WHEN MONTH(r19_fecing) = 11 THEN "11 NOVIEMBRE"
	     WHEN MONTH(r19_fecing) = 12 THEN "12 DICIEMBRE"
	END AS mes,
	fp_numero_semana (DATE(r19_fecing)) AS num_sem,
	(SELECT TRIM(g21_nombre)
		FROM gent021
		WHERE g21_cod_tran = r19_cod_tran) AS cod_t,
	r19_num_tran AS num_t,
	r19_referencia AS refer,
	r19_nomcli AS nom_c,
	DATE(r19_fecing) AS fecha,
	CASE WHEN r10_marca IN ("F.P.S.", "FAMAC", "FRANKL", "GORMAN", "GRUNDF",
				"MARKGR", "MARKPE", "MYERS", "WELLMA")
		THEN "01_FLUIDOS"
	     WHEN r10_marca IN ("ARMSTR", "ENERPA", "JET", "KITO", "MILWAU",
				"POWERS", "RIDGID")
		THEN "02_HERRAMIENTAS"
	     WHEN r10_marca IN ("F.I.V", "INOXTE", "KITZ", "KLINGE", "REDWHI",
				"TECVAL")
		THEN "03_VAPOR"
	     WHEN r10_marca IN ("ARISTON", "AVALON", "ALPHAJ", "ARISTO",
				"BRIGGS", "CALORE", "CASTEL", "CATA", "CERREC",
				"CONACA", "CREIN", "ECERAM", "EDESA", "EREJIL",
				"FECSA", "FIBRAS", "FV", "FVCERA", "FVGRIF",
				"FVSANI", "HACEB", "INCAME", "INSINK", "INTACO",
				"KERAMI","KOHGRI", "KOHSAN", "KWIKSE", "MATEX",
				"PERMAC", "RIALTO", "SIDEC", "TEKA", "TEKVEN")
		THEN "04_SANITARIOS"
	     WHEN r10_marca IN ("1HAG", "1HAN", "1TO", "1VG", "ANDEC", "FUJI",
				"IDEAL", "IMPORT", "NACION", "PLAGAM", "TUGALT",
				"ROOFTE")
		THEN "05_GENERICOS"
		ELSE "06_OTRAS_MARCAS"
	END AS linea_venta,
	r01_nombres AS usuar,
	r10_filtro AS filtro,
	CAST (r20_item AS INTEGER) AS ite,
	r10_nombre AS descrip,
	r72_desc_clase AS clas,
	CASE WHEN (r19_cod_tran   = "A+"            OR
		  (r19_cod_tran   = "TR"            AND
		   r02_codigo     = r19_bodega_dest AND
		   r02_tipo_ident = "C"))
		THEN r20_cant_ven
		ELSE r20_cant_ven * (-1)
	END AS cant,
	CASE WHEN (r19_cod_tran   = "A+"            OR
		  (r19_cod_tran   = "TR"            AND
		   r02_codigo     = r19_bodega_dest AND
		   r02_tipo_ident = "C"))
		THEN r19_bodega_dest
		ELSE r19_bodega_ori
	END AS bode
	FROM rept019, rept002, rept020, rept001, rept010, rept072
	WHERE   r19_compania   = 1
	  AND   r19_localidad  = 1
	  AND ((r02_compania   = r19_compania
	  AND   r02_codigo     = r19_bodega_ori 
	  AND   r02_localidad  = r19_localidad
	  AND   r02_tipo_ident = "C")
	   OR  (r02_compania   = r19_compania
	  AND   r02_codigo     = r19_bodega_dest 
	  AND   r02_localidad  = r19_localidad
	  AND   r02_tipo_ident = "C"))
	  AND   r20_compania   = r19_compania
	  AND   r20_localidad  = r19_localidad
	  AND   r20_cod_tran   = r19_cod_tran
	  AND   r20_num_tran   = r19_num_tran
	  AND EXISTS
		(SELECT 1 FROM rept011
			WHERE r11_compania   = r20_compania
			  AND r11_bodega    IN
				(SELECT a.r02_codigo
					FROM rept002 a
					WHERE a.r02_compania   = r11_compania
					  AND a.r02_localidad  = r20_localidad
					  AND a.r02_tipo_ident = "C")
			  AND r11_item       = r20_item
			  AND r11_stock_act  > 0)
	  AND   r01_compania   = r19_compania
	  AND   r01_codigo     = r19_vendedor
	  AND   r10_compania   = r20_compania
	  AND   r10_codigo     = r20_item
	  AND   r72_compania   = r10_compania
	  AND   r72_linea      = r10_linea
	  AND   r72_sub_linea  = r10_sub_linea
	  AND   r72_cod_grupo  = r10_cod_grupo
	  AND   r72_cod_clase  = r10_cod_clase;
