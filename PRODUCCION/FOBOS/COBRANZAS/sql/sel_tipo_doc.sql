select z01_codcli, z01_nomcli, z01_tipo_doc_id, z01_num_doc_id,
	z01_personeria
	from cxct001
	where z01_estado      = 'A'
	  and (z01_personeria = 'N'
	   or z01_tipo_doc_id = 'C')
	  and length(z01_num_doc_id) <> 10
	into temp t1;
select count(*) total from t1;
select lpad(z01_codcli,5,0) codcli, z01_nomcli[1,30], z01_tipo_doc_id t,
	z01_num_doc_id cedruc, z01_personeria t_per
	from t1
	order by 2;
drop table t1;
