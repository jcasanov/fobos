select z01_codcli, z01_num_doc_id, z01_tipo_doc_id
	from cxct001
	where length(z01_num_doc_id) = 13
	  and z01_tipo_doc_id        <> 'R'
	  and z01_estado             = 'A'
union all
select z01_codcli, z01_num_doc_id, z01_tipo_doc_id
	from cxct001
	where length(z01_num_doc_id) = 10
	  and z01_tipo_doc_id        <> 'C'
	  and z01_estado             = 'A'
	into temp t1;
select count(*) from t1;
select * from t1;
drop table t1;
