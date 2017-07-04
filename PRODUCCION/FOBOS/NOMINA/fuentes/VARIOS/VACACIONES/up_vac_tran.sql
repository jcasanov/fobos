select n56_compania cia, 'VA' proc, n56_cod_depto depto, n56_cod_trab cod_t,
	n56_aux_banco cuenta
	from rolt056
	where n56_compania = 1
	  and n56_proceso  = 'AX'
	  and n56_estado   = 'A'
	into temp t1;

begin work;

	update rolt056
		set n56_aux_val_vac = (select cuenta
					from t1
					where cia   = n56_compania
					  and proc  = n56_proceso
					  and depto = n56_cod_depto
					  and cod_t = n56_cod_trab),
		    n56_aux_val_adi = (select cuenta
					from t1
					where cia   = n56_compania
					  and proc  = n56_proceso
					  and depto = n56_cod_depto
					  and cod_t = n56_cod_trab),
		    n56_aux_iess    = '21050101005'
	where n56_compania  = 1
	  and n56_proceso   = 'VA'
	  and n56_cod_trab in (select cod_t
				from t1
				where cia   = n56_compania
				  and proc  = n56_proceso
				  and depto = n56_cod_depto)
	  and n56_estado    = 'A';

drop table t1;

commit work;
