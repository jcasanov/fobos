begin work;

alter table "fobos".rolt058
	add (n58_valor_div decimal(12,2) before n58_valor_dist);

update "fobos".rolt058
	set n58_valor_div = n58_valor_dist / n58_num_div
	where n58_valor_dist > 0
	  and n58_num_div    > 0;

update "fobos".rolt058 set n58_valor_div = 0 where n58_valor_div is null;

alter table "fobos".rolt058 modify (n58_valor_div decimal(12,2) not null);

commit work;
