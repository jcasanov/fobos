select n39_cod_trab cod_t, min(unique n39_perfin_real) fecha_ini
	from rolt039
	where n39_compania     = 1
	  and n39_proceso      = 'VA'
	  and n39_perfin_real <= mdy(12,31,2004)
	group by 1
	into temp caca;
select cod_t, mdy(month(fecha_ini), 01, year(fecha_ini)) fecha_ini
	from caca
	into temp tmp_fec;
drop table caca;
--select * from tmp_fec;
select n33_cod_trab cod, n30_nombres[1, 30] nom, n33_fecha_fin fecha,
	n33_valor valor
	from rolt033, rolt030
	where n33_compania    = 1
	  and n33_cod_liqrol in('Q1', 'Q2')
	  and n33_fecha_ini  >= (select fecha_ini from tmp_fec
					where cod_t = n33_cod_trab)
	  and n33_fecha_fin  between mdy(01, 01, 2003) and mdy(02, 28, 2007)
	  and n33_cod_rubro   = 11
	  and n33_valor       > 0
	  and n30_compania    = n33_compania
	  and n30_cod_trab    = n33_cod_trab
	  and n30_estado      = 'A'
	  and not exists      (select * from rolt047
				where n47_compania   = n30_compania
				  and n47_proceso    = 'VA'
				  and n47_cod_trab   = n30_cod_trab
				  and n47_fecha_ini >= n33_fecha_ini
				  and n47_fecha_fin <= n33_fecha_fin)
	into temp t1;
drop table tmp_fec;
select count(*) tot_t1 from t1;
--select * from t1 where cod = 105 order by 2, 3;
select * from t1 order by 2, 3;
select cod, nom, nvl(sum(valor), 0) tot_d_va from t1 group by 1, 2 into temp t2;
select count(*) tot_t2 from t2;
select * from t2 order by 2;
select n39_cod_trab cod_t, n39_periodo_ini per_ini,
	n39_periodo_fin per_fin, nvl(sum((n39_dias_vac +
	case when n39_gozar_adic = 'S' then n39_dias_adi else 0 end)),0) dias_v
	from rolt039
	where n39_compania = 1
	  and n39_proceso  = 'VA'
	  and n39_estado   = 'P'
	  and n39_tipo     = 'G'
	  and not exists (select * from rolt047
				where n47_compania    = n39_compania
				  and n47_proceso     = n39_proceso
				  and n47_cod_trab    = n39_cod_trab
				  and n47_periodo_ini = n39_periodo_ini
				  and n47_periodo_fin = n39_periodo_fin)
	group by 1, 2, 3
	into temp t3;
select cod, nom, tot_d_va, nvl(sum(dias_v), 0) dias_v
	from t2, t3
	where cod = cod_t
	group by 1, 2, 3
	into temp t4;
--select count(*) tot_t3 from t3;
--select * from t3 order by 1, 3;
drop table t2;
select count(*) tot_t4 from t4;
select * from t4 order by 2;
--select count(*) tot_fin from t4 where tot_d_va <= dias_v;
--select * from t4 where tot_d_va <= dias_v order by 2;
select t4.*, t3.per_ini, t3.per_fin
        from t4, t3
        where t4.tot_d_va <= t4.dias_v
          and t4.cod       = t3.cod_t
	into temp t5;
drop table t3;
drop table t4;
select count(*) tot_t5 from t5;
--select * from t5 order by 2;
--select * from t5 where cod = 25 order by 2;
SELECT UNIQUE t1.*, t5.per_ini, t5.per_fin
        FROM t1, t5
        WHERE t1.cod   = t5.cod
	  AND t1.fecha > t5.per_fin
UNION
SELECT UNIQUE t1.*, t5.per_ini, t5.per_fin
        FROM t1, t5
        WHERE t1.cod   = t5.cod
	  AND t1.fecha < t5.per_fin
	INTO TEMP tmp_emp;
drop table t1;
drop table t5;
select count(*) tot_fin from tmp_emp;
--select * from tmp_emp where cod = 25 order by 2, 3;
--select * from tmp_emp order by 2, 3;
drop table tmp_emp;
