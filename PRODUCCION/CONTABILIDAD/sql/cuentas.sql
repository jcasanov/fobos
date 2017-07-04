unload to "plan_cta.unl"
	select b10_cuenta as cuenta, b10_descripcion as nombre
		from ctbt010
		where b10_compania = 1
		  and b10_estado   = "A"
		order by 1;
