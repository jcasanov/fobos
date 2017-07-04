begin work;

drop index "fobos".i01_pk_rept087;

alter table "fobos".rept087 drop constraint "fobos".pk_rept087;

alter table "fobos".rept087 add (r87_localidad smallint before r87_item);

update "fobos".rept087 set r87_localidad = 1		-- Poner de acuerdo en
	where 1 = 1;					-- que localidad se lo
							-- ejecute.

alter table "fobos".rept087 modify (r87_localidad smallint not null);

create unique index "fobos".i01_pk_rept087 on "fobos".rept087 
    (r87_compania, r87_localidad, r87_item, r87_secuencia);
    
alter table "fobos".rept087
	add constraint
		primary key (r87_compania, r87_localidad, r87_item,
				r87_secuencia)
			constraint "fobos".pk_rept087;

commit work;
