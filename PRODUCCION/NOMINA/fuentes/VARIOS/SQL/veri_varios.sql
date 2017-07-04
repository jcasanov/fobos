select unique n50_compania cia, n50_cod_rubro rubro
	from rolt050
	where n50_compania = 1
	  and n50_aux_cont = '11240103001'
union
select unique n51_compania cia, n51_cod_rubro rubro
	from rolt051
	where n51_compania = 1
	  and n51_aux_cont = '11240103001'
union
select unique n52_compania cia, n52_cod_rubro rubro
	from rolt052
	where n52_compania = 1
	  and n52_aux_cont = '11240103001'
	into temp tmp_rub;

select n33_cod_liqrol lq, n33_cod_rubro rub, n06_nombre_abr nom,
	round(sum(nvl(case when n33_det_tot = 'DI'
			then n33_valor
		 when n33_det_tot = 'DE'
			then n33_valor * (-1)
		end, 0)), 2) valor
	from rolt033, rolt006
	where n33_compania    = 1
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_fecha_ini  >= mdy(01, 01, 2010)
	  and n33_fecha_fin  <= mdy(01, 31, 2010)
	  and n33_cod_rubro  in
			(select rubro
				from tmp_rub
				where cia   = n33_compania
				  and rubro = n33_cod_rubro)
	  and n33_cant_valor = 'V'
	  and n33_valor      > 0
	  and n06_cod_rubro  = n33_cod_rubro
	group by 1, 2, 3
	into temp t1;

drop table tmp_rub;

select lq, sum(valor)
	from t1
	group by 1;

select * from t1
	order by 1, 2;

drop table t1;
