begin work;
update rolt039
	set n39_dias_goza = 0
	where n39_compania  = 1
	  and n39_proceso   = 'VA'
	  and n39_estado    = 'P'
	  and n39_dias_goza > 0
	  and exists (select * from rolt047
			where n47_compania     = n39_compania
			  and n47_proceso      = n39_proceso
			  and n47_cod_trab     = n39_cod_trab
			  and n47_periodo_ini  = n39_periodo_ini
			  and n47_periodo_fin  = n39_periodo_fin
			  and n47_usuario      = 'FOBOS'
			  and date(n47_fecing) = TODAY);
delete from rolt047
	where n47_compania     = 1
	  and n47_proceso      = 'VA'
	  and n47_usuario      = 'FOBOS'
	  and date(n47_fecing) = TODAY;
commit work;
