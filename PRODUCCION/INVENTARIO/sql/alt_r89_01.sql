begin work;

alter table "fobos".rept089
	add (r89_fec_corte datetime year to second before r89_bueno);

update "fobos".rept089
	set r89_fec_corte = "2004-10-31 23:00:00"
	where 1 = 1;

alter table "fobos".rept089
	modify (r89_fec_corte datetime year to second not null);

commit work;
