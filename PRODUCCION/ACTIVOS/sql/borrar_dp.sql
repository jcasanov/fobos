begin work;

delete from actt012
	where date(a12_fecing) = mdy(01,31,2011)
	  and a12_codigo_tran  = 'DP';

delete from actt013
	where a13_ano = 2011;

delete from actt014
	where a14_anio = 2011;

update actt000
	set a00_mespro = 1;

commit work;
