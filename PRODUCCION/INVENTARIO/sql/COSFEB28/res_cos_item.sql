set isolation to dirty read;

select * from rept010
	where r10_compania = 999
	into temp tmp_gm;

select * from tmp_gm into temp tmp_qm;
select * from tmp_gm into temp tmp_qs;

select r10_codigo items
	from tmp_gm
	into temp tmp_res;

load from "r10_gm.unl" insert into tmp_gm;
load from "r10_qm.unl" insert into tmp_qm;
load from "r10_qs.unl" insert into tmp_qs;

load from "items_cos_res.unl" insert into tmp_res;

select r10_compania cia, 1 loc, r10_codigo item, r10_costo_mb costo
	from tmp_gm
	where r10_compania  = 1
	  and r10_codigo   in (select items from tmp_res)
union
select r10_compania cia, 3 loc, r10_codigo item, r10_costo_mb costo
	from tmp_qm
	where r10_compania  = 1
	  and r10_codigo   in (select items from tmp_res)
union
select r10_compania cia, 4 loc, r10_codigo item, r10_costo_mb costo
	from tmp_qs
	where r10_compania  = 1
	  and r10_codigo   in (select items from tmp_res)
	into temp tmp_ite;

drop table tmp_gm;
drop table tmp_qm;
drop table tmp_qs;
drop table tmp_res;


begin work;

	update aceros:rept010
		set r10_costo_mb    = (select costo
					from tmp_ite
					where cia  = r10_compania
					  and loc  = 1
					  and item = r10_codigo),
		    r10_usu_cosrepo = 'FOBOS',
		    r10_fec_cosrepo = current
		where r10_compania  = 1
		  and r10_codigo   in (select item
					from tmp_ite
					where cia  = r10_compania
					  and loc  = 1);

	update acero_qm:rept010
		set r10_costo_mb    = (select costo
					from tmp_ite
					where cia  = r10_compania
					  and loc  = 3
					  and item = r10_codigo),
		    r10_usu_cosrepo = 'FOBOS',
		    r10_fec_cosrepo = current
		where r10_compania  = 1
		  and r10_codigo   in (select item
					from tmp_ite
					where cia  = r10_compania
					  and loc  = 3);

	update acero_qs:rept010
		set r10_costo_mb    = (select costo
					from tmp_ite
					where cia  = r10_compania
					  and loc  = 4
					  and item = r10_codigo),
		    r10_usu_cosrepo = 'FOBOS',
		    r10_fec_cosrepo = current
		where r10_compania  = 1
		  and r10_codigo   in (select item
					from tmp_ite
					where cia  = r10_compania
					  and loc  = 4);

rollback work;

drop table tmp_ite;
