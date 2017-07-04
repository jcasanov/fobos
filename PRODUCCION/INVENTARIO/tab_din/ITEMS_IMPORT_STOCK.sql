SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS local,
	YEAR(r19_fecing) AS anio,
	CASE WHEN MONTH(r19_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r19_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r19_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r19_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r19_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r19_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r19_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r19_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r19_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r19_fecing) = 00 THEN "OCTUBRE"
	     WHEN MONTH(r19_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r19_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	DATE(r19_fecing) AS fec,
	fp_numero_semana(DATE(r19_fecing)) AS num_sem,
	r19_nomcli AS refer,
	r19_numliq AS num_lq,
	r19_cod_tran AS cod_t,
	r19_num_tran AS num_t,
	r20_item AS item,
	r72_desc_clase AS clas,
	r10_nombre AS descrip,
	r10_marca AS marc,
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
	END AS linea,
	r20_cant_ven AS cant,
	NVL((r20_cant_ven * r20_costo), 0.00) AS cost,
	NVL((r20_cant_ven * r20_fob), 0.00) AS fob,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	NVL(SUM(r11_stock_act), 0) AS sto
	FROM acero_qm:rept019, acero_qm:rept020, acero_qm:rept010,
		acero_qm:rept072, acero_qm:rept011
	WHERE r19_compania   = 1
	  AND r19_localidad  = 3
	  AND r19_cod_tran   = "IM"
	  AND r20_compania   = r19_compania
	  AND r20_localidad  = r19_localidad
	  AND r20_cod_tran   = r19_cod_tran
	  AND r20_num_tran   = r19_num_tran
	  AND r10_compania   = r20_compania
	  AND r10_codigo     = r20_item
	  AND r72_compania   = r10_compania
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND r11_compania   = r10_compania
	  AND r11_bodega    IN
		(SELECT r02_codigo
			FROM acero_qm:rept002
			WHERE r02_compania  = r11_compania
			  AND r02_estado    = "A"
			  AND r02_tipo     IN ("F", "L"))
	  AND r11_item       = r10_codigo
	  AND r11_stock_act  > 0
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
	HAVING SUM(r11_stock_act) > 0;
