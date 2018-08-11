begin work;

select unique r21_compania cia, r21_localidad loc, r21_num_ot orden,
	r21_codcli codcli, r21_dircli direccion, r21_cedruc cedruc,
	r21_fecing fecha
	from rept021
	where r21_compania  in (1, 2)
	  and r21_localidad in (1, 3, 5)
	  and r21_num_ot    is not null
	into temp t1;

select t20_compania cia, t20_localidad loc, t20_numpre numpre,
	t20_cod_cliente cod_c, t20_dir_cliente direccion, t23_orden orden
	from talt020, talt023
	where t20_compania    = t23_compania
	  and t20_localidad   = t23_localidad
	  and t20_numpre      = t23_numpre
	  and t20_cod_cliente = t23_cod_cliente
	into temp tmp_t20;

select unique numpre np, direccion
	from tmp_t20
	into temp caca;

select unique cia, loc, orden, numpre
	from tmp_t20
	into temp caca1;

select unique cia, loc, orden, direccion
	from caca, caca1
	where numpre = np
	into temp t_dir;

drop table caca;
drop table caca1;

select cia, loc, orden, count(*) direcc
	from t_dir
	group by 1, 2, 3
	having count(*) > 1;

select unique orden ord_t, cedruc
	from t1
	where year(fecha) <= 2007
	into temp caca;

select unique cia, loc, orden
	from t1
	where year(fecha) <= 2007
	into temp caca1;

select unique cia, loc, orden, cedruc
	from caca, caca1
	where orden = ord_t
	into temp t_ced;

drop table caca;
drop table caca1;

select cia, loc, orden, count(*) cedruc
	from t_ced
	group by 1, 2, 3
	having count(*) > 1
	into temp caca;

delete from t_ced
	where exists (select * from caca
			where caca.cia   = t_ced.cia
			  and caca.loc   = t_ced.loc
			  and caca.orden = t_ced.orden);

drop table caca;

select unique t23_compania cia, t23_localidad loc, t23_orden orden,
	z01_direccion1 dir_cli, z01_num_doc_id cr_cli
	from talt023, cxct001
	where z01_codcli = t23_cod_cliente
	into temp t_cli;

update talt023
	set t23_dir_cliente = nvl((select unique direccion
					from t_dir
					where cia   = t23_compania
					  and loc   = t23_localidad
					  and orden = t23_orden),
				  (select unique dir_cli
					from t_cli
					where cia   = t23_compania
					  and loc   = t23_localidad
					  and orden = t23_orden)),
	    t23_cedruc      = nvl((select unique cedruc
					from t_ced
					where cia   = t23_compania
					  and loc   = t23_localidad
					  and orden = t23_orden),
			      nvl((select unique cr_cli
					from t_cli
					where cia   = t23_compania
					  and loc   = t23_localidad
					  and orden = t23_orden),
				'9999999999'))
	where t23_compania  in (1, 2)
	  and t23_localidad in (1, 3, 5);

select unique cia, loc, t23_numpre numpre, cedruc
	from t_ced, talt023
	where cia   = t23_compania
	  and loc   = t23_localidad
	  and orden = t23_orden
	into temp t_ced_p;

select unique cia, loc, numpre, count(*) cedruc
	from t_ced_p
	group by 1, 2, 3
	having count(*) > 1
	into temp caca;

delete from t_ced_p
	where exists (select * from caca
			where caca.cia    = t_ced_p.cia
			  and caca.loc    = t_ced_p.loc
			  and caca.numpre = t_ced_p.numpre);

drop table caca;

select unique cia, loc, t23_numpre numpre, cr_cli
	from t_cli, talt023
	where cia   = t23_compania
	  and loc   = t23_localidad
	  and orden = t23_orden
	into temp t_cli_p;

select unique cia, loc, numpre, count(*) cr_cli
	from t_cli_p
	group by 1, 2, 3
	having count(*) > 1
	into temp caca;

delete from t_cli_p
	where exists (select * from caca
			where caca.cia    = t_cli_p.cia
			  and caca.loc    = t_cli_p.loc
			  and caca.numpre = t_cli_p.numpre);

drop table caca;

update talt020
	set t20_cedruc      = nvl((select unique cedruc
					from t_ced_p
					where cia    = t20_compania
					  and loc    = t20_localidad
					  and numpre = t20_numpre),
			      nvl((select unique cr_cli
					from t_cli_p
					where cia    = t20_compania
					  and loc    = t20_localidad
					  and numpre = t20_numpre),
				'9999999999'))
	where t20_compania  in (1, 2)
	  and t20_localidad in (1, 3, 5);

{--
alter table "fobos".talt023
	modify (t23_cedruc		char(15)	not null);

alter table "fobos".talt020
	modify (t20_cedruc		char(15)	not null);
--}

commit work;

drop table t1;
drop table t_dir;
drop table t_ced;
drop table t_cli;
drop table tmp_t20;
drop table t_ced_p;
drop table t_cli_p;
