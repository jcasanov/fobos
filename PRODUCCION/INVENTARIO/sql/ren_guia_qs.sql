create temp table t1
        (cia		integer,
	 loc		smallint,
	 guia           decimal(15,0),
         fecha          date,
         fecing         datetime year to second,
         secuencia      serial
        );
select r95_compania cia, r95_localidad loc, r95_guia_remision guia,
	r95_fecha_emi + 1 units day - 1 units day fecha, r95_fecing fecing
        from rept095
        order by 4, 5
        into temp t2;
insert into t1 select cia, loc, guia, fecha, fecing, 0 from t2;
drop table t2;
select count(*) tot_reg from t1;
select count(*) tot_igu from t1 where guia = secuencia;
select count(*) tot_dif from t1 where guia <> secuencia;
{--
select guia, fecha, fecing, secuencia
	from t1
	where guia <> secuencia
	order by secuencia;
select guia, fecha, fecing, secuencia
	from t1
	order by secuencia;
--}
select * from t1 where guia <> secuencia into temp t3;
drop table t1;
begin work;
	update rept097
		set r97_guia_remision = (select secuencia from t3
					where cia  = r97_compania
					  and loc  = r97_localidad
					  and guia = r97_guia_remision)
		where exists (select 1 from t3
				where cia  = r97_compania
				  and loc  = r97_localidad
				  and guia = r97_guia_remision);
	update rept096
		set r96_guia_remision = (select secuencia from t3
					where cia  = r96_compania
					  and loc  = r96_localidad
					  and guia = r96_guia_remision)
		where exists (select 1 from t3
				where cia  = r96_compania
				  and loc  = r96_localidad
				  and guia = r96_guia_remision);
	update rept095
		set r95_guia_remision = (select secuencia from t3
					where cia  = r95_compania
					  and loc  = r95_localidad
					  and guia = r95_guia_remision)
		where exists (select 1 from t3
				where cia  = r95_compania
				  and loc  = r95_localidad
				  and guia = r95_guia_remision);
commit work;
--rollback work;
drop table t3;
