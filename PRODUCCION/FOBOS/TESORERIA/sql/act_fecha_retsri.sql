select c03_compania cia, c03_tipo_ret tip_r, c03_porcentaje porc,
	c03_codigo_sri cod_sri, c03_fecha_ini_porc fec_ini_p,
	c03_fecha_fin_porc fec_fin_p
	from ordt003
	where c03_compania = 1
	into temp t1;

select p28_compania cia_r, p28_localidad loc_r, p28_num_ret num_r,
	p28_secuencia secu, date(p27_fecing) fec_ret,
	p28_tipo_ret tipo_ret, p28_porcentaje porc_r, p28_codigo_sri cod_sri_r
	from cxpt028, cxpt027
	where p28_compania       = 1
	  and p28_fecha_ini_porc is null
	  and p28_compania       = p27_compania
	  and p28_localidad      = p27_localidad
	  and p28_num_ret        = p27_num_ret
	into temp t2;

select cia_r cia, loc_r loc, num_r, secu, cod_sri_r cod_sri, fec_ini_p
	from t1, t2
	where fec_fin_p is null
	  and cia_r      = cia
	  and tipo_ret   = tip_r
	  and porc_r     = porc
	  and cod_sri_r  = cod_sri
	  and fec_ret   >= fec_ini_p
	into temp t3;

delete from t1 where fec_fin_p is null;

delete from t2
	where not exists
		(select 1 from t3 a
			where a.cia       = t2.cia_r
			  and a.loc       = t2.loc_r
			  and a.num_r     = t2.num_r
			  and a.secu      = t2.secu
			  and a.cod_sri   = t2.cod_sri_r);

insert into t3
	select cia_r, loc_r, num_r, secu, cod_sri_r cod_sri, fec_ini_p
		from t1, t2
		where cia_r     = cia
		  and tipo_ret  = tip_r
		  and porc_r    = porc
		  and cod_sri_r = cod_sri
		  and fec_ret   between fec_ini_p
				    and fec_fin_p;

drop table t1;

drop table t2;

begin work;

	update cxpt028
		set p28_fecha_ini_porc =
			(select fec_ini_p
				from t3
				where cia     = p28_compania
				  and loc     = p28_localidad
				  and num_r   = p28_num_ret
				  and secu    = p28_secuencia
				  and cod_sri = p28_codigo_sri)
	where p28_compania       = 1
	  and p28_fecha_ini_porc is null
	  and exists
		(select 1 from t3
			where cia     = p28_compania
			  and loc     = p28_localidad
			  and num_r   = p28_num_ret
			  and secu    = p28_secuencia
			  and cod_sri = p28_codigo_sri);

--rollback work;
commit work;

drop table t3;
