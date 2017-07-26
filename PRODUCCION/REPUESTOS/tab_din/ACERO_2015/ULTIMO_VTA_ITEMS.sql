SELECT CASE WHEN r20_localidad = 01 THEN "01 GYE J T M"
	    WHEN r20_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r20_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r20_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r20_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(r20_fecing) AS anio,
	CASE WHEN r20_mes = 01 THEN "01 ENERO"
	     WHEN r20_mes = 02 THEN "02 FEBRERO"
	     WHEN r20_mes = 03 THEN "03 MARZO"
	     WHEN r20_mes = 04 THEN "04 ABRIL"
	     WHEN r20_mes = 05 THEN "05 MAYO"
	     WHEN r20_mes = 06 THEN "06 JUNIO"
	     WHEN r20_mes = 07 THEN "07 JULIO"
	     WHEN r20_mes = 08 THEN "08 AGOSTO"
	     WHEN r20_mes = 09 THEN "09 SEPTIEMBRE"
	     WHEN r20_mes = 10 THEN "10 OCTUBRE"
	     WHEN r20_mes = 11 THEN "11 NOVIEMBRE"
	     WHEN r20_mes = 12 THEN "12 DICIEMBRE"
	END AS mes,
	ROUND((DATE(r20_fecing) - MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0) AS num_sem,
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
	r10_filtro AS filtro,
	r20_item AS ite,
	CASE WHEN r20_cod_tran = "AF" THEN "ANULACION FACTURAS"
	     WHEN r20_cod_tran = "DF" THEN "DEVOLUCION FACTURAS"
	     WHEN r20_cod_tran = "FA" THEN "FACTURACION"
	END AS cod_t,
	r20_num_tran AS num_t,
	r20_cant_ven AS cant,
	DATE(r20_fecing) AS fecha
	FROM venta, item
	WHERE r10_codigo = r20_item;
