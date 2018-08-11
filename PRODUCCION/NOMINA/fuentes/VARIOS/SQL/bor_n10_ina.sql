begin work;

	select lpad(n10_cod_trab, 3, 0) cod, n30_nombres[1, 30] empleados,
		n10_cod_liqrol, lpad(n10_cod_rubro, 3, 0) rub, n10_valor
		from rolt030, rolt010
		where n30_compania = 1
		  and n30_estado   = 'I'
		  and n10_compania = n30_compania
		  and n10_cod_trab = n30_cod_trab
		order by 2, 3, 4;

	delete from rolt010
		where n10_compania  = 1
		  and exists
			(select 1 from rolt030
				where n30_compania = n10_compania
				  and n30_cod_trab = n10_cod_trab
				  and n30_estado   = 'I');

--rollback work;
commit work;
