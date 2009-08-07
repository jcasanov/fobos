DATABASE diteca 

MAIN

DEFINE r                RECORD LIKE rept017.*

DEFINE codcia		LIKE rept017.r17_compania
DEFINE codloc   	LIKE rept017.r17_localidad
DEFINE codped		LIKE rept017.r17_pedido

DEFINE i		SMALLINT
DEFINE row		INTEGER

INITIALIZE r.* TO NULL
INITIALIZE codcia,   codloc,    codped TO NULL

DECLARE q1 CURSOR FOR 
	SELECT *, ROWID FROM rept017 ORDER BY 1, 2, 3, ROWID

FOREACH q1 INTO r.*, row 
	IF codcia IS NULL OR codcia <> r.r17_compania 
	OR codloc <> r.r17_localidad OR codped <> r.r17_pedido 
	THEN
		LET codcia = r.r17_compania
		LET codloc = r.r17_localidad
		LET codped = r.r17_pedido  
		LET i      = 1
	END IF

	UPDATE rept017 SET r17_orden = i 
		WHERE r17_compania  = r.r17_compania
		  AND r17_localidad = r.r17_localidad
		  AND r17_pedido    = r.r17_pedido
		  AND r17_item      = r.r17_item	

	LET i = i + 1
END FOREACH

END MAIN
