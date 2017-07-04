begin work;

update rolt042
	set n42_num_cargas = trunc(n42_val_cargas / 39.10)
	where n42_ano        = 2006
	  and n42_num_cargas = 0;

commit work;
