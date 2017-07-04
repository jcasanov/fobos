set isolation to dirty read;

select r10_compania cia, r10_codigo item
	from aceros:rept010
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
union
select r10_compania cia, r10_codigo item
	from acero_gc:rept010
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
union
select r10_compania cia, r10_codigo item
	from acero_qm:rept010
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
union
select r10_compania cia, r10_codigo item
	from acero_qs:rept010
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
union
select r10_compania cia, r10_codigo item
	from sermaco_gm:rept010
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
union
select r10_compania cia, r10_codigo item
	from sermaco_qm:rept010
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	into temp t1;

select cia, count(*) tot_item_pow from t1 group by 1 order by 1;

select unique r20_compania cia, r20_item item
	from aceros:rept010, aceros:rept020
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r20_compania  = r10_compania
	  and r20_item      = r10_codigo
union
select unique r24_compania cia, r24_item item
	from aceros:rept010, aceros:rept024
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r24_compania  = r10_compania
	  and r24_item      = r10_codigo
union
select unique r22_compania cia, r22_item item
	from aceros:rept010, aceros:rept022
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r22_compania  = r10_compania
	  and r22_item      = r10_codigo
union
select unique r82_compania cia, r82_item item
	from aceros:rept010, aceros:rept082
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r82_compania  = r10_compania
	  and r82_item      = r10_codigo
union
select unique r17_compania cia, r17_item item
	from aceros:rept010, aceros:rept017
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r17_compania  = r10_compania
	  and r17_item      = r10_codigo
union
select unique r20_compania cia, r20_item item
	from acero_gc:rept010, acero_gc:rept020
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r20_compania  = r10_compania
	  and r20_item      = r10_codigo
union
select unique r24_compania cia, r24_item item
	from acero_gc:rept010, acero_gc:rept024
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r24_compania  = r10_compania
	  and r24_item      = r10_codigo
union
select unique r22_compania cia, r22_item item
	from acero_gc:rept010, acero_gc:rept022
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r22_compania  = r10_compania
	  and r22_item      = r10_codigo
union
select unique r82_compania cia, r82_item item
	from acero_gc:rept010, acero_gc:rept082
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r82_compania  = r10_compania
	  and r82_item      = r10_codigo
union
select unique r17_compania cia, r17_item item
	from acero_gc:rept010, acero_gc:rept017
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r17_compania  = r10_compania
	  and r17_item      = r10_codigo
union
select unique r20_compania cia, r20_item item
	from acero_qm:rept010, acero_qm:rept020
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r20_compania  = r10_compania
	  and r20_item      = r10_codigo
union
select unique r24_compania cia, r24_item item
	from acero_qm:rept010, acero_qm:rept024
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r24_compania  = r10_compania
	  and r24_item      = r10_codigo
union
select unique r22_compania cia, r22_item item
	from acero_qm:rept010, acero_qm:rept022
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r22_compania  = r10_compania
	  and r22_item      = r10_codigo
union
select unique r82_compania cia, r82_item item
	from acero_qm:rept010, acero_qm:rept082
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r82_compania  = r10_compania
	  and r82_item      = r10_codigo
union
select unique r17_compania cia, r17_item item
	from acero_qm:rept010, acero_qm:rept017
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r17_compania  = r10_compania
	  and r17_item      = r10_codigo
union
select unique r20_compania cia, r20_item item
	from acero_qs:rept010, acero_qs:rept020
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r20_compania  = r10_compania
	  and r20_item      = r10_codigo
union
select unique r24_compania cia, r24_item item
	from acero_qs:rept010, acero_qs:rept024
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r24_compania  = r10_compania
	  and r24_item      = r10_codigo
union
select unique r22_compania cia, r22_item item
	from acero_qs:rept010, acero_qs:rept022
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r22_compania  = r10_compania
	  and r22_item      = r10_codigo
union
select unique r82_compania cia, r82_item item
	from acero_qs:rept010, acero_qs:rept082
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r82_compania  = r10_compania
	  and r82_item      = r10_codigo
union
select unique r17_compania cia, r17_item item
	from acero_qs:rept010, acero_qs:rept017
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r17_compania  = r10_compania
	  and r17_item      = r10_codigo
union
select unique r20_compania cia, r20_item item
	from sermaco_gm:rept010, sermaco_gm:rept020
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r20_compania  = r10_compania
	  and r20_item      = r10_codigo
union
select unique r24_compania cia, r24_item item
	from sermaco_gm:rept010, sermaco_gm:rept024
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r24_compania  = r10_compania
	  and r24_item      = r10_codigo
union
select unique r22_compania cia, r22_item item
	from sermaco_gm:rept010, sermaco_gm:rept022
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r22_compania  = r10_compania
	  and r22_item      = r10_codigo
union
select unique r82_compania cia, r82_item item
	from sermaco_gm:rept010, sermaco_gm:rept082
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r82_compania  = r10_compania
	  and r82_item      = r10_codigo
union
select unique r17_compania cia, r17_item item
	from sermaco_gm:rept010, sermaco_gm:rept017
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r17_compania  = r10_compania
	  and r17_item      = r10_codigo
union
select unique r20_compania cia, r20_item item
	from sermaco_qm:rept010, sermaco_qm:rept020
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r20_compania  = r10_compania
	  and r20_item      = r10_codigo
union
select unique r24_compania cia, r24_item item
	from sermaco_qm:rept010, sermaco_qm:rept024
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r24_compania  = r10_compania
	  and r24_item      = r10_codigo
union
select unique r22_compania cia, r22_item item
	from sermaco_qm:rept010, sermaco_qm:rept022
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r22_compania  = r10_compania
	  and r22_item      = r10_codigo
union
select unique r82_compania cia, r82_item item
	from sermaco_qm:rept010, sermaco_qm:rept082
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r82_compania  = r10_compania
	  and r82_item      = r10_codigo
union
select unique r17_compania cia, r17_item item
	from sermaco_qm:rept010, sermaco_qm:rept017
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r17_compania  = r10_compania
	  and r17_item      = r10_codigo
	into temp t2;

select cia, count(*) tot_ite_tran from t2 group by 1 order by 1;

select unique item from t2 into temp t4;

select count(*) tot_item_no_eli from t4;

select * from t1
	where not exists
		(select 1 from t2
			where t2.cia  = t1.cia
			  and t2.item = t1.item)
	into temp t3;

select unique item
	from t3
	where not exists
		(select 1 from t4
			where t4.item = t3.item)
	into temp t5;

drop table t1;
drop table t2;

select cia, count(*) tot_ite_sin_tra from t3 group by 1 order by 1;

begin work;

	unload to "eli_item_pow01.unl"
		select * from aceros:rept010
			where r10_compania in (1, 2)
			  and r10_marca     = 'POWERS'
			  and not exists
				(select 1 from t4
					where t4.item = r10_codigo);

	unload to "eli_item_pow01_11.unl"
		select * from aceros:rept011
			where r11_compania in (1, 2)
			  and exists
				(select 1 from t5
					where t5.item = r11_item);

	delete from aceros:rept011
		where r11_compania in (1, 2)
		  and exists
			(select 1 from t5
				where t5.item = r11_item);

	delete from aceros:rept010
		where r10_compania in (1, 2)
		  and r10_marca     = 'POWERS'
		  and not exists
			(select 1 from t4
				where t4.item = r10_codigo);

	unload to "eli_item_pow02.unl"
		select * from acero_gc:rept010
			where r10_compania in (1, 2)
			  and r10_marca     = 'POWERS'
			  and not exists
				(select 1 from t4
					where t4.item = r10_codigo);

	unload to "eli_item_pow02_11.unl"
		select * from acero_gc:rept011
			where r11_compania in (1, 2)
			  and exists
				(select 1 from t5
					where t5.item = r11_item);

	delete from acero_gc:rept011
		where r11_compania in (1, 2)
		  and exists
			(select 1 from t5
				where t5.item = r11_item);

	delete from acero_gc:rept010
		where r10_compania in (1, 2)
		  and r10_marca     = 'POWERS'
		  and not exists
			(select 1 from t4
				where t4.item = r10_codigo);

	unload to "eli_item_pow03.unl"
		select * from acero_qm:rept010
			where r10_compania in (1, 2)
			  and r10_marca     = 'POWERS'
			  and not exists
				(select 1 from t4
					where t4.item = r10_codigo);

	unload to "eli_item_pow03_11.unl"
		select * from acero_qm:rept011
			where r11_compania in (1, 2)
			  and exists
				(select 1 from t5
					where t5.item = r11_item);

	delete from acero_qm:rept011
		where r11_compania in (1, 2)
		  and exists
			(select 1 from t5
				where t5.item = r11_item);

	delete from acero_qm:rept010
		where r10_compania in (1, 2)
		  and r10_marca     = 'POWERS'
		  and not exists
			(select 1 from t4
				where t4.item = r10_codigo);

	unload to "eli_item_pow04.unl"
		select * from acero_qs:rept010
			where r10_compania in (1, 2)
			  and r10_marca     = 'POWERS'
			  and not exists
				(select 1 from t4
					where t4.item = r10_codigo);

	unload to "eli_item_pow04_11.unl"
		select * from acero_qs:rept011
			where r11_compania in (1, 2)
			  and exists
				(select 1 from t5
					where t5.item = r11_item);

	delete from acero_qs:rept011
		where r11_compania in (1, 2)
		  and exists
			(select 1 from t5
				where t5.item = r11_item);

	delete from acero_qs:rept010
		where r10_compania in (1, 2)
		  and r10_marca     = 'POWERS'
		  and not exists
			(select 1 from t4
				where t4.item = r10_codigo);

	unload to "eli_item_pow06.unl"
		select * from sermaco_gm:rept010
			where r10_compania in (1, 2)
			  and r10_marca     = 'POWERS'
			  and not exists
				(select 1 from t4
					where t4.item = r10_codigo);

	unload to "eli_item_pow06_11.unl"
		select * from sermaco_gm:rept011
			where r11_compania in (1, 2)
			  and exists
				(select 1 from t5
					where t5.item = r11_item);

	delete from sermaco_gm:rept011
		where r11_compania in (1, 2)
		  and exists
			(select 1 from t5
				where t5.item = r11_item);

	delete from sermaco_gm:rept010
		where r10_compania in (1, 2)
		  and r10_marca     = 'POWERS'
		  and not exists
			(select 1 from t4
				where t4.item = r10_codigo);

	unload to "eli_item_pow07.unl"
		select * from sermaco_qm:rept010
			where r10_compania in (1, 2)
			  and r10_marca     = 'POWERS'
			  and not exists
				(select 1 from t4
					where t4.item = r10_codigo);

	unload to "eli_item_pow07_11.unl"
		select * from sermaco_qm:rept011
			where r11_compania in (1, 2)
			  and exists
				(select 1 from t5
					where t5.item = r11_item);

	delete from sermaco_qm:rept011
		where r11_compania in (1, 2)
		  and exists
			(select 1 from t5
				where t5.item = r11_item);

	delete from sermaco_qm:rept010
		where r10_compania in (1, 2)
		  and r10_marca     = 'POWERS'
		  and not exists
			(select 1 from t4
				where t4.item = r10_codigo);

commit work;
--rollback work;

drop table t3;
drop table t4;
drop table t5;
