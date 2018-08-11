select r19_cod_tran, r20_fecing, r20_item,
	case when r19_cod_tran = 'FA' then
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	else
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto),0) * (-1)
	end val_vta	 --case
	from rept019, rept020
	where r19_compania  = 1
	  and r19_localidad = 1
	  and r19_cod_tran  in ('FA', 'DF', 'AF')
	  and r19_vendedor  = 10
	  and r20_compania  = r19_compania
	  and r20_localidad = r19_localidad
	  and r20_cod_tran  = r19_cod_tran
	  and r20_num_tran  = r19_num_tran
	group by 1, 2, 3
	into temp tmp_r20;
select r19_cod_tran, r20_fecing, r70_desc_sub, r20_item, val_vta
	from tmp_r20, rept010, rept070
	where r10_compania  = 1
	  and r10_codigo    = r20_item
	  and r70_compania  = r10_compania
	  and r70_linea     = r10_linea
	  and r70_sub_linea = r10_sub_linea
	into temp t1;
drop table tmp_r20;
select extend(r19_fecing, year to month) fecha, r19_referencia linea,
	r19_tot_neto val_fac, r19_tot_neto val_dev, r19_tot_neto val_anu,
	r19_tot_neto val_f_a, r19_tot_neto tot_vta
	from rept019
	where r19_compania  = 17
	  and r19_localidad = 19
	into temp temp_vta;
insert into temp_vta
	(fecha, linea, val_fac, val_dev, val_anu, val_f_a, tot_vta)
	select extend(r20_fecing, year to month) fecha_vta, r70_desc_sub,
		round(nvl(sum(val_vta), 0), 2) total_mes, 0, 0, 0, 0
		from t1
		where r19_cod_tran = 'FA'
		group by 1, 2;
select extend(r20_fecing, year to month) fecha_vta, r70_desc_sub,
	round(nvl(sum(val_vta), 0), 2) val_dev, fecha, linea
	from t1, outer temp_vta
	where r19_cod_tran                      = 'DF'
	  and r70_desc_sub                      = linea
	  and extend(r20_fecing, year to month) = fecha
	group by 1, 2, 4, 5
	into temp tmp_fal;
delete from tmp_fal
	where fecha is not null
	  and linea is not null;
insert into temp_vta
	(fecha, linea, val_fac, val_dev, val_anu, val_f_a, tot_vta)
	select fecha_vta, r70_desc_sub, 0, val_dev, 0, 0, 0
		from tmp_fal;
drop table tmp_fal;
update temp_vta
	set val_dev = (select round(nvl(sum(val_vta), 0), 2)
			from t1
			where r19_cod_tran                      = 'DF'
			  and r70_desc_sub                      = linea
			  and extend(r20_fecing, year to month) = fecha),
	    val_anu = (select round(nvl(sum(val_vta), 0), 2)
			from t1
			where r19_cod_tran                      = 'AF'
			  and r70_desc_sub                      = linea
			  and extend(r20_fecing, year to month) = fecha)
	where 1 = 1;
drop table t1;
update temp_vta
	set val_f_a = val_fac + val_anu,
	    tot_vta = val_fac + val_dev + val_anu
	where 1 = 1;
create temp table temp_vta_pan
	(
		fecha		datetime year to month,
		linea		varchar(35,20),
		val_fac		varchar(12),
		val_dev		varchar(12),
		val_anu		varchar(12),
		val_f_a		varchar(12),
		tot_vta		varchar(12)
	);
insert into temp_vta_pan select * from temp_vta;
unload to "alexandra_tot_lin.txt"
	select * from temp_vta_pan order by 1, 2 asc;
unload to "alexandra_tot_lin2.txt"
	select year(fecha) anio, linea, round(sum(val_fac), 2) val_fac,
		round(sum(val_dev), 2) val_dev, round(sum(val_anu), 2) val_anu,
		round(sum(val_fac + val_anu), 2) val_f_a,
		round(sum(tot_vta), 2) tot_vta
		from temp_vta
		group by 1, 2
		order by 1, 2 asc;
select year(fecha) anio, round(sum(val_fac), 2) val_fac,
	round(sum(val_dev), 2) val_dev, round(sum(val_anu), 2) val_anu,
	round(sum(tot_vta), 2) tot_vta
	from temp_vta
	group by 1
	order by 1 asc;
select fecha, round(sum(val_fac), 2) val_fac, round(sum(val_dev), 2) val_dev,
	round(sum(val_anu), 2) val_anu, round(sum(tot_vta), 2) tot_vta
	from temp_vta
	group by 1
	order by 1 asc;
--select * from temp_vta_pan order by 1, 2 asc;
drop table temp_vta;
drop table temp_vta_pan;
