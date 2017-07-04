select z21_localidad, sum(z21_saldo) saldo
	from cxct021
	group by 1
	into temp t1;
select * from t1;
select round(sum(saldo), 2) from t1;
drop table t1;
