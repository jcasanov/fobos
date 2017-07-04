select n45_cod_trab as cod,
	n30_nombres as nom,
	n45_num_prest as anti,
	date(n45_fecha) as fecha,
	n56_aux_val_vac as cta,
	b10_descripcion[1, 23] as nom_cta,
	sum(n45_val_prest + n45_sal_prest_ant) as val_ant,
	sum(n45_descontado) as descon,
	sum((n45_val_prest + n45_sal_prest_ant) - n45_descontado) as sal_ant
	from rolt045, rolt030, rolt056, ctbt010
	where n45_compania    = 1
	  and n45_cod_rubro   in
		(select n18_cod_rubro
			from rolt018
			where n18_flag_ident in ("AN", "AX"))
	  and n45_estado      not in ("E", "T")
	  and year(n45_fecha) = 2014
	  and n30_compania    = n45_compania
	  and n30_cod_trab    = n45_cod_trab
	  and n56_compania    = n30_compania
	  and n56_proceso     = "AN"
	  and n56_cod_depto   = n30_cod_depto
	  and n56_cod_trab    = n30_cod_trab
	  and b10_compania    = n56_compania
	  and b10_cuenta      = n56_aux_val_vac
	group by 1, 2, 3, 4, 5, 6
	into temp tmp_ant;

select cod, nom, cta, nom_cta, sum(val_ant) as val_ant, sum(descon) as descon,
	sum(sal_ant) as sal_ant
	from tmp_ant
	group by 1, 2, 3, 4
	into temp tmp_sal;

select b12_fec_proceso as fec,
	b12_tipo_comp as tp,
	b12_num_comp as num,
	cta as cta1,
	nom_cta as nom_c,
	cod as codi,
	nom as nomb,
	sum(case when b13_valor_base >= 0
		then b13_valor_base
		else 0.00
	end) as val_db,
	sum(case when b13_valor_base < 0
		then b13_valor_base
		else 0.00
	end) as val_cr,
	round(sum(b13_valor_base), 2) as sal_ctb
	from ctbt012, ctbt013, tmp_sal
	where b12_compania           = 1
	  and b12_estado             = "M"
	  and year(b12_fec_proceso)  = 2014
	  and b13_compania           = b12_compania
	  and b13_tipo_comp          = b12_tipo_comp
	  and b13_num_comp           = b12_num_comp
	  and b13_cuenta             = cta
	group by 1, 2, 3, 4, 5, 6, 7
	into temp tmp_ctb;

select cta1, nom_c, codi, nomb, sum(val_db) as val_db, sum(val_cr) as val_cr,
	sum(sal_ctb) as sal_ctb
	from tmp_ctb
	group by 1, 2, 3, 4
	into temp tmp_sal_ctb;

select cod as codtrab, nom as nomtrab, cta1 as cuenta, nom_c as nombre,
	round(val_ant, 2) as val_ant, round(descon, 2) as descon,
	round(sal_ant, 2) as sal_ant, round(val_db, 2) as val_db,
	round(val_cr, 2) as val_cr, round(sal_ctb, 2) as sal_ctb
	from tmp_sal, tmp_sal_ctb
	where cod      = codi
	  and cta      = cta1
	  and val_ant <> val_db
	into temp t1;

drop table tmp_sal;
drop table tmp_sal_ctb;

select * from t1
	order by 2, 4;

{--
select * from tmp_ant
	where cod in (select codtrab from t1)
	order by 2, 4;

select * from tmp_ctb
	where codi in (select codtrab from t1)
	order by 7, 1, 2, 3;
--}

drop table tmp_ant;
drop table tmp_ctb;
drop table t1;
