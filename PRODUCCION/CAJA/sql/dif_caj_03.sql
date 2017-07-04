set isolation to dirty read;

select j05_codigo_caja as cod_caj,
	j05_fecha_aper as fec_ape,
	j05_secuencia as secu,
	j05_ch_apertura as val_ch_ap,
	j05_ch_ing_dia as val_ch_dia,
	((j05_ch_apertura + j05_ch_ing_dia) - j05_ch_egr_dia) as dif_caj
	from cajt005
	where j05_compania     = 1
	  and j05_localidad    = 1
	  and j05_codigo_caja  = 3
	  --and j05_ch_ing_dia  <> 0
	into temp t1;

{--
select j10_codigo_caja as cod_cj,
	date(j10_fecha_pro) as fec_pro,
	sum(j11_valor) as val_ch
	from cajt010, cajt011
	where j10_compania    = 1
	  and j10_localidad   = 1
	  and j10_codigo_caja = 3
	  and j10_estado      = "P"
	  and j11_compania    = j10_compania
	  and j11_localidad   = j10_localidad
	  and j11_tipo_fuente = j10_tipo_fuente
	  and j11_num_fuente  = j10_num_fuente
	  and j11_codigo_pago = "CH"
	group by 1, 2
	into temp t2;

select cod_caj, fec_pro, val_ch_ap, val_ch_dia, val_ch,
	round((val_ch_dia - val_ch), 2) as difer
	from t1, t2
	where cod_caj                = cod_cj
	  and fec_ape                = fec_pro
	  and (val_ch_dia - val_ch) <> 0
	into temp t3;

drop table t1;
drop table t2;

select * from t3
	order by 2;

drop table t3;
--}

select * from t1
	order by 2;

drop table t1;
