set isolation to dirty read;

select r02_localidad loc, r11_bodega bd, r11_item item, r11_stock_act sto_act
	from acero_qs@idsuio02:rept011, acero_qs@idsuio02:rept002
	where r11_compania   = 1
	  and r11_stock_act <> 0
	  and r02_compania   = r11_compania
	  and r02_codigo     = r11_bodega
	  and r02_localidad <> 4
	into temp t1;

insert into t1
	select 1 loc, r11_bodega bd, r11_item item, r11_stock_act sto_act
		from acero_qs@idsuio02:rept011
		where r11_compania   = 1
		  and r11_bodega     = '99'
		  and r11_stock_act <> 0
		  and not exists
			(select 1 from acero_qs@idsuio02:rept020
				where r20_compania   = r11_compania
				  and r20_localidad  = 4
				  and r20_bodega     = r11_bodega
				  and r20_item       = r11_item);

insert into t1
	select 2 loc, bd, item, sto_act
		from t1
		where bd = '99';

insert into t1
	select 3 loc, bd, item, sto_act
		from t1
		where bd = '99';

select loc, bd, item, sto_act
	from t1
	where loc = 1
	  and not exists
		(select 1 from acero_gm@idsgye01:rept020
			where r20_compania  = 1
			  and r20_localidad = loc
			  and r20_item      = item)
union
select loc, bd, item, sto_act
	from t1
	where loc = 2
	  and not exists
		(select 1 from acero_gc@idsgye01:rept020
			where r20_compania  = 1
			  and r20_localidad = loc
			  and r20_item      = item)
union
select loc, bd, item, sto_act
	from t1
	where loc = 3
	  and not exists
		(select 1 from acero_qm@idsuio01:rept020
			where r20_compania  = 1
			  and r20_localidad = loc
			  and r20_item      = item)
	into temp t2;

drop table t1;

select unique bd, item, sto_act
	from t2
	into temp t3;

drop table t2;

select * from t3;

select count(*) tot_ite from t3;

{--
begin work;

	update acero_qs@idsuio02:rept011
		set r11_stock_act = 0,
		    r11_ing_dia    = 0,
		    r11_egr_dia    = 0,
		    r11_tip_ultvta = null,
		    r11_num_ultvta = null
		where r11_compania = 1
		  and exists
			(select 1 from t3
				where bd   = r11_bodega
				  and item = r11_item);

--rollback work;
commit work;
--}

drop table t3;
