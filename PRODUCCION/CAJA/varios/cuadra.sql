create temp table tt (
	tipo_comp	char(2),
	num_comp	char(8),
	debito		decimal(14,2),
	credito		decimal(14,2)
);

insert into tt(tipo_comp, num_comp, debito)
	select b13_tipo_comp, b13_num_comp, sum(b13_valor_base)
	  from ctbt013 where b13_compania = 1 and b13_valor_base < 0
	 group by b13_tipo_comp, b13_num_comp;

update tt set credito = (select sum(b13_valor_base) from ctbt013
			  where b13_compania = 1 
			    and b13_tipo_comp = tipo_comp
			    and b13_num_comp  = num_comp
                            and b13_valor_base > 0)
	where 1=1;

update tt set debito  = debito * (-1) where 1=1;

select * from tt where debito <> credito;

drop table tt;

