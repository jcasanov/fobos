begin work;

	alter table "fobos".rept016 drop r16_numprof;

    alter table "fobos".rept016
        add r16_numprof     integer         before r16_usuario;

	create index "fobos".i08_fk_rept016
		        on "fobos".rept016
			            (r16_compania, r16_localidad, r16_numprof) in idxdbs;

	alter table "fobos".rept016
		add constraint
			(foreign key
				(r16_compania, r16_localidad, r16_numprof)
			references "fobos".rept021
			constraint "fobos".fk_08_rept016);

commit work;
