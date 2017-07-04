set isolation to dirty read;

select r10_compania cia, r10_codigo item, r10_marca marca, r10_filtro filtro
	from rept010
	where r10_compania = 1
	  and r10_marca    in ('FVGRIF', 'FVSANI')
	into temp t1;

unload to "item_fvgs_02.unl" select * from t1;

begin work;

	update rept010
		set r10_marca = 'FV'
		where r10_compania = 1
		  and r10_codigo   in (select item from t1);

commit work;

drop table t1;
