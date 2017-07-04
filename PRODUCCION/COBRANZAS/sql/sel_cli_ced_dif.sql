select z01_num_doc_id cedruc, count(*) tot_num
	from cxct001
	where z01_estado = 'A'
	  and year(z01_fecing) >= 2003
	group by 1
	having count(*) > 1
	into temp t1;
select count(*) total from t1;
select * from t1 order by 2 desc;
select z01_codcli, z01_nomcli, cedruc
	from cxct001, t1
	where z01_num_doc_id = cedruc
	order by 1;
drop table t1;
