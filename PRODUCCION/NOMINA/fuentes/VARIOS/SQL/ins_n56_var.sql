begin work;

	insert into rolt056
		(n56_compania, n56_proceso, n56_cod_depto, n56_cod_trab,
		 n56_estado, n56_aux_val_vac, n56_aux_banco, n56_usuario,
		 n56_fecing)
		select n30_compania cia, 'UV' proc, n30_cod_depto cod_d,
			n30_cod_trab cod_t, n30_estado est,
			n52_aux_cont aux_cont, '11020101006' aux_bco,
			"FOBOS" usua, current fecha
			from rolt030, rolt052
			where n30_compania  = 1
			  and n30_estado    = 'A'
			  and n30_tipo_trab = 'N'
			  and n52_compania  = n30_compania
			  and n52_cod_rubro = 75
			  and n52_cod_trab  = n30_cod_trab;

commit work;
