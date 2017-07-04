select n10_compania cia, n10_cod_liqrol lq, n10_cod_rubro rub,
	n10_cod_trab cod
	from rolt010
	into temp t1;

begin work;

drop index "fobos".i01_pk_rolt010;

drop index "fobos".i03_fk_rolt010;

alter table "fobos".rolt010 drop constraint "fobos".pk_rolt010;

alter table "fobos".rolt010 drop n10_cod_liqrol;

alter table "fobos".rolt010 add (n10_cod_liqrol char(2) before n10_valor);

update "fobos".rolt010
	set n10_cod_liqrol = (select lq from t1
				where cia = n10_compania
				  and rub = n10_cod_rubro
				  and cod = n10_cod_trab)
	where exists (select cia, rub, cod
			from t1
			where cia = n10_compania
			  and rub = n10_cod_rubro
			  and cod = n10_cod_trab);

create unique index "fobos".i01_pk_rolt010 on "fobos".rolt010
	(n10_compania, n10_cod_rubro, n10_cod_trab) in idxdbs;

create index "fobos".i03_fk_rolt010 on "fobos".rolt010
	(n10_cod_liqrol) in idxdbs;

alter table "fobos".rolt010
	add constraint
		primary key (n10_compania, n10_cod_rubro, n10_cod_trab)
			constraint "fobos".pk_rolt010;

alter table "fobos".rolt010
	add constraint (foreign key (n10_cod_liqrol)
			references "fobos".rolt003
			constraint "fobos".fk_03_rolt010);

commit work;

drop table t1;
