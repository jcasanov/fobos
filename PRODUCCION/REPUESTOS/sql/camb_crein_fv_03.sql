set isolation to dirty read;

select r10_compania cia, r10_codigo item, r10_marca marca, r10_filtro filtro
	from rept010
	where r10_compania = 1
	  and r10_marca    = 'CREIN'
	into temp t1;

begin work;

	update rept010
		set r10_marca  = 'FV',
		    r10_filtro = 'FV'
		where r10_compania = 1
		  and r10_codigo   in (select item from t1);

commit work;

unload to "crein_uio.unl" select * from t1;

drop table t1;
