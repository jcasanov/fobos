begin work;

insert into rolt056
	(n56_compania, n56_proceso, n56_cod_depto, n56_cod_trab, n56_estado,
	 n56_aux_val_vac, n56_aux_otr_egr, n56_aux_banco, n56_usuario,
	 n56_fecing)
	select n30_compania, 'DC', n30_cod_depto, n30_cod_trab, 'A',
		'51010301002', '11210104001', '11020101002', 'FOBOS', current
		from rolt030
		where n30_compania  = 1
		  and n30_estado    = 'A'
		  and n30_tipo_trab = 'N';

insert into rolt056
	(n56_compania, n56_proceso, n56_cod_depto, n56_cod_trab, n56_estado,
	 n56_aux_val_vac, n56_aux_otr_egr, n56_aux_banco, n56_usuario,
	 n56_fecing)
	select n30_compania, 'DT', n30_cod_depto, n30_cod_trab, 'A',
		'51010301001', '11210104001', '11020101002', 'FOBOS', current
		from rolt030
		where n30_compania  = 1
		  and n30_estado    = 'A'
		  and n30_tipo_trab = 'N';

insert into rolt056
	(n56_compania, n56_proceso, n56_cod_depto, n56_cod_trab, n56_estado,
	 n56_aux_val_vac, n56_aux_otr_egr, n56_aux_banco, n56_usuario,
	 n56_fecing)
	select n30_compania, 'UT', n30_cod_depto, n30_cod_trab, 'A',
		'21020104001', '11210104001', '11020101003', 'FOBOS', current
		from rolt030
		where n30_compania  = 1
		  and n30_estado    = 'A'
		  and n30_tipo_trab = 'N';

insert into rolt056
	(n56_compania, n56_proceso, n56_cod_depto, n56_cod_trab, n56_estado,
	 n56_aux_val_vac, n56_aux_banco, n56_usuario, n56_fecing)
	select n30_compania, 'FR', n30_cod_depto, n30_cod_trab, 'A',
		'51010401002', '11020101002', 'FOBOS', current
		from rolt030
		where n30_compania  = 1
		  and n30_estado    = 'A';

commit work;
