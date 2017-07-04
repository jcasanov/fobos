SELECT YEAR(r19_fecing) AS anio, MONTH(r19_fecing) AS mes,
        CASE WHEN MONTH(r19_fecing) = 01 THEN "ENERO"
             WHEN MONTH(r19_fecing) = 02 THEN "FEBRERO"
             WHEN MONTH(r19_fecing) = 03 THEN "MARZO"
             WHEN MONTH(r19_fecing) = 04 THEN "ABRIL"
             WHEN MONTH(r19_fecing) = 05 THEN "MAYO"
             WHEN MONTH(r19_fecing) = 06 THEN "JUNIO"
             WHEN MONTH(r19_fecing) = 07 THEN "JULIO"
             WHEN MONTH(r19_fecing) = 08 THEN "AGOSTO"
             WHEN MONTH(r19_fecing) = 09 THEN "SEPTIEMBRE"
             WHEN MONTH(r19_fecing) = 10 THEN "OCTUBRE"
             WHEN MONTH(r19_fecing) = 11 THEN "NOVIEMBRE"
             WHEN MONTH(r19_fecing) = 12 THEN "DICIEMBRE"
        END AS nom_mes,
	r01_iniciales AS cod_ven,
        r01_nombres AS vendedor,
        CASE WHEN r10_marca IN ("FRANKL", "GORMAN", "GRUNDF", "MARKGR", "MYERS",
                                "WELLMA", "FAMAC", "F.P.S.", "MARKPE")
                THEN "01_FLUIDOS"
             WHEN r10_marca IN ("RIDGID", "MILWAU", "ENERPA", "ARMSTR",
                                "POWERS", "JET", "KITO")
                THEN "02_HERRAMIENTAS"
             WHEN r10_marca IN ("INOXTE", "F.I.V", "KITZ", "KLINGE", "TECVAL",
                                "REDWHI")
                THEN "03_VAPOR"
             WHEN r10_marca IN ("ECERAM", "INSINK", "RIALTO", "SIDEC", "FVGRIF",
                                "FVSANI", "FVCERA", "EDESA", "TEKVEN", "TEKA",
                                "CALORE", "KOHGRI", "KOHSAN", "CERREC",
                                "AVALON", "BRIGGS", "CREIN", "ALPHAJ", "ARISTO",
                                "CATA", "CASTEL", "CONACA", "EREJIL", "FECSA",
                                "FIBRAS", "HACEB", "INSINK", "INCAME", "INTACO",
                                "KERAMI", "KWIKSE", "MATEX", "PERMAC")
                THEN "04_SANITARIOS"
             WHEN r10_marca IN ("ANDEC", "FUJI", "IDEAL", "PLAGAM", "TUGALT",
                                "1HAG", "1HAN", "1TO", "1VG", "IMPORT",
                                "NACION", "ROOFTE", "FV")
                THEN "05_GENERICOS"
                ELSE "06_OTRAS_MARCAS"
        END AS linea_venta,
        r73_desc_marca AS marca,
	r10_filtro AS filtro,
        SUM(CASE WHEN r19_cod_tran = "FA"
                THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
                ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
        END) AS venta
        FROM rept019, rept001, rept020, rept010, rept073
        WHERE r19_compania      = 1
          AND r19_localidad     = 1
          AND r19_cod_tran     IN ("FA", "DF", "AF")
          AND YEAR(r19_fecing) >= 2012
          AND r01_compania      = r19_compania
          AND r01_codigo        = r19_vendedor
	  AND r01_codigo       NOT IN (13, 23, 67)
	  AND r01_tipo         IN ('E', 'I')
	  AND r01_estado        = "A"
          AND r20_compania      = r19_compania
          AND r20_localidad     = r19_localidad
          AND r20_cod_tran      = r19_cod_tran
          AND r20_num_tran      = r19_num_tran
          AND r10_compania      = r20_compania
          AND r10_codigo        = r20_item
          AND r73_compania      = r10_compania
          AND r73_marca         = r10_marca
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
        ORDER BY 4 ASC, 1 ASC, 2 ASC, 6 ASC, 7 ASC;
