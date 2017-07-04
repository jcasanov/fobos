select NVL(r19_codcli, 99) r19_codcli, r19_nomcli, r19_vendedor, r19_cod_tran,
	case when r19_cod_tran = 'FA' then
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	else
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0) *(-1)
	end val_vta	 --case
	from rept019, rept020
	where r19_compania     = 1
	  and r19_localidad    = 1
	  --and r19_cod_tran     in ('FA', 'DF', 'AF')
	  and r19_cod_tran     in ('FA', 'AF')
	  --and r19_cod_tran     in ('FA')
	  --and r19_vendedor     = 10
	  and date(r19_fecing) between mdy(11, 01, 2006)
				   and mdy(11, 30, 2006)
	  and r20_compania     = r19_compania
	  and r20_localidad    = r19_localidad
	  and r20_cod_tran     = r19_cod_tran
	  and r20_num_tran     = r19_num_tran
	group by 1, 2, 3, 4
union
select NVL(r19_codcli, 99) r19_codcli, r19_nomcli, r19_vendedor, r19_cod_tran,
	case when r19_cod_tran = 'FA' then
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	else
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0) *(-1)
	end val_vta	 --case
	from acero_gc:rept019, acero_gc:rept020
	where r19_compania     = 1
	  and r19_localidad    = 2
	  --and r19_cod_tran     in ('FA', 'DF', 'AF')
	  and r19_cod_tran     in ('FA', 'AF')
	  --and r19_cod_tran     in ('FA')
	  --and r19_vendedor     = 10
	  and date(r19_fecing) between mdy(11, 01, 2006)
				   and mdy(11, 30, 2006)
	  and r20_compania     = r19_compania
	  and r20_localidad    = r19_localidad
	  and r20_cod_tran     = r19_cod_tran
	  and r20_num_tran     = r19_num_tran
	group by 1, 2, 3, 4
	into temp t1;
select r19_codcli, r19_nomcli, r19_vendedor, nvl(sum(val_vta), 0) total_vta
	from t1
	group by 1, 2, 3
	into temp t2;
drop table t1;
select round(nvl(sum(total_vta), 0), 2) vta_vend_tot from t2;
select r19_vendedor, r01_iniciales, round(nvl(sum(total_vta), 0), 2) vta_vend
	from t2, rept001
	where r01_codigo = r19_vendedor
	group by 1, 2
	order by 1;
drop table t2;
