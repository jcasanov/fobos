select n03_nombre_abr[1, 10] proc,n45_cod_trab cod,n30_nombres[1, 30] empleado,
	n46_valor valor_ant
	from rolt045, rolt046, rolt030, rolt003
	where n45_compania   = 1
	  and n45_estado     in ('A', 'R')
	  and n46_compania   = n45_compania
	  and n46_num_prest  = n45_num_prest
	  and n46_cod_liqrol = 'DC'
	  and n46_saldo      > 0
	  and n30_compania   = n45_compania
	  and n30_cod_trab   = n45_cod_trab
	  and n03_proceso    = n46_cod_liqrol
	into temp t1;
select * from t1 order by 3;
select round(sum(valor_ant), 2) total from t1;
drop table t1;
