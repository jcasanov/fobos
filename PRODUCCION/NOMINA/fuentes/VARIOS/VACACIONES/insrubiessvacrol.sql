select a.n33_compania cia, a.n33_cod_liqrol lq, a.n33_fecha_ini fec_ini,
	a.n33_fecha_fin fec_fin, a.n33_cod_trab cod_t, n06_cod_rubro cod_r,
	n06_orden orden, n06_det_tot det_tot, n06_imprime_0 impri,
	n06_cant_valor cant_v, a.n33_cod_rubro rub_des,
	nvl((select b.n33_valor
		from rolt033 b
		where b.n33_compania    = a.n33_compania
		  and b.n33_cod_liqrol  = a.n33_cod_liqrol
		  and b.n33_fecha_ini   = a.n33_fecha_ini
		  and b.n33_fecha_fin   = a.n33_fecha_fin
		  and b.n33_cod_trab    = a.n33_cod_trab
		  and b.n33_cod_rubro  in (select n06_cod_rubro
						from rolt006
						where n06_flag_ident = 'VV')) -
		(select b.n33_valor
		from rolt033 b
		where b.n33_compania    = a.n33_compania
		  and b.n33_cod_liqrol  = a.n33_cod_liqrol
		  and b.n33_fecha_ini   = a.n33_fecha_ini
		  and b.n33_fecha_fin   = a.n33_fecha_fin
		  and b.n33_cod_trab    = a.n33_cod_trab
		  and b.n33_cod_rubro   = a.n33_cod_rubro), 0) valor
	from rolt033 a, rolt006
	where a.n33_compania   = 1
	  and a.n33_fecha_ini >= mdy(01,01,2009)
	  and a.n33_fecha_fin <= mdy(04,15,2009)
	  and a.n33_cod_rubro in (select n06_cod_rubro
					from rolt006
					where n06_flag_ident = 'XV')
	  and a.n33_valor      > 0
	  and n06_cod_rubro    = 31
	into temp tmp_n33;

select sum(valor) from tmp_n33;

select * from tmp_n33 order by fec_fin, cod_t;

begin work;

	insert into rolt033
		(n33_compania, n33_cod_liqrol, n33_fecha_ini, n33_fecha_fin,
		 n33_cod_trab, n33_cod_rubro, n33_orden, n33_det_tot,
		 n33_imprime_0, n33_cant_valor, n33_valor)
		select cia, lq, fec_ini, fec_fin, cod_t, cod_r, orden, det_tot,
			impri, cant_v, valor
			from tmp_n33;

	update rolt032
		set n32_tot_ing = n32_tot_ing +
				(select valor
					from tmp_n33
					where cia     = n32_compania
					  and lq      = n32_cod_liqrol
					  and fec_ini = n32_fecha_ini
					  and fec_fin = n32_fecha_fin
					  and cod_t   = n32_cod_trab),
		    n32_tot_egr = n32_tot_egr +
				(select valor
					from tmp_n33
					where cia     = n32_compania
					  and lq      = n32_cod_liqrol
					  and fec_ini = n32_fecha_ini
					  and fec_fin = n32_fecha_fin
					  and cod_t   = n32_cod_trab)
		where exists
			(select 1 from tmp_n33
				where cia     = n32_compania
				  and lq      = n32_cod_liqrol
				  and fec_ini = n32_fecha_ini
				  and fec_fin = n32_fecha_fin
				  and cod_t   = n32_cod_trab);

	update rolt033
		set n33_valor = n33_valor +
				(select valor
					from tmp_n33
					where cia     = n33_compania
					  and lq      = n33_cod_liqrol
					  and fec_ini = n33_fecha_ini
					  and fec_fin = n33_fecha_fin
					  and cod_t   = n33_cod_trab
					  and rub_des = n33_cod_rubro)
		where exists
			(select 1 from tmp_n33
				where cia     = n33_compania
				  and lq      = n33_cod_liqrol
				  and fec_ini = n33_fecha_ini
				  and fec_fin = n33_fecha_fin
				  and cod_t   = n33_cod_trab
				  and rub_des = n33_cod_rubro);

drop table tmp_n33;

commit work;
--rollback work;
