alter table actt000 add (a00_anopro	smallint,
			 a00_mespro	smallint);
update actt000 set a00_anopro = 2003, 
		   a00_mespro = 1
	where 1 = 1;
alter table actt000 modify a00_anopro	smallint not null;
alter table actt000 modify a00_mespro	smallint not null
