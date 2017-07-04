select unique a12_tipcomp_gen tp, a12_numcomp_gen num, date(a12_fecing) fecha
	from actt012
	where a12_compania     = 1
	  and a12_codigo_tran  = 'DP'
	  and year(a12_fecing) = 2006
	  and a12_tipcomp_gen  is not null
	into temp t1;
select * from t1;
update actt012
	set a12_tipcomp_gen = (select tp from t1
				where fecha = date(a12_fecing)),
	    a12_numcomp_gen = (select num from t1
				where fecha = date(a12_fecing))
	where a12_compania     = 1
	  and a12_codigo_tran  = 'DP'
	  --and a12_codigo_bien  = 206
	  --and a12_codigo_bien  = 304
	  and a12_codigo_bien  = 8
	  and year(a12_fecing) = 2006
	  and a12_tipcomp_gen  is null
	  and date(a12_fecing) = (select fecha from t1
					where fecha = date(a12_fecing));
drop table t1;
