{
select r20_cod_tran, r20_item, sum(r20_cant_ven) cant from rept020
	where r20_cod_tran not in ('AC','TR')
	group by 1,2
	order by 1,2
	into temp te

update te set cant = cant * -1
	where r20_cod_tran in ('FA','A-')

select r20_item, sum(cant) cant from te
	group by 1
	into temp ta

select r20_item, cant, sum(r11_stock_act) stock from ta, rept011
 	where r11_compania = 1 and r11_item = r20_item
	group by 1, 2
	into temp to
}
select * from to where cant <> stock
