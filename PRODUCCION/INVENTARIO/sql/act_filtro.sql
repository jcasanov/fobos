set isolation to dirty read;

select r10_compania cia, r10_codigo item, r10_filtro filtro
	from acero_qm@idsuio01:rept010
	where r10_compania = 1
	into temp t1;

begin work;

	update rept010
		set r10_filtro = (select filtro
					from t1
					where cia  = r10_compania
					  and item = r10_codigo)
		where r10_compania  = 1
		  and r10_codigo   in (select item
					from t1
					where cia  = r10_compania
					  and item = r10_codigo);

--rollback work;
commit work;

drop table t1;
