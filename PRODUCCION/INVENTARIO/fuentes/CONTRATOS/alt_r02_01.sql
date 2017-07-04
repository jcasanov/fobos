begin work;

--alter table "fobos".rept002 drop r02_tipo_ident;

alter table "fobos".rept002
	add (r02_tipo_ident		char(1)		before r02_usuario);

update "fobos".rept002
	set r02_tipo_ident = 'V'
	where r02_codigo not in ('18', 'GC', 'QC');

update "fobos".rept002
	set r02_tipo_ident = 'C'
	where r02_codigo in ('GC', 'QC');

update "fobos".rept002
	set r02_tipo_ident = 'I'
	where r02_codigo in ('18');

alter table "fobos".rept002
	modify (r02_tipo_ident		char(1)		not null);

alter table "fobos".rept002
        add constraint
		check (r02_tipo_ident in ('C', 'R', 'I', 'V'))
                	constraint "fobos".ck_05_rept002;

commit work;
