set isolation to dirty read;

select r10_compania cia, r10_codigo item, r10_modelo modelo, r10_partida parti,
	r10_cod_comerc cod_com
	from acero_qm@idsuio01:rept010
	where r10_compania = 1
	into temp t1;

{--
unload to "act_mpc_item_gm.unl"
	select r10_compania cia, r10_codigo item, r10_modelo modelo,
		r10_partida parti, r10_cod_comerc cod_com
		from acero_gm@idsgye01:rept010
		where r10_compania = 1;

unload to "act_mpc_item_gc.unl"
	select r10_compania cia, r10_codigo item, r10_modelo modelo,
		r10_partida parti, r10_cod_comerc cod_com
		from acero_gc@idsgye01:rept010
		where r10_compania = 1;

update acero_gm@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '1'
	  and r10_codigo   in (select item from t1);

update acero_gc@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '1'
	  and r10_codigo   in (select item from t1);
--}

update acero_gm@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '2'
	  and r10_codigo   in (select item from t1);

update acero_gc@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '2'
	  and r10_codigo   in (select item from t1);

update acero_gm@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '3'
	  and r10_codigo   in (select item from t1);

update acero_gc@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '3'
	  and r10_codigo   in (select item from t1);

update acero_gm@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '4'
	  and r10_codigo   in (select item from t1);

update acero_gc@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '4'
	  and r10_codigo   in (select item from t1);

update acero_gm@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '5'
	  and r10_codigo   in (select item from t1);

update acero_gc@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '5'
	  and r10_codigo   in (select item from t1);

update acero_gm@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '6'
	  and r10_codigo   in (select item from t1);

update acero_gc@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '6'
	  and r10_codigo   in (select item from t1);

update acero_gm@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '7'
	  and r10_codigo   in (select item from t1);

update acero_gc@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '7'
	  and r10_codigo   in (select item from t1);

update acero_gm@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '8'
	  and r10_codigo   in (select item from t1);

update acero_gc@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '8'
	  and r10_codigo   in (select item from t1);

update acero_gm@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '9'
	  and r10_codigo   in (select item from t1);

update acero_gc@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '9'
	  and r10_codigo   in (select item from t1);

update acero_gm@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '0'
	  and r10_codigo   in (select item from t1);

update acero_gc@idsgye01:rept010
	set r10_modelo     = (select modelo
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_partida    = (select parti
				from t1
				where cia  = r10_compania
				  and item = r10_codigo),
	    r10_cod_comerc = (select cod_com
				from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where r10_compania  = 1
	  and r10_linea     = '0'
	  and r10_codigo   in (select item from t1);

drop table t1;
