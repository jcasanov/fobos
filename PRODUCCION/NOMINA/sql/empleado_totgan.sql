select n32_cod_trab, nvl(sum(n32_tot_gan), 0) tot_gan_nom,
	nvl(sum(n32_tot_gan * 9.35 / 100), 0) tot_iess,
	nvl((select sum(n36_valor_bruto)
		from rolt036
		where n36_compania   = 1
		  and n36_proceso    = 'DT'
		  and n36_fecha_ini >= mdy(12,01,2005)
		  and n36_fecha_fin <= mdy(11,30,2006)
		  and n36_cod_trab   = n32_cod_trab), 0) tot_gan_dt,
	nvl((select sum(n36_valor_bruto)
		from rolt036
		where n36_compania   = 1
		  and n36_proceso    = 'DC'
		  and n36_fecha_ini >= mdy(04,01,2005)
		  and n36_fecha_fin <= mdy(03,31,2006)
		  and n36_cod_trab   = n32_cod_trab), 0) tot_gan_dc
	from rolt032
	where n32_compania   = 1
	  and n32_cod_liqrol in('Q1', 'Q2')
	  and n32_fecha_ini  >= mdy(01,01,2006)
	  and n32_fecha_fin  <= mdy(12,31,2006)
	group by 1
	into temp tmp_tot;
select n30_cod_trab cod, n30_nombres nombre, g31_nombre ciudad,
	n30_domicilio direc, n30_est_civil est, n30_telef_domic telef,
	n30_num_doc_id cedula, n30_carnet_seg carnet, n30_sueldo_mes sueldo,
	tot_gan_nom, tot_iess, tot_gan_nom - tot_iess subtotal, tot_gan_dt,
	tot_gan_dc
	from tmp_tot, rolt030, gent031
	where n30_compania = 1
	  and n30_cod_trab = n32_cod_trab
	  and g31_ciudad   = n30_ciudad_nac
	into temp tmp_emp;
drop table tmp_tot;
unload to "empleados_2006.txt" select * from tmp_emp order by nombre;
drop table tmp_emp;
