create temp table temp_ir
	(
		anio		smallint,
		indice		smallint,
		base_ini	decimal(14,2),
		base_max	decimal(14,2),
		base_fra	decimal(12,2),
		porc		decimal(5,2)
	);

insert into temp_ir values (2007, 1, 0.00, 7850.00, 0.00, 0.00);
insert into temp_ir values (2007, 2, 7850.01, 15360.00, 0.00, 5.00);
insert into temp_ir values (2007, 3, 15360.01, 30720.00, 393.00, 10.00);
insert into temp_ir values (2007, 4, 30720.01, 46080.00, 1536.00, 15.00);
insert into temp_ir values (2007, 5, 46080.01, 61440.00, 4608.00, 20.00);
insert into temp_ir values (2007, 6, 61440.01, 800000.00, 9216.00, 25.00);

select lpad(n32_cod_trab, 3, 0) cod, trim(n30_nombres) empleado,
	nvl(sum(n32_tot_gan), 0) tot_gan,
	nvl(round(sum(n32_tot_gan * n13_porc_trab / 100), 2), 0) val_ap,
	nvl(round(sum(n32_tot_gan - (n32_tot_gan * n13_porc_trab / 100)),
		2), 0) val_nom,
	nvl(sum((select n33_valor from rolt033
		where n33_compania    = n32_compania
		  and n33_cod_liqrol  = n32_cod_liqrol
		  and n33_fecha_ini  >= n32_fecha_ini
		  and n33_fecha_fin  <= n32_fecha_fin
		  and n33_cod_trab    = n32_cod_trab
		  and n33_cod_rubro  not in (17, 18)
		  and n33_valor       > 0
		  and n33_det_tot     = "DI"
		  and n33_cant_valor  = "V"
		  and not exists
			(select 1 from rolt008, rolt006
			 where n08_rubro_base = n33_cod_rubro
			   and n06_cod_rubro  = n08_cod_rubro
			   and n06_flag_ident = "AP"))), 0.00) otros,
	nvl(sum((select n39_valor_vaca + n39_valor_adic
		from rolt039
		where n39_compania     = n32_compania
		  and n39_proceso      in ("VA", "VP")
		  and n39_cod_trab     = n32_cod_trab
		  and n39_estado       = "P"
		  and date(n39_fecing) between n32_fecha_ini
					   and n32_fecha_fin)), 0.00) val_vac,
	nvl(sum((select n39_descto_iess
		from rolt039
		where n39_compania     = n32_compania
		  and n39_proceso      in ("VA", "VP")
		  and n39_cod_trab     = n32_cod_trab
		  and n39_estado       = "P"
		  and date(n39_fecing) between n32_fecha_ini
					   and n32_fecha_fin)), 0.00) ap_vac,
	nvl(sum((select (n39_valor_vaca + n39_valor_adic) - n39_descto_iess
		from rolt039
		where n39_compania     = n32_compania
		  and n39_proceso      in ("VA", "VP")
		  and n39_cod_trab     = n32_cod_trab
		  and n39_estado       = "P"
		  and date(n39_fecing) between n32_fecha_ini
					   and n32_fecha_fin)), 0.00) net_vac,
	nvl(sum((select n36_valor_bruto
		from rolt036
		where n36_compania  = n32_compania
		  and n36_proceso   = "DT"
		  and n36_fecha_ini = n32_fecha_ini - 1 units year
		  and n36_fecha_fin = n32_fecha_ini - 1 units day
		  and n36_cod_trab  = n32_cod_trab
		  and n36_estado    = "P")), 0) val_dt,
	nvl(sum((select n36_valor_bruto
		from rolt036
		where n36_compania  = n32_compania
		  and n36_proceso   = "DC"
		  and n36_fecha_ini = n32_fecha_ini - 1 units year
		  and n36_fecha_fin = n32_fecha_ini - 1 units day
		  and n36_cod_trab  = n32_cod_trab
		  and n36_estado    = "P")), 0) val_dc,
	nvl(case when month(n32_fecha_ini) = 4 then
		(select n42_val_trabaj + n42_val_cargas
		 from rolt041, rolt042
		 where n41_compania      = n32_compania
		   and n41_ano           = year(n32_fecha_ini) - 1
		   and n41_estado        = "P"
		   and month(n41_fecing) = month(n32_fecha_ini)
		   and n42_compania      = n41_compania
		   and n42_ano           = n41_ano
		   and n42_cod_trab      = n32_cod_trab) end, 0.00) val_ut,
	round(nvl((select n10_valor
			from rolt010
			where n10_compania   = n32_compania
			  and n10_cod_liqrol = 'ME'
			  and n10_cod_trab   = n32_cod_trab
			  and n10_cod_trab   in(116, 117, 131)), 0), 2) bonif
	from rolt032, rolt030, rolt013
	where n32_compania   in (1, 2)
	  and n32_cod_liqrol in ("Q1", "Q2")
	  and n32_fecha_ini  >= mdy(04, 01, 2008)
	  and n32_fecha_fin  <= mdy(04, 30, 2008)
	  and n30_compania    = n32_compania
	  and n30_cod_trab    = n32_cod_trab
	  and n13_cod_seguro  = n30_cod_seguro
	group by 1, 2, 12, 13
	into temp t1;
unload to "empleados_ir_abr2008.unl" select * from t1 order by 2;
select count(*) tot_emp from t1;
--select * from t1 order by 2;
select cod, empleado, tot_gan, val_ap, val_nom, otros, val_vac, ap_vac, net_vac,
	val_dt, val_dc, val_ut, bonif, round(val_nom + otros + net_vac + val_dt
	+ val_dc + val_ut + bonif, 2) total
	from t1
	into temp caca;
drop table t1;
select anio, indice, (base_ini / 12) base_ini, (base_max / 12) base_max,
	(base_fra / 12) base_fra, porc
	from temp_ir
	into temp tmp_ir;
drop table temp_ir;
select * from caca
	where total >= (select min(base_max) from tmp_ir where anio = 2008)
	into temp t2;
drop table caca;
select n30_cod_trab codigo, trim(n30_nombres[1, 35]) empleados,
	n56_aux_val_vac cta,
	round(nvl(sum(b13_valor_base) * (-1), 0), 2) val_ir_acum
	from rolt030, rolt056, ctbt012, ctbt013
	where n30_compania           = 1
	  and n56_compania           = n30_compania
	  and n56_proceso            = 'IR'
	  and n56_cod_depto          = n30_cod_depto
	  and n56_cod_trab           = n30_cod_trab
	  and b12_compania           = n56_compania
	  and b12_estado            <> 'E'
	  and year(b12_fec_proceso)  = 2008
	  and b13_compania           = b12_compania
	  and b13_tipo_comp          = b12_tipo_comp
	  and b13_num_comp           = b12_num_comp
	  and b13_cuenta             = n56_aux_val_vac
	  and b13_valor_base         < 0
	group by 1, 2, 3
	into temp tmp_ir_cob;
select * from tmp_ir_cob order by 2;
select count(*) tot_emp_ir from t2;
select cod, empleado, tot_gan, val_ap, val_nom, otros, val_vac, ap_vac, net_vac,
	val_dt, val_dc, val_ut, bonif, total, nvl(val_ir_acum, 0) tot_ir_ret,
	round((total - nvl((select base_ini from tmp_ir
			where anio     = 2008
			  and base_ini < total
			  and base_max > total), 0)) *
			nvl((select porc / 100 from tmp_ir
			where anio     = 2008
			  and base_ini < total
			  and base_max > total), 0) +
			nvl((select base_fra from tmp_ir
			where anio     = 2008
			  and base_ini < total
			  and base_max > total), 0), 2) val_ir
	from t2, outer tmp_ir_cob
	where cod = codigo
	into temp t3;
drop table t2;
select round(sum(val_ir), 2) total_ir from t3;
--select * from t3 order by 2;
select cod, empleado, tot_gan, val_ap, val_nom, otros, val_vac, ap_vac, net_vac,
	val_dt, val_dc, val_ut, bonif, total, tot_ir_ret, val_ir,
	nvl(round(val_ir - tot_ir_ret, 2), 0) val_ir_real
	from t3
	order by 17 desc;
drop table t3;
drop table tmp_ir;
drop table tmp_ir_cob;
