SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM localidad
		WHERE g02_localidad = r20_localidad) AS local,
	YEAR(r20_fecing) AS anio,
	CASE WHEN MONTH(r20_fecing) = 01 THEN "01 ENERO"
	     WHEN MONTH(r20_fecing) = 02 THEN "02 FEBRERO"
	     WHEN MONTH(r20_fecing) = 03 THEN "03 MARZO"
	     WHEN MONTH(r20_fecing) = 04 THEN "04 ABRIL"
	     WHEN MONTH(r20_fecing) = 05 THEN "05 MAYO"
	     WHEN MONTH(r20_fecing) = 06 THEN "06 JUNIO"
	     WHEN MONTH(r20_fecing) = 07 THEN "07 JULIO"
	     WHEN MONTH(r20_fecing) = 08 THEN "08 AGOSTO"
	     WHEN MONTH(r20_fecing) = 09 THEN "09 SEPTIEMBRE"
	     WHEN MONTH(r20_fecing) = 10 THEN "10 OCTUBRE"
	     WHEN MONTH(r20_fecing) = 11 THEN "11 NOVIEMBRE"
	     WHEN MONTH(r20_fecing) = 12 THEN "12 DICIEMBRE"
	END AS mes,
	TO_CHAR(r20_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(r20_fecing)), 2, 0) AS num_sem,
	DATE(r20_fecing) AS fec,
	r01_nombres AS vendedor,
	r01_iniciales AS ini_vend,
	r20_cliente AS cod_cli,
	z01_nomcli AS nom_cli,
	z01_direccion1 AS dir_cliente,
	r20_bodega AS bodega,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r20_item AS item,
	r10_marca AS marca,
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
	END AS linea_vent,
	"01_VENTAS" AS tipo,
	r20_cod_tran AS codt,
	r20_num_tran AS numt,
	NVL(SUM(r20_val_descto), 0) AS descuento,
	NVL(SUM((r20_cant_ven * r20_precio) - r20_val_descto), 0) AS valor
	FROM venta, item, clase, vendedor, cliente
	WHERE r20_localidad    = 1
	  AND YEAR(r20_fecing) > 2012
	  AND r20_cod_tran     = "FA"
	  AND r10_codigo       = r20_item
	  AND r72_linea        = r10_linea
	  AND r72_sub_linea    = r10_sub_linea
	  AND r72_cod_grupo    = r10_cod_grupo
	  AND r72_cod_clase    = r10_cod_clase
	  AND z01_localidad    = r20_localidad
	  AND z01_codcli       = r20_cliente
	  AND r01_localidad    = r20_localidad
	  AND r01_codigo       = r20_vendedor
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
		18, 19
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM localidad
		WHERE g02_localidad = r22_localidad) AS local,
	YEAR(r22_fecing) AS anio,
	CASE WHEN MONTH(r22_fecing) = 01 THEN "01 ENERO"
	     WHEN MONTH(r22_fecing) = 02 THEN "02 FEBRERO"
	     WHEN MONTH(r22_fecing) = 03 THEN "03 MARZO"
	     WHEN MONTH(r22_fecing) = 04 THEN "04 ABRIL"
	     WHEN MONTH(r22_fecing) = 05 THEN "05 MAYO"
	     WHEN MONTH(r22_fecing) = 06 THEN "06 JUNIO"
	     WHEN MONTH(r22_fecing) = 07 THEN "07 JULIO"
	     WHEN MONTH(r22_fecing) = 08 THEN "08 AGOSTO"
	     WHEN MONTH(r22_fecing) = 09 THEN "09 SEPTIEMBRE"
	     WHEN MONTH(r22_fecing) = 10 THEN "10 OCTUBRE"
	     WHEN MONTH(r22_fecing) = 11 THEN "11 NOVIEMBRE"
	     WHEN MONTH(r22_fecing) = 12 THEN "12 DICIEMBRE"
	END AS mes,
	TO_CHAR(r22_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(r22_fecing)), 2, 0) AS num_sem,
	DATE(r22_fecing) AS fec,
	r01_nombres AS vendedor,
	r01_iniciales AS ini_vend,
	r22_codcli AS cod_cli,
	r22_nomcli AS nom_cli,
	z01_direccion1 AS dir_cliente,
	r22_bodega AS bodega,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r22_item AS item,
	r10_marca AS marca,
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
	END AS linea_vent,
	"02_PROFORMAS_NO_FACT" AS tipo,
	"PR" AS codt,
	r22_numprof AS numt,
	NVL(SUM(r22_val_descto), 0) AS descuento,
	NVL(SUM((r22_cantidad * r22_precio) - r22_val_descto), 0) AS valor
	FROM proforma, item, clase, vendedor, cliente
	WHERE r22_localidad    = 1
	  AND r22_cod_tran     IS NULL
	  AND YEAR(r22_fecing) > 2012
	  AND r10_codigo       = r22_item
	  AND r72_linea        = r10_linea
	  AND r72_sub_linea    = r10_sub_linea
	  AND r72_cod_grupo    = r10_cod_grupo
	  AND r72_cod_clase    = r10_cod_clase
	  AND z01_localidad    = r22_localidad
	  AND z01_codcli       = r22_codcli
	  AND r01_localidad    = r22_localidad
	  AND r01_codigo       = r22_vendedor
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
		18, 19;
