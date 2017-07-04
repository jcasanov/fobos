select unique n32_compania, n32_cod_trab, trim(n30_nombres[1, 35]) empleados,
	n30_cod_depto
	from rolt032, rolt030
	where n32_compania    = 1
	  and n32_ano_proceso = 2007
	  and n30_compania    = n32_compania
	  and n30_cod_trab    = n32_cod_trab
	into temp tmp_emp;
select n32_cod_trab codigo, empleados, n56_aux_val_vac cta,
	round(nvl(sum(b13_valor_base) * (-1), 0), 2) val_ir_acum
	from tmp_emp, rolt056, ctbt012, ctbt013
	where n56_compania           = n32_compania
	  and n56_proceso            = 'IR'
	  and n56_cod_depto          = n30_cod_depto
	  and n56_cod_trab           = n32_cod_trab
	  and b12_compania           = n56_compania
	  and b12_estado            <> 'E'
	  and year(b12_fec_proceso)  = 2007
	  and b13_compania           = b12_compania
	  and b13_tipo_comp          = b12_tipo_comp
	  and b13_num_comp           = b12_num_comp
	  and b13_cuenta             = n56_aux_val_vac
	  and b13_valor_base         < 0
	group by 1, 2, 3
	into temp tmp_ir;
unload to "empleados_ir_ret2007.unl"
	select n32_cod_trab codigo, tmp_emp.empleados, cta,
		nvl(val_ir_acum, 0) val_ir_acum
		from tmp_emp, outer tmp_ir
		where n32_cod_trab = codigo
		order by 2;
select n32_cod_trab codigo, tmp_emp.empleados, cta,
	nvl(val_ir_acum, 0) val_ir_acum
	from tmp_emp, outer tmp_ir
	where n32_cod_trab = codigo
	into temp t1;
drop table tmp_emp;
drop table tmp_ir;
select * from t1 order by 2;
select round(sum(val_ir_acum), 2) total_ir from t1;
select n33_cod_trab, n33_valor
	from rolt033
	where n33_compania   = 1
	  and n33_cod_liqrol = 'Q2'
	  and n33_fecha_fin  = mdy(12,31,2007)
	  and n33_cod_rubro  = (select n06_cod_rubro from rolt006
				where n06_flag_ident = 'IR')
	  and n33_valor      > 0
	into temp t2;
select codigo, (val_ir_acum - n33_valor) valor_ret
	from t1, t2
	where n33_cod_trab = codigo
	into temp t3;
drop table t1;
drop table t2;
begin work;
	update rolt084
		set n84_imp_ret = (select valor_ret from t3
					where codigo = n84_cod_trab)
		where n84_compania     = 1
		  and n84_proceso      = 'IR'
		  and n84_cod_trab    in (select codigo from t3)
		  and n84_ano_proceso  = 2007;
commit work;
drop table t3;
