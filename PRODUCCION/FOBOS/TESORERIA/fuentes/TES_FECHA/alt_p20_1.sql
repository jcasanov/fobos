begin work;

alter table "fobos".cxpt020
	add (p20_cod_tran char(2) before p20_usuario);

alter table "fobos".cxpt020
	add (p20_num_tran decimal(15,0) before p20_usuario);

create index "fobos".i07_fk_cxpt020 on "fobos".cxpt020
	(p20_compania, p20_localidad, p20_cod_tran, p20_num_tran);

alter table "fobos".cxpt020
	add constraint
		(foreign key (p20_compania, p20_localidad, p20_cod_tran,
				p20_num_tran)
		references "fobos".rept019);

commit work;
