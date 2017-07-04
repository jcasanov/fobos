begin work;

	insert into rolt056
		(n56_compania, n56_proceso, n56_cod_depto, n56_cod_trab,
		 n56_estado, n56_aux_val_vac, n56_aux_banco, n56_usuario,
		 n56_fecing)
		select n30_compania cia, 'JU' proc, n30_cod_depto cod_d,
			n30_cod_trab cod_t, 'A' est, '24010101001' aux_cont,
			'11020101003' aux_bco, "FOBOS" usua, current fecha
			from rolt030
			where n30_compania  = 1
			  and n30_estado    = 'J';

commit work;
