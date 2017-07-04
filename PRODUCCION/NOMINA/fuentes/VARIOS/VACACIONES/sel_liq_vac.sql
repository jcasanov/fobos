select n47_proceso proc, n47_cod_trab cod_t, n30_nombres empleado,
	n47_periodo_ini per_ini, n47_periodo_fin per_fin, n47_dias_goza d_g,
	n47_valor_pag val_pag, n47_valor_des val_des, n47_cod_liqrol lq,
	n47_fecha_ini fec_ini, n47_fecha_fin fec_fin
	from rolt047, rolt030
	where n47_compania = 1
	  and n47_estado   = 'G'
	  and n30_compania = n47_compania
	  and n30_cod_trab = n47_cod_trab
	into temp tmp_n47;
select cod_t cd_t, lq liq, fec_ini fec_i, fec_fin fec_f, count(*) ctos
	from tmp_n47
	group by 1, 2, 3, 4
	having count(*) > 1
	into temp t1;
select tmp_n47.*
	from tmp_n47, t1
	where cod_t   = cd_t
	  and lq      = liq
	  and fec_ini = fec_i
	  and fec_fin = fec_f
	order by fec_fin, empleado;
drop table tmp_n47;
drop table t1;
