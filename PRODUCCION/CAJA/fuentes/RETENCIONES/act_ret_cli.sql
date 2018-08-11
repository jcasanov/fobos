begin work;

	update cxct008
		set z08_codigo_sri     = '312',
		    z08_fecha_ini_porc = mdy(02, 01, 2009),
		    z08_flete          = 'N'
		where z08_compania             in (1, 2)
		  and z08_tipo_ret             = 'F'
		  and z08_porcentaje           = 1.00
		  and z08_codigo_sri           = '313'
		  and year(z08_fecha_ini_porc) < 2009;

	update cxct008
		set z08_codigo_sri     = '310',
		    z08_fecha_ini_porc = mdy(02, 01, 2009),
		    z08_flete          = 'S'
		where z08_compania             in (1, 2)
		  and z08_tipo_ret             = 'F'
		  and z08_porcentaje           = 1.00
		  and z08_codigo_sri           = '307'
		  and year(z08_fecha_ini_porc) < 2009;

	update cxct008
		set z08_fecha_ini_porc = mdy(02, 01, 2009)
		where z08_compania             in (1, 2)
		  and z08_tipo_ret             = 'F'
		  and z08_porcentaje           = 2.00
		  and z08_codigo_sri           = '307'
		  and year(z08_fecha_ini_porc) < 2009;

	update cxct008
		set z08_codigo_sri     = '721',
		    z08_fecha_ini_porc = mdy(02, 01, 2009)
		where z08_compania             in (1, 2)
		  and z08_tipo_ret             = 'I'
		  and z08_porcentaje           = 30.00
		  and z08_codigo_sri           = '819'
		  and year(z08_fecha_ini_porc) < 2009;

	update cxct008
		set z08_codigo_sri     = '723',
		    z08_fecha_ini_porc = mdy(02, 01, 2009)
		where z08_compania             in (1, 2)
		  and z08_tipo_ret             = 'I'
		  and z08_porcentaje           = 70.00
		  and z08_codigo_sri           = '813'
		  and year(z08_fecha_ini_porc) < 2009;

	update cxct008
		set z08_codigo_sri     = '340',
		    z08_fecha_ini_porc = mdy(02, 01, 2009),
		    z08_flete          = 'N'
		where z08_compania             in (1, 2)
		  and z08_tipo_ret             = 'F'
		  and z08_porcentaje           = 1.00
		  and z08_codigo_sri           in ('304', '306', '309', '310',
							'312', '317', '329')
		  and year(z08_fecha_ini_porc) < 2009;

	update cxct008
		set z08_codigo_sri     = '341',
		    z08_fecha_ini_porc = mdy(02, 01, 2009),
		    z08_flete          = 'N'
		where z08_compania             in (1, 2)
		  and z08_tipo_ret             = 'F'
		  and z08_porcentaje           = 2.00
		  and z08_codigo_sri           = '329'
		  and year(z08_fecha_ini_porc) < 2009;

	update srit025
		set s25_codigo_sri     = '312',
		    s25_fecha_ini_porc = mdy(02, 01, 2009)
		where s25_compania             in (1, 2)
		  and s25_tipo_ret             = 'F'
		  and s25_porcentaje           = 1.00
		  and s25_codigo_sri           = '307'
		  and year(s25_fecha_ini_porc) < 2009
		  and s25_cliprov              = 'C';

	update srit025
		set s25_fecha_ini_porc = mdy(02, 01, 2009)
		where s25_compania             in (1, 2)
		  and s25_tipo_ret             = 'F'
		  and s25_porcentaje           = 2.00
		  and s25_codigo_sri           = '307'
		  and year(s25_fecha_ini_porc) < 2009
		  and s25_cliprov              = 'C';

commit work;
