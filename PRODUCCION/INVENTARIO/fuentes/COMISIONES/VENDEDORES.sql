SELECT r01_codigo AS cod_ven,
	r01_iniciales AS iniciales,
	r01_nombres AS vendedor,
	CASE WHEN r01_codigo IN (25, 78, 20, 70, 69, 8, 77, 68, 10, 37, 36, 71,
				 72, 75, 14, 15, 49, 17, 66, 18)
		THEN "SI"
		ELSE "NO"
	END AS comision,
	CASE WHEN  r01_tipo = "I"
		THEN "VENDEDOR ALMACEN"
	     WHEN (r01_tipo = "E" OR r01_codigo = 62)
		THEN "VENDEDOR EXTERNO"
	     WHEN  r01_tipo = "B"
		THEN "BODEGUERO"
	     WHEN (r01_tipo = "J" AND r01_codigo NOT IN (36, 75))
		THEN "JEFES"
	     WHEN (r01_tipo = "J" OR r01_codigo IN (36, 75))
		THEN "JEFES FLUIDOS"
	     WHEN  r01_tipo = "G"
		THEN "GERENTE"
	END AS tipo,
	CASE WHEN r01_codigo IN (68, 18, 70)
		THEN "R"
		ELSE "N"
	END AS tip_alm,
	CASE WHEN r01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado,
	r01_codrol AS codtrab,
	CASE WHEN r01_codigo NOT IN (13, 20, 62)
		THEN
			CASE WHEN r01_tipo = "I" THEN "03 VENDEDOR ALMACEN"
			     WHEN r01_tipo = "E" THEN "01 VENDEDOR EXTERNO"
			     WHEN r01_tipo = "J" THEN "02 JEFES"
			     WHEN r01_tipo = "G" THEN "06 GERENTE"
			END
		ELSE
			"04 SOPORTE VENTAS"
	END AS tip_ord
	FROM rept001
	WHERE r01_compania = 1
UNION
SELECT 999 AS cod_ven, "JAV" AS iniciales, "JEFE ALAMCEN VALVULAS" AS vendedor,
	"SI" AS comision, "JEFES" AS tipo, "N" AS tip_alm, "ACTIVO" AS estado,
	r01_codrol AS codtrab, "02 JEFES" AS tip_ord
        FROM rept001
        WHERE r01_compania = 1
	  AND r01_codigo   = 68
UNION
SELECT t03_mecanico AS cod_ven,
	t03_iniciales AS iniciales,
	t03_nombres AS vendedor,
	"SI" AS comision,
	"TALLER" AS tipo,
	t03_tipo AS tip_alm,
	CASE WHEN t03_mecanico NOT IN (1, 11, 9, 8, 5, 4)
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado,
	t03_codrol AS codtrab,
	"05 TALLER" AS tip_ord
	FROM talt003
	WHERE t03_mecanico <> 3
        ORDER BY 3 ASC;
