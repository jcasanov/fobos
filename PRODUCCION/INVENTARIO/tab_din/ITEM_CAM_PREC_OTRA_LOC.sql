SELECT r10_codigo AS item,
	r10_nombre AS descripcion,
	r10_marca AS marca,
	r10_cantveh AS actprec,
	r10_precio_mb AS precio_act,
	r10_precio_ant AS precio_ant,
	r10_fec_cosrepo AS fecha_modif,
	CASE WHEN r10_estado = 'A'
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado
	FROM rept010
	WHERE r10_compania = 1
	  AND r10_estado   = 'A'
	  AND ((r10_marca  IN ('EDESA', 'ECERAM', 'FVGRIF', 'FVSANI', 'KERAMI',
				'PLYCEM', 'RIALTO', 'MICHEL', 'ROOFTE',
				'CREIN ', 'CESA', 'SIDEC', 'ICAMET'))
	   OR   r10_marca  MATCHES 'CALO*'
	   OR   r10_marca  MATCHES 'RIAL*'
	   OR   r10_marca  MATCHES 'ECUA*'
	   OR   r10_marca  MATCHES 'KERAM*'
	   OR   r10_marca  MATCHES 'CRAM*'
	   OR   r10_marca  MATCHES "FV*"
	   OR   r10_marca  MATCHES "EDES*"
	   OR   r10_marca  MATCHES "TEK*")
	  AND r10_cantveh  = 0;
