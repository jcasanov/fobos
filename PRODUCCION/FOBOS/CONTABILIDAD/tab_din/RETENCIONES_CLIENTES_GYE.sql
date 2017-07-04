SELECT 
	'GUAYAQUIL' CIUDAD,
	j10_localidad LOC,
	CASE
		WHEN j10_tipo_destino = "PG"	THEN "CREDITO" 
		WHEN j10_tipo_destino = "FA"	THEN "CONTADO"
	END TIPO,
	j10_tipo_fuente fuente,
	z01_num_doc_id CODCLI,
	j10_nomcli NOMCLI,
	j10_tipo_destino TIPODOC, 
	j10_num_destino NUMDOC,
--	r38_num_sri SRIDOC,
	j11_num_ch_aut SRIRET,
	j11_valor VALORRET,
        CASE
                WHEN month(j10_fecing) = 1 THEN "ENE"
                WHEN month(j10_fecing) = 2 THEN "FEB"
                WHEN month(j10_fecing) = 3 THEN "MAR"
                WHEN month(j10_fecing) = 4 THEN "ABR"
                WHEN month(j10_fecing) = 5 THEN "MAY"
                WHEN month(j10_fecing) = 6 THEN "JUN"
                WHEN month(j10_fecing) = 7 THEN "JUL"
                WHEN month(j10_fecing) = 8 THEN "AGO"
                WHEN month(j10_fecing) = 9 THEN "SEP"
                WHEN month(j10_fecing) = 10 THEN "OCT"
                WHEN month(j10_fecing) = 11 THEN "NOV"
                WHEN month(j10_fecing) = 12 THEN "DIC"
        END MES,
	year(j10_fecing) ANIO,
	j10_fecing fechaFacRet,
	j14_fec_emi_fact fecfac,
	j14_num_fact_sri numfacsri,
	j14_cod_tran codtran,
	j14_num_tran numfacint,
	j14_base_imp baseret


FROM
	acero_gm:cajt010 j10, 
	acero_gm:cajt011, 
	acero_gm:cajt014, 
	acero_gm:cxct001

WHERE
	j10_compania 	=	j11_compania	AND
	j10_localidad 	=	j11_localidad	AND
	j10_tipo_fuente	=	j11_tipo_fuente	AND
	j10_num_fuente	=	j11_num_fuente	AND

	z01_codcli	=	j10_codcli	AND

--	year(j10_fecing) >= 2006 AND
	j11_codigo_pago = "RT"   AND
	j10_estado 	= "P"	 AND
	j10_tipo_destino IN ("FA","PG")
	AND j14_compania    = j11_compania
        AND j14_localidad   = j11_localidad
        AND j14_tipo_fuente = j11_tipo_fuente
        AND j14_num_fuente  = j11_num_fuente
        AND j14_secuencia   = j14_secuencia
