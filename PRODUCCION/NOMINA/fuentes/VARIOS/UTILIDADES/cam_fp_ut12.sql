select n30_compania cia, n30_cod_trab cod
	from rolt030
	where n30_compania = 1
	  and n30_estado   = 'I'
	into temp t1;

begin work;

	update rolt042
		set n42_tipo_pago  = 'C',
		    n42_cta_trabaj = null
		where n42_compania = 1
		  and n42_ano      = 2012
		  and n42_cod_trab in (select cod from t1);

	update rolt030
		set n30_tipo_pago  = 'C',
		    n30_cta_trabaj = null
		where n30_compania = 1
		  and n30_cod_trab in (select cod from t1);

--rollback work;
commit work;

drop table t1;
