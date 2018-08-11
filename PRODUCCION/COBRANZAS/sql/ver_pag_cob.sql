select z22_localidad loc, z22_tipo_trn tt, z23_tipo_doc tp,
	count(z23_tipo_doc) tot_reg,
	round(sum(z23_valor_cap * (-1)), 2) val_cob
	from aceros:cxct023, aceros:cxct022
	where z23_compania      = 1
	  and z23_tipo_trn     in ("PG", "AR", "PR")
	  and z22_compania      = z23_compania
	  and z22_localidad     = z23_localidad
	  and z22_codcli        = z23_codcli
	  and z22_tipo_trn      = z23_tipo_trn
	  and z22_num_trn       = z23_num_trn
	  and year(z22_fecing)  = 2013
	group by 1, 2, 3
union
select z22_localidad loc, z22_tipo_trn tt, z23_tipo_doc tp,
	count(z23_tipo_doc) tot_reg,
	round(sum(z23_valor_cap * (-1)), 2) val_cob
	from acero_qm:cxct023, acero_qm:cxct022
	where z23_compania      = 1
	  and z23_tipo_trn     in ("PG", "AR", "PR")
	  and z22_compania      = z23_compania
	  and z22_localidad     = z23_localidad
	  and z22_codcli        = z23_codcli
	  and z22_tipo_trn      = z23_tipo_trn
	  and z22_num_trn       = z23_num_trn
	  and year(z22_fecing)  = 2013
	group by 1, 2, 3
	into temp t1;
select * from t1
	order by 1, 2, 3;
select loc, tt, count(tot_reg) tot_reg, round(sum(val_cob), 2) val_cob
	from t1
	group by 1, 2
	order by 1, 2;
drop table t1;
