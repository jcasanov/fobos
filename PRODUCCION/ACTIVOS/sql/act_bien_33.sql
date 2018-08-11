begin work;

update actt010
	set a10_porc_deprec = 33
	where a10_compania  = 1
	  and a10_grupo_act = 6
	  and a10_estado    not in ('B', 'V', 'D', 'E');

update actt010
	set a10_val_dep_mb  = ((a10_valor_mb * a10_porc_deprec) / 100) / 12
	where a10_compania  = 1
	  and a10_grupo_act = 6
	  and a10_estado    not in ('B', 'V', 'D', 'E');

update actt001 set a01_porc_deprec = 33
	where a01_compania  = 1
	  and a01_grupo_act = 6;

commit work;
