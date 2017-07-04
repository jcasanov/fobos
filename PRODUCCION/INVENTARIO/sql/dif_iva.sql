select r19_cod_tran, r19_num_tran,
	case when r19_cod_tran = 'FA' then
		nvl(r19_tot_neto - (r19_tot_bruto - r19_tot_dscto) -
			r19_flete, 0)
	else
		nvl(r19_tot_neto - (r19_tot_bruto - r19_tot_dscto) -
			r19_flete, 0) * (-1)
	end val_iva_c
	from rept019
	where r19_cod_tran in ('FA', 'DF', 'AF')
	  and extend(r19_fecing, year to month) =
		extend(mdy(05, 01, 2006), year to month)
	into temp t1;
select r20_cod_tran, r20_num_tran,
	case when r20_cod_tran = 'FA' then
		nvl(round(sum((r20_cant_ven * r20_precio) - r20_val_descto),
			2), 0) * 0.12
	else
		nvl(round(sum((r20_cant_ven * r20_precio) - r20_val_descto),
			2), 0) * (-0.12)
	end val_iva_d
	from rept020
	where r20_cod_tran in ('FA', 'DF', 'AF')
	  and extend(r20_fecing, year to month) =
		extend(mdy(05, 01, 2006), year to month)
	group by 1, 2
	into temp t2;
select r19_cod_tran tp, r19_num_tran num, round(val_iva_c, 2) val_iva_c,
	round(val_iva_d, 4) val_iva_d
	from t1, t2
	where r19_cod_tran  = r20_cod_tran
	  and r19_num_tran  = r20_num_tran
	  and val_iva_c    <> val_iva_d
	into temp t3;
drop table t1;
drop table t2;
select count(*) tot_fact from t3;
select * from t3 order by 2;
select nvl(round(sum(val_iva_c), 2), 0) tot_c,
	nvl(round(sum(val_iva_d), 2), 0) tot_d
	from t3
	into temp t4;
drop table t3;
select tot_c, tot_d, round(tot_c - tot_d, 2) diferencia from t4;
drop table t4;
