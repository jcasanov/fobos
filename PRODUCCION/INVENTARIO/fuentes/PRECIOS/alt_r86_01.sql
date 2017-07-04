begin work;

alter table "fobos".rept086
	add (r86_reversado	char(1));

update rept086
	set r86_reversado = 'N'
	where exists
		(select 1 from rept085
			where r85_compania = r86_compania
			  and r85_codigo   = r86_codigo
			  and r85_estado   = 'A');

update rept086
	set r86_reversado = 'S'
	where exists
		(select 1 from rept085
			where r85_compania = r86_compania
			  and r85_codigo   = r86_codigo
			  and r85_estado   = 'R');

alter table "fobos".rept086
	modify (r86_reversado	char(1)		not null);

alter table "fobos".rept086
        add constraint
		check (r86_reversado in ('S', 'N'))
                	constraint "fobos".ck_01_rept086;

commit work;
