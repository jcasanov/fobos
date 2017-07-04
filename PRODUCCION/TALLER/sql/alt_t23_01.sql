begin work;

alter table "fobos".talt023
	add (t23_dir_cliente	varchar(40,20)	before t23_codcli_est);
alter table "fobos".talt023
	add (t23_cedruc		char(15)	before t23_codcli_est);

alter table "fobos".talt020
	add (t20_cedruc		char(15)	before t20_motivo);

select unique r21_compania cia, r21_localidad loc, r21_num_ot orden,
	r21_codcli codcli, r21_dircli direccion, r21_cedruc cedruc,
	r21_fecing fecha
	from rept021
	where r21_compania  in (1, 2)
	  and r21_localidad in (1, 3, 5)
	  and r21_num_ot    is not null
	into temp t1;

update talt023
	set t23_dir_cliente = nvl((select unique t20_dir_cliente
					from talt020
					where t20_compania  = t23_compania
					  and t20_localidad = t23_localidad
					  and t20_numpre    = t23_numpre
					and t20_cod_cliente = t23_cod_cliente),
				  (select unique z01_direccion1
					from cxct001
					where z01_codcli = t23_cod_cliente)),
	    t23_cedruc      = nvl((select unique cedruc
					from t1
					where cia          = t23_compania
					  and loc          = t23_localidad
					  and orden        = t23_orden
					  and codcli       = t23_cod_cliente
					  and year(fecha) <= 2007),
			      nvl((select unique z01_num_doc_id
					from cxct001
					where z01_codcli = t23_cod_cliente),
				'9999999999'))
	where t23_compania  in (1, 2)
	  and t23_localidad in (1, 3, 5);

update talt020
	set t20_cedruc = nvl((select unique t23_cedruc
				from talt023
				where t23_compania    = t20_compania
				  and t23_localidad   = t20_localidad
				  and t23_numpre      = t20_numpre
				  and t23_cod_cliente = t20_cod_cliente),
				'9999999999')
	where t20_compania  in (1, 2)
	  and t20_localidad in (1, 3, 5);

alter table "fobos".talt023
	modify (t23_cedruc		char(15)	not null);

alter table "fobos".talt020
	modify (t20_cedruc		char(15)	not null);

commit work;

drop table t1;
