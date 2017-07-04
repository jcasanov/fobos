rollback work;
drop table t1;
select b12_tipo_comp tp, b12_num_comp num
        from ctbt012
        where b12_subtipo in(52,53,54)
          and extend(b12_fec_proceso, year to month) = '2007-08'
	into temp t1;
select count(*) from t1;
begin work;
delete from rept040
	where exists (select * from t1
			where tp  = r40_tipo_comp
			  and num = r40_num_comp);
delete from ctbt012
	where exists (select * from t1
			where tp  = b12_tipo_comp
			  and num = b12_num_comp);
delete from ctbt013
	where exists (select * from t1
			where tp  = b13_tipo_comp
			  and num = b13_num_comp);
commit work;
drop table t1;
