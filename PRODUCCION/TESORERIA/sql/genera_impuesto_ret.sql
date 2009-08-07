--UNLOAD TO "impto_retenciones" DELIMITER '|'
select 	p01_nomprov PROVEEDOR, -- p01_num_doc RUC, SUBSTR(p01_direccion1,1,20),
--      SUBSTR(p28_tipo_doc,1,2) TIP,
	p28_valor_base BASE,
--      FECHA_CONTA,
  	p28_num_doc NUMFAC, -- SUBSTR(p28_dividendo,1,2) DIVFAC,
	p28_valor_fact VALFAC,
	p28_tipo_ret TIPORET, p28_porcentaje PORC,
	p28_valor_ret VALRET, date(p27_fecing) FECHA
   from cxpt027, cxpt028, cxpt001
  where p27_compania = p28_compania
    and p27_localidad= p28_localidad
    and p27_num_ret  = p28_num_ret
    and p28_codprov  = p01_codprov
--  and p28_tipo_ret = 'I'
    and p27_estado <> 'E'
