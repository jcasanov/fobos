SELECT
        "CO" MODULO,
--        c01_nombre SUSTENTO,
	s23_sustento_tri SUSTENTO,
	"01" IDTIPO,
        p01_num_doc IDPROV,
	1 TC,
        c10_factura[1,3] ESTABLECIMIENTO,
        c10_factura[5,7] PEMISION,
        c10_factura[9,15] SECUENCIA,
	c13_num_aut  AUT,
	day(c13_fecha_recep) || "/" || month(c13_fecha_recep) || "/"  || year(c13_fecha_recep) FECHA_REG,
	day(c13_fecha_recep) || "/" || month(c13_fecha_recep) || "/"  || year(c13_fecha_recep) FECHA_EMI,
	month(today) || "/"  || year(today) FECHA_CAD,
        CASE 	WHEN c10_tot_impto = 0	THEN 	c10_tot_compra
		ELSE	0
	END	BASE_SIN,
        CASE 	WHEN c10_tot_impto > 0	THEN	(c10_tot_compra - c10_tot_impto)
		ELSE	0
	END	BASE_CON,
	0 BASE_ICE, 12 IVA, 0 ICE,
	c10_tot_impto MONTO_IVA,
	0 MONTO_ICE,
--	NVL(p28_codigo_sri,307) AIR,	
--	p28_valor_base AIR_BASE,
--	p28_valor_ret AIR_RET,
--	p28_porcentaje,

	NVL((SELECT 
		p28_valor_base || ", " || p28_porcentaje || ", " || p28_valor_ret  
	 FROM
		cxpt028, cxpt027, ordt002
	 WHERE
		p27_estado = "A" AND
		p28_tipo_ret = "I" AND
		c02_tipo_fuente = "B" AND

		p27_compania = p28_compania AND
		p27_localidad = p28_localidad AND
		p27_num_ret = p28_num_ret AND
	
		p28_compania = p20_compania AND
		p28_localidad = p20_localidad AND
		p28_tipo_doc = p20_tipo_doc AND
		p28_num_doc = p20_num_doc AND
		p28_codprov = p20_codprov AND
		p28_dividendo = p20_dividendo AND


		c02_compania = p28_compania AND
		c02_tipo_ret = p28_tipo_ret AND
		c02_porcentaje = p28_porcentaje


	),0) bienes, 
	NVL((SELECT 
		p28_valor_base || ", " || p28_porcentaje || ", " || p28_valor_ret  
	 FROM
		cxpt028, cxpt027, ordt002
	 WHERE
		p27_estado = "A" AND
		p28_tipo_ret = "I" AND
		c02_tipo_fuente = "S" AND

		p27_compania = p28_compania AND
		p27_localidad = p28_localidad AND
		p27_num_ret = p28_num_ret AND
	
		p28_compania = p20_compania AND
		p28_localidad = p20_localidad AND
		p28_tipo_doc = p20_tipo_doc AND
		p28_num_doc = p20_num_doc AND
		p28_codprov = p20_codprov AND
		p28_dividendo = p20_dividendo AND

		c02_compania = p28_compania AND
		c02_tipo_ret = p28_tipo_ret AND
		c02_porcentaje = p28_porcentaje


	),0) servicios,
			
	at_air(p20_compania, p20_localidad, p20_codprov, p20_tipo_doc, p20_num_doc),

        CASE
                WHEN month(c10_fecing) = 1 THEN "ENE"
                WHEN month(c10_fecing) = 2 THEN "FEB"
                WHEN month(c10_fecing) = 3 THEN "MAR"
                WHEN month(c10_fecing) = 4 THEN "ABR"
                WHEN month(c10_fecing) = 5 THEN "MAY"
                WHEN month(c10_fecing) = 6 THEN "JUN"
                WHEN month(c10_fecing) = 7 THEN "JUL"
                WHEN month(c10_fecing) = 8 THEN "AGO"
                WHEN month(c10_fecing) = 9 THEN "SEP"
                WHEN month(c10_fecing) = 10 THEN "OCT"
                WHEN month(c10_fecing) = 11 THEN "NOV"
                WHEN month(c10_fecing) = 12 THEN "DIC"
        END MES,
        year(c10_fecing) ANIO,
        c10_usuario USUARIO
FROM
        ordt010, cxpt001, ordt001, ordt013, 
	cxpt020, srit023
	
WHERE
        
	c10_compania = 1 AND 
	c10_estado = "C" AND c13_estado = "A" AND
        c10_tipo_orden = c01_tipo_orden AND


	c10_compania = c13_compania AND
	c10_localidad = c13_localidad AND
	c10_numero_oc = c13_numero_oc AND

	c10_compania = p20_compania AND
	c10_localidad = p20_localidad AND
	c10_numero_oc = p20_numero_oc AND



	s23_compania = c10_compania AND
	s23_tipo_orden = c10_tipo_orden



        AND extend(c10_fecing, year to month) between '2006-1' AND '2006-1'
        AND p01_codprov = c10_codprov

UNION

SELECT
        "TE" MODULO,
--        "NO CLASIFICADO" SUSTENTO,
	"01" SUSTENTO,
	"01" IDTIPO,
        p01_num_doc IDPROV,
        1 TC,
        p20_num_doc[1,3] ESTABLECIEMIENTO,
        p20_num_doc[5,7] PEMISION,
        p20_num_doc[9,15] SECUENCIA,
	"1109999999" AUT,
	day(p20_fecha_emi) || "/" || month(p20_fecha_emi) || "/"  || year(p20_fecha_emi) FECHA_REG,
	day(p20_fecha_emi) || "/" || month(p20_fecha_emi) || "/"  || year(p20_fecha_emi) FECHA_EMI,
	month(today) || "/"  || year(today) FECHA_CAD,
        CASE 	WHEN p20_valor_impto = 0	THEN 	p20_valor_fact
		ELSE	0
	END	BASE_SIN,
        CASE 	WHEN p20_valor_impto > 0	THEN	(p20_valor_fact - p20_valor_impto)
		ELSE	0
	END	BASE_CON,
	0 BASE_ICE, 12 IVA, 0 ICE,
	p20_valor_impto MONTO_IVA,
	0 MONTO_ICE,
--	NVL(p28_codigo_sri,307) AIR,	
--	p28_valor_base AIR_BASE,
--	p28_valor_ret AIR_RET,
--	p28_porcentaje,


	NVL((SELECT 
		p28_valor_base || ", " || p28_porcentaje || ", " || p28_valor_ret  
	 FROM
		cxpt028, cxpt027, ordt002
	 WHERE
		p27_estado = "A" AND
		p28_tipo_ret = "I" AND
		c02_tipo_fuente = "B" AND

		p27_compania = p28_compania AND
		p27_localidad = p28_localidad AND
		p27_num_ret = p28_num_ret AND
	
		p28_compania = p20_compania AND
		p28_localidad = p20_localidad AND
		p28_tipo_doc = p20_tipo_doc AND
		p28_num_doc = p20_num_doc AND
		p28_codprov = p20_codprov AND
		p28_dividendo = p20_dividendo AND


		c02_compania = p28_compania AND
		c02_tipo_ret = p28_tipo_ret AND
		c02_porcentaje = p28_porcentaje


	),0) bienes, 
	NVL((SELECT 
		p28_valor_base || ", " || p28_porcentaje || ", " || p28_valor_ret  
	 FROM
		cxpt028, cxpt027, ordt002
	 WHERE
		p27_estado = "A" AND
		p28_tipo_ret = "I" AND
		c02_tipo_fuente = "S" AND

		p27_compania = p28_compania AND
		p27_localidad = p28_localidad AND
		p27_num_ret = p28_num_ret AND
	
		p28_compania = p20_compania AND
		p28_localidad = p20_localidad AND
		p28_tipo_doc = p20_tipo_doc AND
		p28_num_doc = p20_num_doc AND
		p28_codprov = p20_codprov AND
		p28_dividendo = p20_dividendo AND

		c02_compania = p28_compania AND
		c02_tipo_ret = p28_tipo_ret AND
		c02_porcentaje = p28_porcentaje


	),0) servicios,
			
	at_air(p20_compania, p20_localidad, p20_codprov, p20_tipo_doc, p20_num_doc),

        CASE
                WHEN month(p20_fecha_emi) = 1 THEN "ENE"
                WHEN month(p20_fecha_emi) = 2 THEN "FEB"
                WHEN month(p20_fecha_emi) = 3 THEN "MAR"
                WHEN month(p20_fecha_emi) = 4 THEN "ABR"
                WHEN month(p20_fecha_emi) = 5 THEN "MAY"
                WHEN month(p20_fecha_emi) = 6 THEN "JUN"
                WHEN month(p20_fecha_emi) = 7 THEN "JUL"
                WHEN month(p20_fecha_emi) = 8 THEN "AGO"
                WHEN month(p20_fecha_emi) = 9 THEN "SEP"
                WHEN month(p20_fecha_emi) = 10 THEN "OCT"
                WHEN month(p20_fecha_emi) = 11 THEN "NOV"
                WHEN month(p20_fecha_emi) = 12 THEN "DIC"
        END MES,
        year(p20_fecha_emi) ANIO,
        p20_usuario USUARIO

FROM
        cxpt020, cxpt041, cxpt001
WHERE
	p20_codprov     = p01_codprov AND

        p20_compania    = p41_compania AND
        p20_localidad   = p41_localidad AND
        p20_codprov     = p41_codprov AND
        p20_tipo_doc    = p41_tipo_doc AND
        p20_num_doc     = p41_num_doc AND
	p20_dividendo	= p41_dividendo

        AND p20_tipo_doc = "FA" 
        AND p20_compania = 1
--	AND p20_localidad = 1
        AND extend(p20_fecha_emi, year to month) between '2006-01' AND '2006-1'
ORDER BY
        7, 6

#####################  QUITO - SOLO MODULO TE ########################

FROM
        cxpt020, cxpt001
WHERE
	p20_codprov     = p01_codprov
        AND p20_tipo_doc = "FA" 
        AND p20_compania = 1 
--	AND p20_localidad = 1
	AND NOT EXISTS(
		SELECT 1 FROM ordt013, ordt010 
		WHERE 	c10_compania = c13_compania AND
			c10_localidad = c13_localidad AND
			c10_numero_oc = c13_numero_oc AND
			c13_factura = p20_num_doc AND
			c10_codprov = p20_codprov 
	)
        AND extend(p20_fecha_emi, year to month) between '2006-1' AND '2006-1'
ORDER BY
        7, 6
