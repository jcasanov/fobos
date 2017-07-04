DATABASE acero_gm

MAIN

CALL arregla_aux_tarjeta_cred()

END MAIN



FUNCTION arregla_aux_tarjeta_cred()
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE r_g10		RECORD LIKE gent010.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE i		SMALLINT
DEFINE num_reg		INTEGER
DEFINE expr		CHAR(80)

DECLARE q_tj CURSOR FOR 
	SELECT acero_gc:cajt010.*, acero_gc:cajt011.* 
	FROM acero_gc:cajt011, acero_gc:cajt010
	WHERE j11_codigo_pago = 'TJ' AND 
	      j11_compania    = j10_compania    AND 
	      j11_localidad   = j10_localidad   AND 
	      j10_tipo_fuente = j11_tipo_fuente AND
	      j10_num_fuente  = j11_num_fuente
LET i = 0
FOREACH q_tj INTO r_j10.*, r_j11.*
	 DISPLAY r_j10.j10_tipo_destino, ' ', r_j10.j10_num_destino, ' ',
		 r_j10.j10_fecha_pro
	 LET expr = '*' || r_j10.j10_num_destino  CLIPPED || '*'
	 SELECT ctbt013.*, ROWID INTO r_b13.*, num_reg FROM ctbt013
		WHERE b13_compania   = r_j11.j11_compania AND 
   		      b13_valor_base = r_j11.j11_valor    AND 
		      b13_tipo_comp  = 'DR' AND
		      b13_cuenta     = '11210101001' AND 
		      b13_glosa      MATCHES expr
	IF status = NOTFOUND THEN
		DISPLAY 'No existe.'
		CONTINUE FOREACH
	END IF
	LET i = i + 1
	DISPLAY i, ' ', r_j10.j10_tipo_destino, ' ', 
		r_j10.j10_num_destino, ' ', r_b13.b13_glosa
	SELECT * INTO r_g10.* FROM gent010
		WHERE g10_tarjeta = r_j11.j11_cod_bco_tarj
	IF status = NOTFOUND THEN
		DISPLAY 'No existe tarjeta.'
		CONTINUE FOREACH
	END IF
	IF r_g10.g10_codcobr IS NULL THEN
		DISPLAY 'Cod. cobranzas de tarjeta es nulo.'
		CONTINUE FOREACH
	END IF
	SELECT * INTO r_z02.* FROM cxct002 
		WHERE z02_compania  = r_j11.j11_compania  AND 
		      z02_localidad = r_j11.j11_localidad AND 
		      z02_codcli    = r_g10.g10_codcobr
	IF status = NOTFOUND THEN
		DISPLAY 'No existe cliente: ', r_g10.g10_codcobr
		CONTINUE FOREACH
	END IF
	IF r_z02.z02_aux_clte_mb IS NULL THEN
		DISPLAY 'Auxiliar cliente nulo en: ', r_g10.g10_codcobr
		CONTINUE FOREACH
	END IF
	UPDATE ctbt013 SET b13_cuenta = r_z02.z02_aux_clte_mb
		WHERE ROWID = num_reg
END FOREACH

END FUNCTION
