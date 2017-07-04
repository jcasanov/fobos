begin work;

	update rolt042
		set n42_tipo_pago   = 'C',
		{--
		    n42_bco_empresa = 3,
		    n42_cta_empresa = '000900-3031',
		--}
		    n42_cta_trabaj  = null
		where n42_compania  = 1
		  and n42_proceso   = 'UT'
		  and n42_ano       = 2009
		  and n42_cod_trab in
			(select n30_cod_trab
				from rolt030
				where n30_compania  = n42_compania
				  and n30_cod_trab  = n42_cod_trab
				  and n30_cod_depto = n42_cod_depto
				  and n30_estado    = 'I');

	{--
	update rolt056
		set n56_aux_banco = '11020101003'
		where n56_compania  = 1
		  and n56_proceso   = 'UT'
		  and n56_estado    = 'A'
		  and n56_cod_trab in
			(select n30_cod_trab
				from rolt030
				where n30_compania  = n56_compania
				  and n30_cod_trab  = n56_cod_trab
				  and n30_cod_depto = n56_cod_depto
				  and n30_estado    = 'I');
	--}

commit work;
