select r01_nombres[1, 20] vendedor, r19_cod_tran tp, r19_num_tran num,
	r20_item[1, 6] item,
	round(nvl(sum(
	case when r20_cod_tran = 'FA'
		then ((r20_cant_ven * r20_precio) - r20_val_descto)
		else ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	end), 0), 2) total
	from rept019, rept001, rept020, rept010
	where r19_compania  = 1
	  and r19_localidad = 1
	  and r19_cod_tran  in ("FA", "DF", "AF")
	  and extend(r19_fecing, year to month) = '2010-06'
	  and r01_compania  = r19_compania
	  and r01_codigo    = r19_vendedor
	  and r20_compania  = r19_compania
	  and r20_localidad = r19_localidad
	  and r20_cod_tran  = r19_cod_tran
	  and r20_num_tran  = r19_num_tran
	  and r10_compania  = r20_compania
	  and r10_codigo    = r20_item
	  and r10_marca     = 'POWERS'
	group by 1, 2, 3, 4
	order by 1, 2, 3;
select round(nvl(sum(
	case when r20_cod_tran = 'FA'
		then ((r20_cant_ven * r20_precio) - r20_val_descto)
		else ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	end), 0), 2) total
	from rept019, rept020, rept010
	where r19_compania  = 1
	  and r19_localidad = 1
	  and r19_cod_tran  in ("FA", "DF", "AF")
	  and extend(r19_fecing, year to month) = '2010-06'
	  and r20_compania  = r19_compania
	  and r20_localidad = r19_localidad
	  and r20_cod_tran  = r19_cod_tran
	  and r20_num_tran  = r19_num_tran
	  and r10_compania  = r20_compania
	  and r10_codigo    = r20_item
	  and r10_marca     = 'POWERS';
