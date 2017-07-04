SELECT YEAR(r20_fecing) AS anio,
	CASE WHEN MONTH(r20_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r20_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r20_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r20_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r20_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r20_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r20_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r20_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r20_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r20_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r20_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r20_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
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
	r20_item AS codigo,
	r72_desc_clase AS clas,
	r10_nombre AS descrip,
	r10_marca AS marca,
	TO_CHAR(r20_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(r20_fecing)), 2, 0) AS num_sem,
	(SELECT r01_nombres
		FROM rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS vend,
	"CON VENTA" AS tipo,
	NVL(SUM(CASE WHEN r19_cod_tran = "FA"
			THEN r20_cant_ven
			ELSE r20_cant_ven * (-1)
		END), 0.00) AS cant,
	NVL(SUM(CASE WHEN r19_cod_tran = "FA"
			THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
			ELSE ((r20_cant_ven * r20_precio) - r20_val_descto)
				* (-1)
		END), 0.00) AS vta
	FROM rept019, rept020, rept010, rept072
	WHERE r19_compania      = 1
	  AND r19_localidad     = 1
	  AND r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(r19_fecing) >= 2012
	  AND r19_codcli       <> 101
	  AND r20_compania      = r19_compania
	  AND r20_localidad     = r19_localidad
	  AND r20_cod_tran      = r19_cod_tran
	  AND r20_num_tran      = r19_num_tran
	  AND r10_compania      = r20_compania
	  AND r10_codigo        = r20_item
	  AND r72_compania      = r10_compania
	  AND r72_linea         = r10_linea
	  AND r72_sub_linea     = r10_sub_linea
	  AND r72_cod_grupo     = r10_cod_grupo
	  AND r72_cod_clase     = r10_cod_clase
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
UNION
SELECT YEAR(TODAY) AS anio,
	CASE WHEN MONTH(TODAY) = 01 THEN "ENERO"
	     WHEN MONTH(TODAY) = 02 THEN "FEBRERO"
	     WHEN MONTH(TODAY) = 03 THEN "MARZO"
	     WHEN MONTH(TODAY) = 04 THEN "ABRIL"
	     WHEN MONTH(TODAY) = 05 THEN "MAYO"
	     WHEN MONTH(TODAY) = 06 THEN "JUNIO"
	     WHEN MONTH(TODAY) = 07 THEN "JULIO"
	     WHEN MONTH(TODAY) = 08 THEN "AGOSTO"
	     WHEN MONTH(TODAY) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(TODAY) = 10 THEN "OCTUBRE"
	     WHEN MONTH(TODAY) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(TODAY) = 12 THEN "DICIEMBRE"
	END AS mes,
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
	r10_codigo AS codigo,
	r72_desc_clase AS clas,
	r10_nombre AS descrip,
	r10_marca AS marca,
	TO_CHAR(TODAY, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(TODAY)), 2, 0) AS num_sem,
	"SIN VENDEDOR" AS vend,
	"SIN VENTA" AS tipo,
	NVL((SELECT SUM(r11_stock_act)
		FROM rept011, rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad  = 1
		  AND r02_estado     = "A"
		  AND r02_tipo      <> "S"), 0.00) AS cant,
	NVL((SELECT SUM(r11_stock_act)
		FROM rept011, rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad  = 1
		  AND r02_estado     = "A"
		  AND r02_tipo      <> "S"), 0.00) * r10_precio_mb AS vta
	FROM rept010, rept072
	WHERE r10_compania  = 1
	  AND r10_estado    = "A"
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
	  AND NOT EXISTS
		(SELECT 1 FROM rept020
			WHERE r20_compania      = r10_compania
			  AND r20_item          = r10_codigo
	  		  AND r20_cod_tran     IN ("FA", "DF", "AF")
			  AND YEAR(r20_fecing) >= 2012);
