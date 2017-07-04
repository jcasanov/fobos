select j10_compania cia, j10_localidad loc, j10_codigo_caja cod, 
	date(j10_fecha_pro) fecha, j02_nombre_caja caja, j11_codigo_pago cp,
	nvl(sum(j11_valor), 0) saldo
	from cajt010, cajt011, cajt002
	where j10_compania        in (1, 2)
	  and j10_estado           = 'P'
	  and date(j10_fecha_pro)  = mdy(09, 12, 2007)
	  and j11_compania         = j10_compania
	  and j11_localidad        = j10_localidad
	  and j11_tipo_fuente      = j10_tipo_fuente
	  and j11_num_fuente       = j10_num_fuente
	  and j02_compania         = j10_compania
	  and j02_localidad        = j10_localidad
	  and j02_codigo_caja      = j10_codigo_caja
	group by 1, 2, 3, 4, 5, 6
	into temp t1;
select cod, caja, cp, saldo from t1 order by 2, 3;
select cod, caja, round(nvl(sum(saldo), 0), 2) saldo_dia
	from t1
	group by 1, 2
	order by 2, 3;
select cod, caja, cp, saldo,
	case when cp = 'CH' then
		nvl((select j05_ch_apertura
			from cajt005
			where j05_compania    = cia
			  and j05_localidad   = loc
			  and j05_codigo_caja = cod
			  and j05_fecha_aper  = 
				(select max(a.j05_fecha_aper)
					from cajt005 a
					where a.j05_compania    = cia
					  and a.j05_localidad   = loc
					  and a.j05_codigo_caja = cod
					  and a.j05_fecha_aper  < fecha)), 0)
	     when cp = 'EF' then
		nvl((select j05_ef_apertura
			from cajt005
			where j05_compania    = cia
			  and j05_localidad   = loc
			  and j05_codigo_caja = cod
			  and j05_fecha_aper  = 
				(select max(a.j05_fecha_aper)
					from cajt005 a
					where a.j05_compania    = cia
					  and a.j05_localidad   = loc
					  and a.j05_codigo_caja = cod
					  and a.j05_fecha_aper  < fecha)), 0)
	end sal_eg
	from t1
	where cp in ('EF', 'CH')
	into temp t2;
drop table t1;
select * from t2 where sal_eg <> 0 order by 2, 3;
drop table t2;
