begin work;

	update rept010
		set r10_estado = 'A',
		    r10_feceli = ''
		where r10_compania = 1
		  and r10_estado   = 'B'
		  and r10_marca    = 'POWERS';

commit work;
