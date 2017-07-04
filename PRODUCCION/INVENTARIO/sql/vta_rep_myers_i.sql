select NVL(r19_codcli, 99) r19_codcli, r19_nomcli, r19_vendedor, r19_cod_tran,
	r20_item[1,6] r20_item, r20_fecing,
	case when r19_cod_tran = 'FA' then
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	else
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0) *(-1)
	end val_vta
	from rept019, rept020, rept010
	where r19_compania  = 1
	  and r19_localidad = 1
	  and r19_cod_tran  in ('FA', 'DF', 'AF')
	  and r20_compania  = r19_compania
	  and r20_localidad = r19_localidad
	  and r20_cod_tran  = r19_cod_tran
	  and r20_num_tran  = r19_num_tran
	  and extend(r20_fecing, year to month)
			between extend(current, year to month) - 2 units month
			    and current - 1 units day
	  and r10_compania  = r20_compania
	  and r10_codigo    = r20_item
	  and r10_linea     = '2'
	  and r10_sub_linea = '22'
	  and r10_cod_grupo = '22R'
	  and r10_marca     = 'MYERS'
	group by 1, 2, 3, 4, 5, 6
	into temp t1;
select extend(r19_fecing, year to month) fecha, 'xxxxxx' item,
	r19_tot_neto val_fac, r19_tot_neto val_dev, r19_tot_neto val_anu,
	r19_tot_neto tot_vta
	from rept019
	where r19_compania  = 17
	  and r19_localidad = 19
	into temp temp_vta;
insert into temp_vta
	(fecha, item, val_fac, val_dev, val_anu, tot_vta)
	select extend(r20_fecing, year to month) fecha_vta, r20_item,
		round(nvl(sum(val_vta), 0), 2) total_mes, 0, 0, 0
		from t1
		where r19_cod_tran = 'FA'
		group by 1, 2;
update temp_vta
	set val_dev = (select round(nvl(sum(val_vta), 0), 2)
			from t1
			where r19_cod_tran                      = 'DF'
			  and extend(r20_fecing, year to month) = fecha
			  and r20_item                          = item),
	    val_anu = (select round(nvl(sum(val_vta), 0), 2)
			from t1
			where r19_cod_tran                      = 'AF'
			  and extend(r20_fecing, year to month) = fecha
			  and r20_item                          = item)
	where 1 = 1;
drop table t1;
update temp_vta set tot_vta = val_fac + val_dev + val_anu where 1 = 1;
select * from temp_vta order by 1 asc;
select round(sum(val_fac), 2) tot_fac, round(sum(val_dev), 2) tot_dev,
	round(sum(val_anu), 2) tot_anu, round(sum(tot_vta), 2) tot_net
	from temp_vta;
drop table temp_vta;
