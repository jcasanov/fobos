begin work;

	update rept010
		set r10_cod_util = 'EE135'
		where r10_compania = 1
		  and r10_estado   = 'A'
		  and r10_marca    = 'BRIGGS'
		  and r10_cantveh  = 0
		  and r10_cod_util matches 'IP*';

	update rept010
		set r10_cantveh  = 1
		where r10_compania = 1
		  and r10_estado   = 'A'
		  and r10_marca    = 'BRIGGS'
		  and r10_cantveh  = 0;

commit work;
