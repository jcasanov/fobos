begin work;

--------------------------------------------------------------------------------
-- Este UPDATE solo se lo ejecuta si es que se paga bono navideño a traves del
-- sistema FOBOS

{
	update rolt056
		set n56_aux_val_vac = '51014201001'
		where n56_compania = 1
		  and n56_proceso  = 'UV'
		  and n56_estado   = 'A';
}
--

--------------------------------------------------------------------------------
-- Este UPDATE es para restaurar la cuenta original de roles de usos varios

	update rolt056
		set n56_aux_val_vac = (select n52_aux_cont
					from rolt030, rolt052
					where n30_compania  = n56_compania
					  and n30_cod_trab  = n56_cod_trab
					  and n52_compania  = n30_compania
					  and n52_cod_rubro = 75
					  and n52_cod_trab  = n30_cod_trab)
		where n56_compania = 1
		  and n56_proceso  = 'UV'
		  and n56_estado   = 'A';
--

--------------------------------------------------------------------------------

commit work;
