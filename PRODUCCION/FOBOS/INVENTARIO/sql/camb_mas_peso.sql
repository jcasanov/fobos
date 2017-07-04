set isolation to dirty read;

select r10_compania cia, "GYE" loc, r10_codigo item, r10_peso peso
	from acero_gm@idsgye01:rept010
	where r10_compania = 1
	  and r10_peso     in (0.01, 0.10)
union
select r10_compania cia, "UIO" loc, r10_codigo item, r10_peso peso
	from acero_qm@idsuio01:rept010
	where r10_compania = 1
	  and r10_peso     in (0.01, 0.10)
	into temp t1;

select cia, loc, item, r10_peso peso
	from acero_gm@idsgye01:rept010, t1
	where cia          = 1
	  and loc          = "UIO"
	  and r10_compania = cia
	  and r10_codigo   = item
	  and r10_peso     > peso
	group by 1, 2, 3, 4
	into temp t2;

insert into t2
	select cia, loc, item, r10_peso peso
		from acero_qm@idsuio01:rept010, t1
		where cia          = 1
		  and loc          = "GYE"
		  and r10_compania = cia
		  and r10_codigo   = item
		  and r10_peso     > peso
		group by 1, 2, 3, 4;

drop table t1;

select count(*) tot_ite from t2;

select loc, count(*) tot_ite_loc
	from t2
	group by 1;

select cia, item, max(peso) peso
	from t2
	group by 1, 2
	into temp t3;

drop table t2;

begin work;

	update rept010
		set r10_peso = (select peso
					from t3
					where cia  = r10_compania
					  and item = r10_codigo)
		where r10_compania = 1
		  and r10_codigo   in (select item from t3);

commit work;

drop table t3;
