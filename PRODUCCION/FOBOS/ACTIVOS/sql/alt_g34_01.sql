alter table gent034 add (g34_aux_deprec char(12) before g34_usuario);

create index "fobos".i03_fk_gent034 on "fobos".gent034
	(g34_compania, g34_aux_deprec) in idxdbs;

alter table "fobos".gent034 add constraint
	(foreign key (g34_compania, g34_aux_deprec) references "fobos".ctbt010);
