select z40_compania cia, z40_tipo_comp tp, z40_num_comp num, z40_num_doc
	from cxct040
	where z40_compania  = 1
	  and z40_localidad in (1, 2)
	  and z40_tipo_doc  = 'PG'
	  and z40_num_doc   in (10576, 10636, 10647)
	into temp t1;

select count(*) total_pg from t1;

--select * from t1 order by z40_num_doc;

begin work;

update ctbt012
	set b12_fec_proceso = mdy(01,08,2007)
	where exists (select * from t1
			where cia = b12_compania
			  and tp  = b12_tipo_comp
			  and num = b12_num_comp);

update ctbt013
	set b13_fec_proceso = mdy(01,08,2007)
	where exists (select * from t1
			where cia = b13_compania
			  and tp  = b13_tipo_comp
			  and num = b13_num_comp);

commit work;

drop table t1;
