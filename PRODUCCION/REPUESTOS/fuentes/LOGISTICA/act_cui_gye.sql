select g31_nombre nomciu, g31_divi_poli prov
	from gent031
	where g31_pais = 999
	into temp tmp_cui_uio;

load from "gent031_uio.unl" insert into tmp_cui_uio;

select g31_ciudad ciu, g31_nombre nomciug, g31_divi_poli provg
	from gent031
	where g31_pais = 1
	into temp tmp_cui_gye;

select ciu, nomciu, prov
	from tmp_cui_gye, tmp_cui_uio
	where nomciu  = nomciug
	  and prov   <> provg
	into temp t1;

drop table tmp_cui_uio;

drop table tmp_cui_gye;

select ciu, count(*) tot_reg
	from t1
	group by 1
	having count(*) > 1;

begin work;

	update gent031
		set g31_divi_poli = (select prov
					from t1
					where ciu = g31_ciudad)
		where g31_ciudad in (select ciu from t1);

--rollback work;
commit work;

drop table t1;
