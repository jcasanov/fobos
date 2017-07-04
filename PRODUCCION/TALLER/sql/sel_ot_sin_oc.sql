select t23_orden, (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti +
	t23_val_otros2) valor, t23_fecing fecha
	from talt023
	where t23_estado = 'F'
	  and (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti +
		t23_val_otros2) > 0
	into temp t1;
select fecha, t23_orden, valor, c10_numero_oc
	from t1, outer ordt010
	where c10_ord_trabajo = t23_orden
	  and c10_estado      = 'C'
	into temp t2;
drop table t1;
delete from t2 where c10_numero_oc is not null;
select count(*) tot_orden from t2;
select round(sum(valor), 2) tot_valor from t2;
select * from t2 order by 1;
drop table t2;
