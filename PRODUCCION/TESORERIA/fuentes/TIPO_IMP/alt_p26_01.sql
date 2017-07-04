begin work;

drop index "fobos".i01_pk_cxpt026;
drop index "fobos".i01_fk_cxpt026;

alter table "fobos".cxpt026 drop constraint "fobos".pk_cxpt026;
alter table "fobos".cxpt026 drop constraint "fobos".r216_5285;

update cxpt026
	set p26_codigo_sri = '307'
	where p26_compania  = 1
	  and p26_tipo_ret  = 'F'
	  and p26_porcentaje in (1.00, 2.00)
	  and p26_codigo_sri is null;

update cxpt026
	set p26_codigo_sri = '303'
	where p26_compania  = 1
	  and p26_tipo_ret  = 'F'
	  and p26_porcentaje in (8.00, 5.00)
	  and p26_codigo_sri is null;

update cxpt026
	set p26_codigo_sri = '332'
	where p26_compania  = 1
	  and p26_tipo_ret  = 'F'
	  and p26_porcentaje in (0.00)
	  and p26_codigo_sri is null;

update cxpt026
	set p26_codigo_sri = '400'
	where p26_compania  = 1
	  and p26_tipo_ret  = 'F'
	  and p26_porcentaje in (0.10)
	  and p26_codigo_sri is null;

update cxpt026
	set p26_codigo_sri = '819'
	where p26_compania  = 1
	  and p26_tipo_ret  = 'I'
	  and p26_porcentaje in (30.00)
	  and p26_codigo_sri is null;

update cxpt026
	set p26_codigo_sri = '813'
	where p26_compania  = 1
	  and p26_tipo_ret  = 'I'
	  and p26_porcentaje in (70.00)
	  and p26_codigo_sri is null;

update cxpt026
	set p26_codigo_sri = '801'
	where p26_compania  = 1
	  and p26_tipo_ret  = 'I'
	  and p26_porcentaje in (100.00)
	  and p26_codigo_sri is null;

alter table "fobos".cxpt026 modify(p26_codigo_sri char(6) not null);

create unique index "fobos".i01_pk_cxpt026
	on "fobos".cxpt026
		(p26_compania, p26_localidad, p26_orden_pago, p26_secuencia,
		 p26_tipo_ret, p26_porcentaje, p26_codigo_sri)
	in idxdbs;

alter table "fobos".cxpt026
	add constraint
		primary key (p26_compania, p26_localidad, p26_orden_pago,
				p26_secuencia, p26_tipo_ret, p26_porcentaje,
				p26_codigo_sri)
			constraint "fobos".pk_cxpt026;

commit work;
