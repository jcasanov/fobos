select * from rolt056
	where n56_compania  = 1
	  and n56_cod_trab in
		(select n30_cod_trab
			from rolt030
			where n30_compania   = n56_compania
			  and n30_cod_trab   = n56_cod_trab
			  and n30_cod_depto <> n56_cod_depto
			  and n30_estado     = 'A')
	  and n56_estado    = 'A'
	into temp t1;

select unique n56_cod_trab from t1;

begin work;

	update rolt056
		set n56_estado = 'B'
		where n56_compania = 1
		  and n56_cod_trab in
			(select unique t1.n56_cod_trab
				from t1
				where t1.n56_compania = n56_compania
				  and t1.n56_cod_trab = n56_cod_trab)
		  and n56_estado   = 'A';

	insert into rolt056
		select n56_compania, n56_proceso, n30_cod_depto, n56_cod_trab,
			n56_estado, n56_aux_val_vac, n56_aux_val_adi,
			n56_aux_otr_ing, n56_aux_iess, n56_aux_otr_egr,
			n56_aux_banco, 'FOBOS', current
			from t1, rolt030
			where n30_compania = n56_compania
			  and n30_cod_trab = n56_cod_trab;

--rollback work;
commit work;

drop table t1;
