select n56_compania cia, 'AX' proc, n56_cod_depto depto, n56_cod_trab cod_t,
	n56_estado est, n56_aux_val_vac aux_cta,
	trim('11240104' || n56_aux_val_vac[9, 12]) aux_banco, 'FOBOS' usuario,
	current fecing
	from rolt056, rolt030
	where n56_compania  = 1
	  and n56_proceso   = 'AN'
	  and n56_estado    = 'A'
	  and n30_compania  = n56_compania
	  and n30_cod_trab  = n56_cod_trab
	  and n30_estado    = 'A'
	  and n30_tipo_trab = 'N'
	into temp t1;
insert into rolt056
	(n56_compania, n56_proceso, n56_cod_depto, n56_cod_trab, n56_estado,
	 n56_aux_val_vac, n56_aux_banco, n56_usuario, n56_fecing)
	select * from t1
		where not exists
			(select 1 from rolt056 a
				where a.n56_compania  = t1.cia
				  and a.n56_proceso   = t1.proc
				  and a.n56_cod_depto = t1.depto
				  and a.n56_cod_trab  = t1.cod_t);
drop table t1;
