begin work;

{-- SE VA A ELIMINAR PRIMARY KEY E INDICES UNICOS DE ESTAS TABLAS --}

alter table "fobos".ctbt040 drop constraint "fobos".pk_ctbt040;
alter table "fobos".ctbt043 drop constraint "fobos".pk_ctbt043;

drop index "fobos".i01_pk_ctbt040;
drop index "fobos".i01_pk_ctbt043;

{-- --}


{-- SE VA ADICIONAR NUEVA COLUMNA, PRIMARY KEY E INDICES UNICOS EN ESTAS
 -- TABLAS PARA CONTABILIZAR LAS VENTAS EXENTAS DE IVA --}

alter table "fobos".ctbt040
	add (b40_porc_impto decimal(5, 2) before b40_venta);
alter table "fobos".ctbt043
	add (b43_porc_impto decimal(5, 2) before b43_vta_mo_tal);

update ctbt040 set b40_porc_impto = 12.0 where 1 = 1;
update ctbt043 set b43_porc_impto = 12.0 where 1 = 1;

alter table "fobos".ctbt040 modify (b40_porc_impto decimal(5, 2) not null);
alter table "fobos".ctbt043 modify (b43_porc_impto decimal(5, 2) not null);

create unique index "fobos".i01_pk_ctbt040 on "fobos".ctbt040
	(b40_compania, b40_localidad, b40_modulo, b40_bodega, b40_grupo_linea,
	 b40_porc_impto) in idxdbs;
create unique index "fobos".i01_pk_ctbt043 on "fobos".ctbt043
	(b43_compania, b43_localidad, b43_grupo_linea, b43_porc_impto)
	in idxdbs;

alter table "fobos".ctbt040
	add constraint
		primary key (b40_compania, b40_localidad, b40_modulo,
				b40_bodega, b40_grupo_linea, b40_porc_impto)
			constraint "fobos".pk_ctbt040;
alter table "fobos".ctbt043
	add constraint
		primary key (b43_compania, b43_localidad, b43_grupo_linea,
				b43_porc_impto)
			constraint "fobos".pk_ctbt043;

{-- --}


{-- AUMENTO EN EL TAMANIO DE LA GLOSA CONTABLE DEL DETALLE (b13_glosa) --}

alter table "fobos".ctbt013 modify (b13_glosa varchar(90,40));

{-- --}

commit work;
