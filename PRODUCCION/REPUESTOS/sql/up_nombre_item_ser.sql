set isolation to dirty read;

begin work;

select r10_codigo item, r10_nombre nom_desc
	from rept010
	where r10_compania = 1
	into temp t1;

update sermaco_gm@segye01:rept010
	set r10_nombre = (select nom_desc from t1 where item = r10_codigo)
	where r10_compania in (1, 2)
	  and r10_codigo   in (select item from t1);
