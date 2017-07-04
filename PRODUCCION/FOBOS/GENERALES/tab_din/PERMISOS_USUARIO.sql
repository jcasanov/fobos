SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = g53_compania
		  AND g02_localidad = 1) AS local,
	g54_proceso AS proc,
	g54_nombre AS nomproc,
	g50_nombre AS modu,
	CASE WHEN g54_tipo = "C" THEN "CONSULTA"
	     WHEN g54_tipo = "R" THEN "REPORTE"
	     WHEN g54_tipo = "P" THEN "PROCESO"
	     WHEN g54_tipo = "M" THEN "MANTENIMIENTO"
	     WHEN g54_tipo = "E" THEN "ESPECIAL"
	     WHEN g54_tipo = "N" THEN "MENU"
	END AS tip,
	CASE WHEN g54_estado = "A" THEN "ACTIVO"
	     WHEN g54_estado = "B" THEN "BLOQUEADO"
	     WHEN g54_estado = "R" THEN "RESTRINGIDO"
	END AS est,
	"X" AS per_men,
	NVL((SELECT "X"
		FROM gent057
		WHERE g57_user     = g05_usuario
		  AND g57_compania = g53_compania
		  AND g57_modulo   = g50_modulo
		  AND g57_proceso  = g54_proceso), "") AS per_pro,
	g53_usuario AS usua,
	g05_nombres AS nom_usu,
	g04_nombre AS grup,
	CASE WHEN g05_tipo = "AG" THEN "ADMINISTRADOR GENERAL"
	     WHEN g05_tipo = "AM" THEN "ADMINISTRADOR MODULO"
	     WHEN g05_tipo = "UF" THEN "USUARIO FINAL"
	END AS tip_usu,
	NVL((SELECT "MODIFICA PRECIO PROFORMAS"
		FROM rept001
		WHERE r01_compania   = g53_compania
		  AND r01_user_owner = g53_usuario
		  AND r01_mod_descto = "S"),
		"NO CAMBIA PRECIOS") AS cam_prec,
	NVL((SELECT CASE WHEN r01_tipo = "I" THEN "INTERNO"
			 WHEN r01_tipo = "E" THEN "EXTERNO"
			 WHEN r01_tipo = "B" THEN "BODEGUERO"
			 WHEN r01_tipo = "J" THEN "JEFE VENTAS/BODEGA"
			 WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
			END
		FROM rept001
		WHERE r01_compania   = g53_compania
		  AND r01_user_owner = g53_usuario),
		"USUARIO ADMINISTRATIVO") AS tip_v,
	CASE WHEN g05_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_usu
	FROM gent053, gent005, gent004, gent050, gent054
	WHERE g53_compania = 1
	  AND g05_usuario  = g53_usuario
	  AND g04_grupo    = g05_grupo
	  AND g50_modulo   = g53_modulo
	  AND g50_estado   = "A"
	  AND g54_modulo   = g50_modulo
	  AND NOT EXISTS
		(SELECT 1 FROM gent055
			WHERE g55_user     = g05_usuario
			  AND g55_compania = g53_compania
			  AND g55_modulo   = g50_modulo
			  AND g55_proceso  = g54_proceso)
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_gc:gent002
		WHERE g02_compania  = g53_compania
		  AND g02_localidad = 2) AS local,
	g54_proceso AS proc,
	g54_nombre AS nomproc,
	g50_nombre AS modu,
	CASE WHEN g54_tipo = "C" THEN "CONSULTA"
	     WHEN g54_tipo = "R" THEN "REPORTE"
	     WHEN g54_tipo = "P" THEN "PROCESO"
	     WHEN g54_tipo = "M" THEN "MANTENIMIENTO"
	     WHEN g54_tipo = "E" THEN "ESPECIAL"
	     WHEN g54_tipo = "N" THEN "MENU"
	END AS tip,
	CASE WHEN g54_estado = "A" THEN "ACTIVO"
	     WHEN g54_estado = "B" THEN "BLOQUEADO"
	     WHEN g54_estado = "R" THEN "RESTRINGIDO"
	END AS est,
	"X" AS per_men,
	NVL((SELECT "X"
		FROM acero_gc:gent057
		WHERE g57_user     = g05_usuario
		  AND g57_compania = g53_compania
		  AND g57_modulo   = g50_modulo
		  AND g57_proceso  = g54_proceso), "") AS per_pro,
	g53_usuario AS usua,
	g05_nombres AS nom_usu,
	g04_nombre AS grup,
	CASE WHEN g05_tipo = "AG" THEN "ADMINISTRADOR GENERAL"
	     WHEN g05_tipo = "AM" THEN "ADMINISTRADOR MODULO"
	     WHEN g05_tipo = "UF" THEN "USUARIO FINAL"
	END AS tip_usu,
	NVL((SELECT "MODIFICA PRECIO PROFORMAS"
		FROM acero_gc:rept001
		WHERE r01_compania   = g53_compania
		  AND r01_user_owner = g53_usuario
		  AND r01_mod_descto = "S"),
		"NO CAMBIA PRECIOS") AS cam_prec,
	NVL((SELECT CASE WHEN r01_tipo = "I" THEN "INTERNO"
			 WHEN r01_tipo = "E" THEN "EXTERNO"
			 WHEN r01_tipo = "B" THEN "BODEGUERO"
			 WHEN r01_tipo = "J" THEN "JEFE VENTAS/BODEGA"
			 WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
			END
		FROM acero_gc:rept001
		WHERE r01_compania   = g53_compania
		  AND r01_user_owner = g53_usuario),
		"USUARIO ADMINISTRATIVO") AS tip_v,
	CASE WHEN g05_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_usu
	FROM acero_gc:gent053, acero_gc:gent005, acero_gc:gent004,
		acero_gc:gent050, acero_gc:gent054
	WHERE g53_compania = 1
	  AND g05_usuario  = g53_usuario
	  AND g04_grupo    = g05_grupo
	  AND g50_modulo   = g53_modulo
	  AND g50_estado   = "A"
	  AND g54_modulo   = g50_modulo
	  AND NOT EXISTS
		(SELECT 1 FROM acero_gc:gent055
			WHERE g55_user     = g05_usuario
			  AND g55_compania = g53_compania
			  AND g55_modulo   = g50_modulo
			  AND g55_proceso  = g54_proceso)
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm@acgyede:gent002
		WHERE g02_compania  = g53_compania
		  AND g02_localidad = 3) AS local,
	g54_proceso AS proc,
	g54_nombre AS nomproc,
	g50_nombre AS modu,
	CASE WHEN g54_tipo = "C" THEN "CONSULTA"
	     WHEN g54_tipo = "R" THEN "REPORTE"
	     WHEN g54_tipo = "P" THEN "PROCESO"
	     WHEN g54_tipo = "M" THEN "MANTENIMIENTO"
	     WHEN g54_tipo = "E" THEN "ESPECIAL"
	     WHEN g54_tipo = "N" THEN "MENU"
	END AS tip,
	CASE WHEN g54_estado = "A" THEN "ACTIVO"
	     WHEN g54_estado = "B" THEN "BLOQUEADO"
	     WHEN g54_estado = "R" THEN "RESTRINGIDO"
	END AS est,
	"X" AS per_men,
	NVL((SELECT "X"
		FROM acero_qm@acgyede:gent057
		WHERE g57_user     = g05_usuario
		  AND g57_compania = g53_compania
		  AND g57_modulo   = g50_modulo
		  AND g57_proceso  = g54_proceso), "") AS per_pro,
	g53_usuario AS usua,
	g05_nombres AS nom_usu,
	g04_nombre AS grup,
	CASE WHEN g05_tipo = "AG" THEN "ADMINISTRADOR GENERAL"
	     WHEN g05_tipo = "AM" THEN "ADMINISTRADOR MODULO"
	     WHEN g05_tipo = "UF" THEN "USUARIO FINAL"
	END AS tip_usu,
	NVL((SELECT "MODIFICA PRECIO PROFORMAS"
		FROM acero_qm@acgyede:rept001
		WHERE r01_compania   = g53_compania
		  AND r01_codigo     NOT IN (10, 50, 70)
		  AND r01_user_owner = g53_usuario
		  AND r01_mod_descto = "S"),
		"NO CAMBIA PRECIOS") AS cam_prec,
	NVL((SELECT CASE WHEN r01_tipo = "I" THEN "INTERNO"
			 WHEN r01_tipo = "E" THEN "EXTERNO"
			 WHEN r01_tipo = "B" THEN "BODEGUERO"
			 WHEN r01_tipo = "J" THEN "JEFE VENTAS/BODEGA"
			 WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
			END
		FROM acero_qm@acgyede:rept001
		WHERE r01_compania   = g53_compania
		  AND r01_codigo     NOT IN (10, 50, 70)
		  AND r01_user_owner = g53_usuario),
		"USUARIO ADMINISTRATIVO") AS tip_v,
	CASE WHEN g05_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_usu
	FROM acero_qm@acgyede:gent053, acero_qm@acgyede:gent005,
		acero_qm@acgyede:gent004, acero_qm@acgyede:gent050,
		acero_qm@acgyede:gent054
	WHERE g53_compania = 1
	  AND g05_usuario  = g53_usuario
	  AND g04_grupo    = g05_grupo
	  AND g50_modulo   = g53_modulo
	  AND g50_estado   = "A"
	  AND g54_modulo   = g50_modulo
	  AND NOT EXISTS
		(SELECT 1 FROM acero_qm@acgyede:gent055
			WHERE g55_user     = g05_usuario
			  AND g55_compania = g53_compania
			  AND g55_modulo   = g50_modulo
			  AND g55_proceso  = g54_proceso)
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qs@acgyede:gent002
		WHERE g02_compania  = g53_compania
		  AND g02_localidad = 4) AS local,
	g54_proceso AS proc,
	g54_nombre AS nomproc,
	g50_nombre AS modu,
	CASE WHEN g54_tipo = "C" THEN "CONSULTA"
	     WHEN g54_tipo = "R" THEN "REPORTE"
	     WHEN g54_tipo = "P" THEN "PROCESO"
	     WHEN g54_tipo = "M" THEN "MANTENIMIENTO"
	     WHEN g54_tipo = "E" THEN "ESPECIAL"
	     WHEN g54_tipo = "N" THEN "MENU"
	END AS tip,
	CASE WHEN g54_estado = "A" THEN "ACTIVO"
	     WHEN g54_estado = "B" THEN "BLOQUEADO"
	     WHEN g54_estado = "R" THEN "RESTRINGIDO"
	END AS est,
	"X" AS per_men,
	NVL((SELECT "X"
		FROM acero_qs@acgyede:gent057
		WHERE g57_user     = g05_usuario
		  AND g57_compania = g53_compania
		  AND g57_modulo   = g50_modulo
		  AND g57_proceso  = g54_proceso), "") AS per_pro,
	g53_usuario AS usua,
	g05_nombres AS nom_usu,
	g04_nombre AS grup,
	CASE WHEN g05_tipo = "AG" THEN "ADMINISTRADOR GENERAL"
	     WHEN g05_tipo = "AM" THEN "ADMINISTRADOR MODULO"
	     WHEN g05_tipo = "UF" THEN "USUARIO FINAL"
	END AS tip_usu,
	NVL((SELECT "MODIFICA PRECIO PROFORMAS"
		FROM acero_qs@acgyede:rept001
		WHERE r01_compania   = g53_compania
		  AND r01_user_owner = g53_usuario
		  AND r01_mod_descto = "S"),
		"NO CAMBIA PRECIOS") AS cam_prec,
	NVL((SELECT CASE WHEN r01_tipo = "I" THEN "INTERNO"
			 WHEN r01_tipo = "E" THEN "EXTERNO"
			 WHEN r01_tipo = "B" THEN "BODEGUERO"
			 WHEN r01_tipo = "J" THEN "JEFE VENTAS/BODEGA"
			 WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
			END
		FROM acero_qs@acgyede:rept001
		WHERE r01_compania   = g53_compania
		  AND r01_user_owner = g53_usuario),
		"USUARIO ADMINISTRATIVO") AS tip_v,
	CASE WHEN g05_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_usu
	FROM acero_qs@acgyede:gent053, acero_qs@acgyede:gent005,
		acero_qs@acgyede:gent004, acero_qs@acgyede:gent050,
		acero_qs@acgyede:gent054
	WHERE g53_compania = 1
	  AND g05_usuario  = g53_usuario
	  AND g04_grupo    = g05_grupo
	  AND g50_modulo   = g53_modulo
	  AND g50_estado   = "A"
	  AND g54_modulo   = g50_modulo
	  AND NOT EXISTS
		(SELECT 1 FROM acero_qs@acgyede:gent055
			WHERE g55_user     = g05_usuario
			  AND g55_compania = g53_compania
			  AND g55_modulo   = g50_modulo
			  AND g55_proceso  = g54_proceso);
