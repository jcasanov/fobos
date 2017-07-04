begin work;

alter table "fobos".ordt010
	modify (c10_recargo decimal(5,2) not null);

commit work;
