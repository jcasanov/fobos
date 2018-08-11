select r40_localidad loc, r40_cod_tran ct, r40_num_tran numt, r40_tipo_comp tp,
	r40_num_comp num
	from rept040
	where r40_compania = 99
	into temp t1;
load from "rept040_sur.unl" insert into t1;
select count(*) tot_reg from t1;
insert into t1
	select r40_localidad loc, r40_cod_tran ct, r40_num_tran numt,
		r40_tipo_comp tp, r40_num_comp num
	        from rept040
		where r40_compania  = 1
		  and exists (select * from t1 a
				where a.loc  = r40_localidad
				  and a.ct   = r40_cod_tran
				  and a.numt = r40_num_tran)
		  and not exists (select * from t1 b
				where b.tp   = r40_tipo_comp
				  and b.num  = r40_num_comp);
select count(*) tot_reg from t1;
begin work;
delete from rept040
	where r40_compania  = 1
	  and exists (select * from t1
			where loc  = r40_localidad
			  and ct   = r40_cod_tran
			  and numt = r40_num_tran);
delete from ctbt013
	where b13_compania  = 1
	  and exists (select * from t1
			where tp  = b13_tipo_comp
			  and num = b13_num_comp);
delete from ctbt012
	where b12_compania  = 1
	  and exists (select * from t1
			where tp  = b12_tipo_comp
			  and num = b12_num_comp);
commit work;
drop table t1;
