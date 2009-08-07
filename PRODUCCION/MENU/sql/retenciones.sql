select 	p28_codprov COD, p01_nomprov PROVEEDOR, p28_tipo_doc TIP,
	p28_num_doc NUM, p28_dividendo DIV, p28_valor_fact VALFAC,
	p28_tipo_ret TIPO, p28_porcentaje PORC, p28_valor_base BASE,
	p28_valor_ret VALRET  from cxpt027, cxpt028, cxpt001
  where p27_compania = p28_compania
    and p27_localidad= p28_localidad
    and p27_num_ret  = p28_num_ret
    and p28_codprov  = p01_codprov
    and p28_tipo_ret = 'I'
