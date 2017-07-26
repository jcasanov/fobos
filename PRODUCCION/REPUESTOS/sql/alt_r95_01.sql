begin work;

alter table "fobos".rept095
	drop constraint ck_01_rept095;

alter table "fobos".rept095
	add constraint
		check (r95_motivo in ('V', 'D', 'I', 'N'))
			constraint ck_01_rept095;

commit work;
