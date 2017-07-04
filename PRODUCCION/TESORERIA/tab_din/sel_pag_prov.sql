SELECT b12_fec_proceso AS fecha,
	COUNT(*) AS total_pagos
	FROM ctbt012
	WHERE b12_compania          = 1
	  AND b12_estado            = 'M'
	  AND b12_tipo_comp         = "EG"
	  AND YEAR(b12_fec_proceso) = 2012
	GROUP BY 1
	ORDER BY 1;
