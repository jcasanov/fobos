set isolation to dirty read;

select j05_codigo_caja as cod_caj,
	j05_fecha_aper as fec_ape,
	j05_secuencia as secu,
	j05_ef_apertura as val_ef_ap,
	j05_ef_ing_dia as val_ef_dia,
	((j05_ef_apertura + j05_ef_ing_dia) - j05_ef_egr_dia) as dif_caj
	from cajt005
	where j05_compania     = 1
	  and j05_localidad    = 1
	  and j05_codigo_caja  = 3
	into temp t1;

select * from t1
	order by 2;

drop table t1;
