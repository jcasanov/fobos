select p25_compania cia, p25_localidad loc, p25_secuencia sec,p25_codprov prov,
	p25_tipo_doc tipo_doc, p25_num_doc num_doc, p25_dividendo divid,
	p26_tipo_ret tipo_ret, p26_porcentaje porc, p26_codigo_sri cod_sri,
	p24_fecing fec_pag
	from cxpt024, cxpt025, cxpt026
	where p24_compania   in (1, 2)
	  and p24_estado     = 'P'
	  and p25_compania   = p24_compania
	  and p25_localidad  = p24_localidad
	  and p25_orden_pago = p24_orden_pago
	  and p26_compania   = p25_compania
	  and p26_localidad  = p25_localidad
	  and p26_orden_pago = p25_orden_pago
	  and p26_secuencia  = p25_secuencia
	  and p26_codigo_sri is not null
	into temp t_doc;

select min(fec_pag) fec_p24 from t_doc;

drop table t_doc;

select min(p27_fecing) fec_p27
	from cxpt027, cxpt028
	where p27_compania  in (1, 2)
	  and p27_estado     = 'A'
	  and p28_compania   = p27_compania
	  and p28_localidad  = p27_localidad
	  and p28_num_ret    = p27_num_ret
	  and p28_codigo_sri is not null;
