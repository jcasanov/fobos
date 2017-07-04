select r40_localidad loc, r40_cod_tran ct, r40_num_tran numt, r40_tipo_comp tp,
	r40_num_comp num, r40_num_tran sub_t
	from rept040
	where r40_compania = 99
	into temp t1;
select ctbt013.* from ctbt013 where b13_compania = 99 into temp t2;
load from "rept040_sur_f.unl" insert into t1;
load from "ctbt013_fin.unl" insert into t2;
select count(*) tot_reg from t1;
begin work;
delete from ctbt013
	where b13_compania  = 1
	  and exists (select * from t1
			where tp  = b13_tipo_comp
			  and num = b13_num_comp);
insert into ctbt013 select * from t2;
commit work;
drop table t1;
