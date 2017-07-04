SELECT 
	"VENTAS" documento,
	CASE	WHEN	b10_cuenta  MATCHES "4102*" THEN
		"IVA 0%"
		WHEN	b10_cuenta  MATCHES "4101*" THEN
		"CON IVA"
		WHEN	(b10_cuenta  = "42010101014" OR
			 b10_cuenta  = "42010101015") THEN
		"SEMINARIO"
		ELSE
		"XXX"
	END tipo,

	CASE	WHEN	b10_cuenta  MATCHES "410201*" THEN
		"ESTATALES"
		WHEN  	b10_cuenta  MATCHES "410202*" THEN
		"OTROS"
		WHEN	b10_cuenta  MATCHES "4101*" THEN
		"12%"
		WHEN	(b10_cuenta  = "42010101014" OR
			 b10_cuenta  = "42010101015") THEN
		"SEMINARIO TALLER"
		ELSE
		"TRANSPORTE"
	END subtipo,

        CASE
                WHEN MONTH(b12_fec_proceso) = 1 THEN "ENE"
                WHEN MONTH(b12_fec_proceso) = 2 THEN "FEB"
                WHEN MONTH(b12_fec_proceso) = 3 THEN "MAR"
                WHEN MONTH(b12_fec_proceso) = 4 THEN "ABR"
                WHEN MONTH(b12_fec_proceso) = 5 THEN "MAY"
                WHEN MONTH(b12_fec_proceso) = 6 THEN "JUN"
                WHEN MONTH(b12_fec_proceso) = 7 THEN "JUL"
                WHEN MONTH(b12_fec_proceso) = 8 THEN "AGO"
                WHEN MONTH(b12_fec_proceso) = 9 THEN "SEP"
                WHEN MONTH(b12_fec_proceso) = 10 THEN "OCT"
                WHEN MONTH(b12_fec_proceso) = 11 THEN "NOV"
                WHEN MONTH(b12_fec_proceso) = 12 THEN "DIC"
        END MES,

	b13_cuenta CUENTA, b10_descripcion CUENTA_NOMBRE,
	b13_tipo_comp TC, b13_num_comp NUMCOMP, b13_glosa glosa,
	CASE	WHEN	(b10_cuenta  = "42010101014" OR
			 b10_cuenta  = "42010101015") AND
			b13_valor_base > 0
		THEN	0.00
		ELSE	CASE WHEN	(b10_cuenta  = "42010101014" OR
					 b10_cuenta  = "42010101015")
				THEN	(b13_valor_base / 2)
				ELSE	 b13_valor_base
			END
	END   valor
FROM
	ctbt010, ctbt012, ctbt013
WHERE

	YEAR(b12_fec_proceso) = 2010
	AND (b13_cuenta MATCHES "41*"
	 OR  b13_cuenta IN ("42010101014", "42010101015"))

	AND (
	    b13_cuenta 	NOT IN (SELECT UNIQUE b40_dev_venta FROM ctbt040) 
	AND b13_cuenta 	NOT IN (SELECT UNIQUE b44_dev_venta FROM ctbt044) 
	
	AND b13_cuenta  NOT IN (SELECT b43_dvt_mo_tal FROM ctbt043 UNION 
				SELECT b43_dvt_mo_ext FROM ctbt043 UNION
				SELECT b43_dvt_mo_cti FROM ctbt043 UNION
				SELECT b43_dvt_rp_tal FROM ctbt043 UNION
				SELECT b43_dvt_rp_ext FROM ctbt043 UNION
				SELECT b43_dvt_rp_cti FROM ctbt043 UNION
				SELECT b43_dvt_rp_alm FROM ctbt043 UNION
				SELECT b43_dvt_otros1 FROM ctbt043 UNION
				SELECT b43_dvt_otros2 FROM ctbt043)
	AND b13_cuenta  NOT IN (SELECT b45_dvt_mo_tal FROM ctbt045 UNION 
				SELECT b45_dvt_mo_ext FROM ctbt045 UNION
				SELECT b45_dvt_mo_cti FROM ctbt045 UNION
				SELECT b45_dvt_rp_tal FROM ctbt045 UNION
				SELECT b45_dvt_rp_ext FROM ctbt045 UNION
				SELECT b45_dvt_rp_cti FROM ctbt045 UNION
				SELECT b45_dvt_rp_alm FROM ctbt045 UNION
				SELECT b45_dvt_otros1 FROM ctbt045 UNION
				SELECT b45_dvt_otros2 FROM ctbt045)
	) 
	AND (
	    b13_cuenta 	NOT IN (SELECT UNIQUE b40_descuento FROM ctbt040) 
	AND b13_cuenta 	NOT IN (SELECT UNIQUE b44_descuento FROM ctbt044) 
	AND b13_cuenta  NOT IN (SELECT b43_des_mo_tal FROM ctbt043 UNION 
				SELECT b43_des_rp_tal FROM ctbt043 UNION
				SELECT b43_des_rp_alm FROM ctbt043)
	AND b13_cuenta  NOT IN (SELECT b45_des_mo_tal FROM ctbt045 UNION 
				SELECT b45_des_rp_tal FROM ctbt045 UNION
				SELECT b45_des_rp_alm FROM ctbt045)
	)

	AND b12_estado 		<> "E"
	AND b12_compania	= b13_compania
	AND b12_tipo_comp	= b13_tipo_comp
	AND b12_num_comp	= b13_num_comp

	AND b10_compania	= b13_compania
	AND b10_cuenta		= b13_cuenta

UNION ALL

SELECT 
	"VENTAS" documento,
	CASE	WHEN	b10_cuenta  MATCHES "4102*" THEN
		"IVA 0%"
		WHEN	b10_cuenta  MATCHES "4101*" THEN
		"CON IVA"
		WHEN	(b10_cuenta  = "42010101014" OR
			 b10_cuenta  = "42010101015") THEN
		"SEMINARIO"
		ELSE
		"XXX"
	END tipo,
	CASE	WHEN	b10_cuenta  MATCHES "410201*" THEN
		"ESTATALES"
		WHEN  	b10_cuenta  MATCHES "410202*" THEN
		"OTROS"
		WHEN	b10_cuenta  MATCHES "4101*" THEN
		"12%"
		WHEN	(b10_cuenta  = "42010101014" OR
			 b10_cuenta  = "42010101015") THEN
		"SEMINARIO TALLER"
		ELSE
		"TRANSPORTE"
	END subtipo,

        CASE
                WHEN MONTH(b12_fec_proceso) = 1 THEN "ENE"
                WHEN MONTH(b12_fec_proceso) = 2 THEN "FEB"
                WHEN MONTH(b12_fec_proceso) = 3 THEN "MAR"
                WHEN MONTH(b12_fec_proceso) = 4 THEN "ABR"
                WHEN MONTH(b12_fec_proceso) = 5 THEN "MAY"
                WHEN MONTH(b12_fec_proceso) = 6 THEN "JUN"
                WHEN MONTH(b12_fec_proceso) = 7 THEN "JUL"
                WHEN MONTH(b12_fec_proceso) = 8 THEN "AGO"
                WHEN MONTH(b12_fec_proceso) = 9 THEN "SEP"
                WHEN MONTH(b12_fec_proceso) = 10 THEN "OCT"
                WHEN MONTH(b12_fec_proceso) = 11 THEN "NOV"
                WHEN MONTH(b12_fec_proceso) = 12 THEN "DIC"
        END MES,

	b13_cuenta CUENTA, b10_descripcion CUENTA_NOMBRE,
	b13_tipo_comp TC, b13_num_comp NUMCOMP, b13_glosa glosa,
	CASE	WHEN	(b10_cuenta  = "42010101014" OR
			 b10_cuenta  = "42010101015") AND
			b13_valor_base > 0
		THEN	0.00
		ELSE	CASE WHEN	(b10_cuenta  = "42010101014" OR
					 b10_cuenta  = "42010101015")
				THEN	(b13_valor_base / 2)
				ELSE	 b13_valor_base
			END
	END   valor
FROM
	ctbt010, ctbt012, ctbt013
WHERE

	YEAR(b12_fec_proceso) = 2010
	AND b12_subtipo IN (8,52,21,41)
	AND (
	     b13_cuenta IN ("42010101014", "42010101015")
	 OR b13_cuenta 	IN (SELECT UNIQUE b40_descuento FROM ctbt040) 
	OR b13_cuenta 	IN (SELECT UNIQUE b44_descuento FROM ctbt044) 
	OR b13_cuenta  IN (SELECT b43_des_mo_tal FROM ctbt043 UNION 
				SELECT b43_des_rp_tal FROM ctbt043 UNION
				SELECT b43_des_rp_alm FROM ctbt043)
	OR b13_cuenta  IN (SELECT b45_des_mo_tal FROM ctbt045 UNION 
				SELECT b45_des_rp_tal FROM ctbt045 UNION
				SELECT b45_des_rp_alm FROM ctbt045)
	)
	AND b12_estado 		<> "E"
	AND b12_compania	= b13_compania
	AND b12_tipo_comp	= b13_tipo_comp
	AND b12_num_comp	= b13_num_comp

	AND b10_compania	= b13_compania
	AND b10_cuenta		= b13_cuenta

UNION ALL

SELECT 
	"NC" documento,
	CASE	WHEN	b10_cuenta  MATCHES "4102*" THEN
		"IVA 0%"
		WHEN	b10_cuenta  MATCHES "4101*" THEN
		"CON IVA"
		WHEN	(b10_cuenta  = "42010101014" OR
			 b10_cuenta  = "42010101015") THEN
		"SEMINARIO"
		ELSE
		"XXX"
	END tipo,
	CASE	WHEN	b10_cuenta  MATCHES "410201*" THEN
		"ESTATALES"
		WHEN  	b10_cuenta  MATCHES "410202*" THEN
		"OTROS"
		WHEN	b10_cuenta  MATCHES "4101*" THEN
		"12%"
		WHEN	(b10_cuenta  = "42010101014" OR
			 b10_cuenta  = "42010101015") THEN
		"SEMINARIO TALLER"
		ELSE
		"TRANSPORTE"
	END subtipo,

        CASE
                WHEN MONTH(b12_fec_proceso) = 1 THEN "ENE"
                WHEN MONTH(b12_fec_proceso) = 2 THEN "FEB"
                WHEN MONTH(b12_fec_proceso) = 3 THEN "MAR"
                WHEN MONTH(b12_fec_proceso) = 4 THEN "ABR"
                WHEN MONTH(b12_fec_proceso) = 5 THEN "MAY"
                WHEN MONTH(b12_fec_proceso) = 6 THEN "JUN"
                WHEN MONTH(b12_fec_proceso) = 7 THEN "JUL"
                WHEN MONTH(b12_fec_proceso) = 8 THEN "AGO"
                WHEN MONTH(b12_fec_proceso) = 9 THEN "SEP"
                WHEN MONTH(b12_fec_proceso) = 10 THEN "OCT"
                WHEN MONTH(b12_fec_proceso) = 11 THEN "NOV"
                WHEN MONTH(b12_fec_proceso) = 12 THEN "DIC"
        END MES,

	b13_cuenta CUENTA, b10_descripcion CUENTA_NOMBRE,
	b13_tipo_comp TC, b13_num_comp NUMCOMP, b13_glosa glosa,
	CASE	WHEN	(b10_cuenta  = "42010101014" OR
			 b10_cuenta  = "42010101015") AND
			b13_valor_base <= 0
		THEN	0.00
		ELSE	b13_valor_base
	END   valor
FROM
	ctbt010, ctbt012, ctbt013
WHERE

	YEAR(b12_fec_proceso) = 2010
	AND b13_cuenta MATCHES "41*"

	AND (
	     b13_cuenta IN ("42010101014", "42010101015")
    	   	OR b13_cuenta IN (SELECT UNIQUE b40_dev_venta FROM ctbt040) 
 		OR b13_cuenta IN (SELECT UNIQUE b44_dev_venta FROM ctbt044) 
		OR b13_cuenta IN (SELECT b43_dvt_mo_tal FROM ctbt043 UNION 
		 		  SELECT b43_dvt_mo_ext FROM ctbt043 UNION
				  SELECT b43_dvt_mo_cti FROM ctbt043 UNION
				  SELECT b43_dvt_rp_tal FROM ctbt043 UNION
				  SELECT b43_dvt_rp_ext FROM ctbt043 UNION
				  SELECT b43_dvt_rp_cti FROM ctbt043 UNION
				  SELECT b43_dvt_rp_alm FROM ctbt043 UNION
				  SELECT b43_dvt_otros1 FROM ctbt043 UNION
				  SELECT b43_dvt_otros2 FROM ctbt043)
		 OR b13_cuenta IN (SELECT b45_dvt_mo_tal FROM ctbt045 UNION 
				  SELECT b45_dvt_mo_ext FROM ctbt045 UNION
				  SELECT b45_dvt_mo_cti FROM ctbt045 UNION
				  SELECT b45_dvt_rp_tal FROM ctbt045 UNION
				  SELECT b45_dvt_rp_ext FROM ctbt045 UNION
				  SELECT b45_dvt_rp_cti FROM ctbt045 UNION
				  SELECT b45_dvt_rp_alm FROM ctbt045 UNION
				  SELECT b45_dvt_otros1 FROM ctbt045 UNION
				  SELECT b45_dvt_otros2 FROM ctbt045)
	) 
	AND b12_estado 		<> "E"
	AND b12_compania	= b13_compania
	AND b12_tipo_comp	= b13_tipo_comp
	AND b12_num_comp	= b13_num_comp

	AND b10_compania	= b13_compania
	AND b10_cuenta		= b13_cuenta

UNION ALL

SELECT 
	"NC" documento,
	CASE	WHEN	b10_cuenta  MATCHES "4102*" THEN
		"IVA 0%"
		WHEN	b10_cuenta  MATCHES "4101*" THEN
		"CON IVA"
		WHEN	(b10_cuenta  = "42010101014" OR
			 b10_cuenta  = "42010101015") THEN
		"SEMINARIO"
		ELSE
		"XXX"
	END tipo,
	CASE	WHEN	b10_cuenta  MATCHES "410201*" THEN
		"ESTATALES"
		WHEN  	b10_cuenta  MATCHES "410202*" THEN
		"OTROS"
		WHEN	b10_cuenta  MATCHES "4101*" THEN
		"12%"
		WHEN	(b10_cuenta  = "42010101014" OR
			 b10_cuenta  = "42010101015") THEN
		"SEMINARIO TALLER"
		ELSE
		"TRANSPORTE"
	END tipo,

        CASE
                WHEN MONTH(b12_fec_proceso) = 1 THEN "ENE"
                WHEN MONTH(b12_fec_proceso) = 2 THEN "FEB"
                WHEN MONTH(b12_fec_proceso) = 3 THEN "MAR"
                WHEN MONTH(b12_fec_proceso) = 4 THEN "ABR"
                WHEN MONTH(b12_fec_proceso) = 5 THEN "MAY"
                WHEN MONTH(b12_fec_proceso) = 6 THEN "JUN"
                WHEN MONTH(b12_fec_proceso) = 7 THEN "JUL"
                WHEN MONTH(b12_fec_proceso) = 8 THEN "AGO"
                WHEN MONTH(b12_fec_proceso) = 9 THEN "SEP"
                WHEN MONTH(b12_fec_proceso) = 10 THEN "OCT"
                WHEN MONTH(b12_fec_proceso) = 11 THEN "NOV"
                WHEN MONTH(b12_fec_proceso) = 12 THEN "DIC"
        END MES,

	b13_cuenta CUENTA, b10_descripcion CUENTA_NOMBRE,
	b13_tipo_comp TC, b13_num_comp NUMCOMP, b13_glosa glosa,
	CASE	WHEN	(b10_cuenta  = "42010101014" OR
			 b10_cuenta  = "42010101015") AND
			b13_valor_base <= 0
		THEN	0.00
		ELSE	b13_valor_base
	END   valor
FROM
	ctbt010, ctbt012, ctbt013
WHERE

	YEAR(b12_fec_proceso) = 2010
	AND b12_subtipo NOT IN (8,52,21, 41)
	AND (
	     b13_cuenta IN ("42010101014", "42010101015")
	 OR b13_cuenta 	IN (SELECT UNIQUE b40_descuento FROM ctbt040) 
	OR b13_cuenta 	IN (SELECT UNIQUE b44_descuento FROM ctbt044) 
	OR b13_cuenta  IN (SELECT b43_des_mo_tal FROM ctbt043 UNION 
				SELECT b43_des_rp_tal FROM ctbt043 UNION
				SELECT b43_des_rp_alm FROM ctbt043)
	OR b13_cuenta  IN (SELECT b45_des_mo_tal FROM ctbt045 UNION 
				SELECT b45_des_rp_tal FROM ctbt045 UNION
				SELECT b45_des_rp_alm FROM ctbt045)
	)
	AND b12_estado 		<> "E"
	AND b12_compania	= b13_compania
	AND b12_tipo_comp	= b13_tipo_comp
	AND b12_num_comp	= b13_num_comp

	AND b10_compania	= b13_compania
	AND b10_cuenta		= b13_cuenta


UNION ALL

SELECT 
	"RETENCIONES" documento,
	"FUENTE" tipo,
	CASE 	WHEN b13_codcli IS NULL THEN "SIN FILTRO"
	ELSE	"FILTRADAS" END subtipo,

        CASE
                WHEN MONTH(b12_fec_proceso) = 1 THEN "ENE"
                WHEN MONTH(b12_fec_proceso) = 2 THEN "FEB"
                WHEN MONTH(b12_fec_proceso) = 3 THEN "MAR"
                WHEN MONTH(b12_fec_proceso) = 4 THEN "ABR"
                WHEN MONTH(b12_fec_proceso) = 5 THEN "MAY"
                WHEN MONTH(b12_fec_proceso) = 6 THEN "JUN"
                WHEN MONTH(b12_fec_proceso) = 7 THEN "JUL"
                WHEN MONTH(b12_fec_proceso) = 8 THEN "AGO"
                WHEN MONTH(b12_fec_proceso) = 9 THEN "SEP"
                WHEN MONTH(b12_fec_proceso) = 10 THEN "OCT"
                WHEN MONTH(b12_fec_proceso) = 11 THEN "NOV"
                WHEN MONTH(b12_fec_proceso) = 12 THEN "DIC"
        END MES,

	b13_cuenta CUENTA, b10_descripcion CUENTA_NOMBRE,
	b13_tipo_comp TC, b13_num_comp NUMCOMP, b13_glosa glosa,
	b13_valor_base  valor
FROM
	ctbt010, ctbt012, ctbt013
WHERE

	YEAR(b12_fec_proceso) = 2010
	AND (b13_cuenta MATCHES "113*"
	 OR  b13_cuenta IN ("42010101014", "42010101015"))

	AND b13_cuenta IN (
		SELECT UNIQUE z09_aux_cont FROM cxct009 
			WHERE
			 z09_codigo_pago 	<> "RI"
			 AND z09_aux_cont	IS NOT NULL
		UNION
		SELECT UNIQUE j91_aux_cont  FROM ordt002, cajt091
			WHERE	    c02_compania 	= j91_compania
				AND c02_tipo_ret	= j91_tipo_ret
				AND c02_porcentaje 	= j91_porcentaje
				AND j91_codigo_pago	<> "RI"
				AND j91_aux_cont	IS NOT NULL
		UNION
		SELECT UNIQUE j01_aux_cont FROM cajt001 
			WHERE 		j01_retencion = "S" 	
				AND j01_codigo_pago <> "RI"
				AND j01_aux_cont 	IS NOT NULL
	)	

	AND b12_estado 		<> "E"
	AND b12_compania	= b13_compania
	AND b12_tipo_comp	= b13_tipo_comp
	AND b12_num_comp	= b13_num_comp

	AND b10_compania	= b13_compania
	AND b10_cuenta		= b13_cuenta

UNION ALL

SELECT 
	"RETENCIONES" documento,
	"IVA" tipo,
	CASE 	WHEN b13_codcli IS NULL THEN "SIN FILTRO"
	ELSE	"FILTRADAS" END subtipo,

        CASE
                WHEN MONTH(b12_fec_proceso) = 1 THEN "ENE"
                WHEN MONTH(b12_fec_proceso) = 2 THEN "FEB"
                WHEN MONTH(b12_fec_proceso) = 3 THEN "MAR"
                WHEN MONTH(b12_fec_proceso) = 4 THEN "ABR"
                WHEN MONTH(b12_fec_proceso) = 5 THEN "MAY"
                WHEN MONTH(b12_fec_proceso) = 6 THEN "JUN"
                WHEN MONTH(b12_fec_proceso) = 7 THEN "JUL"
                WHEN MONTH(b12_fec_proceso) = 8 THEN "AGO"
                WHEN MONTH(b12_fec_proceso) = 9 THEN "SEP"
                WHEN MONTH(b12_fec_proceso) = 10 THEN "OCT"
                WHEN MONTH(b12_fec_proceso) = 11 THEN "NOV"
                WHEN MONTH(b12_fec_proceso) = 12 THEN "DIC"
        END MES,

	b13_cuenta CUENTA, b10_descripcion CUENTA_NOMBRE,
	b13_tipo_comp TC, b13_num_comp NUMCOMP, b13_glosa glosa,
	b13_valor_base  valor
FROM
	ctbt010, ctbt012, ctbt013
WHERE

	YEAR(b12_fec_proceso) = 2010
	AND (b13_cuenta MATCHES "113*"
	 OR  b13_cuenta IN ("42010101014", "42010101015"))

	AND b13_cuenta IN (
		SELECT UNIQUE z09_aux_cont FROM cxct009 
			WHERE
			 z09_codigo_pago 	= "RI"
			 AND z09_aux_cont	IS NOT NULL
		UNION
		SELECT UNIQUE j91_aux_cont  FROM ordt002, cajt091
			WHERE	    c02_compania 	= j91_compania
				AND c02_tipo_ret	= j91_tipo_ret
				AND c02_porcentaje 	= j91_porcentaje
				AND j91_codigo_pago	= "RI"
				AND j91_aux_cont	IS NOT NULL
		UNION
		SELECT UNIQUE j01_aux_cont FROM cajt001 
			WHERE 		j01_retencion = "S" 	
				AND j01_codigo_pago = "RI"
				AND j01_aux_cont 	IS NOT NULL
	)	

	AND b12_estado 		<> "E"
	AND b12_compania	= b13_compania
	AND b12_tipo_comp	= b13_tipo_comp
	AND b12_num_comp	= b13_num_comp

	AND b10_compania	= b13_compania
	AND b10_cuenta		= b13_cuenta
