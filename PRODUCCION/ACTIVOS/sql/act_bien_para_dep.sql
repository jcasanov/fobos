begin work;

select count(*) from actt010
	where a10_compania    = 1
	  and a10_fecha_comp >= mdy(01,01,2004)
	  and a10_estado      = 'A'
	  and a10_numero_oc   is null
	  and a10_val_dep_mb  = 0;

update actt010
	set a10_estado     = 'S',
	    a10_val_dep_mb = ((a10_valor_mb * a10_porc_deprec) / 100) / 12
	where a10_compania    = 1
	  and a10_fecha_comp >= mdy(01,01,2004)
	  and a10_estado      = 'A'
	  and a10_numero_oc   is null
	  and a10_val_dep_mb  = 0;

commit work;
