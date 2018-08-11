select b12_tipo_comp, b12_num_comp, b12_fec_proceso, b12_fecing, b13_cuenta
	from ctbt012, ctbt013
	where b12_compania     = 1
	  --and b12_estado      <> 'E'
	  and b12_origen       = 'M'
	  and year(b12_fecing) = 2004
	  and month(b12_fecing) = 2
	  and b12_fec_proceso <> b12_fecing
	  and b13_compania     = b12_compania
	  and b13_tipo_comp    = b12_tipo_comp
	  and b13_num_comp     = b12_num_comp
	into temp t1;
select unique b12_tipo_comp, b12_num_comp from t1 into temp t2;
select count(*) from t2;
drop table t2;
select * from t1;
drop table t1;
