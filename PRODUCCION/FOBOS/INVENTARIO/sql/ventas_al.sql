SELECT r20_anio AS anio,
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
        END AS meses,
        DAY(r20_fecing) AS dia,
        r20_cliente AS cod_cli,
        z01_nomcli AS nom_cli,
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
                                "NACION", "ROOFTE")
                THEN "05_GENERICOS"
                ELSE "06_OTRAS_MARCAS"
        END AS linea_venta,
        r73_desc_marca AS marca,
        r72_desc_clase AS clase,
        r10_nombre AS descripcion,
        r20_item AS item,
	CASE WHEN r20_cod_tran = "FA" THEN "FACTURADO"
	     WHEN r20_cod_tran = "DF" THEN "DEVUELTO"
	     WHEN r20_cod_tran = "AF" THEN "ANULADO"
	END AS tip_vta,
        NVL(SUM((r20_cant_ven * r20_precio)), 0) AS prec,
        NVL(SUM(r20_val_descto * (-1)), 0) AS descto,
        NVL(SUM((r20_cant_ven * r20_precio) - r20_val_descto), 0) AS venta
        FROM venta, item, clase, marca, cliente
        WHERE r20_vendedor   = 10
	  AND r10_codigo     = r20_item
          AND r72_linea      = r10_linea
          AND r72_sub_linea  = r10_sub_linea
          AND r72_cod_grupo  = r10_cod_grupo
          AND r72_cod_clase  = r10_cod_clase
          AND r73_marca      = r10_marca
          AND z01_localidad  = r20_localidad
          AND z01_codcli     = r20_cliente
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;
