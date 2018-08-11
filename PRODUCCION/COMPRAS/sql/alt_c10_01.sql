begin work;

	alter table "fobos".ordt010
		add c10_numprof		integer			before c10_usuario;

	create index "fobos".i12_fk_ordt010
		on "fobos".ordt010
			(c10_compania, c10_localidad, c10_numprof)
		in idxdbs; 

	alter table "fobos".ordt010 
		add constraint
			(foreign key
				(c10_compania, c10_localidad, c10_numprof)
                 references "fobos".rept021
				 constraint "fobos".fk_12_ordt010);

--rollback work;
commit work;
