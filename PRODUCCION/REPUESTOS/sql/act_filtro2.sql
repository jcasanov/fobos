set isolation to dirty read;

select r10_compania cia, r10_codigo item,
	case when r10_marca = 'MILWAU' then 'MILWAU'
	     when r10_marca = 'POWERS' then 'POWERS'
	     when r10_marca = 'INTERS' then 'INTERS'
	end filtro
	from acero_qm@idsuio01:rept010
	where r10_compania  = 1
	  and r10_estado    = 'A'
	  and r10_marca    in ('MILWAU', 'POWERS', 'INTERS')
	into temp t1;

begin work;

	update acero_qm@idsuio01:rept010
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

select r10_compania cia, r10_codigo item,
	case when r10_marca = 'MILWAU' then 'MILWAU'
	     when r10_marca = 'POWERS' then 'POWERS'
	     when r10_marca = 'INTERS' then 'INTERS'
	end filtro
	from acero_gm@idsgye01:rept010
	where r10_compania  = 1
	  and r10_estado    = 'A'
	  and r10_marca    in ('MILWAU', 'POWERS', 'INTERS')
	into temp t1;

begin work;

	update acero_gm@idsgye01:rept010
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
