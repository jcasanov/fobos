select n30_compania, lpad(n32_cod_trab, 3, 0) codigo,
	trim(n30_nombres) empleados, n56_aux_val_vac cta_ir,
	round(((today - n30_fecha_nacim) / 365), 0) anios,
	n56_proceso proc
	from rolt032, rolt030, outer rolt056
	where n32_compania    = 1
	  and n32_ano_proceso = 2013
	  and n30_compania    = n32_compania
	  and n30_cod_trab    = n32_cod_trab
	  and n56_compania    = n30_compania
	  and n56_proceso     IN ("IR", "AI")
	  and n56_cod_depto   = n30_cod_depto
	  and n56_cod_trab    = n30_cod_trab
	group by 1, 2, 3, 4, 5, 6
union
	select n30_compania, lpad(n30_cod_trab, 3, 0) codigo,
		trim(n30_nombres) empleados, n56_aux_val_vac cta_ir,
		round(((today - n30_fecha_nacim) / 365), 0) anios,
		n56_proceso proc
		from rolt042, rolt041, rolt030, outer rolt056
		where n42_compania  = 1
		  and n42_proceso   = 'UT'
		  and n42_ano       = 2012
		  and n41_compania  = n42_compania
		  and n41_proceso   = n42_proceso
		  and n41_ano       = n42_ano
		  and n30_compania  = n42_compania
		  and n30_cod_trab  = n42_cod_trab
		  and n56_compania  = n30_compania
		  and n56_proceso   = "IR"
		  and n56_cod_depto = n30_cod_depto
		  and n56_cod_trab  = n30_cod_trab
		group by 1, 2, 3, 4, 5, 6
	into temp tmp_emp;
select a.codigo codigo_ir, a.empleados empleados_ir, a.anios anios_ir,
	a.cta_ir cta_ir2, month(b12_fec_proceso) mes,
	round(nvl(sum(b13_valor_base * (-1)), 0), 2) val_ir_acum
	from tmp_emp a, ctbt012, ctbt013
	where a.proc                                  = "IR"
	  and b12_compania                            = a.n30_compania
	  and b12_estado                             <> 'E'
	  and b12_tipo_comp                           = "DN"
	  and extend(b12_fec_proceso, year to month) >= '2013-01'
	  and extend(b12_fec_proceso, year to month) <= '2013-12'
	  and b13_compania                            = b12_compania
	  and b13_tipo_comp                           = b12_tipo_comp
	  and b13_num_comp                            = b12_num_comp
	  and b13_cuenta                              = a.cta_ir
	  and b13_valor_base                          < 0
	group by 1, 2, 3, 4, 5
union
select a.codigo codigo_ir, a.empleados empleados_ir, a.anios anios_ir,
	(select b.cta_ir
		from tmp_emp b
		where b.n30_compania = a.n30_compania
		  and b.codigo       = a.codigo
		  and b.cta_ir[1, 1] = '2') cta_ir2,
	month(b12_fec_proceso) mes,
	round(nvl(sum(b13_valor_base), 0), 2) val_ir_acum
	from tmp_emp a, ctbt012, ctbt013
	where a.proc                                  = "AI"
	  and b12_compania                            = a.n30_compania
	  and b12_estado                             <> 'E'
	  and extend(b12_fec_proceso, year to month) >= '2013-01'
	  and extend(b12_fec_proceso, year to month) <= '2013-12'
	  and b13_compania                            = b12_compania
	  and b13_tipo_comp                           = b12_tipo_comp
	  and b13_num_comp                            = b12_num_comp
	  and b13_cuenta                              = a.cta_ir
	  and b13_valor_base                          > 0
	group by 1, 2, 3, 4, 5
	into temp tmp_ir;
delete from tmp_emp where proc = "AI";
select codigo, empleados, anios, cta_ir,
	nvl(sum(case when mes = 01 then val_ir_acum end), 0) val_ir_ene,
	nvl(sum(case when mes = 02 then val_ir_acum end), 0) val_ir_feb,
	nvl(sum(case when mes = 03 then val_ir_acum end), 0) val_ir_mar,
	nvl(sum(case when mes = 04 then val_ir_acum end), 0) val_ir_abr,
	nvl(sum(case when mes = 05 then val_ir_acum end), 0) val_ir_may,
	nvl(sum(case when mes = 06 then val_ir_acum end), 0) val_ir_jun,
	nvl(sum(case when mes = 07 then val_ir_acum end), 0) val_ir_jul,
	nvl(sum(case when mes = 08 then val_ir_acum end), 0) val_ir_ago,
	nvl(sum(case when mes = 09 then val_ir_acum end), 0) val_ir_sep,
	nvl(sum(case when mes = 10 then val_ir_acum end), 0) val_ir_oct,
	nvl(sum(case when mes = 11 then val_ir_acum end), 0) val_ir_nov,
	nvl(sum(case when mes = 12 then val_ir_acum end), 0) val_ir_dic
	from tmp_emp, outer tmp_ir
	where codigo = codigo_ir
	group by 1, 2, 3, 4
	into temp t1;
drop table tmp_emp;
drop table tmp_ir;
unload to "empleados_ir_ret2013.unl"
	select * from t1
		order by 2;
--select * from t1 order by 2;
--select round(sum(val_ir_acum), 2) total_ir from t1;
select round(sum(val_ir_ene + val_ir_feb + val_ir_mar + val_ir_abr +
		val_ir_may + val_ir_jun + val_ir_jul + val_ir_ago + val_ir_sep
		+ val_ir_oct + val_ir_nov + val_ir_dic), 2) total_ir
	from t1;
drop table t1;
