set isolation to dirty read;
select r10_codigo item,
	  nvl((select sum(r11_stock_act)
		from rept011
		where r11_compania  = r10_compania
		  and r11_item      = r10_codigo), 0) stock
	from rept010
	where r10_compania = 1
	  and r10_marca    in ("KOHSAN", "KOHGRI")
	into temp t1;
begin work;
	update rept010
		set r10_estado = 'B',
		    r10_feceli = current
	where r10_compania  = 1
	  and r10_codigo   in (select item from t1 where stock = 0)
	  and r10_estado    = 'A';
	update rept010
		set r10_marca = "KOHLER"
	where r10_compania  = 1
	  and r10_codigo   in (select item from t1);
commit work;
drop table t1;
