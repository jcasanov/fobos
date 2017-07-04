set isolation to dirty read;
begin work;
	update rept010
		set r10_tipo        = 7,
		    r10_usu_cosrepo = 'FOBOS',
		    r10_fec_cosrepo = current
	where r10_compania = 1
	  and r10_estado   = 'A'
	  and exists (select 1 from rept011
			where r11_compania = r10_compania
			  and r11_bodega   = 'EB'
			  and r11_item     = r10_codigo);
commit work;
