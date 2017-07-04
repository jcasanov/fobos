select unique p22_codprov, p22_tipo_trn, p22_num_trn, p22_fecing,
	p23_tipo_favor, p23_doc_favor
	from cxpt023, cxpt022
	where p23_tipo_favor is not null
	  and p22_compania  = p23_compania
	  and p22_localidad = p23_localidad
	  and p22_codprov   = p23_codprov
	  and p22_tipo_trn  = p23_tipo_trn
	  and p22_num_trn   = p23_num_trn
	into temp t1;
select p22_codprov codprov, p22_tipo_trn tipo_trn, p22_num_trn num_trn,
	p22_fecing fecha, count(*) tot_doc
	from t1
	group by 1, 2, 3, 4
	having count(*) > 1
	into temp t2;
select t2.*, p23_tipo_favor, p23_doc_favor
	from t1, t2
	where p22_codprov   = codprov
	  and p22_tipo_trn  = tipo_trn
	  and p22_num_trn   = num_trn
	order by 5 desc;
drop table t1;
drop table t2;
