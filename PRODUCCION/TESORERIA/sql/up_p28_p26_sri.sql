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

select unique cia, loc, prov, tipo_doc, num_doc, divid, tipo_ret, porc, cod_sri,
	p27_fecing fecha
	from t_doc, cxpt027, cxpt028
	where p28_codigo_sri is null
	  and cod_sri        is not null
	  and cia            = p28_compania
	  and loc            = p28_localidad
	  and prov           = p28_codprov
	  and tipo_doc       = p28_tipo_doc
	  and num_doc        = p28_num_doc
	  and divid          = p28_dividendo
	  and tipo_ret       = p28_tipo_ret
	  and porc           = p28_porcentaje
	  and p27_compania   = p28_compania
	  and p27_localidad  = p28_localidad
	  and p27_num_ret    = p28_num_ret
	  and p27_estado     = 'A'
	  and p27_origen     = 'A'
	into temp t1;

select min(fecha) from t1;

drop table t_doc;

select count(*) total_reg from t1;

select * from t1 order by fecha;

begin work;

update cxpt028
	set p28_codigo_sri = (select cod_sri from t1
				where cia      = p28_compania
				  and loc      = p28_localidad
				  and prov     = p28_codprov
				  and tipo_doc = p28_tipo_doc
				  and num_doc  = p28_num_doc
				  and divid    = p28_dividendo
				  and tipo_ret = p28_tipo_ret
				  and porc     = p28_porcentaje)
	where p28_codigo_sri is null
	  and exists (select cod_sri from t1
			where cia      = p28_compania
			  and loc      = p28_localidad
			  and prov     = p28_codprov
			  and tipo_doc = p28_tipo_doc
			  and num_doc  = p28_num_doc
			  and divid    = p28_dividendo
			  and tipo_ret = p28_tipo_ret
			  and porc     = p28_porcentaje);

commit work;

drop table t1;
