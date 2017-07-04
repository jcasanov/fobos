--load from "rolt045_res.unl" insert into rolt045;
--load from "rolt046_res.unl" insert into rolt046;
unload to "rolt045_res.unl" select * from rolt045;
unload to "rolt046_res.unl" select * from rolt046;
select n45_compania cia, n45_num_prest num_prest, n45_cod_rubro cod_rubro,
	n45_cod_trab cod_trab, n30_nombres empleado, n45_val_prest prestamo,
	n45_descontado descont, n46_secuencia divi, n46_cod_liqrol lq,
	n46_fecha_ini fec_ini, n46_fecha_fin fec_fin, n46_valor valor,
	n46_saldo saldo, n33_num_prest num_ant, n33_valor val_rol
	from rolt045, rolt046, rolt032, rolt033, rolt030
	where n45_estado     = 'A'
	  and n46_compania   = n45_compania
	  and n46_num_prest  = n45_num_prest
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
	  and n33_valor      > 0
	  and n30_compania   = n45_compania
	  and n30_cod_trab   = n45_cod_trab
	into temp t1;
select count(*) tot_empl_prest from t1;
select count(unique num_prest) tot_prest from t1;
select cia, num_prest, cod_rubro, cod_trab, descont,
	round(descont + nvl(sum(saldo), 0), 2) val_n,nvl(sum(val_rol), 0) val_r
	from t1
	group by 1, 2, 3, 4, 5
	into temp t2;
--select * from t2 where val_n < val_r into temp t3;
--drop table t2;
select count(*) tot_empl_t2 from t2;
--select * from t3 order by num_prest;
begin work;
update rolt045
	set n45_descontado = (select val_n from t2
				where cia        = n45_compania
				  and num_prest  = n45_num_prest)
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
			  and val_n     = n45_val_prest
			  and val_n     <= val_r);
update rolt045
	set n45_estado = 'P'
	where n45_descontado = n45_val_prest
	  and n45_estado     = 'A';
update rolt045
	set n45_descontado = nvl((select sum(n46_valor - n46_saldo)
					from rolt046
					where n46_compania  = n45_compania
					  and n46_num_prest = n45_num_prest),0)
	where n45_descontado = 0
	  and n45_estado     = 'A';
{--
update rolt033
	set n33_num_prest = (select unique num_prest from t1
				where cia       = n33_compania
				  and lq        = n33_cod_liqrol
				  and fec_ini   = n33_fecha_ini
				  and fec_fin   = n33_fecha_fin
				  and cod_trab  = n33_cod_trab
				  and cod_rubro = n33_cod_rubro)
	where n33_num_prest is null
	  and n33_valor     > 0
 	  and exists (select unique cia, lq, fec_ini, fec_fin, cod_trab,
				cod_rubro
			from t1
			where cia       = n33_compania
			  and lq        = n33_cod_liqrol
			  and fec_ini   = n33_fecha_ini
			  and fec_fin   = n33_fecha_fin
			  and cod_trab  = n33_cod_trab
			  and cod_rubro = n33_cod_rubro);
--}
commit work;
drop table t1;
drop table t2;
