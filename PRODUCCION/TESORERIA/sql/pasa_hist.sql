insert into cxpt051 select 2002,2, * from cxpt021
	where p21_saldo > 0;
insert into cxpt050 select 2002,2, * from cxpt020
	where p20_saldo_cap + p20_saldo_int > 0
