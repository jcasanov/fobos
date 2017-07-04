set isolation to dirty read;

select 1 loc, * from acero_gm@idsgye01:rept010
	where r10_compania  = 1
	  and r10_marca    in ('POWERS')
union
select 2 loc, * from acero_gc@idsgye01:rept010
	where r10_compania  = 1
	  and r10_marca    in ('POWERS')
union
select 3 loc, * from acero_qm@idsuio01:rept010
	where r10_compania  = 1
	  and r10_marca    in ('POWERS')
union
select 4 loc, * from acero_qs@idsuio02:rept010
	where r10_compania  = 1
	  and r10_marca    in ('POWERS')
union
select 6 loc, * from sermaco_gm@segye01:rept010
	where r10_compania  = 2
	  and r10_marca    in ('POWERS')
union
select 7 loc, * from sermaco_qm@seuio01:rept010
	where r10_compania  = 2
	  and r10_marca    in ('POWERS')
	into temp t1;

select r10_compania cia, loc, r10_marca marca, count(*) tot_item
	from t1
	group by 1, 2, 3
	order by 1, 2, 3;

select unique r10_codigo item from t1 where loc = 7 into temp ite_uni;

delete from t1
	where loc        = 6
	  and r10_codigo in (select item from ite_uni);

drop table ite_uni;

select unique r10_codigo item from t1 where r10_compania = 2 into temp ite_uni;

delete from t1
	where loc        = 1
	  and r10_codigo in (select item from ite_uni);

delete from t1
	where loc        = 2
	  and r10_codigo in (select item from ite_uni);

delete from t1
	where loc        = 3
	  and r10_codigo in (select item from ite_uni);

delete from t1
	where loc        = 4
	  and r10_codigo in (select item from ite_uni);

drop table ite_uni;

select r10_compania cia, loc, r10_marca marca, count(*) tot_item
	from t1
	group by 1, 2, 3
	order by 1, 2, 3;
--------------------------------------------------
--SELECT * FROM t1 WHERE r10_codigo IN ("150623","69271","69279");
SELECT count(*) ttt FROM acero_gm@idsgye01:rept010 a, sermaco_gm:rept010 b
WHERE 
	a.r10_compania = 1 AND b.r10_compania = 2
	AND a.r10_codigo = b.r10_codigo
	AND a.r10_marca = "POWERS"
	AND b.r10_marca = a.r10_marca
;

SELECT * FROM t1 a
WHERE a.r10_codigo NOT IN (SELECT b.r10_codigo FROM acero_gm@idsgye01:rept010 b 
		WHERE b.r10_compania = 1 AND b.r10_marca = "POWERS"
		AND   b.r10_codigo 	= a.r10_codigo)
INTO TEMP fs1;

SELECT a.r10_compania, 1, a.r10_codigo, a.r10_marca FROM acero_gm@idsgye01:rept010 a, t1 WHERE	a.r10_compania = 1 AND a.r10_codigo = t1.r10_codigo AND a.r10_marca <> "POWERS"
UNION
SELECT a.r10_compania, 2, a.r10_codigo, a.r10_marca FROM acero_gc@idsgye01:rept010 a, t1 WHERE	a.r10_compania = 1 AND a.r10_codigo = t1.r10_codigo AND a.r10_marca <> "POWERS"
UNION
SELECT a.r10_compania, 3, a.r10_codigo, a.r10_marca FROM acero_qm@idsuio01:rept010 a, t1 WHERE	a.r10_compania = 1 AND a.r10_codigo = t1.r10_codigo AND a.r10_marca <> "POWERS"
UNION
SELECT a.r10_compania, 4, a.r10_codigo, a.r10_marca FROM acero_qs@idsuio02:rept010 a, t1 WHERE	a.r10_compania = 1 AND a.r10_codigo = t1.r10_codigo AND a.r10_marca <> "POWERS"
UNION
SELECT a.r10_compania, 6, a.r10_codigo, a.r10_marca FROM sermaco_gm@segye01:rept010 a, t1 WHERE	a.r10_compania = 2 AND a.r10_codigo = t1.r10_codigo AND a.r10_marca <> "POWERS"
UNION
SELECT a.r10_compania, 7, a.r10_codigo, a.r10_marca FROM sermaco_qm@seuio01:rept010 a, t1 WHERE	a.r10_compania = 2 AND a.r10_codigo = t1.r10_codigo AND a.r10_marca <> "POWERS";

SELECT count(*) FROM fs1;
DROP TABLE fs1;

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

select r10_compania cia, count(unique r10_codigo) ite_uni_beg
	from t1
	group by 1
	order by 1;
select a.r10_codigo, b.r10_codigo item
	from t1 a, acero_gm@idsgye01:rept010 b
	where a.r10_compania = 1
	  and b.r10_compania = a.r10_compania
	  and b.r10_codigo   = a.r10_codigo
	into temp caca;
select count(*) cca from caca;
select count(*) cca from caca where item is null;
select count(*) cca from caca where item is not null;
--select * from caca order by 2 desc;
drop table caca;

{
begin work;

	select a.* from t1 a
		where a.r10_compania = 1
		  and a.r10_codigo not in
			(select b.r10_codigo
				from aceros@acgyede:rept010 b
				where b.r10_compania = a.r10_compania
				  and b.r10_codigo   = a.r10_codigo)
		into temp t2;

	select t2.r10_compania cia, t2.r10_codigo item, b.r77_codigo_util cu1,
		t2.r10_cod_util cu2
		from t2, outer aceros@acgyede:rept077 b
		where t2.r10_compania   = 1
		  and b.r77_compania    = t2.r10_compania
		  and b.r77_codigo_util = t2.r10_cod_util
		into temp t3;
	delete from t3 where cu1 is null;
	update t2
		set r10_cod_util = 'RE000'
		where exists
			(select 1
				from t3
				where cia  = t2.r10_compania
				  and item = t2.r10_codigo);
	drop table t3;
	insert into aceros@acgyede:rept010
		select * from t2;
	drop table t2;

rollback work;
}

drop table t1;
