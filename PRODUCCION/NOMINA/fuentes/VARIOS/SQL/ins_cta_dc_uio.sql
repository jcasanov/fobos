begin work;
insert into rolt056
	(n56_compania, n56_proceso, n56_cod_depto, n56_cod_trab, n56_estado,
	 n56_aux_val_vac, n56_aux_banco, n56_usuario, n56_fecing)
	select n56_compania, n56_proceso, n30_cod_depto, n30_cod_trab,
		n56_estado, n56_aux_val_vac, n56_aux_banco, n56_usuario,
		current
		from rolt030, rolt056
		where n30_compania = 1
		  and n30_estado   = 'A'
		  --and n30_cod_trab > 470
		  and n30_cod_trab = 403
		  and n56_compania = n30_compania
		  and n56_proceso  = 'DC'
		  and n56_cod_trab = 470;
commit work;
