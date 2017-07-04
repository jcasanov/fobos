begin work;

select * from rept010
	where r10_compania = 2
	  and r10_codigo   in('120136', '120137', '120138')
	into temp t1;

select count(*) total_item from t1;

select r10_codigo item_old, r10_codigo item_new
	from rept010
	where r10_compania = 999
	into temp t2;

insert into t2 select r10_codigo, '' from t1;

update t1 set r10_codigo = '120169' where r10_codigo = '120136';
update t1 set r10_codigo = '120170' where r10_codigo = '120137';
update t1 set r10_codigo = '120171' where r10_codigo = '120138';

update t2 set item_new = '120169' where item_old = '120136';
update t2 set item_new = '120170' where item_old = '120137';
update t2 set item_new = '120171' where item_old = '120138';

insert into rept010 select * from t1;

update rept011 set r11_item = (select item_new from t2
				where item_old = r11_item)
	where r11_compania = 2
	  and r11_item     in (select item_old from t2);

update rept012 set r12_item = (select item_new from t2
				where item_old = r12_item)
	where r12_compania = 2
	  and r12_item     in (select item_old from t2);

update rept020 set r20_item = (select item_new from t2
				where item_old = r20_item)
	where r20_compania = 2
	  and r20_item     in (select item_old from t2);

update rept022 set r22_item = (select item_new from t2
				where item_old = r22_item)
	where r22_compania = 2
	  and r22_item     in (select item_old from t2);

update rept024 set r24_item = (select item_new from t2
				where item_old = r24_item)
	where r24_compania = 2
	  and r24_item     in (select item_old from t2);

update rept035 set r35_item = (select item_new from t2
				where item_old = r35_item)
	where r35_compania = 2
	  and r35_item     in (select item_old from t2);

update rept037 set r37_item = (select item_new from t2
				where item_old = r37_item)
	where r37_compania = 2
	  and r37_item     in (select item_old from t2);

update ordt011 set c11_codigo = (select item_new from t2
				  where item_old = c11_codigo)
	where c11_compania = 2
	  and c11_codigo     in (select item_old from t2);

update ordt014 set c14_codigo = (select item_new from t2
				  where item_old = c14_codigo)
	where c14_compania = 2
	  and c14_codigo     in (select item_old from t2);

delete from rept010
	where r10_compania = 2
	  and r10_codigo   in (select item_old from t2);

commit work;
