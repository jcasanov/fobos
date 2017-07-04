select r10_compania cia, r10_codigo item, r10_peso peso
	from acero_qm@idsuio01:rept010
	where r10_compania = 1
	  and r10_estado   = 'A'
	  and r10_peso     = 0.01
	into temp t1;

begin work;

	update rept010
		set r10_peso        = (select peso
					from t1
					where cia  = r10_compania
					  and item = r10_codigo),
		    r10_usu_cosrepo = 'E1EWDGUZ',
		    r10_fec_cosrepo = current
		where r10_compania  = 1
		  and r10_codigo   in (select item from t1)
		  and r10_estado    = 'A'
		  and r10_peso      = 0;

--rollback work;
commit work;

drop table t1;
