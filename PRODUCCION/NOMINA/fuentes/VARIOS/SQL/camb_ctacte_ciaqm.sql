begin work;

	update rolt030
		set n30_bco_empresa = 1,
		    n30_cta_empresa = "01002398012"
		where n30_compania     = 1
		  and n30_estado      in ("A", "J")
		  and n30_bco_empresa  = 15
		  and n30_cta_empresa  = "1002398012"
		  and n30_tipo_pago    = "T";

--rollback work;
commit work;
