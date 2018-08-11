select n30_num_doc_id, n30_cod_trab, n30_nombres, n33_valor tot_gan,
	n33_valor rus, n33_valor aporte
	from rolt030, rolt033
	where n30_compania   = 10
	  and n33_compania   = n30_compania
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_fecha_ini >= mdy(01, 01, 2003)
	  and n33_fecha_fin <= mdy(12, 31, 2003)
	  and n33_cod_trab   = n30_cod_trab
	  and n33_det_tot    = 'DI'
	  and n33_cant_valor = 'V'
	  and (n33_cod_rubro in
		(select n06_cod_rubro from rolt006
		where n06_flag_ident in ('VT', 'V1', 'V5', 'VM', 'VE', 'CO'))
	   or n33_cod_rubro = 12)
	into temp t1;
select n30_num_doc_id, n30_cod_trab, n30_nombres, sum(n33_valor) tot_gan,
	0 rus, 0 aporte
	from rolt030, rolt033
	where n30_compania   = 1
	  and n33_compania   = n30_compania
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_fecha_ini >= mdy(01, 01, 2003)
	  and n33_fecha_fin <= mdy(12, 31, 2003)
	  and n33_cod_trab   = n30_cod_trab
	  and n33_det_tot    = 'DI'
	  and n33_cant_valor = 'V'
	  and (n33_cod_rubro in
		(select n06_cod_rubro from rolt006
		where n06_flag_ident in ('VT', 'V1', 'V5', 'VM', 'VE', 'CO'))
	   or n33_cod_rubro = 12)
	group by 1, 2, 3, 5, 6
	into temp t2;
insert into t1 select * from t2;
drop table t2;
select n30_cod_trab cod_trab, sum(n33_valor) ruse
	from rolt030, rolt033
	where n30_compania   = 1
	  and n33_compania   = n30_compania
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_fecha_ini >= mdy(01, 01, 2003)
	  and n33_fecha_fin <= mdy(12, 31, 2003)
	  and n33_cod_trab   = n30_cod_trab
	  and n33_det_tot    = 'DI'
	  and n33_cant_valor = 'V'
	  and n33_cod_rubro in
		(select n06_cod_rubro from rolt006
			where n06_flag_ident in ('CS'))
	group by 1
	into temp t2;
update t1 set rus = (select ruse from t2 where cod_trab = n30_cod_trab)
	where 1 = 1;
drop table t2;
select n30_cod_trab cod_trab, sum(n33_valor) aport
	from rolt030, rolt033
	where n30_compania   = 1
	  and n33_compania   = n30_compania
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_fecha_ini >= mdy(01, 01, 2003)
	  and n33_fecha_fin <= mdy(12, 31, 2003)
	  and n33_cod_trab   = n30_cod_trab
	  and n33_det_tot    = 'DE'
	  and n33_cant_valor = 'V'
	  and n33_cod_rubro in
		(select n06_cod_rubro from rolt006
			where n06_flag_ident in ('AP'))
	group by 1
	into temp t2;
update t1 set aporte = (select aport from t2 where cod_trab = n30_cod_trab)
	where 1 = 1;
drop table t2;
select count(*) from t1;
unload to "impto_renta.txt"
	select n30_num_doc_id, n30_nombres, tot_gan, rus, aporte
		from t1
		order by 2;
drop table t1;
