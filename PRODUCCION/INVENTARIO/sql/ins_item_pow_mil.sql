set isolation to dirty read;

select * from acero_gm@idsgye01:rept010
	where r10_compania in (1, 2)
	  and r10_marca    in ('POWERS')
union
select * from acero_gc@idsgye01:rept010
	where r10_compania in (1, 2)
	  and r10_marca    in ('POWERS')
union
select * from acero_qm@idsuio01:rept010
	where r10_compania in (1, 2)
	  and r10_marca    in ('POWERS')
union
select * from acero_qs@idsuio02:rept010
	where r10_compania in (1, 2)
	  and r10_marca    in ('POWERS')
union
select * from sermaco_gm@segye01:rept010
	where r10_compania in (1, 2)
	  and r10_marca    in ('POWERS')
union
select * from sermaco_qm@seuio01:rept010
	where r10_compania in (1, 2)
	  and r10_marca    in ('POWERS')
	into temp t1;

select r10_compania cia, r10_marca marca, count(*) tot_item
	from t1
	group by 1, 2
	order by 1, 2;

select * from t1
	where r10_compania = 2
	into temp t2;

update t2
	set r10_compania = 1
	where 1 = 1;

select unique * from t1
union
select unique * from t2
into temp t3;

drop table t2;

select * from t1
	where r10_compania = 1
	into temp t2;

update t2
	set r10_compania = 2
	where 1 = 1;

select unique * from t3
union
select unique * from t2
into temp t4;

drop table t1;
drop table t2;
drop table t3;

select unique * from t4
	into temp t1;

drop table t4;

select r10_compania cia, r10_marca marca, count(*) tot_item_fin
	from t1
	group by 1, 2
	order by 1, 2;

begin work;

	select a.* from t1 a
		where not exists
			(select 1 from acero_gm@idsgye01:rept010 b
				where b.r10_compania = a.r10_compania
				  and b.r10_codigo   = a.r10_codigo)
		into temp t2;
	insert into acero_gm@idsgye01:rept010
		select * from t2;
	drop table t2;

rollback work;

drop table t1;
