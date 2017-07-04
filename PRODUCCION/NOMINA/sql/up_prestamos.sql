select n45_compania cia, n45_num_prest num_prest, n45_cod_trab cod_trab,
	n30_nombres empleado, n45_val_prest prestamo, n45_descontado descont,
	n46_secuencia divi, n46_cod_liqrol lq, n46_fecha_ini fec_ini,
	n46_fecha_fin fec_fin, n46_valor valor, n46_saldo saldo,
	n33_num_prest num_ant
	from rolt045, rolt046, rolt032, rolt033, rolt030
	where n45_estado     = 'A'
	  and n46_compania   = n45_compania
	  and n46_num_prest  = n45_num_prest
	  and n46_saldo      > 0
	  and n46_valor      = n46_saldo
	  and n32_compania   = n45_compania
	  and n32_cod_liqrol = n46_cod_liqrol
	  and n32_fecha_ini  = n46_fecha_ini
	  and n32_fecha_fin  = n46_fecha_fin
	  and n32_cod_trab   = n45_cod_trab
	  and n32_estado     = 'C'
	  and n33_compania   = n32_compania
	  and n33_cod_liqrol = n32_cod_liqrol
	  and n33_fecha_ini  = n32_fecha_ini
	  and n33_fecha_fin  = n32_fecha_fin
	  and n33_cod_trab   = n32_cod_trab
	  and n33_cod_rubro  = n45_cod_rubro
	  and n33_num_prest  = n46_num_prest
	  and n33_valor      > 0
	  and n30_compania   = n45_compania
	  and n30_cod_trab   = n45_cod_trab
	into temp t1;
select count(*) tot_empl_prest from t1;
select * from t1 order by empleado, num_prest, divi, fec_fin;
select cia, num_prest, cod_trab, descont,
	round(descont + nvl(sum(saldo), 0), 2) val_n
	from t1
	group by 1, 2, 3, 4
	into temp t2;
select * from t2;
begin work;
update rolt045
	set n45_descontado = (select val_n from t2
				where cia       = n45_compania
				  and num_prest = n45_num_prest),
	where exists (select cia, num_prest from t2
			where cia       = n45_compania
			  and num_prest = n45_num_prest);
update rolt046
	set n46_saldo = 0
	where exists (select cia, num_prest, divi, lq, fec_ini, fec_fin
			from t1
			where cia       = n46_compania
			  and num_prest = n46_num_prest
			  and divi      = n46_secuencia
			  and lq        = n46_cod_liqrol
			  and fec_ini   = n46_fecha_ini
			  and fec_fin   = n46_fecha_fin);
update rolt045
	set n45_estado = 'P'
	where exists (select cia, num_prest from t2
			where cia       = n45_compania
			  and num_prest = n45_num_prest
			  and val_n     = n45_val_prest);
commit work;
drop table t1;
drop table t2;
