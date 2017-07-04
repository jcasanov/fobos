DATABASE aceros


DEFINE base		CHAR(20)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad



MAIN

	IF num_args() <> 3 THEN
		DISPLAY 'Parametros Incorrectos: BASE COMPANIA LOCALIDAD'
	END IF
	LET base   = arg_val(1)
	LET codcia = arg_val(2)
	LET codloc = arg_val(3)
	CALL fl_activar_base_datos(base)
	BEGIN WORK
		CALL verifica_pago_tarjeta_credito_inv()
		CALL verifica_pago_tarjeta_credito_tal()
	COMMIT WORK
	DISPLAY 'Proceso Terminado OK.'

END MAIN



FUNCTION verifica_pago_tarjeta_credito_inv()
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE r_g10		RECORD LIKE gent010.*
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r_z50		RECORD LIKE cxct050.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE mensaje		VARCHAR(100)
DEFINE i		SMALLINT

DISPLAY 'Generando Facturas INVENTARIO con Tarjetas de Credito...'
INITIALIZE r_j10.*, r_j11.* TO NULL
DECLARE q_pagotj CURSOR WITH HOLD FOR
	SELECT * FROM cajt010, cajt011
		WHERE j10_compania          = codcia
		  AND j10_localidad         = codloc
		  AND j10_tipo_fuente       = 'PR'
		  AND YEAR(j10_fecing)      = 2009
		  AND j11_compania          = j10_compania
		  AND j11_localidad         = j10_localidad
		  AND j11_tipo_fuente       = j10_tipo_fuente
		  AND j11_num_fuente        = j10_num_fuente
		  AND j11_codigo_pago[1, 1] = 'T'
OPEN q_pagotj
FETCH q_pagotj INTO r_j10.*, r_j11.*
IF STATUS = NOTFOUND THEN
	CLOSE q_pagotj
	FREE q_pagotj
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET i = 0
FOREACH q_pagotj INTO r_j10.*, r_j11.*
	CALL fl_lee_tarjeta_credito(r_j11.j11_cod_bco_tarj) RETURNING r_g10.*
	IF r_g10.g10_codcobr IS NULL THEN
		ROLLBACK WORK
		LET mensaje = 'Tarjeta de crédito: ' , r_g10.g10_nombre,
				' no tiene código cobranzas asignado. ',
				'Por favor asígnelo en el módulo de ',
				'parametros GENERALES.'
		CALL fl_mostrar_mensaje(mensaje,'stop')
		EXIT PROGRAM
	END IF
	SELECT * FROM cxct020
		WHERE z20_compania  = r_j10.j10_compania
		  AND z20_localidad = r_j10.j10_localidad
		  AND z20_codcli    = r_g10.g10_codcobr
		  AND z20_tipo_doc  = r_j10.j10_tipo_destino
		  AND z20_num_doc   = r_j10.j10_num_destino
		  AND z20_dividendo = 01
		  AND z20_areaneg   = r_j10.j10_areaneg
	IF STATUS <> NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_preventa_rep(codcia, codloc, r_j10.j10_num_fuente)
		RETURNING r_r23.*
	INITIALIZE r_doc.* TO NULL
	LET r_doc.z20_compania 	 = codcia
	LET r_doc.z20_localidad  = codloc
	LET r_doc.z20_codcli 	 = r_g10.g10_codcobr
	LET r_doc.z20_tipo_doc 	 = r_j10.j10_tipo_destino
	LET r_doc.z20_num_doc 	 = r_j10.j10_num_destino
	LET r_doc.z20_dividendo  = 01
	LET r_doc.z20_areaneg 	 = r_j10.j10_areaneg
	LET r_doc.z20_referencia = 'AUI. #: ', r_j11.j11_num_ch_aut
	LET r_doc.z20_fecha_emi  = DATE(r_j10.j10_fecing)
	LET r_doc.z20_fecha_vcto = r_doc.z20_fecha_emi + 30 UNITS DAY
	LET r_doc.z20_tasa_int   = 0
	LET r_doc.z20_tasa_mora  = 0
	LET r_doc.z20_moneda 	 = r_j10.j10_moneda
	LET r_doc.z20_paridad 	 = 1
	LET r_doc.z20_val_impto  = 0
	LET r_doc.z20_valor_cap  = r_j11.j11_valor
	LET r_doc.z20_valor_int  = 0
	LET r_doc.z20_saldo_cap  = r_j11.j11_valor
	LET r_doc.z20_saldo_int  = 0
	LET r_doc.z20_cartera 	 = 1
	LET r_doc.z20_linea 	 = r_r23.r23_grupo_linea
	LET r_doc.z20_origen  	 = 'A'
	LET r_doc.z20_cod_tran   = r_j10.j10_tipo_destino
	LET r_doc.z20_num_tran   = r_j10.j10_num_destino
	LET r_doc.z20_usuario 	 = r_j10.j10_usuario
	LET r_doc.z20_fecing 	 = r_j10.j10_fecing
	INSERT INTO cxct020 VALUES (r_doc.*)
	IF r_doc.z20_fecha_emi < MDY(MONTH(TODAY), 01, YEAR(TODAY)) THEN
		INITIALIZE r_z50.* TO NULL
		LET r_z50.z50_ano        = YEAR(r_doc.z20_fecha_emi)
		LET r_z50.z50_mes        = MONTH(r_doc.z20_fecha_emi)
		LET r_z50.z50_compania 	 = codcia
		LET r_z50.z50_localidad  = codloc
		LET r_z50.z50_codcli 	 = r_g10.g10_codcobr
		LET r_z50.z50_tipo_doc 	 = r_j10.j10_tipo_destino
		LET r_z50.z50_num_doc 	 = r_j10.j10_num_destino
		LET r_z50.z50_dividendo  = 01
		LET r_z50.z50_areaneg 	 = r_j10.j10_areaneg
		LET r_z50.z50_referencia = 'AUI. #: ', r_j11.j11_num_ch_aut
		LET r_z50.z50_fecha_emi  = DATE(r_j10.j10_fecing)
		LET r_z50.z50_fecha_vcto = r_doc.z20_fecha_emi + 30 UNITS DAY
		LET r_z50.z50_tasa_int   = 0
		LET r_z50.z50_tasa_mora  = 0
		LET r_z50.z50_moneda 	 = r_j10.j10_moneda
		LET r_z50.z50_paridad 	 = 1
		LET r_z50.z50_val_impto  = 0
		LET r_z50.z50_valor_cap  = r_j11.j11_valor
		LET r_z50.z50_valor_int  = 0
		LET r_z50.z50_saldo_cap  = r_j11.j11_valor
		LET r_z50.z50_saldo_int  = 0
		LET r_z50.z50_cartera 	 = 1
		LET r_z50.z50_linea 	 = r_r23.r23_grupo_linea
		LET r_z50.z50_origen  	 = 'A'
		LET r_z50.z50_cod_tran   = r_j10.j10_tipo_destino
		LET r_z50.z50_num_tran   = r_j10.j10_num_destino
		LET r_z50.z50_usuario 	 = r_j10.j10_usuario
		LET r_z50.z50_fecing 	 = CURRENT
		INSERT INTO cxct050 VALUES (r_z50.*)
	END IF
	CALL fl_lee_tipo_pago_caja(codcia, r_j11.j11_codigo_pago, 'C')
		RETURNING r_j01.*
	DISPLAY '  Fact.: ', r_j10.j10_tipo_destino, ' ',
		r_j10.j10_num_destino USING "<<<<<<&", '  Tar.: ',
		r_j11.j11_codigo_pago, ' ', r_j01.j01_nombre CLIPPED, ' Cod. ',
		r_j11.j11_cod_bco_tarj USING "<<<<<<&", '.'
	CALL fl_genera_saldos_cliente(codcia, codloc, r_g10.g10_codcobr)
	LET i = i + 1
END FOREACH
DISPLAY ' Se generaron ', i USING "<<<<<&", ' facturas (IN) tarjeta credito',
	' en Cobranzas. OK'
DISPLAY ' '

END FUNCTION



FUNCTION verifica_pago_tarjeta_credito_tal()
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE r_g10		RECORD LIKE gent010.*
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r_z50		RECORD LIKE cxct050.*
DEFINE r_t01		RECORD LIKE talt001.*
DEFINE r_t04		RECORD LIKE talt004.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE mensaje		VARCHAR(100)
DEFINE i		SMALLINT

DISPLAY 'Generando Facturas TALLER con Tarjetas de Credito...'
INITIALIZE r_j10.*, r_j11.* TO NULL
DECLARE q_pagotj2 CURSOR WITH HOLD FOR
	SELECT * FROM cajt010, cajt011
		WHERE j10_compania          = codcia
		  AND j10_localidad         = codloc
		  AND j10_tipo_fuente       = 'OT'
		  AND YEAR(j10_fecing)      = 2009
		  AND j11_compania          = j10_compania
		  AND j11_localidad         = j10_localidad
		  AND j11_tipo_fuente       = j10_tipo_fuente
		  AND j11_num_fuente        = j10_num_fuente
		  AND j11_codigo_pago[1, 1] = 'T'
OPEN q_pagotj2
FETCH q_pagotj2 INTO r_j10.*, r_j11.*
IF STATUS = NOTFOUND THEN
	CLOSE q_pagotj2
	FREE q_pagotj2
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET i = 0
FOREACH q_pagotj2 INTO r_j10.*, r_j11.*
	CALL fl_lee_tarjeta_credito(r_j11.j11_cod_bco_tarj) RETURNING r_g10.*
	IF r_g10.g10_codcobr IS NULL THEN
		ROLLBACK WORK
		LET mensaje = 'Tarjeta de crédito: ' , r_g10.g10_nombre,
				' no tiene código cobranzas asignado. ',
				'Por favor asígnelo en el módulo de ',
				'parametros GENERALES.'
		CALL fl_mostrar_mensaje(mensaje,'stop')
		EXIT PROGRAM
	END IF
	SELECT * FROM cxct020
		WHERE z20_compania  = r_j10.j10_compania
		  AND z20_localidad = r_j10.j10_localidad
		  AND z20_codcli    = r_g10.g10_codcobr
		  AND z20_tipo_doc  = r_j10.j10_tipo_destino
		  AND z20_num_doc   = r_j10.j10_num_destino
		  AND z20_dividendo = 01
		  AND z20_areaneg   = r_j10.j10_areaneg
	IF STATUS <> NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_orden_trabajo(codcia, codloc, r_j10.j10_num_fuente)
		RETURNING r_t23.*
	CALL fl_lee_tipo_vehiculo(codcia, r_t23.t23_modelo) RETURNING r_t04.*
	CALL fl_lee_linea_taller(codcia, r_t04.t04_linea) RETURNING r_t01.*
	INITIALIZE r_doc.* TO NULL
	LET r_doc.z20_compania 	 = codcia
	LET r_doc.z20_localidad  = codloc
	LET r_doc.z20_codcli 	 = r_g10.g10_codcobr
	LET r_doc.z20_tipo_doc 	 = r_j10.j10_tipo_destino
	LET r_doc.z20_num_doc 	 = r_j10.j10_num_destino
	LET r_doc.z20_dividendo  = 01
	LET r_doc.z20_areaneg 	 = r_j10.j10_areaneg
	LET r_doc.z20_referencia = 'AUI. #: ', r_j11.j11_num_ch_aut
	LET r_doc.z20_fecha_emi  = DATE(r_j10.j10_fecing)
	LET r_doc.z20_fecha_vcto = r_doc.z20_fecha_emi + 30 UNITS DAY
	LET r_doc.z20_tasa_int   = 0
	LET r_doc.z20_tasa_mora  = 0
	LET r_doc.z20_moneda 	 = r_j10.j10_moneda
	LET r_doc.z20_paridad 	 = 1
	LET r_doc.z20_val_impto  = 0
	LET r_doc.z20_valor_cap  = r_j11.j11_valor
	LET r_doc.z20_valor_int  = 0
	LET r_doc.z20_saldo_cap  = r_j11.j11_valor
	LET r_doc.z20_saldo_int  = 0
	LET r_doc.z20_cartera 	 = 1
	LET r_doc.z20_linea 	 = r_t01.t01_grupo_linea
	LET r_doc.z20_origen  	 = 'A'
	LET r_doc.z20_cod_tran   = r_j10.j10_tipo_destino
	LET r_doc.z20_num_tran   = r_j10.j10_num_destino
	LET r_doc.z20_usuario 	 = r_j10.j10_usuario
	LET r_doc.z20_fecing 	 = r_j10.j10_fecing
	INSERT INTO cxct020 VALUES (r_doc.*)
	IF r_doc.z20_fecha_emi < MDY(MONTH(TODAY), 01, YEAR(TODAY)) THEN
		INITIALIZE r_z50.* TO NULL
		LET r_z50.z50_ano        = YEAR(r_doc.z20_fecha_emi)
		LET r_z50.z50_mes        = MONTH(r_doc.z20_fecha_emi)
		LET r_z50.z50_compania 	 = codcia
		LET r_z50.z50_localidad  = codloc
		LET r_z50.z50_codcli 	 = r_g10.g10_codcobr
		LET r_z50.z50_tipo_doc 	 = r_j10.j10_tipo_destino
		LET r_z50.z50_num_doc 	 = r_j10.j10_num_destino
		LET r_z50.z50_dividendo  = 01
		LET r_z50.z50_areaneg 	 = r_j10.j10_areaneg
		LET r_z50.z50_referencia = 'AUI. #: ', r_j11.j11_num_ch_aut
		LET r_z50.z50_fecha_emi  = DATE(r_j10.j10_fecing)
		LET r_z50.z50_fecha_vcto = r_doc.z20_fecha_emi + 30 UNITS DAY
		LET r_z50.z50_tasa_int   = 0
		LET r_z50.z50_tasa_mora  = 0
		LET r_z50.z50_moneda 	 = r_j10.j10_moneda
		LET r_z50.z50_paridad 	 = 1
		LET r_z50.z50_val_impto  = 0
		LET r_z50.z50_valor_cap  = r_j11.j11_valor
		LET r_z50.z50_valor_int  = 0
		LET r_z50.z50_saldo_cap  = r_j11.j11_valor
		LET r_z50.z50_saldo_int  = 0
		LET r_z50.z50_cartera 	 = 1
		LET r_z50.z50_linea 	 = r_t01.t01_grupo_linea
		LET r_z50.z50_origen  	 = 'A'
		LET r_z50.z50_cod_tran   = r_j10.j10_tipo_destino
		LET r_z50.z50_num_tran   = r_j10.j10_num_destino
		LET r_z50.z50_usuario 	 = r_j10.j10_usuario
		LET r_z50.z50_fecing 	 = CURRENT
		INSERT INTO cxct050 VALUES (r_z50.*)
	END IF
	CALL fl_lee_tipo_pago_caja(codcia, r_j11.j11_codigo_pago, 'C')
		RETURNING r_j01.*
	DISPLAY '  Fact.: ', r_j10.j10_tipo_destino, ' ',
		r_j10.j10_num_destino USING "<<<<<<&", '  Tar.: ',
		r_j11.j11_codigo_pago, ' ', r_j01.j01_nombre CLIPPED, ' Cod. ',
		r_j11.j11_cod_bco_tarj USING "<<<<<<&", '.'
	CALL fl_genera_saldos_cliente(codcia, codloc, r_g10.g10_codcobr)
	LET i = i + 1
END FOREACH
DISPLAY ' Se generaron ', i USING "<<<<<&", ' facturas (TA) tarjeta credito',
	' en Cobranzas. OK'
DISPLAY ' '

END FUNCTION
