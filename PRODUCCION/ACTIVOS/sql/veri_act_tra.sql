select a12_compania cia, a12_codigo_bien activo, --a12_codigo_tran tp,
	nvl(sum(a12_valor_mb), 0) val_tra
	from actt012
	where a12_compania in (1, 2)
	group by 1, 2
	into temp tmp_a12;
select activo,
	trim((select a06_descripcion[1, 15]
		from actt006
		where a06_compania = a10_compania
		  and a06_estado   = a10_estado)) estado,
	round(nvl(a10_valor_mb - a10_tot_dep_mb, 0), 2) val_act,
	round(val_tra, 2) val_tra
	--round((nvl(a10_valor_mb - a10_tot_dep_mb, 0)) - val_tra, 2) diferen
	from tmp_a12, actt010
	where a10_compania    = cia
	  and a10_codigo_bien = activo
	  and a10_estado      not in ('A', 'B')
	into temp tmp_a10;
drop table tmp_a12;
select * from tmp_a10
	where val_act <> val_tra
	into temp t1;
drop table tmp_a10;
select count(*) tot_reg from t1;
select * from t1 order by 1;
drop table t1;
