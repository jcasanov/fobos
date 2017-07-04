select a10_codigo_bien, a10_descripcion, date(c10_fecing) fecha
	from actt010, ordt010, ordt011
	where a10_compania  = 1
	  and c10_compania  = a10_compania
	  and c10_localidad = 1
	  and c10_estado   <> 'E'
	  and c10_tipo_orden in (15, 16)
	  and c11_compania  = c10_compania
	  and c11_localidad = c10_localidad
	  and c11_numero_oc = c10_numero_oc
	  and c11_codigo    = a10_codigo_bien
	order by a10_codigo_bien asc;
unload to "activo_faltan.unl"
	select actt010.* from actt010, ordt010, ordt011
	where a10_compania  = 1
	  and c10_compania  = a10_compania
	  and c10_localidad = 1
	  and c10_estado   <> 'E'
	  and c10_tipo_orden in (15, 16)
	  and c11_compania  = c10_compania
	  and c11_localidad = c10_localidad
	  and c11_numero_oc = c10_numero_oc
	  and c11_codigo    = a10_codigo_bien
	order by a10_codigo_bien asc;
