alter table actt010
	drop constraint c325_2792;

alter table actt010
	add constraint
		(check (a10_estado in ('A', 'B', 'V', 'D', 'S', 'E')));
