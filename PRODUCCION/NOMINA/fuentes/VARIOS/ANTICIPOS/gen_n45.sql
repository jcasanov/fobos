select a.n45_compania cia, lpad(a.n45_num_prest, 5, 0) ant,
	lpad(a.n45_cod_trab, 4, 0) cod, trim(n30_nombres[1, 25]) emp,
	round(nvl(sum(n46_saldo), 0), 2) sal,
	a.n45_estado est, (a.n45_val_prest + a.n45_valor_int +
	a.n45_sal_prest_ant) val_p, ((a.n45_val_prest + a.n45_valor_int +
	a.n45_sal_prest_ant) - a.n45_descontado) desco
	from rolt045 a, rolt046, rolt030
	where a.n45_compania in (1, 2)
	  and a.n45_estado   <> 'E'
	  and n46_compania    = a.n45_compania
	  and n46_num_prest   = a.n45_num_prest
	  and n30_compania    = a.n45_compania
	  and n30_cod_trab    = a.n45_cod_trab
	group by 1, 2, 3, 4, 6, 7, 8
	into temp t1;
select cia, ant, cod, emp, sal, val_p, desco, est
	from t1
	where sal <> desco
	into temp t2;
drop table t1;
select "TOTAL ANT. DIF: " || trunc(count(*)) from t2;
--select ant, cod, emp, sal, desco, est from t2 order by 6, 1, 3;
begin work;
	update rolt045
		set n45_descontado = (select val_p - sal
					from t2
					where cia = n45_compania
					  and ant = n45_num_prest)
		where n45_compania  in (1, 2)
		  and n45_num_prest in (select ant from t2);
	update rolt045
		set n45_estado = 'P'
		where n45_compania  in (1, 2)
		  and n45_estado    in ('A', 'R')
		  and ((n45_val_prest + n45_valor_int + n45_sal_prest_ant) -
			n45_descontado) = 0;
commit work;
--rollback work;
drop table t2;
