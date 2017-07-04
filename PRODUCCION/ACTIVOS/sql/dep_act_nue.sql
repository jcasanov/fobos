select a10_compania cia, a10_codigo_bien activo, a10_grupo_act grupo_act,
	a10_cod_depto dep_ant,
	case when a10_grupo_act = 1 then 22
	     when a10_grupo_act = 2 then 23
	     when a10_grupo_act = 3 then 24
	     when a10_grupo_act = 4 then 27
	     when a10_grupo_act = 5 then 25
	     when a10_grupo_act = 6 then 26
	     when a10_grupo_act = 7 then 28
	end dep_nue
	from actt010
	where a10_compania  = 1
	  and a10_estado    in ('A', 'S', 'R')
	into temp t1;
select count(*) tot_t1
	from t1;
select grupo_act, a01_nombre nom_gr, count(*) tot_gr
	from t1, actt001
	where a01_compania  = cia
	  and a01_grupo_act = grupo_act
	group by 1, 2
	order by 1;
select grupo_act, activo, dep_ant, dep_nue
	from t1
	order by 1, 2;
begin work;
	update actt010
		set a10_cod_depto = (select dep_nue
					from t1
					where cia    = a10_compania
					  and activo = a10_codigo_bien)
	where a10_compania    = 1
	  and a10_estado      in ('A', 'S', 'R')
	  and a10_codigo_bien in (select activo
					from t1
					where cia = a10_compania);
commit work;
drop table t1;
