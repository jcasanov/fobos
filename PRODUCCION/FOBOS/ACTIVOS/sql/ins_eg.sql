select a10_codigo_bien bien, a10_valor_mb valor, a10_numero_oc oc
	from actt010, ordt011, ordt013
	where a10_compania  = 1
	  and a10_numero_oc is not null
	  and a10_valor_mb  > 0
	  and c11_compania  = a10_compania
	  and c11_localidad = 1
	  and c11_numero_oc = a10_numero_oc
	  and c11_codigo    = a10_codigo_bien
	  and c13_compania  = c11_compania
	  and c13_localidad = c11_localidad
	  and c13_numero_oc = c11_numero_oc
	  and c13_estado    = 'E'
	order by 1;
