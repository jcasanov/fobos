begin work;

select n30_compania, 'UT' proc, n30_cod_depto, n30_cod_trab, 'A' estado,
	'21020104001' cta_deb, '11210104001' cta_egr, '11020101010' cta_cre,
	'FOBOS' usuario, current fecing
	from rolt030
	where n30_compania  = 1
	  and n30_estado    = 'A'
	  and n30_tipo_trab = 'N'
union
select n30_compania, 'UT' proc, n30_cod_depto, n30_cod_trab, 'A' estado,
	'21020104001' cta_deb, '11210104001' cta_egr, '11020101010' cta_cre,
	'FOBOS' usuario, current fecing
	from rolt030
	where n30_compania   = 1
	  and n30_estado     = 'I'
	  and n30_tipo_trab  = 'N'
	  and n30_fecha_sal >= mdy(01, 01, 2007)
	into temp t1;

insert into rolt056
	(n56_compania, n56_proceso, n56_cod_depto, n56_cod_trab, n56_estado,
	 n56_aux_val_vac, n56_aux_otr_egr, n56_aux_banco, n56_usuario,
	 n56_fecing)
	select * from t1
		where not exists
			(select 1 from rolt056
				where n56_compania  = n30_compania
				  and n56_proceso   = proc
				  and n56_cod_depto = n30_cod_depto
				  and n56_cod_trab  = n30_cod_trab);

drop table t1;

commit work;
