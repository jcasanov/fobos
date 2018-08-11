begin work;

update gent010
	set g10_estado = 'B'
	where g10_compania  = 1
	  and g10_tarjeta  in (2, 6, 7);

update gent010
	set g10_cod_tarj = 'TM'
	where g10_compania = 1
	  and g10_tarjeta  = 1;

update gent010
	set g10_cod_tarj = 'TA'
	where g10_compania = 1
	  and g10_tarjeta  = 3;

update gent010
	set g10_cod_tarj = 'TD'
	where g10_compania = 1
	  and g10_tarjeta  = 4;

update gent010
	set g10_cod_tarj = 'TV'
	where g10_compania = 1
	  and g10_tarjeta  = 5;

select * from gent010
	where g10_compania = 1
	  and g10_estado   = 'A'
	into temp t1;

update t1
	set g10_tarjeta   = 8,
	    g10_cont_cred = 'R'
	where g10_tarjeta = 1;

update t1
	set g10_tarjeta   = 9,
	    g10_cont_cred = 'R'
	where g10_tarjeta = 3;

update t1
	set g10_tarjeta   = 10,
	    g10_cont_cred = 'R'
	where g10_tarjeta = 4;

update t1
	set g10_tarjeta   = 11,
	    g10_cont_cred = 'R'
	where g10_tarjeta = 5;

insert into gent010
	select g10_compania, g10_tarjeta, g10_cod_tarj, g10_cont_cred,
		g10_estado, g10_nombre, g10_codcobr, g10_usuario, current
		from t1;

commit work;

drop table t1;
