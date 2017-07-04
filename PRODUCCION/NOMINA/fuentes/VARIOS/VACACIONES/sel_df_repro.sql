select n32_compania cia, n32_cod_liqrol lq, n32_cod_trab cod_t,
	n32_fecha_ini fec_ini, n32_fecha_fin fec_fin,
	sum(n33_valor) tot_gan
        from rolt032, rolt033
        where n32_compania   in(1, 2)
          and n32_dias_falt  > 0
          and n32_fecha_fin  between mdy(07,01,2006) and mdy(11,30,2007)
          and n32_tot_gan    > n32_tot_ing
	  and n33_compania   = n32_compania
	  and n33_cod_liqrol = n32_cod_liqrol
	  and n33_fecha_ini  = n32_fecha_ini
	  and n33_fecha_fin  = n32_fecha_fin
	  and n33_cod_trab   = n32_cod_trab
	  and n33_cod_rubro  in (select n08_rubro_base
					from rolt008, rolt006
					where n08_cod_rubro  = n06_cod_rubro
				          and n06_flag_ident = 'AP')
	group by 1, 2, 3, 4, 5
	into temp t1;
select * from t1 order by fec_fin;
begin work;
update rolt032
	set n32_tot_gan = (select tot_gan
				from t1
				where cia     = n32_compania
				  and lq      = n32_cod_liqrol
				  and fec_ini = n32_fecha_ini
				  and fec_fin = n32_fecha_fin
				  and cod_t   = n32_cod_trab)
	where exists (select * from t1
			where cia     = n32_compania
			  and lq      = n32_cod_liqrol
			  and fec_ini = n32_fecha_ini
			  and fec_fin = n32_fecha_fin
			  and cod_t   = n32_cod_trab);
commit work;
drop table t1;
