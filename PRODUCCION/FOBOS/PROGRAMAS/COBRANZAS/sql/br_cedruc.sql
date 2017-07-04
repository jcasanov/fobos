select z01_num_doc_id cedruc, count(*) hay
	from cxct001
	group by 1
	order by 2 desc
	into temp te;
delete from te where hay = 1;
select * from te;
select count(*) from te;
drop table te;
