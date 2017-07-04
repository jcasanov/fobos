select n45_cod_trab cod, n30_nombres empleado, n46_cod_liqrol lq,
	n45_num_prest num,
	nvl((select count(b.n46_secuencia)
		from rolt046 b
		where b.n46_compania   = a.n46_compania
		  and b.n46_num_prest  = a.n46_num_prest
		  and b.n46_cod_liqrol = a.n46_cod_liqrol
		  and b.n46_saldo      = 0), 0) div_det,
	nvl(n58_div_act, 0) div_cab,
	nvl(sum(a.n46_saldo), 0) sal_det, nvl(n58_saldo_dist, 0) sal_cab
	from rolt045, rolt030, rolt046 a, rolt058
	where n45_compania    in (1, 2)
	  and n45_estado      <> 'E'
	  and n30_compania     = n45_compania
	  and n30_cod_trab     = n45_cod_trab
	  and a.n46_compania   = n45_compania
	  and a.n46_num_prest  = n45_num_prest
	  and n58_compania     = n45_compania
	  and n58_num_prest    = n45_num_prest
	  and n58_proceso      = a.n46_cod_liqrol
	group by 1, 2, 3, 4, 5, 6, 8
	into temp t1;
select num, lq, cod, empleado[1, 35] empleado, div_det, div_cab, sal_det,
	sal_cab
	from t1
	where sal_det <> sal_cab
	into temp t2;
drop table t1;
select count(*) tot_t2 from t2;
select * from t2 order by 1, 2, 4;
begin work;
	update rolt058
		set n58_div_act    = (select div_det from t2
					where num = n58_num_prest
					  and lq  = n58_proceso),
		    n58_saldo_dist = (select sal_det from t2
					where num = n58_num_prest
					  and lq  = n58_proceso)
		where n58_compania in (1, 2)
		  and exists (select * from t2
				where num = n58_num_prest
				  and lq  = n58_proceso);
commit work;
drop table t2;
