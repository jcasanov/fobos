alter table "fobos".ctbt003 add b03_tipo_reversa char(2) before b03_usuario;
create index i04_fk_ctbt003 on "fobos".ctbt003(b03_compania, b03_tipo_reversa);
alter table "fobos".ctbt003 add constraint (
	foreign key (b03_compania, b03_tipo_reversa)
	references "fobos".ctbt003(b03_compania, b03_tipo_comp)
);
