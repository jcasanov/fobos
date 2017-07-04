{
select unique z01_codcli, z01_num_doc_id, z01_nomcli
	from cxct001, srit021
	where s21_compania   = 1
	  and s21_localidad  = 1
	  and s21_anio       = 2006
	  and s21_mes        = 1
	  and z01_num_doc_id = s21_num_doc_id
	into temp t1;
select count(*) tot_t1 from t1;
select z01_num_doc_id num, count(*) ctos
	from t1
	group by 1
	having count(*) > 1
	into temp t2;
select count(*) tot_t2 from t2;
select * from t2;
select * from t1 where z01_num_doc_id in (select num from t2);
}
unload to "anexo_venta_raz.unl"
	select (select b.z01_nomcli from cxct001 b
		where b.z01_codcli = (select max(a.z01_codcli)
					from cxct001 a
					where trim(a.z01_num_doc_id) = 
						trim(s21_num_doc_id))), *
		from srit021
		where s21_compania  = 1
		  and s21_localidad = 1
		  and s21_anio      = 2006
		  and s21_mes       = 1;
{
drop table t1;
drop table t2;
}
