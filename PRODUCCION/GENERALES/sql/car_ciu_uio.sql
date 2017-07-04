begin work;

select g31_ciudad ciudad, g31_pais pais, g31_divi_poli provi, g31_nombre nom,
	g31_siglas sigl, g31_usuario usua, g31_fecing fec
	from gent031
	where g31_ciudad = -1
	into temp t1;

load from "ciudades_uio.unl" insert into t1;

insert into gent031
	(g31_ciudad, g31_pais, g31_divi_poli, g31_nombre, g31_siglas,
	 g31_usuario, g31_fecing)
	select ciudad, pais, provi, trim(nom), trim(sigl), usua, fec
		from t1;

drop table t1;

commit work;
