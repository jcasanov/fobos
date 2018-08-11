select sum(r31_stock) valor1
	from rept031, rept002
	where r31_compania  = 12
	  and r31_ano       = 2003
	  and r31_mes       = 12
	  and r02_compania  = r31_compania
	  and r02_codigo    = r31_bodega
	  and r02_localidad in (1,2)
	  and r02_tipo      = 'F'
	  and r02_area      = 'R'
	into temp t1;
insert into t1
	select sum(r31_stock) valor1
		from rept031, rept002
		where r31_compania  = 1
		  and r31_ano       = 2003
		  and r31_mes       = 12
		  and r02_compania  = r31_compania
		  and r02_codigo    = r31_bodega
		  and r02_localidad = 1
		  and r02_tipo      = 'F'
		  and r02_area      = 'R';
insert into t1
	select sum(r31_stock) valor1
		from acero_gc:rept031, acero_gc:rept002
		where r31_compania  = 1
		  and r31_ano       = 2003
		  and r31_mes       = 12
		  and r02_compania  = r31_compania
		  and r02_codigo    = r31_bodega
		  and r02_localidad = 2
		  and r02_tipo      = 'F'
		  and r02_area      = 'R';
select sum(valor1) from t1;
drop table t1;
