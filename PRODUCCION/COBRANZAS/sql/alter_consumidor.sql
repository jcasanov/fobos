begin work;

alter table "fobos".rept000 
	add r00_cliente_final integer references "fobos".cxct001
	before r00_tipo_margen;

alter table "fobos".talt000 
	add t00_cliente_final integer references "fobos".cxct001
	before t00_factor_mb;

commit work;
