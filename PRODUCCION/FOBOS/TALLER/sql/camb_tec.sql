select t23_compania cia, t23_localidad loc, t23_orden orden, t23_cod_mecani tec
	from talt023
	where t23_compania = 999
	into temp tmp_tec;

load from "tecnicos.unl" insert into tmp_tec;

begin work;

	update talt023
		set t23_cod_mecani = (select tec
					from tmp_tec
					where cia   = t23_compania
					  and loc   = t23_localidad
					  and orden = t23_orden)
		where t23_compania  = 1
		  and t23_localidad = 1
		  and t23_orden     in (select orden from tmp_tec);

	update talt024
		set t24_mecanico = (select tec
					from tmp_tec
					where cia   = t24_compania
					  and loc   = t24_localidad
					  and orden = t24_orden)
		where t24_compania  = 1
		  and t24_localidad = 1
		  and t24_orden     in (select orden from tmp_tec);

--rollback work;
commit work;

drop table tmp_tec;
