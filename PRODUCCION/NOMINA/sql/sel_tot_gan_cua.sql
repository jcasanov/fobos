select n32_cod_trab cod, n30_nombres empleado, n32_fecha_ini fecini,
	n32_fecha_fin fecfin, n32_cod_liqrol qn, n32_tot_gan totgan,
	round (((n32_sueldo / 240) * 8 *
		(15 - (select nvl(sum(n33_valor), 0)
			from rolt033
			where n33_compania   = n32_compania
			  and n33_cod_liqrol = n32_cod_liqrol
			  and n33_fecha_ini  = n32_fecha_ini
			  and n33_fecha_fin  = n32_fecha_fin
			  and n33_cod_trab   = n32_cod_trab
			  and n33_cod_rubro  = 11))) +
	(select nvl(sum(n33_valor), 0)
		from rolt033
		where n33_compania   = n32_compania
		  and n33_cod_liqrol = n32_cod_liqrol
		  and n33_fecha_ini  = n32_fecha_ini
		  and n33_fecha_fin  = n32_fecha_fin
		  and n33_cod_trab   = n32_cod_trab
		  and n33_cod_rubro  in (8, 10, 12, 13)), 2) totreal
	from rolt032, rolt033, rolt030
	where n32_compania    = 1
	  and n32_cod_liqrol in ('Q1', 'Q2')
	  and n32_fecha_ini  >= mdy (07, 01, 2005)
	  and n32_dias_trab   < 15
	  and n33_compania    = n32_compania
	  and n33_cod_liqrol  = n32_cod_liqrol
	  and n33_fecha_ini   = n32_fecha_ini
	  and n33_fecha_fin   = n32_fecha_fin
	  and n33_cod_trab    = n32_cod_trab
	  and n33_cod_rubro  in (3, 5, 20)
{--
	  and not exists     (select a.* from rolt033 a
	  			where a.n33_compania    = n32_compania
				  and a.n33_cod_liqrol  = n32_cod_liqrol
				  and a.n33_fecha_ini   = n32_fecha_ini
				  and a.n33_fecha_fin   = n32_fecha_fin
				  and a.n33_cod_trab    = n32_cod_trab
	  			  and a.n33_cod_rubro   = 12
	  			  and a.n33_valor       > 0)
--}
	  and n33_valor       > 0
	  and n30_compania    = n32_compania
	  and n30_cod_trab    = n32_cod_trab
	group by 1, 2, 3, 4, 5, 6, 7
	into temp tmp_emp;

select count(*) tot_reg from tmp_emp;
select count(*) tot_qui, fecfin from tmp_emp group by 2 order by fecfin;
--select * from tmp_emp where cod = 113 order by fecfin, empleado;
select * from tmp_emp order by fecfin, empleado;
select count(unique empleado) tot_empl from tmp_emp;
select unique empleado from tmp_emp order by empleado;

begin work;
update rolt032
	set n32_tot_gan = (select totreal from tmp_emp
				where qn     = n32_cod_liqrol
				  and fecini = n32_fecha_ini
				  and fecfin = n32_fecha_fin
				  and cod    = n32_cod_trab)
	where n32_compania = 1
	  and exists (select qn, fecini, fecfin, cod from tmp_emp
			where qn     = n32_cod_liqrol
			  and fecini = n32_fecha_ini
			  and fecfin = n32_fecha_fin
			  and cod    = n32_cod_trab);
commit work;

drop table tmp_emp;
