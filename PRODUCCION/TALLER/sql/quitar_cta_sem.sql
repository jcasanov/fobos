begin work;

	update ctbt043
		set b43_vta_mo_tal = '41010102003',
		    b43_dvt_mo_tal = '41010102103',
		    b43_des_mo_tal = '41010102002'
		where b43_compania    = 1
		  and b43_grupo_linea = 'ACERT'
		  and b43_porc_impto  = 12.00;

	update ctbt042
		set b42_iva_venta = '21040201001'
		where b42_compania  = 1
		  and b42_localidad =
			(select g02_localidad
				from gent002
				where g02_matriz = 'S'
				  and g02_estado = 'A');

commit work;
