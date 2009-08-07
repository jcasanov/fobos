{
drop table tf;
select r19_cod_tran, sum(r19_tot_costo) costo from rept019
	where r19_cod_tran <> 'TR'
	group by 1
	into temp tf;
update tf set costo = costo * -1 where r19_cod_tran in ('FA','A-','RQ');

select r11_item, r11_bodega, r11_stock_act from rept011
	where r11_stock_act > 0  into temp stock;
}
select sum(costo) from tf;
select sum(r10_costo_mb * r11_stock_act) from rept010, stock
	where r10_compania = 1 and r10_codigo = r11_item
