select p20_compania, p20_localidad, p20_codprov, p20_tipo_doc, p20_num_doc,
	p20_dividendo, p20_saldo_cap, p20_saldo_int, p22_tipo_trn, p22_num_trn,
	p23_valor_cap, p23_valor_int, p23_saldo_cap, p23_saldo_int, p22_fecing
	from cxpt020, cxpt023, cxpt022
	where p20_compania  in (1, 2)
	  and p23_compania   = p20_compania
	  and p23_localidad  = p20_localidad
	  and p23_codprov    = p20_codprov
	  and p23_tipo_doc   = p20_tipo_doc
	  and p23_num_doc    = p20_num_doc
	  and p23_div_doc    = p20_dividendo
	  and p23_orden      = (select max(p23_orden)
				from cxpt023, cxpt022
				where p23_compania   = p20_compania
				  and p23_localidad  = p20_localidad
				  and p23_codprov    = p20_codprov
				  and p23_tipo_doc   = p20_tipo_doc
				  and p23_num_doc    = p20_num_doc
				  and p23_div_doc    = p20_dividendo
				  and p22_compania   = p23_compania
				  and p22_localidad  = p23_localidad
				  and p22_codprov    = p23_codprov
				  and p22_tipo_trn   = p23_tipo_trn
				  and p22_num_trn    = p23_num_trn
				  and p22_fecing     =
					(select max(p22_fecing)
					from cxpt023, cxpt022
					where p23_compania   = p20_compania
					  and p23_localidad  = p20_localidad
					  and p23_codprov    = p20_codprov
					  and p23_tipo_doc   = p20_tipo_doc
					  and p23_num_doc    = p20_num_doc
					  and p23_div_doc    = p20_dividendo
					  and p22_compania   = p23_compania
					  and p22_localidad  = p23_localidad
					  and p22_codprov    = p23_codprov
					  and p22_tipo_trn   = p23_tipo_trn
					  and p22_num_trn    = p23_num_trn
					  and p22_fecing    <= current))
	  and p22_compania   = p23_compania
	  and p22_localidad  = p23_localidad
	  and p22_codprov    = p23_codprov
	  and p22_tipo_trn   = p23_tipo_trn
	  and p22_num_trn    = p23_num_trn
	  and p22_fecing    in (select max(a.p22_fecing)
				from cxpt023 b, cxpt022 a
				where b.p23_compania  = p20_compania
				  and b.p23_localidad = p20_localidad
				  and b.p23_codprov   = p20_codprov
				  and b.p23_tipo_doc  = p20_tipo_doc
				  and b.p23_num_doc   = p20_num_doc
				  and b.p23_div_doc   = p20_dividendo
				  and a.p22_compania  = b.p23_compania
				  and a.p22_localidad = b.p23_localidad
				  and a.p22_codprov   = b.p23_codprov
				  and a.p22_tipo_trn  = b.p23_tipo_trn
				  and a.p22_num_trn   = b.p23_num_trn)
	into temp t1;
select p20_codprov p23_codprov, nvl(sum(p23_saldo_cap + p23_saldo_int +
		p23_valor_cap +	p23_valor_int), 0) saldo_p23
	from t1
	group by 1
	into temp t2;
select p20_codprov, nvl(sum(p20_saldo_cap + p20_saldo_int), 0) saldo_p20
	from t1
	group by 1
	into temp t3;
select count(p23_codprov) prov_p23 from t2;
select count(p20_codprov) prov_p20 from t3;
select p20_codprov, saldo_p20, saldo_p23
	from t2, t3
	where p20_codprov  = p23_codprov
	  and saldo_p20   <> saldo_p23
	into temp t4;
select p20_codprov, p23_codprov
	from t3, outer t2
	where p20_codprov = p23_codprov
	into temp t5;
delete from t5 where p23_codprov is not null;
drop table t2;
drop table t3;
select count(*) total_prov from t4;
select * from t4 order by 1;
select p20_localidad, p20_codprov, p20_tipo_doc, p20_num_doc,
	p20_dividendo, p20_saldo_cap, p20_saldo_int, p22_tipo_trn, p22_num_trn,
	p23_valor_cap, p23_valor_int, p23_saldo_cap, p23_saldo_int, p22_fecing
	from t1
	where p20_codprov                    in (select t4.p20_codprov from t4)
	  and p20_saldo_cap + p20_saldo_int <>
		p23_saldo_cap + p23_saldo_int + p23_valor_cap +	p23_valor_int
	order by p22_fecing;
drop table t1;
drop table t4;
select unique p20_codprov
	from cxpt020
	where p20_compania                  in (1, 2)
	  and p20_codprov                   in (select t5.p20_codprov from t5)
	  and p20_saldo_cap + p20_saldo_int  > 0
	  and year(p20_fecing)               < 2003
	into temp t6;
drop table t5;
select count(*) prov_no_estan_p23 from t6;
select * from t6 order by 1;
drop table t6;
