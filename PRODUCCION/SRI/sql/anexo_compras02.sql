close database; database acero_gm;
drop procedure at_air; 
create procedure at_air(proveedor int, tipo char(2), numero char(15))  
returning   char(10000);

   define tempo char(160);
   define salida char(10000);

   let tempo = "";
   let salida = "";
   FOREACH 
	SELECT 	 
		"<detalleAir><codRetAir>" || nvl(p28_codigo_sri,"307") || "</codRetAir> "
		|| "<baseImpAir>" || p28_valor_base || "</baseImpAir> "
		|| "<porcentajeAir>" || p28_porcentaje || "</porcentajeAir>" 
		||  "<valRetAir>" || p28_valor_ret  || "</valRetAir></detalleAir>"
		INTO tempo
	 FROM
		cxpt028, cxpt027, ordt002, cxpt020
	 WHERE
		p27_estado = "A" AND
		p28_tipo_ret = "F" AND
--		p28_codprov = 551 AND p28_tipo_doc = 'FA' AND p28_num_doc = '0020030016742' AND
		p20_tipo_doc = tipo AND p20_num_doc = numero AND p20_codprov = proveedor AND
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
	let salida =  salida || tempo;
--	let salida = trim(tempo);
   END FOREACH;
   return salida;
end procedure;

select at_air(551,"FA","0020030016742") from dual ;

######  SECCION SOLO CUANDO HAY RETENCION, DATOS RETENCION #############

	## <estabRetencion1>
	NVL((SELECT UNIQUE (SELECT UNIQUE g37_pref_sucurs FROM gent037 WHERE g37_tipo_doc = "FA") FROM
			cxpt028, cxpt027
			WHERE
			p27_estado = "A" AND p28_tipo_ret = "F" AND

			p27_compania = p28_compania AND
			p27_localidad = p28_localidad AND
			p27_num_ret = p28_num_ret AND
	
			p28_compania = p20_compania AND
			p28_localidad = p20_localidad AND
			p28_tipo_doc = p20_tipo_doc AND
			p28_num_doc = p20_num_doc AND
			p28_codprov = p20_codprov AND
			p28_dividendo = p20_dividendo
		       ), 0)

	## <ptoEmiRetencion1>
	NVL((SELECT UNIQUE (SELECT UNIQUE g37_pref_pto_vta FROM gent037 WHERE g37_tipo_doc = "FA") FROM
			cxpt028, cxpt027
			WHERE
			p27_estado = "A" AND p28_tipo_ret = "F" AND

			p27_compania = p28_compania AND
			p27_localidad = p28_localidad AND
			p27_num_ret = p28_num_ret AND
	
			p28_compania = p20_compania AND
			p28_localidad = p20_localidad AND
			p28_tipo_doc = p20_tipo_doc AND
			p28_num_doc = p20_num_doc AND
			p28_codprov = p20_codprov AND
			p28_dividendo = p20_dividendo
		       ), 0)

	## <secRetencion1> "00000099"
	## <autRetencion1> "110XXXXXXX"
	## <fechaEmiRet1>
	SELECT UNIQUE TO_CHAR(p27_fecing, "%d/%m/%Y")  FROM
			cxpt028, cxpt027
			WHERE
			p27_estado = "A" 

			p27_compania = p28_compania AND
			p27_localidad = p28_localidad AND
			p27_num_ret = p28_num_ret AND
	
			p28_compania = p20_compania AND
			p28_localidad = p20_localidad AND
			p28_tipo_doc = p20_tipo_doc AND
			p28_num_doc = p20_num_doc AND
			p28_codprov = p20_codprov AND
			p28_dividendo = p20_dividendo

