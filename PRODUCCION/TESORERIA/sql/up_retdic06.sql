select z40_compania cia, z40_tipo_comp tp, z40_num_comp num, z40_num_doc
	from cxct040
	where z40_compania  = 2
	  and z40_localidad = 6
	  and z40_codcli    in(824, 2877, 2078, 2336, 958, 872, 1993, 972,
				1719, 1974, 3050, 753, 1917, 606)
	  and z40_tipo_doc  = 'PG'
	  and z40_num_doc   in(438, 439, 442, 443, 444, 445, 448, 449, 450,
				451, 453, 456, 457, 458, 462, 464, 465, 466,
				467, 468, 469, 473, 482, 484)
	into temp t1;

select count(*) total_pg from t1;

--select * from t1 order by z40_num_doc;

begin work;

update ctbt012
	set b12_fec_proceso = mdy(12,31,2006)
	where exists (select * from t1
			where cia = b12_compania
			  and tp  = b12_tipo_comp
			  and num = b12_num_comp);

update ctbt013
	set b13_fec_proceso = mdy(12,31,2006)
	where exists (select * from t1
			where cia = b13_compania
			  and tp  = b13_tipo_comp
			  and num = b13_num_comp);

commit work;

drop table t1;
