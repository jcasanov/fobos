select z40_compania cia, z40_tipo_comp tp, z40_num_comp num, z40_num_doc
	from cxct040
	where z40_compania  = 1
	  and z40_localidad in (1, 2)
	  and z40_tipo_doc  = 'PG'
	  and z40_num_doc   in (10590, 10593, 10607, 10619, 10620, 10626,10636,
				10638, 10640, 10642, 10646, 10647, 10653,10520,
				10524, 10525, 10528, 10523, 10531, 10534,10535,
				10537, 10540, 10541, 10544, 10545, 10542,10555,
				10556, 10554, 10564, 10565, 10562, 10572,10573,
				10576, 10580, 10583, 10584, 10586, 10589)
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
