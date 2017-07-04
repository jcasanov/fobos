set isolation to dirty read;
select r10_codigo item
	from rept010
	where r10_compania = 1
	  and r10_estado   = "A"
	  and r10_marca    = "KERAMI"
	  and (select sum(r11_stock_act)
		from rept011
		where r11_compania  = r10_compania
		  and r11_item      = r10_codigo) = 0
	into temp t1;
begin work;
	update rept010
		set r10_estado = 'B',
		    r10_feceli = current
	where r10_compania  = 1
	  and r10_codigo   in (select item from t1)
	  and r10_estado    = 'A';
commit work;
drop table t1;
