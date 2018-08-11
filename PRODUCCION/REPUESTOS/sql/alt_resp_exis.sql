begin work;

alter table "fobos".resp_exis add (r11_fec_corte datetime year to second);

update "fobos".resp_exis
	set r11_fec_corte = "2004-10-31 23:00:00"
	where 1 = 1;

alter table "fobos".resp_exis
	modify (r11_fec_corte datetime year to second not null);

commit work;
