select * from rept010 where r10_compania = 999 into temp t1;

load from "rept010_gm_31dic2008.unl" insert into t1;

{--
select r20_compania cia, r20_localidad loc, r20_cod_tran cod_tran,
	r20_num_tran num_tran
	from rept020
	where r20_compania      = 1
	  and year(r20_fecing)  = 2009
	  and date(r20_fecing) <= mdy(10,31,2009)
	  and r20_item         in (select unique item from ite_cos_rea)
	into temp tt;

select unique r20_item item
	from rept020
	where r20_compania      = 1
	  and year(r20_fecing)  = 2009
	  and date(r20_fecing) <= mdy(10,31,2009)
	  and exists (select 1 from tt
			where cia      = r20_compania
			  and loc      = r20_localidad
			  and cod_tran = r20_cod_tran
			  and num_tran = r20_num_tran)
	into temp tmp_r20;

drop table tt;
--}

select r10_compania cia, r10_codigo item, r10_costo_mb costo_mb,
	r10_costult_mb costult_mb, r10_costrepo_mb costrepo_mb
	from t1
	where r10_codigo in (select unique item
				from ite_cos_rea
				where localidad <> 1)
	into temp tmp_r10;

drop table t1;
--drop table tmp_r20;

begin work;

	update rept010
		set r10_costo_mb    = (select costo_mb
					from tmp_r10
					where cia  = r10_compania
					  and item = r10_codigo),
		    r10_costult_mb  = (select costult_mb
					from tmp_r10
					where cia  = r10_compania
					  and item = r10_codigo),
		    r10_costrepo_mb = (select costrepo_mb
					from tmp_r10
					where cia  = r10_compania
					  and item = r10_codigo)
		where r10_compania = 1
		  and r10_codigo   = (select item
					from tmp_r10
					where cia  = r10_compania
					  and item = r10_codigo);

	update rept010
		set r10_costo_mb   = (select costo_teo
					from ite_cos_rea
					where compania  = r10_compania
					  and item      = r10_codigo
					  and localidad = 1),
		    r10_costult_mb = (select costo_teo
					from ite_cos_rea
					where compania  = r10_compania
					  and item      = r10_codigo
					  and localidad = 1)
		where r10_compania = 1
		  and r10_codigo   in (select item
					from ite_cos_rea
					where compania  = r10_compania
					  and localidad = 1);

commit work;

drop table tmp_r10;
