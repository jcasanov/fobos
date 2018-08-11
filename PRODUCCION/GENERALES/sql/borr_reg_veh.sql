begin work;

	delete from gent015
		where g15_compania  = 1
		  and g15_localidad = 1
		  and g15_modulo    = 'VE'
		  and g15_bodega    = 'MA'
		  and g15_tipo      = 'AC';

commit work;
