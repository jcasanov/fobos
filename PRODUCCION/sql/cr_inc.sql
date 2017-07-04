select z01_codcli, z01_num_doc_id
	from cxct001
	where z01_codcli = -1
	into temp t1;
load from "VENTAS2003/clientes2003.txt" insert into t1;
--select z01_codcli, count(*) from t1 group by 1 order by 2 desc;
select t1.z01_codcli, trim(z01_nomcli) nombre, t1.z01_num_doc_id,
	z01_tipo_doc_id, z01_telefono1, z01_telefono2
	from t1, cxct001
	where t1.z01_codcli = cxct001.z01_codcli
	into temp t2;
drop table t1;
unload to "clientes2003cr.txt" select * from t2;
drop table t2;
