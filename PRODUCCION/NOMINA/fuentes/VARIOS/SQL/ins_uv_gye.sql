begin work;

	update rolt056
		set n56_aux_banco = '11020101006'
		where n56_compania = 1
		  and n56_proceso  = 'UV'
		  and n56_estado   = 'A';

	insert into rolt056
		(n56_compania, n56_proceso, n56_cod_depto, n56_cod_trab,
		 n56_estado, n56_aux_val_vac, n56_aux_val_adi, n56_aux_banco,
		 n56_usuario, n56_fecing)
		select n30_compania, "UV", n30_cod_depto, n30_cod_trab, "A",
			(select n52_aux_cont
				from rolt052
				where n52_compania  = n30_compania
				  and n52_cod_rubro = 75
				  and n52_cod_trab  = n30_cod_trab),
			"51014201001", "11020101006", "FOBOS", current
			from rolt030
			where n30_compania = 1
		  	  and n30_estado   = 'A'
			  and not exists
				(select 1 from rolt056
					where n56_compania  = n30_compania
					  and n56_proceso   = "UV"
					  and n56_cod_depto = n30_cod_depto
					  and n56_cod_trab  = n30_cod_trab);

--rollback work;
commit work;
