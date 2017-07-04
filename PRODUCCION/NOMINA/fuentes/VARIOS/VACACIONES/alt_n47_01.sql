begin work;

--------------------------------------------------------------------------------
alter table "fobos".rolt047
	add (n47_valor_pag decimal (12,2) before n47_usuario);

alter table "fobos".rolt047
	add (n47_valor_des decimal (12,2) before n47_usuario);
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
update rolt047
	set n47_valor_pag = nvl((select (((n39_valor_vaca + n39_valor_adic +
					n39_otros_ing) /
					(n39_dias_vac + n39_dias_adi)) *
					n47_dias_goza)
				from rolt039
				where n39_compania    = n47_compania
				  and n39_proceso     = 'VA'
				  and n39_cod_trab    = n47_cod_trab
				  and n39_periodo_ini = n47_periodo_ini
				  and n39_periodo_fin = n47_periodo_fin), 0),
	    n47_valor_des = nvl((select (((n39_valor_vaca + n39_valor_adic +
					n39_otros_ing) /
					(n39_dias_vac + n39_dias_adi)) *
					n47_dias_goza) -
					((((n39_valor_vaca + n39_valor_adic +
					n39_otros_ing) /
					(n39_dias_vac + n39_dias_adi)) *
					n47_dias_goza) * n13_porc_trab / 100)
				from rolt039, rolt030, rolt013
				where n39_compania    = n47_compania
				  and n39_proceso     = 'VA'
				  and n39_cod_trab    = n47_cod_trab
				  and n39_periodo_ini = n47_periodo_ini
				  and n39_periodo_fin = n47_periodo_fin
				  and n30_compania    = n39_compania
				  and n30_cod_trab    = n39_cod_trab
				  and n13_cod_seguro  = n30_cod_seguro), 0)
	where 1 = 1;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
alter table "fobos".rolt047
	modify (n47_valor_pag decimal (12,2) not null);

alter table "fobos".rolt047
	modify (n47_valor_des decimal (12,2) not null);
--------------------------------------------------------------------------------

commit work;
