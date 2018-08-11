--op table t1;
select a.z01_codcli, a.z01_nomcli, a.z01_num_doc_id, a.z01_estado,
	b.z01_codcli codcli, b.z01_nomcli nomcli, b.z01_num_doc_id num_doc_id,
	b.z01_estado estado
	from acero_qm:cxct001 a, acero_qs:cxct001 b
	where a.z01_codcli      = b.z01_codcli
	  --and a.z01_nomcli     <> b.z01_nomcli
	  and a.z01_num_doc_id <> b.z01_num_doc_id
	  and a.z01_estado      = 'A'
	  --and year(a.z01_fecing) > 2002
	into temp t1;
select count(*) total_t1 from t1;
select count(*) total_t1_1 from t1
where nomcli like "%" || z01_nomcli || "%";
select count(*) total_t1_2 from t1
where z01_nomcli like "%" || nomcli || "%";
select * from t1
where nomcli like "%" || z01_nomcli || "%"
--der by 1
union all
select * from t1
where z01_nomcli like "%" || nomcli || "%"
order by 1
into temp t2;

select count(*) total_t2 from t2;
select * from t1
where z01_codcli not in (select z01_codcli from t2)
and codcli not in (select codcli from t2)
into temp t3;
select count(*) total_t3 from t3;
select * from t3;
drop table t3;
drop table t2;
drop table t1;
