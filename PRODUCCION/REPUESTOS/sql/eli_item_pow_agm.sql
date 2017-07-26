set isolation to dirty read;

select r10_compania cia, r10_codigo item
	from acero_gm@idsgye01:rept010
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
union
select r10_compania cia, r10_codigo item
	from acero_gc@idsgye01:rept010
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
union
select r10_compania cia, r10_codigo item
	from acero_qm@idsuio01:rept010
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
union
select r10_compania cia, r10_codigo item
	from acero_qs@idsuio02:rept010
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
union
select r10_compania cia, r10_codigo item
	from sermaco_gm@segye01:rept010
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
union
select r10_compania cia, r10_codigo item
	from sermaco_qm@seuio01:rept010
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	into temp t1;

select cia, count(*) tot_item_pow from t1 group by 1 order by 1;

select unique r20_compania cia, r20_item item
	from acero_gm@idsgye01:rept010, acero_gm@idsgye01:rept020
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r20_compania  = r10_compania
	  and r20_item      = r10_codigo
union
select unique r24_compania cia, r24_item item
	from acero_gm@idsgye01:rept010, acero_gm@idsgye01:rept024
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r24_compania  = r10_compania
	  and r24_item      = r10_codigo
union
select unique r22_compania cia, r22_item item
	from acero_gm@idsgye01:rept010, acero_gm@idsgye01:rept022
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r22_compania  = r10_compania
	  and r22_item      = r10_codigo
union
select unique r82_compania cia, r82_item item
	from acero_gm@idsgye01:rept010, acero_gm@idsgye01:rept082
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r82_compania  = r10_compania
	  and r82_item      = r10_codigo
union
select unique r17_compania cia, r17_item item
	from acero_gm@idsgye01:rept010, acero_gm@idsgye01:rept017
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r17_compania  = r10_compania
	  and r17_item      = r10_codigo
union
select unique r20_compania cia, r20_item item
	from acero_gc@idsgye01:rept010, acero_gc@idsgye01:rept020
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r20_compania  = r10_compania
	  and r20_item      = r10_codigo
union
select unique r24_compania cia, r24_item item
	from acero_gc@idsgye01:rept010, acero_gc@idsgye01:rept024
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r24_compania  = r10_compania
	  and r24_item      = r10_codigo
union
select unique r22_compania cia, r22_item item
	from acero_gc@idsgye01:rept010, acero_gc@idsgye01:rept022
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r22_compania  = r10_compania
	  and r22_item      = r10_codigo
union
select unique r82_compania cia, r82_item item
	from acero_gc@idsgye01:rept010, acero_gc@idsgye01:rept082
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r82_compania  = r10_compania
	  and r82_item      = r10_codigo
union
select unique r17_compania cia, r17_item item
	from acero_gc@idsgye01:rept010, acero_gc@idsgye01:rept017
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r17_compania  = r10_compania
	  and r17_item      = r10_codigo
union
select unique r20_compania cia, r20_item item
	from acero_qm@idsuio01:rept010, acero_qm@idsuio01:rept020
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r20_compania  = r10_compania
	  and r20_item      = r10_codigo
union
select unique r24_compania cia, r24_item item
	from acero_qm@idsuio01:rept010, acero_qm@idsuio01:rept024
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r24_compania  = r10_compania
	  and r24_item      = r10_codigo
union
select unique r22_compania cia, r22_item item
	from acero_qm@idsuio01:rept010, acero_qm@idsuio01:rept022
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r22_compania  = r10_compania
	  and r22_item      = r10_codigo
union
select unique r82_compania cia, r82_item item
	from acero_qm@idsuio01:rept010, acero_qm@idsuio01:rept082
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r82_compania  = r10_compania
	  and r82_item      = r10_codigo
union
select unique r17_compania cia, r17_item item
	from acero_qm@idsuio01:rept010, acero_qm@idsuio01:rept017
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r17_compania  = r10_compania
	  and r17_item      = r10_codigo
union
select unique r20_compania cia, r20_item item
	from acero_qs@idsuio02:rept010, acero_qs@idsuio02:rept020
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r20_compania  = r10_compania
	  and r20_item      = r10_codigo
union
select unique r24_compania cia, r24_item item
	from acero_qs@idsuio02:rept010, acero_qs@idsuio02:rept024
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r24_compania  = r10_compania
	  and r24_item      = r10_codigo
union
select unique r22_compania cia, r22_item item
	from acero_qs@idsuio02:rept010, acero_qs@idsuio02:rept022
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r22_compania  = r10_compania
	  and r22_item      = r10_codigo
union
select unique r82_compania cia, r82_item item
	from acero_qs@idsuio02:rept010, acero_qs@idsuio02:rept082
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r82_compania  = r10_compania
	  and r82_item      = r10_codigo
union
select unique r17_compania cia, r17_item item
	from acero_qs@idsuio02:rept010, acero_qs@idsuio02:rept017
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r17_compania  = r10_compania
	  and r17_item      = r10_codigo
union
select unique r20_compania cia, r20_item item
	from sermaco_gm@segye01:rept010, sermaco_gm@segye01:rept020
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r20_compania  = r10_compania
	  and r20_item      = r10_codigo
union
select unique r24_compania cia, r24_item item
	from sermaco_gm@segye01:rept010, sermaco_gm@segye01:rept024
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r24_compania  = r10_compania
	  and r24_item      = r10_codigo
union
select unique r22_compania cia, r22_item item
	from sermaco_gm@segye01:rept010, sermaco_gm@segye01:rept022
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r22_compania  = r10_compania
	  and r22_item      = r10_codigo
union
select unique r82_compania cia, r82_item item
	from sermaco_gm@segye01:rept010, sermaco_gm@segye01:rept082
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r82_compania  = r10_compania
	  and r82_item      = r10_codigo
union
select unique r17_compania cia, r17_item item
	from sermaco_gm@segye01:rept010, sermaco_gm@segye01:rept017
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r17_compania  = r10_compania
	  and r17_item      = r10_codigo
union
select unique r20_compania cia, r20_item item
	from sermaco_qm@seuio01:rept010, sermaco_qm@seuio01:rept020
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r20_compania  = r10_compania
	  and r20_item      = r10_codigo
union
select unique r24_compania cia, r24_item item
	from sermaco_qm@seuio01:rept010, sermaco_qm@seuio01:rept024
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r24_compania  = r10_compania
	  and r24_item      = r10_codigo
union
select unique r22_compania cia, r22_item item
	from sermaco_qm@seuio01:rept010, sermaco_qm@seuio01:rept022
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r22_compania  = r10_compania
	  and r22_item      = r10_codigo
union
select unique r82_compania cia, r82_item item
	from sermaco_qm@seuio01:rept010, sermaco_qm@seuio01:rept082
	where r10_compania in (1, 2)
	  and r10_marca     = 'POWERS'
	  and r82_compania  = r10_compania
	  and r82_item      = r10_codigo
union
select unique r17_compania cia, r17_item item
	from sermaco_qm@seuio01:rept010, sermaco_qm@seuio01:rept017
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
		select * from acero_gm@idsgye01:rept010
			where r10_compania in (1, 2)
			  and r10_marca     = 'POWERS'
			  and not exists
				(select 1 from t4
					where t4.item = r10_codigo);

	unload to "eli_item_pow01_11.unl"
		select * from acero_gm@idsgye01:rept011
			where r11_compania in (1, 2)
			  and exists
				(select 1 from t5
					where t5.item = r11_item);

	delete from acero_gm@idsgye01:rept011
		where r11_compania in (1, 2)
		  and exists
			(select 1 from t5
				where t5.item = r11_item);

	delete from acero_gm@idsgye01:rept010
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
