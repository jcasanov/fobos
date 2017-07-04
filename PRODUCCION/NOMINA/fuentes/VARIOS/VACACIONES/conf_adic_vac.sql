--rollback work;

begin work;

drop index "fobos".i01_pk_rolt040;
drop index "fobos".i01_fk_rolt040;
alter table "fobos".rolt040 drop constraint "fobos".pk_rolt040;
alter table "fobos".rolt040 drop n40_secuencia;


drop index "fobos".i01_pk_rolt057;
drop index "fobos".i01_fk_rolt057;
alter table "fobos".rolt057 drop constraint "fobos".pk_rolt057;
alter table "fobos".rolt057 drop constraint "fobos".fk_01_rolt057;
alter table "fobos".rolt057 drop n57_secuencia;


drop index "fobos".i01_pk_rolt047;
alter table "fobos".rolt047 drop constraint "fobos".pk_rolt047;


drop index "fobos".i01_pk_rolt039;
alter table "fobos".rolt039 drop constraint "fobos".pk_rolt039;
alter table "fobos".rolt039 drop n39_secuencia;


alter table "fobos".rolt039 add (n39_proceso     char(2)  before n39_cod_trab);
alter table "fobos".rolt039 add (n39_ano_proceso smallint before n39_fecha_ing);
alter table "fobos".rolt039 add (n39_mes_proceso smallint before n39_fecha_ing);

update "fobos".rolt039
	set n39_proceso     = 'VA',
	    n39_ano_proceso = year(n39_perfin_real),
	    n39_mes_proceso = month(n39_perfin_real)
	where 1 = 1;

alter table "fobos".rolt039 modify (n39_proceso     char(2)  not null);
alter table "fobos".rolt039 modify (n39_ano_proceso smallint not null);
alter table "fobos".rolt039 modify (n39_mes_proceso smallint not null);

create unique index "fobos".i01_pk_rolt039 on "fobos".rolt039
	(n39_compania, n39_proceso, n39_cod_trab, n39_periodo_ini,
		n39_periodo_fin)
	in idxdbs;

create index "fobos".i05_fk_rolt039 on "fobos".rolt039 (n39_proceso) in idxdbs;

create index "fobos".i06_fk_rolt039 on "fobos".rolt039
	(n39_bco_empresa) in idxdbs;

create index "fobos".i07_fk_rolt039 on "fobos".rolt039
	(n39_compania, n39_bco_empresa, n39_cta_empresa) in idxdbs;

alter table "fobos".rolt039
	add constraint
		primary key (n39_compania, n39_proceso, n39_cod_trab,
				n39_periodo_ini, n39_periodo_fin)
			constraint "fobos".pk_rolt039;

alter table "fobos".rolt039
	add constraint (foreign key (n39_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_05_rolt039);

alter table "fobos".rolt039
	add constraint (foreign key (n39_bco_empresa)
			references "fobos".gent008
			constraint "fobos".fk_06_rolt039);

alter table "fobos".rolt039
	add constraint (foreign key (n39_compania, n39_bco_empresa,
					n39_cta_empresa)
			references "fobos".gent009
			constraint "fobos".fk_07_rolt039);


alter table "fobos".rolt040 add (n40_proceso char(2) before n40_cod_trab);

update "fobos".rolt040 set n40_proceso = 'VA' where 1 = 1;

alter table "fobos".rolt040 modify (n40_proceso char(2) not null);

create unique index "fobos".i01_pk_rolt040 on "fobos".rolt040
	(n40_compania, n40_proceso, n40_cod_trab, n40_periodo_ini,
		n40_periodo_fin, n40_cod_rubro)
	in idxdbs;

create index "fobos".i01_fk_rolt040 on "fobos".rolt040
	(n40_compania, n40_proceso, n40_cod_trab, n40_periodo_ini,
		n40_periodo_fin)
	in idxdbs;

create index "fobos".i04_fk_rolt040 on "fobos".rolt040 (n40_proceso) in idxdbs;

alter table "fobos".rolt040
	add constraint
		primary key (n40_compania, n40_proceso, n40_cod_trab,
				n40_periodo_ini, n40_periodo_fin, n40_cod_rubro)
			constraint "fobos".pk_rolt040;

alter table "fobos".rolt040
	add constraint (foreign key (n40_compania, n40_proceso, n40_cod_trab,
				n40_periodo_ini, n40_periodo_fin)
			references "fobos".rolt039
			constraint "fobos".fk_01_rolt040);

alter table "fobos".rolt040
	add constraint (foreign key (n40_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_04_rolt040);


alter table "fobos".rolt047 add (n47_proceso char(2) before n47_cod_trab);

update "fobos".rolt047 set n47_proceso = 'VA' where 1 = 1;

alter table "fobos".rolt047 modify (n47_proceso char(2)    not null);

alter table "fobos".rolt047 add (n47_estado     char(1)    not null);

alter table "fobos".rolt047 add (n47_max_dias   smallint   not null);
alter table "fobos".rolt047 add (n47_dias_goza  smallint   not null);

alter table "fobos".rolt047 add (n47_cod_liqrol char(2)    not null);
alter table "fobos".rolt047 add (n47_fecha_ini  date       not null);
alter table "fobos".rolt047 add (n47_fecha_fin  date       not null);

alter table "fobos".rolt047 add (n47_usuario varchar(10,5) not null);
alter table "fobos".rolt047 add (n47_fecing  datetime year to second not null);

create unique index "fobos".i01_pk_rolt047 on "fobos".rolt047
	(n47_compania, n47_proceso, n47_cod_trab, n47_periodo_ini,
		n47_periodo_fin, n47_secuencia)
	in idxdbs;

create index "fobos".i01_fk_rolt047 on "fobos".rolt047
	(n47_compania, n47_proceso, n47_cod_trab, n47_periodo_ini,
		n47_periodo_fin)
	in idxdbs;

create index "fobos".i02_fk_rolt047 on "fobos".rolt047 (n47_proceso) in idxdbs;

create index "fobos".i03_fk_rolt047 on "fobos".rolt047
	(n47_compania, n47_cod_liqrol, n47_fecha_ini, n47_fecha_fin,
		n47_cod_trab)
	in idxdbs;

create index "fobos".i04_fk_rolt047 on "fobos".rolt047
	(n47_cod_liqrol) in idxdbs;

create index "fobos".i05_fk_rolt047 on "fobos".rolt047 (n47_usuario) in idxdbs;

alter table "fobos".rolt047
	add constraint
		primary key (n47_compania, n47_proceso, n47_cod_trab,
				n47_periodo_ini, n47_periodo_fin, n47_secuencia)
			constraint "fobos".pk_rolt047;

alter table "fobos".rolt047
	add constraint (foreign key (n47_compania, n47_proceso, n47_cod_trab,
				n47_periodo_ini, n47_periodo_fin)
			references "fobos".rolt039
			constraint "fobos".fk_01_rolt047);

alter table "fobos".rolt047
	add constraint (foreign key (n47_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_02_rolt047);

alter table "fobos".rolt047
	add constraint (foreign key (n47_compania, n47_cod_liqrol,
					n47_fecha_ini, n47_fecha_fin,
					n47_cod_trab)
			references "fobos".rolt032
			constraint "fobos".fk_03_rolt047);

alter table "fobos".rolt047
	add constraint (foreign key (n47_cod_liqrol)
			references "fobos".rolt003
			constraint "fobos".fk_04_rolt047);

alter table "fobos".rolt047
	add constraint (foreign key (n47_usuario)
			references "fobos".gent005
			constraint "fobos".fk_05_rolt047);

alter table "fobos".rolt047
	add constraint check (n47_estado in ('A', 'G'))
			constraint "fobos".ck_01_rolt047;


alter table "fobos".rolt057 add (n57_proceso char(2) before n57_cod_trab);

update "fobos".rolt057 set n57_proceso = 'VA' where 1 = 1;

alter table "fobos".rolt057 modify (n57_proceso char(2) not null);

create unique index "fobos".i01_pk_rolt057 on "fobos".rolt057
	(n57_compania, n57_proceso, n57_cod_trab, n57_periodo_ini,
		n57_periodo_fin, n57_tipo_comp, n57_num_comp)
	in idxdbs;

create index "fobos".i01_fk_rolt057 on "fobos".rolt057
	(n57_compania, n57_proceso, n57_cod_trab, n57_periodo_ini,
		n57_periodo_fin)
	in idxdbs;

create index "fobos".i03_fk_rolt057 on "fobos".rolt057 (n57_proceso) in idxdbs;

alter table "fobos".rolt057
	add constraint
		primary key (n57_compania, n57_proceso, n57_cod_trab,
				n57_periodo_ini, n57_periodo_fin, n57_tipo_comp,
				n57_num_comp)
			constraint "fobos".pk_rolt057;

alter table "fobos".rolt057
	add constraint (foreign key (n57_compania, n57_proceso, n57_cod_trab,
				n57_periodo_ini, n57_periodo_fin)
			references "fobos".rolt039
			constraint "fobos".fk_01_rolt057);

alter table "fobos".rolt057
	add constraint (foreign key (n57_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_03_rolt057);

commit work;
