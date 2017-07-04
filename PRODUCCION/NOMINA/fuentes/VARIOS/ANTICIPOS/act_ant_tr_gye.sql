begin work;

	update rolt046
		set n46_saldo = 0
		where n46_compania  in (1, 2)
		  and n46_num_prest in (select n45_num_prest
					from rolt045
					where n45_compania = n46_compania
					  and n45_estado   = 'T');

	update rolt045
		set n45_descontado = (n45_val_prest + n45_valor_int
					+ n45_sal_prest_ant)
		where n45_compania in (1, 2)
		  and n45_estado    = 'T';

commit work;
