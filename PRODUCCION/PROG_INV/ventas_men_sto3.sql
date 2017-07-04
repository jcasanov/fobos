set explain on;

select r20_item, r20_cant_ven, r31_stock,
	(r20_precio * r20_cant_ven) valor_bruto,
	(r20_val_descto * r20_cant_ven) descto,
	((r20_precio * r20_cant_ven) - (r20_val_descto * r20_cant_ven))
	valor_neto
	from rept019, rept020, rept031
	where r19_compania      = 1
	  and r19_localidad     = 1
	  and r19_cod_tran      = 'FA'
	  and r19_tipo_dev is null
	  and year(r19_fecing)  = 2004
	  and month(r19_fecing) = 3
	  and r20_compania      = r19_compania
	  and r20_localidad     = r19_localidad
	  and r20_cod_tran      = r19_cod_tran
	  and r20_num_tran      = r19_num_tran
	  and r31_compania      = r20_compania
	  and r31_ano           = 2004
	  and r31_mes           = 3
	  and r31_item          = r20_item
	group by 1
	order by r20_item;

set explain off;
