select z23_compania cia, z23_localidad loc, z23_codcli cli, z23_tipo_trn tip,
	z23_num_trn num, z23_tipo_doc tp_d, z23_num_doc num_d, z23_div_doc div, 
	z23_tipo_favor tp_f, z23_doc_favor num_f, z23_valor_cap valor
	from cxct023
	where not exists
		(select 1 from cxct020
			where z23_compania  = z20_compania
			  and z23_localidad = z20_localidad
			  and z23_codcli    = z20_codcli
			  and z23_tipo_doc  = z20_tipo_doc
			  and z23_num_doc   = z20_num_doc
			  and z23_div_doc   = z20_dividendo)
	into temp t1;

select tp_d, num_d, z23_tipo_favor, z23_doc_favor, count(*) tot_reg
	from cxct023, t1
	where z23_compania  = cia
	  and z23_localidad = loc
	  and z23_codcli    = cli
	  and z23_tipo_trn  = tip
	  and z23_num_trn   = num
	group by 1, 2, 3, 4
	having count(*) > 1;

select count(*) tot_reg from t1;

select * from t1
	--where tp_f is null
	order by tp_f, num_f;

begin work;

	update cxct023
		set z23_num_doc = '0'
		where exists
			(select 1 from t1
			where z23_compania  = cia
			  and z23_localidad = loc
			  and z23_codcli    = cli
			  and z23_tipo_trn  = tip
			  and z23_num_trn   = num);
commit work;

drop table t1;
