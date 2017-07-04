select r19_num_tran from rept019
	where r19_cod_tran = 'FA'
	  and r19_num_tran < 1320
	into temp t1;
select r19_num_tran, t23_orden
	from t1, outer talt023
	where r19_num_tran = t23_orden
	into temp t2;
drop table t1;
select * from t2 where t23_orden is null order by 1 desc;
drop table t2;
