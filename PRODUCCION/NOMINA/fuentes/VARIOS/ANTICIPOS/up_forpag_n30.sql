begin work;

update rolt030
	set n30_tipo_pago   = 'C',
	    n30_bco_empresa = 3,
	    n30_cta_empresa = '000900-3031'
	where n30_compania    in (1, 2)
	  and n30_estado       = 'A'
	  and n30_tipo_pago    = 'E'
	  and n30_bco_empresa is null;

commit work;
