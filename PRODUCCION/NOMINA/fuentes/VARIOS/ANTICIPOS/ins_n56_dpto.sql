select n30_compania cia, n30_cod_trab cod_trab, n30_cod_depto depto
	from rolt030
	where n30_compania  = 1
	  and n30_estado    = 'A'
	  and n30_cod_depto not in
		(select unique n56_cod_depto
			from rolt056
			where n56_compania  = n30_compania
			  and n56_cod_depto = n30_cod_depto
			  and n56_cod_trab  = n30_cod_trab
			  and n56_estado    = 'A')
union
select n30_compania cia, n30_cod_trab cod_trab, n30_cod_depto depto
	from rolt030
	where n30_compania  = 1
	  and n30_estado    = 'I'
	  and n30_fecha_sal >= mdy(07,01,2009)
	  and n30_cod_depto not in
		(select unique n56_cod_depto
			from rolt056
			where n56_compania  = n30_compania
			  and n56_cod_depto = n30_cod_depto
			  and n56_cod_trab  = n30_cod_trab
			  and n56_estado    = 'A')
	into temp t1;

select n56_compania cia, n56_proceso proc, depto depto_act, cod_trab,
	n56_estado est, n56_aux_val_vac aux_vv, n56_aux_val_adi aux_va,
	n56_aux_otr_ing aux_oi, n56_aux_iess aux_iess, n56_aux_otr_egr aux_oe,
	n56_aux_banco aux_b, n56_usuario usua, current fecing,
	n56_cod_depto depto_ant
	from rolt056, t1
	where n56_compania  = cia
	  and n56_cod_trab  = cod_trab
	  and n56_estado    = 'A'
	into temp tmp_emp;

drop table t1;

begin work;

	insert into rolt056
		select cia, proc, depto_act, cod_trab, est, aux_vv, aux_va,
			aux_oi, aux_iess, aux_oe, aux_b, usua, fecing
			from tmp_emp;

	update rolt056
		set n56_estado = 'B'
		where n56_compania = 1
		  and n56_estado   = 'A'
		  and exists (select 1 from tmp_emp
				where cia       = n56_compania
				  and depto_ant = n56_cod_depto
				  and cod_trab  = n56_cod_trab);

commit work;

drop table tmp_emp;
