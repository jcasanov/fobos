begin work;

alter table "fobos".cajt013 drop constraint c225_1354;

alter table "fobos".cajt013
	add constraint check
		(j13_trn_generada in ('FA', 'NV', 'PG', 'PA', 'OI', 'EC'));

commit work;
