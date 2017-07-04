SET ISOLATION TO DIRTY READ;

BEGIN WORK;

UPDATE rept010
	SET r10_cantveh     = 1,
	    r10_usu_cosrepo = 'HSALAZAR',
	    r10_fec_cosrepo = CURRENT
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

COMMIT WORK;
