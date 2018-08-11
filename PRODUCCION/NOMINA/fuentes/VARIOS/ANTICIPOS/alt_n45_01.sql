select n45_compania cia, n45_num_prest num_prest, n45_estado estado
	from rolt045
	into temp t1;


begin work;

--------------------------------------------------------------------------------
--- MODIFICANDO EL ESTADO DE LA TABLA rolt045 PARA QUE SOPORTE 2 ESTADOS MAS
--- T: Transferido
--- R: Redistribuido
--

alter table "fobos".rolt045 drop n45_estado;

alter table "fobos".rolt045 add (n45_estado char(1) before n45_referencia);

update "fobos".rolt045
	set n45_estado = (select estado from t1
				where cia       = n45_compania
				  and num_prest = n45_num_prest)
	where n45_compania  in (1, 2)
	  and n45_num_prest = (select num_prest from t1
				where cia       = n45_compania
				  and num_prest = n45_num_prest);

alter table "fobos".rolt045 modify (n45_estado char(1) not null);

alter table "fobos".rolt045
	add constraint check (n45_estado in ('A', 'P', 'E', 'T', 'R'))
		constraint "fobos".ck_01_rolt045;

--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--- CREANDO NUEVO ENLACE CON LA rolt045 (CIRCULAR) PARA PRESTAMOS CON ESTADO
--- "T" TRANSFERIDO, CON SU NUEVO PRESTAMO "R" REDISTRIBUIDO.
--- ADEMAS FORMA DE PAGO Y CUENTA PARA LA CONTABILIZACION.
--

alter table "fobos".rolt045 add (n45_tipo_pago   char(1)  before n45_usuario);
alter table "fobos".rolt045 add (n45_bco_empresa integer  before n45_usuario);
alter table "fobos".rolt045 add (n45_cta_empresa char(15) before n45_usuario);
alter table "fobos".rolt045 add (n45_cta_trabaj  char(15) before n45_usuario);

alter table "fobos".rolt045 add (n45_prest_tran  integer  before n45_usuario);

create index "fobos".i05_fk_rolt045 on "fobos".rolt045
	(n45_bco_empresa) in idxdbs;
create index "fobos".i06_fk_rolt045 on "fobos".rolt045
	(n45_compania, n45_bco_empresa, n45_cta_empresa) in idxdbs;

create index "fobos".i07_fk_rolt045 on "fobos".rolt045
	(n45_compania, n45_prest_tran) in idxdbs;

alter table "fobos".rolt045
	add constraint (foreign key (n45_bco_empresa)
			references "fobos".gent008
			constraint "fobos".fk_05_rolt045);
alter table "fobos".rolt045
	add constraint (foreign key (n45_compania, n45_bco_empresa,
					n45_cta_empresa)
			references "fobos".gent009
			constraint "fobos".fk_06_rolt045);

alter table "fobos".rolt045
	add constraint (foreign key (n45_compania, n45_prest_tran)
			references "fobos".rolt045
			constraint "fobos".fk_07_rolt045);

alter table "fobos".rolt045
	add (n45_sal_prest_ant decimal(12,2) before n45_usuario);

update "fobos".rolt045
	set n45_tipo_pago     = 'C',
	    n45_sal_prest_ant = 0.00
	where 1 = 1;

alter table "fobos".rolt045 modify (n45_sal_prest_ant decimal(12,2) not null);

alter table "fobos".rolt045 modify (n45_tipo_pago     char(1) not null);

alter table "fobos".rolt045
	add constraint check (n45_tipo_pago in ('E', 'C', 'T'))
		constraint "fobos".ck_02_rolt045;

--
--------------------------------------------------------------------------------
alter table "fobos".rolt046 drop constraint "fobos".c258_1801;

commit work;

drop table t1;
