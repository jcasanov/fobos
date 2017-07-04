	SELECT j10_tipo_destino, DATE(j10_fecha_pro),
			g08_nombre, j11_num_cta_tarj, j11_num_ch_aut, 
			j11_protestado, j10_compania, j10_localidad, 
			j10_tipo_fuente, j10_num_fuente, j11_compania,
			j11_localidad, j11_tipo_fuente, j11_num_fuente,
			j11_secuencia, j11_cod_bco_tarj 
			FROM cajt010, cajt011, gent008 
			WHERE j10_compania     =1
			  AND j10_localidad    =1
			  AND j10_areaneg IS NOT NULL
			  AND DATE(j10_fecha_pro) 
			  BETWEEN MDY(12,01,2002) AND MDY(12,17,2002)
			  AND j11_compania     = j10_compania 
			  AND j11_localidad    = j10_localidad
			  AND j11_tipo_fuente  = j10_tipo_fuente 
			  AND j11_num_fuente   = j10_num_fuente 
			  AND j11_codigo_pago  = "CH" 
			  AND j11_protestado   = "N" 
			  AND j11_cod_bco_tarj = g08_banco 
			  AND j11_num_egreso IS NOT NULL 
