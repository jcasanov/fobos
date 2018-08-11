SELECT g50_nombre AS modulo,
	g54_proceso AS programa,
	g54_nombre AS nombre,
	CASE WHEN g54_estado = "A" THEN "ACTIVO"
	     WHEN g54_estado = "B" THEN "BLOQUEADO"
	     WHEN g54_estado = "R" THEN "RESTRINGIDO"
	END AS estado
	FROM gent054, gent050
	WHERE g54_estado <> "B"
	  AND g50_modulo  = g54_modulo
	  AND g50_modulo NOT IN ("VE", "CH")
	ORDER BY 1, 2;
