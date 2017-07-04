--rollback work;

begin work;

delete from rolt047 where 1 = 1;

insert into rolt047 select * from aceros@acgyede:rolt047;

update rolt039
	set n39_dias_goza = nvl((select sum(n47_dias_goza)
				from rolt047
				where n47_compania    = n39_compania
				  and n47_proceso     = n39_proceso
				  and n47_cod_trab    = n39_cod_trab
				  and n47_periodo_ini = n39_periodo_ini
				  and n47_periodo_fin = n39_periodo_fin), 0)
	where n39_compania in (1, 2)
	  and n39_proceso   = 'VA'
	  and exists (select * from rolt047
			where n47_compania    = n39_compania
			  and n47_proceso     = n39_proceso
			  and n47_cod_trab    = n39_cod_trab
			  and n47_periodo_ini = n39_periodo_ini
			  and n47_periodo_fin = n39_periodo_fin);

commit work;
