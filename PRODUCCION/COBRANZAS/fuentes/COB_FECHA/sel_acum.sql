drop table t1;
select z22_codcli, z23_tipo_doc, z23_num_doc, z23_div_doc, z23_saldo_cap,
	max(date(z22_fecing)) fecha
	from cxct022, cxct023
	where z22_compania  = 1
	  and z22_localidad = 1
	  and extend(z22_fecing, year to month) <
		extend(current, year to month)
	  and z23_compania  = z22_compania
	  and z23_localidad = z22_localidad
	  and z23_codcli    = z22_codcli
	  and z23_tipo_trn  = z22_tipo_trn
	  and z23_num_trn   = z22_num_trn
	group by 1, 2, 3, 4, 5
	into temp t1;
select count(*) from t1;
select * from t1 order by z22_codcli asc, 6 desc;
drop table t1;
