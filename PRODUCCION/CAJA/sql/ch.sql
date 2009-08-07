SELECT z26_estado FROM cxct026
	WHERE EXISTS (SELECT z26_compania, z26_localidad, z26_codcli,
		             z26_banco,    z26_num_cta,   z26_num_cheque
  			FROM cajt011
  			WHERE j11_compania    = 1
  		  	  AND j11_localidad   = 1
  			  AND j11_tipo_fuente = 'SC'
  			  AND j11_num_fuente  = 13
  			  AND j11_codigo_pago = 'CH'
  			  AND j11_protestado  = 'N'
  			  AND z26_compania    = j11_compania
  			  AND z26_localidad   = j11_localidad
  			  AND z26_codcli      = 450
  			  AND z26_banco       = j11_cod_bco_tarj
  			  AND z26_num_cta     = j11_num_cta_tarj
  			  AND z26_num_cheque  = j11_num_ch_aut
  			  AND z26_estado     <> 'A')
