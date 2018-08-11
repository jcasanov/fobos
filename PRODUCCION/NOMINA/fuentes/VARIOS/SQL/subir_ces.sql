select compania, cod_liqrol, anio_cen, mes_cen, cod_trab, fecha_repar,
	 fecha_prox, valor_repar, usuario
	from tr_cesantia
	where compania = 999
	into temp t1;

load from "tr_cesantia201407.unl" delimiter "," insert into t1;

insert into tr_cesantia
	(compania, cod_liqrol, anio_cen, mes_cen, cod_trab, fecha_repar,
	 fecha_prox, valor_repar, usuario, fecing)
	select t1.compania, t1.cod_liqrol, t1.anio_cen, t1.mes_cen,
		t1.cod_trab, t1.fecha_repar, t1.fecha_prox, t1.valor_repar,
		t1.usuario, current
		from t1;

drop table t1;
