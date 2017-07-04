select n30_compania cia, n30_cod_trab cod, n30_ano_sect ani_sec,
	n30_sectorial sect
	from rolt030
	where n30_compania  = 1
	  and n30_estado    = 'I'
	  and n30_cod_trab in (185, 177, 167, 105, 178, 58, 71)
	into temp t1;

update aceros@acgyede:rolt030
	set n30_ano_sect  = (select ani_sec
				from t1
				where cia = n30_compania
				  and cod = n30_cod_trab),
	    n30_sectorial = (select sect
				from t1
				where cia = n30_compania
				  and cod = n30_cod_trab)
	where n30_compania  = 1
	  and n30_cod_trab in (select cod from t1);

update acero_gm@acuiopr:rolt030
	set n30_ano_sect  = (select ani_sec
				from t1
				where cia = n30_compania
				  and cod = n30_cod_trab),
	    n30_sectorial = (select sect
				from t1
				where cia = n30_compania
				  and cod = n30_cod_trab)
	where n30_compania  = 1
	  and n30_cod_trab in (select cod from t1);

drop table t1;
