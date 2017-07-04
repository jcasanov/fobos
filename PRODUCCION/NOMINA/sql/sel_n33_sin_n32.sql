select unique n33_compania, n33_cod_liqrol, n33_fecha_ini, n33_fecha_fin,
	n33_cod_trab, n33_cod_rubro, n32_cod_trab
        from rolt033, outer rolt032
        where n32_compania   = n33_compania
          and n32_cod_liqrol = n33_cod_liqrol
          and n32_fecha_ini  = n33_fecha_ini
          and n32_fecha_fin  = n33_fecha_fin
          and n32_cod_trab   = n33_cod_trab
	  --and n33_valor     <> 0
        into temp t1;
delete from t1 where n32_cod_trab is not null;
select n33_cod_trab, n30_nombres, n33_fecha_fin, n33_cod_rubro, n32_cod_trab
	from t1, rolt030
	where n33_cod_trab = n30_cod_trab
	into temp temp_emp;
select count(*) tot_reg_n33 from temp_emp;
select unique n33_cod_trab, n30_nombres, n33_fecha_fin, n32_cod_trab
	from temp_emp
	into temp t2;
select * from temp_emp order by n33_fecha_fin, n33_cod_trab;
select unique n32_cod_trab, n30_nombres from t2;
drop table temp_emp;
select count(*) tot_reg from t2;
select * from t2 order by n33_fecha_fin, n33_cod_trab;
drop table t2;
begin work;
delete from rolt033
	where exists (select * from t1
			where t1.n33_compania   = rolt033.n33_compania
			  and t1.n33_cod_liqrol = rolt033.n33_cod_liqrol
			  and t1.n33_fecha_ini  = rolt033.n33_fecha_ini
			  and t1.n33_fecha_fin  = rolt033.n33_fecha_fin
			  and t1.n33_cod_trab   = rolt033.n33_cod_trab
			  and t1.n33_cod_rubro  = rolt033.n33_cod_rubro);
commit work;
drop table t1;
