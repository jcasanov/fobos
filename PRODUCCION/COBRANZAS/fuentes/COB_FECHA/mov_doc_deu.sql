select z22_tipo_trn tt, lpad(z22_num_trn,2,0) num, z23_tipo_doc td, 
	lpad(z23_num_doc,5,0) num_d, lpad(z23_div_doc, 2, 0) div,
	z23_valor_cap valor, z23_saldo_cap saldo, z22_fecing fecha
	from cxct023, cxct022
	where z23_compania  = 1
	  and z23_localidad = 1
	  and z23_tipo_doc  = "FA"
	  and z23_num_doc   = "82743"
	  and z22_compania  = z23_compania
	  and z22_localidad = z23_localidad
	  and z22_codcli    = z23_codcli
	  and z22_tipo_trn  = z23_tipo_trn
	  and z22_num_trn   = z23_num_trn
	into temp t1;
select * from t1
	order by 8 asc;
select sum(valor) tot_val, sum(saldo) tot_sal
	from t1;
drop table t1;
