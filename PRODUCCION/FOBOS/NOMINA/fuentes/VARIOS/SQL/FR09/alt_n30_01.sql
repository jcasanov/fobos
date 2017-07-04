begin work;

	alter table "fobos".rolt030
		add (n30_fon_res_anio		char(1)	before n30_usuario);

	select n30_cod_trab cod, n30_fon_res_anio fr_men
		from rolt030
		where n30_compania = 999
		into temp t1;

	load from "fr_men_gye.unl" insert into t1;
	--load from "fr_men_uio.unl" insert into t1;

	update "fobos".rolt030
		set n30_fon_res_anio = (select fr_men
						from t1
						where cod = n30_cod_trab)
		where n30_compania  = 1
		  and n30_cod_trab in (select cod from t1);

	update "fobos".rolt030
		set n30_fon_res_anio = 'S'
		where n30_fon_res_anio is null;

	drop table t1;

	alter table "fobos".rolt030
		modify (n30_fon_res_anio	char(1)	not null);

	alter table "fobos".rolt030
		add constraint
			check (n30_fon_res_anio in ('S', 'N'))
				constraint "fobos".ck_12_rolt030;

commit work;
