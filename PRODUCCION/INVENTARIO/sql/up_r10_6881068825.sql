begin work;

select r10_codigo codigo, r10_nombre nombre
	from acero_qm:rept010
	where r10_compania = 1
	  and r10_codigo   in('68810', '68811', '68812',  '68813', '68814',
				'68815', '68816', '68817', '68818', '68819',
				'68820', '68821', '68822', '68823', '68824',
				'68825')
	into temp t1;

update rept010
	set r10_nombre = (select nombre from t1 where codigo = r10_codigo)
	where r10_compania = 1
	  and r10_codigo   in('68810', '68811', '68812',  '68813', '68814',
				'68815', '68816', '68817', '68818', '68819',
				'68820', '68821', '68822', '68823', '68824',
				'68825');

commit work;

drop table t1;
