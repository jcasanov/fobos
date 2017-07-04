select n30_num_doc_id, n30_cod_trab, n30_nombres, n33_valor tot_gan,
	n33_valor vac, n33_valor aporte, n33_valor dec_ter, n33_valor dec_cua
	from rolt030, rolt033
	where n30_compania   = 10
	  and n33_compania   = n30_compania
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_fecha_ini  >= mdy(01, 01, 2005)
	  and n33_fecha_fin  <= mdy(12, 31, 2005)
	  and n33_cod_trab   = n30_cod_trab
	  and n33_det_tot    = 'DI'
	  and n33_cant_valor = 'V'
	  and n33_cod_rubro in
		(select n06_cod_rubro from rolt006
		where n06_flag_ident in ('VT', 'V1', 'V5', 'VM', 'VE', 'CO'))
	into temp t1;
select n30_num_doc_id, n30_cod_trab, n30_nombres, sum(n33_valor) tot_gan,
	0 vac, 0 aporte, 0 dec_ter, 0 dec_cua
	from rolt030, rolt033
	where n30_compania   = 1
	  and n33_compania   = n30_compania
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_fecha_ini  >= mdy(01, 01, 2005)
	  and n33_fecha_fin  <= mdy(12, 31, 2005)
	  and n33_cod_trab   = n30_cod_trab
	  and n33_det_tot    = 'DI'
	  and n33_cant_valor = 'V'
	  and n33_cod_rubro in
		(select n06_cod_rubro from rolt006
		where n06_flag_ident in ('VT', 'V1', 'V5', 'VM', 'VE', 'CO'))
	group by 1, 2, 3, 5, 6
	into temp t2;
insert into t1 select * from t2;
drop table t2;
select n30_cod_trab cod_trab, sum(n33_valor) vaca
	from rolt030, rolt033
	where n30_compania   = 1
	  and n33_compania   = n30_compania
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_fecha_ini  >= mdy(01, 01, 2005)
	  and n33_fecha_fin  <= mdy(12, 31, 2005)
	  and n33_cod_trab   = n30_cod_trab
	  and n33_det_tot    = 'DI'
	  and n33_cant_valor = 'V'
	  and n33_cod_rubro  = 12
	group by 1
	into temp t2;
update t1 set vac = (select vaca from t2 where cod_trab = n30_cod_trab)
	where 1 = 1;
drop table t2;
select n30_cod_trab cod_trab, sum(n33_valor) aport
	from rolt030, rolt033
	where n30_compania   = 1
	  and n33_compania   = n30_compania
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_fecha_ini  >= mdy(01, 01, 2005)
	  and n33_fecha_fin  <= mdy(12, 31, 2005)
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
select n36_cod_trab, n36_valor_bruto
        from rolt036
        where n36_compania  = 1
          and n36_proceso   = 'DT'
          and n36_fecha_ini = mdy(12,01,2004)
          and n36_fecha_fin = mdy(11,30,2005)
	into temp t2;
update t1 set dec_ter = (select n36_valor_bruto from t2
				where n36_cod_trab = n30_cod_trab)
	where n30_cod_trab in (select n36_cod_trab from t2);
drop table t2;
select n36_cod_trab, n36_valor_bruto
        from rolt036
        where n36_compania  = 1
          and n36_proceso   = 'DC'
          and n36_fecha_ini = mdy(04,01,2004)
          and n36_fecha_fin = mdy(03,31,2005)
	into temp t2;
update t1 set dec_cua = (select n36_valor_bruto from t2
				where n36_cod_trab = n30_cod_trab)
	where n30_cod_trab in (select n36_cod_trab from t2);
drop table t2;
select count(*) from t1;
unload to "impto_renta.txt"
	select n30_num_doc_id, n30_nombres, tot_gan, vac, aporte, dec_ter,
			dec_cua
		from t1
		order by 2;
drop table t1;
