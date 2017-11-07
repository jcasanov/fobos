begin work;

	insert into jadesa:ordt003
		select a.* from acero_gm:ordt003 a
			where not exists
				(select 1 from jadesa:ordt003 b, jadesa:ordt002
					where b.c03_compania       = a.c03_compania
					  and b.c03_tipo_ret       = a.c03_tipo_ret
					  and b.c03_porcentaje     = a.c03_porcentaje
					  and b.c03_codigo_sri     = a.c03_codigo_sri
					  and b.c03_fecha_ini_porc = a.c03_fecha_ini_porc
					  and c02_compania         = b.c03_compania
					  and c02_tipo_ret         = b.c03_tipo_ret
					  and c02_porcentaje       = b.c03_porcentaje);

rollback work;
