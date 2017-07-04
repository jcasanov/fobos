select NVL(r19_codcli, 99) r19_codcli, r19_nomcli, r19_vendedor, r19_cod_tran,
	r20_fecing,
	case when r19_cod_tran = 'FA' then
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	else
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0) *(-1)
	end val_vta	 --case
	from rept019, rept020
	where r19_compania     = 1
	  and r19_localidad    = 1
	  and r19_cod_tran     in ('FA', 'DF', 'AF')
	  and r19_vendedor     = 10
	  and r20_compania     = r19_compania
	  and r20_localidad    = r19_localidad
	  and r20_cod_tran     = r19_cod_tran
	  and r20_num_tran     = r19_num_tran
	group by 1, 2, 3, 4, 5
	into temp t1;
select extend(r19_fecing, year to month) fecha, r19_tot_neto val_fac,
	r19_tot_neto val_dev, r19_tot_neto val_anu, r19_tot_neto tot_vta
	from rept019
	where r19_compania  = 17
	  and r19_localidad = 19
	into temp temp_vta;
insert into temp_vta
	(fecha, val_fac, val_dev, val_anu, tot_vta)
	select extend(r20_fecing, year to month) fecha_vta,
		round(nvl(sum(val_vta), 0), 2) total_mes, 0, 0, 0
		from t1
		where r19_cod_tran = 'FA'
		group by 1;
update temp_vta
	set val_dev = (select round(nvl(sum(val_vta), 0), 2)
			from t1
			where r19_cod_tran                      = 'DF'
			  and extend(r20_fecing, year to month) = fecha),
	    val_anu = (select round(nvl(sum(val_vta), 0), 2)
			from t1
			where r19_cod_tran                      = 'AF'
			  and extend(r20_fecing, year to month) = fecha)
	where 1 = 1;
drop table t1;
update temp_vta set tot_vta = val_fac + val_dev + val_anu where 1 = 1;
select * from temp_vta order by 1 asc;
unload to "alexandra_tot.txt"
	select * from temp_vta order by 1 asc;
drop table temp_vta;
