begin work;

drop index "fobos".i01_pk_rolt042;
drop index "fobos".i01_fk_rolt042;
drop index "fobos".i02_fk_rolt042;
drop index "fobos".i03_fk_rolt042;

alter table "fobos".rolt042 drop constraint "fobos".pk_rolt042;
alter table "fobos".rolt042 drop constraint "fobos".r252_6048;
alter table "fobos".rolt042 drop constraint "fobos".r252_6049;
alter table "fobos".rolt042 drop constraint "fobos".r252_6050;

drop index "fobos".i01_pk_rolt041;
drop index "fobos".i01_fk_rolt041;
drop index "fobos".i02_fk_rolt041;
drop index "fobos".i03_fk_rolt041;

alter table "fobos".rolt041 drop constraint "fobos".pk_rolt041;
alter table "fobos".rolt041 drop constraint "fobos".r484_6045;
alter table "fobos".rolt041 drop constraint "fobos".r484_6047;
alter table "fobos".rolt041 drop n41_moneda;


alter table "fobos".rolt041 add (n41_proceso     char(2)  before n41_ano);
alter table "fobos".rolt041 add (n41_fecha_ini   date     before n41_ano);
alter table "fobos".rolt041 add (n41_fecha_fin   date     before n41_ano);

alter table "fobos".rolt041 add (n41_moneda      char(2)  before n41_paridad);

update rolt041
	set n41_proceso   = 'UT',
	    n41_fecha_ini = mdy(01, 01, n41_ano),
	    n41_fecha_fin = mdy(12, 31, n41_ano),
	    n41_moneda    = 'DO'
	where 1 = 1;

alter table "fobos".rolt041 modify (n41_proceso     char(2)  not null);
alter table "fobos".rolt041 modify (n41_fecha_ini   date     not null);
alter table "fobos".rolt041 modify (n41_fecha_fin   date     not null);

alter table "fobos".rolt041 modify (n41_moneda      char(2)  not null);


create unique index "fobos".i01_pk_rolt041
	on "fobos".rolt041
		(n41_compania, n41_proceso, n41_fecha_ini, n41_fecha_fin)
	in idxdbs;

create index "fobos".i01_fk_rolt041
	on "fobos".rolt041
		(n41_compania)
	in idxdbs;

create index "fobos".i02_fk_rolt041
	on "fobos".rolt041
		(n41_proceso)
	in idxdbs;

create index "fobos".i03_fk_rolt041
	on "fobos".rolt041
		(n41_moneda)
	in idxdbs;

create index "fobos".i04_fk_rolt041
	on "fobos".rolt041
		(n41_usuario)
	in idxdbs;



alter table "fobos".rolt041
	add constraint
		primary key (n41_compania, n41_proceso, n41_fecha_ini,
				n41_fecha_fin)
			constraint "fobos".pk_rolt041;

alter table "fobos".rolt041
	add constraint
		(foreign key (n41_compania)
			references "fobos".rolt000
			constraint "fobos".fk_01_rolt041);

alter table "fobos".rolt041
	add constraint
		(foreign key (n41_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_02_rolt041);

alter table "fobos".rolt041
	add constraint
		(foreign key (n41_moneda)
			references "fobos".gent013
			constraint "fobos".fk_03_rolt041);

alter table "fobos".rolt041
	add constraint
		(foreign key (n41_usuario)
			references "fobos".gent005
			constraint "fobos".fk_04_rolt041);


alter table "fobos".rolt042 add (n42_proceso     char(2)  before n42_ano);
alter table "fobos".rolt042 add (n42_fecha_ini   date     before n42_cod_depto);
alter table "fobos".rolt042 add (n42_fecha_fin   date     before n42_cod_depto);

update rolt042
	set n42_proceso   = 'UT',
	    n42_fecha_ini = mdy(01, 01, n42_ano),
	    n42_fecha_fin = mdy(12, 31, n42_ano)
	where 1 = 1;

alter table "fobos".rolt042 modify (n42_proceso     char(2)  not null);
alter table "fobos".rolt042 modify (n42_fecha_ini   date     not null);
alter table "fobos".rolt042 modify (n42_fecha_fin   date     not null);


alter table "fobos".rolt042 add (n42_dias_trab smallint before n42_num_cargas);
select n42_cod_trab cod, n42_ano anio,
        case when n30_fecha_sal is not null
                then case when n30_fecha_ing < n42_fecha_ini
                        then n30_fecha_sal - n42_fecha_ini + 1
                        else n30_fecha_sal - n30_fecha_ing + 1
                     end
                else case when n30_fecha_ing < n42_fecha_ini
                        then n42_fecha_fin - n42_fecha_ini + 1
                        else n42_fecha_fin - n30_fecha_ing + 1
                     end
        end dias_trab
        from rolt042, rolt030
        where n42_compania = 1
          and n30_compania = n42_compania
          and n30_cod_trab = n42_cod_trab
	into temp t1;
update rolt042
	set n42_dias_trab = (select dias_trab from t1
				where cod  = n42_cod_trab
				  and anio = n42_ano)
	where 1 = 1;
alter table "fobos".rolt042 modify (n42_dias_trab smallint not null);
drop table t1;


alter table "fobos".rolt042 drop n42_ano;
alter table "fobos".rolt042 add    (n42_ano smallint before n42_cod_depto);
update rolt042 set n42_ano = 2006 where 1 = 1;
alter table "fobos".rolt042 modify (n42_ano smallint not null);

rename column "fobos".rolt042.n42_anticipos to n42_descuentos;


create unique index "fobos".i01_pk_rolt042
	on "fobos".rolt042
		(n42_compania, n42_proceso, n42_cod_trab, n42_fecha_ini,
		 n42_fecha_fin)
	in idxdbs;

create index "fobos".i01_fk_rolt042
	on "fobos".rolt042
		(n42_compania, n42_proceso, n42_fecha_ini, n42_fecha_fin)
	in idxdbs;

create index "fobos".i02_fk_rolt042
	on "fobos".rolt042
		(n42_compania, n42_cod_trab)
	in idxdbs;

create index "fobos".i03_fk_rolt042
	on "fobos".rolt042
		(n42_compania, n42_cod_depto)
	in idxdbs;

create index "fobos".i04_fk_rolt042
	on "fobos".rolt042
		(n42_bco_empresa)
	in idxdbs;

create index "fobos".i05_fk_rolt042
	on "fobos".rolt042
		(n42_compania, n42_bco_empresa, n42_cta_empresa)
	in idxdbs;


alter table "fobos".rolt042
	add constraint
		primary key (n42_compania, n42_proceso, n42_cod_trab,
				n42_fecha_ini, n42_fecha_fin)
			constraint "fobos".pk_rolt042;

alter table "fobos".rolt042
	add constraint
		(foreign key (n42_compania, n42_proceso, n42_fecha_ini,
				n42_fecha_fin)
			references "fobos".rolt041
			constraint "fobos".fk_01_rolt042);

alter table "fobos".rolt042
	add constraint
		(foreign key (n42_compania, n42_cod_trab)
			references "fobos".rolt030
			constraint "fobos".fk_02_rolt042);

alter table "fobos".rolt042
	add constraint
		(foreign key (n42_compania, n42_cod_depto)
			references "fobos".gent034
			constraint "fobos".fk_03_rolt042);

alter table "fobos".rolt042
	add constraint
		(foreign key (n42_bco_empresa)
			references "fobos".gent008
			constraint "fobos".fk_04_rolt042);

alter table "fobos".rolt042
	add constraint
		(foreign key (n42_compania, n42_bco_empresa, n42_cta_empresa)
			references "fobos".gent009
			constraint "fobos".fk_05_rolt042);

commit work;
