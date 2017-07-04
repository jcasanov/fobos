select * from rolt033
	where n33_compania   = 1
	  and n33_fecha_ini >= mdy(01,01,2009)
	  and n33_fecha_fin <= mdy(03,31,2009)
	  and n33_cod_rubro in (select n06_cod_rubro
				from rolt006
				where n06_flag_ident = 'XV')
	  and n33_valor      > 0
	into temp t1;

--select sum(n33_valor) from t1;

select n33_compania cia,
	case when n33_cod_liqrol = 'Q2'
		then 'Q1'
		else 'Q2'
	end lq,
	n33_fecha_fin + 1 units day fec_ini,
	case when n33_cod_liqrol = 'Q2'
		then mdy(month(n33_fecha_fin), 15, year(n33_fecha_fin))
			+ 1 units month
		else n33_fecha_ini + 1 units month - 1 units day
	end fec_fin,
	n33_cod_trab cod_t, n06_cod_rubro cod_r, n06_orden orden,
	n06_det_tot det_tot, n06_imprime_0 impri, n06_cant_valor cant_v,
	n33_valor valor
	from t1, rolt006
	where n06_cod_rubro = 30
	union all
	select n33_compania cia,
		case when n33_cod_liqrol = 'Q2'
			then 'Q1'
			else 'Q2'
		end lq,
		n33_fecha_fin + 1 units day fec_ini,
		case when n33_cod_liqrol = 'Q2'
			then mdy(month(n33_fecha_fin), 15, year(n33_fecha_fin))
				+ 1 units month
			else n33_fecha_ini + 1 units month - 1 units day
		end fec_fin,
		n33_cod_trab cod_t, n06_cod_rubro cod_r, n06_orden orden,
		n06_det_tot det_tot, n06_imprime_0 impri, n06_cant_valor cant_v,
		n33_valor valor
		from t1, rolt006
		where n06_cod_rubro = 75
	into temp tmp_n33;

drop table t1;

--select * from tmp_n33 order by cod_r;

begin work;

	insert into rolt033
		(n33_compania, n33_cod_liqrol, n33_fecha_ini, n33_fecha_fin,
		 n33_cod_trab, n33_cod_rubro, n33_orden, n33_det_tot,
		 n33_imprime_0, n33_cant_valor, n33_valor)
		select * from tmp_n33;

	update rolt032
		set n32_tot_ing = n32_tot_ing +
				(select valor
					from tmp_n33
					where cia     = n32_compania
					  and lq      = n32_cod_liqrol
					  and fec_ini = n32_fecha_ini
					  and fec_fin = n32_fecha_fin
					  and cod_t   = n32_cod_trab
					  and cod_r   = 30),
		    n32_tot_egr = n32_tot_egr +
				(select valor
					from tmp_n33
					where cia     = n32_compania
					  and lq      = n32_cod_liqrol
					  and fec_ini = n32_fecha_ini
					  and fec_fin = n32_fecha_fin
					  and cod_t   = n32_cod_trab
					  and cod_r   = 75)
		where exists
			(select 1 from tmp_n33
				where cia     = n32_compania
				  and lq      = n32_cod_liqrol
				  and fec_ini = n32_fecha_ini
				  and fec_fin = n32_fecha_fin
				  and cod_t   = n32_cod_trab);

drop table tmp_n33;

--rollback work;
commit work;
