begin work;

update actt010
	set a10_estado     = 'S',
	    a10_valor_mb   = a10_valor,
	    a10_val_dep_mb = ((a10_valor * a10_porc_deprec) / 100) / 12
	    --a10_fecha_comp = mdy(01, 30, 2007)
	where a10_compania    = 1
	  --and a10_codigo_bien between 198 and 200;
	  and a10_codigo_bien = 304;
	  --and a10_codigo_bien between 202 and 204;

commit work;
