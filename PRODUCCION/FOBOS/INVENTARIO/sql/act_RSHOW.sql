begin work;

	update rept010
		set r10_cod_util = 'RSHOW'
		where r10_compania = 1
		  and r10_estado   = 'A'
		  and r10_marca    = 'RIDGID';

--rollback work;
commit work;
