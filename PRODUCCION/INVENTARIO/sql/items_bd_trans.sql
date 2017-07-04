SELECT (SELECT g02_abreviacion
		FROM aceros:rept002, aceros:gent002
		WHERE r02_compania  = r11_compania
		  AND r02_codigo    = r11_bodega
		  AND g02_compania  = r02_compania
		  AND g02_localidad = r02_localidad) AS localidad,
	r11_bodega AS bodega,
	(SELECT r02_nombre
		FROM aceros:rept002
		WHERE r02_compania  = r11_compania
		  AND r02_codigo    = r11_bodega) AS nom_bod,
	r11_item AS item,
	r10_nombre AS descripcion
	FROM aceros:rept011, aceros:rept010
	WHERE r11_compania  = 1
	  AND r11_bodega   IN
		(SELECT r19_bodega_ori
			FROM aceros:rept019
			WHERE r19_compania     = r11_compania
			  AND r19_localidad    = 1
			  AND r19_cod_tran     = 'TR'
			  AND r19_bodega_dest IN
			(SELECT r02_codigo
				FROM aceros:rept002
				WHERE r02_compania   = r19_compania
				  AND r02_localidad <> r19_localidad
				  AND r02_area       = 'R'
				  AND r02_tipo      <> 'S'
				  AND r02_estado     = 'A'))
	  AND r10_compania  = r11_compania
	  AND r10_codigo    = r11_item
UNION
SELECT (SELECT g02_abreviacion
		FROM acero_qm:rept002, acero_qm:gent002
		WHERE r02_compania  = r11_compania
		  AND r02_codigo    = r11_bodega
		  AND g02_compania  = r02_compania
		  AND g02_localidad = r02_localidad) AS localidad,
	r11_bodega AS bodega,
	(SELECT r02_nombre
		FROM acero_qm:rept002
		WHERE r02_compania  = r11_compania
		  AND r02_codigo    = r11_bodega) AS nom_bod,
	r11_item AS item,
	r10_nombre AS descripcion
	FROM acero_qm:rept011, acero_qm:rept010
	WHERE r11_compania  = 1
	  AND r11_bodega   IN
		(SELECT r19_bodega_ori
			FROM acero_qm:rept019
			WHERE r19_compania     = r11_compania
			  AND r19_localidad   IN (3, 5)
			  AND r19_cod_tran     = 'TR'
			  AND r19_bodega_dest IN
			(SELECT r02_codigo
				FROM acero_qm:rept002
				WHERE r02_compania   = r19_compania
				  AND r02_localidad <> r19_localidad
				  AND r02_area       = 'R'
				  AND r02_tipo      <> 'S'
				  AND r02_estado     = 'A'))
	  AND r10_compania  = r11_compania
	  AND r10_codigo    = r11_item
UNION
SELECT (SELECT g02_abreviacion
		FROM acero_qs:rept002, acero_qs:gent002
		WHERE r02_compania  = r11_compania
		  AND r02_codigo    = r11_bodega
		  AND g02_compania  = r02_compania
		  AND g02_localidad = r02_localidad) AS localidad,
	r11_bodega AS bodega,
	(SELECT r02_nombre
		FROM acero_qs:rept002
		WHERE r02_compania  = r11_compania
		  AND r02_codigo    = r11_bodega) AS nom_bod,
	r11_item AS item,
	r10_nombre AS descripcion
	FROM acero_qs:rept011, acero_qs:rept010
	WHERE r11_compania  = 1
	  AND r11_bodega   IN
		(SELECT r19_bodega_ori
			FROM acero_qs:rept019
			WHERE r19_compania     = r11_compania
			  AND r19_localidad    = 4
			  AND r19_cod_tran     = 'TR'
			  AND r19_bodega_dest IN
			(SELECT r02_codigo
				FROM acero_qs:rept002
				WHERE r02_compania   = r19_compania
				  AND r02_localidad <> r19_localidad
				  AND r02_area       = 'R'
				  AND r02_tipo      <> 'S'
				  AND r02_estado     = 'A'))
	  AND r10_compania  = r11_compania
	  AND r10_codigo    = r11_item
