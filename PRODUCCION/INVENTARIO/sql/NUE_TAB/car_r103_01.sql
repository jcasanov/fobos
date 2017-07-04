select r103_compania cia, r103_localidad loc, r103_pre_lin_anio pl_anio,
	r103_pre_lin_mes pl_mes, r103_pre_lin_sem pl_sem, r103_vendedor vend,
	r103_cod_linea codlin, r103_cod_filtro filtro, r103_pre_lin_val valor
	from rept103
	where r103_compania = 999
	into temp t1;

load from "rept103.csv" delimiter "," insert into t1;

select cia, filtro
	from t1
	where filtro not in
		(select r101_cod_filtro
			from rept101)
	group by 1, 2;

insert into rept103
	(r103_compania, r103_localidad, r103_pre_lin_anio, r103_pre_lin_mes,
	 r103_pre_lin_sem, r103_vendedor, r103_cod_linea, r103_cod_filtro,
	 r103_pre_lin_val, r103_usuario, r103_fecing)
	select t1.*, "FOBOS", current
		from t1
		where loc     = 1
		  and filtro <> "MONOFLO";

drop table t1;
