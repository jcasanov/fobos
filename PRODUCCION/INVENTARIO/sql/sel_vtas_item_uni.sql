select NVL(r19_codcli, 99) r19_codcli, r19_nomcli, r19_vendedor, r19_cod_tran,
	r20_item[1,6] r20_item, r20_fecing,
	case when r19_cod_tran = 'FA' then
		nvl(sum(r20_cant_ven), 0)
	else
		nvl(sum(r20_cant_ven), 0) * (-1)
	end uni_vta
	from rept019, rept020, rept010
	where r19_compania  = 1
	  and r19_localidad = 1
	  and r19_cod_tran  in ('FA', 'DF', 'AF')
	  and r20_compania  = r19_compania
	  and r20_localidad = r19_localidad
	  and r20_cod_tran  = r19_cod_tran
	  and r20_num_tran  = r19_num_tran
	  and extend(r20_fecing, year to month)
			between extend(current, year to month) - 11 units month
			    and current - 1 units day
	  and r10_compania  = r20_compania
	  and r10_codigo    = r20_item
	group by 1, 2, 3, 4, 5, 6
	into temp t1;
select extend(r19_fecing, year to month) fecha, 'xxxxxx' item,
	r19_tot_neto uni_fac, r19_tot_neto uni_dev, r19_tot_neto uni_anu,
	r19_tot_neto tot_vta
	from rept019
	where r19_compania  = 17
	  and r19_localidad = 19
	into temp temp_vta;
insert into temp_vta
	(fecha, item, uni_fac, uni_dev, uni_anu, tot_vta)
	select extend(a.r20_fecing, year to month) fecha_vta, a.r20_item,
		nvl((select round(sum(b.uni_vta), 2)
			from t1 b
			where b.r19_cod_tran = 'FA'
			  and b.r20_item     = a.r20_item
			  and extend(b.r20_fecing, year to month) =
			extend(a.r20_fecing, year to month)), 0) total_fac,
		nvl((select round(sum(c.uni_vta), 2)
			from t1 c
			where c.r19_cod_tran = 'DF'
			  and c.r20_item     = a.r20_item
			  and extend(c.r20_fecing, year to month) =
			extend(a.r20_fecing, year to month)), 0) total_dev,
		nvl((select round(sum(d.uni_vta), 2)
			from t1 d
			where d.r19_cod_tran = 'AF'
			  and d.r20_item     = a.r20_item
			  and extend(d.r20_fecing, year to month) =
			extend(a.r20_fecing, year to month)), 0) total_anu, 0
		from t1 a;
		--group by 1, 2, 6;
drop table t1;
update temp_vta set tot_vta = uni_fac + uni_dev + uni_anu where 1 = 1;
select * from temp_vta order by 1 asc;
select round(sum(uni_fac), 2) tot_fac, round(sum(uni_dev), 2) tot_dev,
	round(sum(uni_anu), 2) tot_anu, round(sum(tot_vta), 2) tot_net
	from temp_vta;
drop table temp_vta;
