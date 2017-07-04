select p20_compania cia, p20_localidad loc, p20_codprov prov,
	p20_tipo_doc tipo, p20_num_doc num, p20_dividendo divi,
	p20_valor_fact, nvl(sum(p20_valor_cap + p20_valor_int), 0) valor_doc
	from cxpt020
	where p20_compania   = 1
	  and p20_localidad  = 1
	  and p20_valor_fact > 0
	group by 1, 2, 3, 4, 5, 6, 7
	into temp t1;
delete from t1 where p20_valor_fact = valor_doc;
select t1.*, p20_fecha_emi
	from cxpt020, t1
	where p20_compania  = cia
	  and p20_localidad = loc
	  and p20_codprov   = prov
	  and p20_tipo_doc  = tipo
	  and p20_num_doc   = num
	  and p20_dividendo = divi
	into temp t2;
drop table t1;
select count(*) total_doc from t2;
select * from t2 order by 8;
drop table t2;
