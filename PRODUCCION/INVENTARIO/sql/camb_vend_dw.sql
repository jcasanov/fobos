select 1 loc, r01_codigo cod, r01_nombres nom, r01_iniciales ini,
	r01_estado est, r01_tipo tip
	from acero_gm@idsgye01:rept001
	where r01_compania = 1
union
select 2 loc, r01_codigo cod, r01_nombres nom, r01_iniciales ini,
	r01_estado est, r01_tipo tip
	from acero_gc@idsgye01:rept001
	where r01_compania = 1
union
select 3 loc, r01_codigo cod, r01_nombres nom, r01_iniciales ini,
	r01_estado est, r01_tipo tip
	from acero_qm@idsuio01:rept001
	where r01_compania = 1
union
select 4 loc, r01_codigo cod, r01_nombres nom, r01_iniciales ini,
	r01_estado est, r01_tipo tip
	from acero_qs@idsuio02:rept001
	where r01_compania = 1
	into temp t1;

update acero_dw@idsgyere:vendedor
	set r01_codigo   = (select cod
				from t1
				where loc = r01_localidad
				  and cod = r01_codigo),
	    r01_nombres   = (select nom
				from t1
				where loc = r01_localidad
				  and cod = r01_codigo),
	    r01_iniciales = (select ini
				from t1
				where loc = r01_localidad
				  and cod = r01_codigo),
	    r01_estado    = (select est
				from t1
				where loc = r01_localidad
				  and cod = r01_codigo),
	    r01_tipo      = (select tip
				from t1
				where loc = r01_localidad
				  and cod = r01_codigo)
	where exists (select cod
				from t1
				where loc = r01_localidad
				  and cod = r01_codigo);

drop table t1;
