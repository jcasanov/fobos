begin work;

{-- SE VA A REHACER PRIMARY KEY E INDICES UNICOS DE ESTAS TABLAS --}

alter table "fobos".ctbt040 drop constraint "fobos".pk_ctbt040;
alter table "fobos".ctbt043 drop constraint "fobos".pk_ctbt043;

drop index "fobos".i01_pk_ctbt040;
drop index "fobos".i01_pk_ctbt043;

{-- --}


{-- SE VA A QUITAR LA NUEVA COLUMNA, PRIMARY KEY E INDICES UNICOS EN ESTAS
 -- TABLAS PARA DESHACER LAS VENTAS EXENTAS DE IVA (CONFIGURACION CONTABLE)--}

alter table "fobos".ctbt040 drop b40_porc_impto;
alter table "fobos".ctbt043 drop b43_porc_impto;

create unique index "fobos".i01_pk_ctbt040 on "fobos".ctbt040
	(b40_compania, b40_localidad, b40_modulo, b40_bodega, b40_grupo_linea)
	in idxdbs;
create unique index "fobos".i01_pk_ctbt043 on "fobos".ctbt043
	(b43_compania, b43_localidad, b43_grupo_linea) in idxdbs;

alter table "fobos".ctbt040
	add constraint
		primary key (b40_compania, b40_localidad, b40_modulo,
				b40_bodega, b40_grupo_linea)
			constraint "fobos".pk_ctbt040;
alter table "fobos".ctbt043
	add constraint
		primary key (b43_compania, b43_localidad, b43_grupo_linea)
			constraint "fobos".pk_ctbt043;

{-- --}


{-- RESTAURAR EL TAMANIO DE LA GLOSA CONTABLE DEL DETALLE (b13_glosa) --}

alter table "fobos".ctbt013 modify (b13_glosa varchar(35,0));

{-- --}

commit work;
