select z50_codcli, sum(z50_saldo_cap + z50_saldo_int) total
	from cxct050
	where z50_ano = 2003
	  and z50_mes = 12
	  and z50_compania = 1
	  and z50_localidad in (3,4)
	group by 1
	into temp t1;
select sum(total) from t1;
drop table t1;
