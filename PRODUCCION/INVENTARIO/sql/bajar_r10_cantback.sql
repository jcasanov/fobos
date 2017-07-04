unload to "r10_cantback_uio.unl"
	select r10_compania, r10_codigo, r10_cantback
		from rept010
		where r10_compania = 1
		  and r10_estado   = 'A';
