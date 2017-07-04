select g31_siglas sig, count(*) tot_reg
	from gent031
	group by 1
	having count(*) > 1
	into temp t1;

select * from t1 order by 1;

drop table t1;
