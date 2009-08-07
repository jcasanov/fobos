insert into cxct051 select 2002,3, * from cxct021
	where z21_saldo > 0;
insert into cxct050 select 2002,3, * from cxct020
	where z20_saldo_cap + z20_saldo_int > 0
