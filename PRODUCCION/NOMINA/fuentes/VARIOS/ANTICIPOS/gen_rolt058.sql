begin work;

delete from rolt058
	where n58_compania    in (1, 2);
{--
	  and (n58_div_act    > n58_num_div
	   or  n58_valor_dist = n58_saldo_dist
	   or  n58_saldo_dist > 0);
--}

insert into rolt058
	(n58_compania, n58_num_prest, n58_proceso, n58_div_act, n58_num_div,
	 n58_valor_div, n58_valor_dist, n58_saldo_dist, n58_usuario,n58_fecing)
	select a.n46_compania, a.n46_num_prest, a.n46_cod_liqrol,
		nvl((select count(b.n46_secuencia)
			from rolt046 b
			where b.n46_compania   = a.n46_compania
			  and b.n46_num_prest  = a.n46_num_prest
			  and b.n46_cod_liqrol = a.n46_cod_liqrol
			  and b.n46_saldo      = 0), 0),
		count(a.n46_secuencia),
		nvl((select sum(b.n46_valor) / count(b.n46_secuencia)
			from rolt046 b
			where b.n46_compania   = a.n46_compania
			  and b.n46_num_prest  = a.n46_num_prest
			  and b.n46_cod_liqrol = a.n46_cod_liqrol), 0),
 		nvl(sum(a.n46_valor), 0), nvl(sum(a.n46_saldo), 0),
		n45_usuario, n45_fecing
		from rolt045, rolt046 a
		where a.n46_compania  = n45_compania
		  and a.n46_num_prest = n45_num_prest
		  and not exists (select * from rolt058
					where n58_compania  = a.n46_compania
					  and n58_num_prest = a.n46_num_prest
					  and n58_proceso   = a.n46_cod_liqrol)
		group by 1, 2, 3, 4, 6, 9, 10;

commit work;
