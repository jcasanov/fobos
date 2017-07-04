begin work;

	update rept010
		set r10_peso = 0.1
		where  r10_compania = 1
		 -- and  r10_estado   = 'A'
		  and (r10_peso     = 0.00
		   or  r10_peso     = 0.001);

commit work;
