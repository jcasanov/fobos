begin work;
alter table cxct005 drop constraint c208_1217;
alter table cxct005 add constraint (
	check (z05_tipo IN ('E' ,'C', 'J'))
);
commit work;

