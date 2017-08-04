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
	  and r10_compania  = r20_compania
	  and r10_codigo    = r20_item
	group by 1, 2, 3, 4, 5, 6
	into temp t1;