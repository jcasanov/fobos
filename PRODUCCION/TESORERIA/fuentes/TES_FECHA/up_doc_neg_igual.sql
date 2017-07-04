begin work;

update cxpt023
	set p23_saldo_cap = p23_saldo_cap * (-1)
	where p23_compania  in (1, 2)
	  and p23_valor_cap = p23_saldo_cap
	  and p23_saldo_cap < 0;

commit work;
