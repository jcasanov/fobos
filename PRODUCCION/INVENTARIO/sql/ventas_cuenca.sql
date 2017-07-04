select NVL(r19_codcli, 99) r19_codcli, r19_nomcli, r19_vendedor, r01_nombres,
	r19_cod_tran, r20_fecing,
	case when r19_cod_tran = 'FA' then
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	else
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0) *(-1)
	end val_vta
	from acero_gm:rept019, acero_gm:rept020, acero_gm:rept001,
		acero_gm:cxct001
	where r19_compania     = 1
	  and r19_localidad    = 1
	  and r19_cod_tran     in ('FA', 'DF', 'AF')
	  and date(r19_fecing) >= mdy(01, 01, 2005)
	  and r20_compania     = r19_compania
	  and r20_localidad    = r19_localidad
	  and r20_cod_tran     = r19_cod_tran
	  and r20_num_tran     = r19_num_tran
	  and r01_codigo       = r19_vendedor
	  and z01_codcli       = r19_codcli
	  --and (z01_ciudad      in (3, 4, 7, 19, 23, 27, 36, 64)
	  and (z01_num_doc_id[1, 2] = '07' and z01_tipo_doc_id = 'C')
	   --or (z01_num_doc_id[1, 3] = '019' and z01_tipo_doc_id = 'R'))
	group by 1, 2, 3, 4, 5, 6
	into temp t1;
insert into t1
select NVL(r19_codcli, 99) r19_codcli, r19_nomcli, r19_vendedor, r01_nombres,
	r19_cod_tran, r20_fecing,
	case when r19_cod_tran = 'FA' then
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	else
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0) *(-1)
	end val_vta
	from acero_gc:rept019, acero_gc:rept020, acero_gc:rept001,
		acero_gc:cxct001
	where r19_compania     = 1
	  and r19_localidad    = 2
	  and r19_cod_tran     in ('FA', 'DF', 'AF')
	  and date(r19_fecing) >= mdy(01, 01, 2005)
	  and r20_compania     = r19_compania
	  and r20_localidad    = r19_localidad
	  and r20_cod_tran     = r19_cod_tran
	  and r20_num_tran     = r19_num_tran
	  and r01_codigo       = r19_vendedor
	  and z01_codcli       = r19_codcli
	  and (z01_ciudad      in (3, 4, 7, 19, 23, 27, 36, 64)
	   or (z01_num_doc_id[1, 3] = '019' and z01_tipo_doc_id in ('C', 'R')))
	group by 1, 2, 3, 4, 5, 6;
select extend(r19_fecing, year to month) fecha, r19_codcli codcli,
	r19_nomcli cliente, r19_vendedor vend, r01_nombres nom_vend,
	r19_tot_neto val_fac, r19_tot_neto val_dev, r19_tot_neto val_anu,
	r19_tot_neto tot_vta
	from rept019, rept001
	where r19_compania  = 17
	  and r19_localidad = 19
	  and r01_codigo    = r19_vendedor
	into temp temp_vta;
insert into temp_vta
	(fecha, codcli, cliente, vend, nom_vend, val_fac, val_dev, val_anu,
	 tot_vta)
	select extend(r20_fecing, year to month) fecha_vta, r19_codcli,
		r19_nomcli, r19_vendedor, r01_nombres,
		round(nvl(sum(val_vta), 0), 2) total_mes, 0, 0, 0
		from t1
		where r19_cod_tran = 'FA'
		group by 1, 2, 3, 4, 5;
update temp_vta
	set val_dev = (select round(nvl(sum(val_vta), 0), 2)
			from t1
			where r19_cod_tran                      = 'DF'
			  and extend(r20_fecing, year to month) = fecha
			  and r19_codcli                        = codcli
			  and r19_nomcli                        = cliente
			  and r19_vendedor                      = vend
			  and r01_nombres                       = nom_vend),
	    val_anu = (select round(nvl(sum(val_vta), 0), 2)
			from t1
			where r19_cod_tran                      = 'AF'
			  and extend(r20_fecing, year to month) = fecha
			  and r19_codcli                        = codcli
			  and r19_nomcli                        = cliente
			  and r19_vendedor                      = vend
			  and r01_nombres                       = nom_vend)
	where 1 = 1;
drop table t1;
update temp_vta set tot_vta = val_fac + val_dev + val_anu where 1 = 1;
select fecha, codcli, cliente[1, 40], vend, nom_vend, tot_vta
	from temp_vta order by 1 asc, 3 asc;
unload to "clientes_cuenca.txt"
	select * from temp_vta order by 1 asc;
drop table temp_vta;
