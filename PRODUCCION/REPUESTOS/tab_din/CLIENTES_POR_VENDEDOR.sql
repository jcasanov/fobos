SELECT r19_codcli AS codi,
	r19_cedruc AS cedrc,
	r19_nomcli AS nomc,
	z01_direccion1 AS dircli,
	z01_telefono1 AS telcli,
	r01_nombres AS vended,
	CASE WHEN r01_tipo = "I" THEN "VENDEDOR ALMACEN"
	     WHEN r01_tipo = "E" THEN "VENDEDOR EXTERNO"
	     WHEN r01_tipo = "B" THEN "BODEGUERO"
	     WHEN r01_tipo = "J" THEN "JEFE DE VENTAS"
	     WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
	END AS tip,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est
	FROM rept019, rept001, cxct001
	WHERE r19_compania     = 1
	  AND r19_localidad    = 1
	  AND r19_cod_tran     IN ("DF", "AF", "FA")
	  AND r19_codcli       NOT IN (99, 101)
	  AND YEAR(r19_fecing) > 2002
	  AND r01_compania     = r19_compania
	  AND r01_codigo       = r19_vendedor
	  AND z01_codcli       = r19_codcli
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8;
