begin work;

update ordt010 set c10_tipo_orden = 2		-- antes tenia 16
	where c10_compania  = 1
	  and c10_localidad = 1
	  and c10_numero_oc = 1850;

update actt010 set a10_numero_oc = NULL,	-- antes tenia 1850
		   a10_estado    = 'A'		-- antes tenia 'S'
	where a10_compania    = 1
	  and a10_codigo_bien = 137;

unload to "tran_a12_activo_137.unl"
	select * from actt012
		where a12_compania    = 1
		  and a12_codigo_tran = 'IN'
		  and a12_numero_tran = 3
		  and a12_codigo_bien = 137;

delete from actt012
	where a12_compania    = 1
	  and a12_codigo_tran = 'IN'
	  and a12_numero_tran = 3
	  and a12_codigo_bien = 137;

commit work;
