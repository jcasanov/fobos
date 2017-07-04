begin work;

drop index "fobos".i01_pk_cxpt005;
drop index "fobos".i03_fk_cxpt005;

alter table "fobos".cxpt005 drop constraint "fobos".pk_cxpt005;
alter table "fobos".cxpt005 drop constraint "fobos".r326_6467;

update cxpt005
	set p05_codigo_sri = '307'
	where p05_compania  = 1
	  and p05_tipo_ret  = 'F'
	  and p05_porcentaje in (1.00, 2.00)
	  and p05_codigo_sri is null;

update cxpt005
	set p05_codigo_sri = '303'
	where p05_compania  = 1
	  and p05_tipo_ret  = 'F'
	  and p05_porcentaje in (8.00, 5.00)
	  and p05_codigo_sri is null;

update cxpt005
	set p05_codigo_sri = '332'
	where p05_compania  = 1
	  and p05_tipo_ret  = 'F'
	  and p05_porcentaje in (0.00)
	  and p05_codigo_sri is null;

update cxpt005
	set p05_codigo_sri = '400'
	where p05_compania  = 1
	  and p05_tipo_ret  = 'F'
	  and p05_porcentaje in (0.10)
	  and p05_codigo_sri is null;

update cxpt005
	set p05_codigo_sri = '322'
	where p05_compania  = 1
	  and p05_tipo_ret  = 'F'
	  and p05_porcentaje in (0.20)
	  and p05_codigo_sri is null;

update cxpt005
	set p05_codigo_sri = '305'
	where p05_compania  = 1
	  and p05_tipo_ret  = 'F'
	  and p05_porcentaje in (25)
	  and p05_codigo_sri is null;

update cxpt005
	set p05_codigo_sri = '819'
	where p05_compania  = 1
	  and p05_tipo_ret  = 'I'
	  and p05_porcentaje in (30.00)
	  and p05_codigo_sri is null;

update cxpt005
	set p05_codigo_sri = '813'
	where p05_compania  = 1
	  and p05_tipo_ret  = 'I'
	  and p05_porcentaje in (70.00)
	  and p05_codigo_sri is null;

update cxpt005
	set p05_codigo_sri = '801'
	where p05_compania  = 1
	  and p05_tipo_ret  = 'I'
	  and p05_porcentaje in (100.00)
	  and p05_codigo_sri is null;

alter table "fobos".cxpt005 modify(p05_codigo_sri char(6) not null);

create unique index "fobos".i01_pk_cxpt005
	on "fobos".cxpt005
		(p05_compania, p05_codprov, p05_tipo_ret, p05_porcentaje,
		 p05_codigo_sri)
	in idxdbs;

alter table "fobos".cxpt005
	add constraint
		primary key (p05_compania, p05_codprov, p05_tipo_ret,
				p05_porcentaje, p05_codigo_sri)
			constraint "fobos".pk_cxpt005;

commit work;
