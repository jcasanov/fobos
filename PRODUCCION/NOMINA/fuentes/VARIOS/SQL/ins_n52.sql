begin work;

	insert into rolt052
		(n52_compania, n52_cod_rubro, n52_cod_trab, n52_aux_cont)
		select n56_compania,
			(select n18_cod_rubro
				from rolt018
				where n18_flag_ident = n56_proceso),
			n56_cod_trab, n56_aux_val_vac
			from rolt056
			where n56_compania = 1
			  and n56_proceso  = 'AI'
			  and n56_estado   = 'A'
			  and not exists
				(select 1 from rolt052
				where n52_compania  = n56_compania
				  and n52_cod_rubro =
					(select n18_cod_rubro
					from rolt018
					where n18_flag_ident = n56_proceso)
				  and n52_cod_trab  = n56_cod_trab);

commit work;
