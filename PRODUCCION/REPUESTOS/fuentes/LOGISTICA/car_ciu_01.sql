begin work;

select g31_pais pais, g31_ciudad ciudad, g31_pais loc, g31_divi_poli provi
	from gent031
	where g31_ciudad = -1
	into temp t1;

load from "ciudades.csv" delimiter "," insert into t1;

update gent031
	set g31_divi_poli = (select provi
				from t1
				where loc    = 1
				  and pais   = g31_pais
				  and ciudad = g31_ciudad)
	where exists
		(select 1 from t1
			where loc    = 1
			  and pais   = g31_pais
			  and ciudad = g31_ciudad);

drop table t1;

commit work;
