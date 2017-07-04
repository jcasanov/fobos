select n30_num_doc_id as cedula, n30_sueldo_mes as sueldo,
	n30_factor_hora as factor
	from rolt030
	where n30_compania = 999
	into temp t1;
load from "empl_2012.unl" insert into t1;
--load from "empl_2012_aj.unl" insert into t1;
select count(*) tot_t1 from t1;
begin work;
	update rolt030
		set n30_sueldo_mes  = (select sueldo
					from t1
					where cedula = n30_num_doc_id),
		    n30_factor_hora = (select factor
					from t1
					where cedula = n30_num_doc_id)
	where n30_compania = 1
	  and n30_num_doc_id in (select cedula from t1);
commit work;
drop table t1;
