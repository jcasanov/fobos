begin work;
	
{------------------------------------------------------------------------------}

	drop index "fobos".i08_fk_rolt030;

	alter table "fobos".rolt030
		drop constraint "fobos".r242_7081;

	drop index "fobos".i04_fk_rolt027;

	alter table "fobos".rolt027
		drop constraint "fobos".fk_04_rolt027;

	drop index "fobos".i01_pk_rolt017;

	alter table "fobos".rolt017
		drop constraint "fobos".pk_rolt017;

{------------------------------------------------------------------------------}

{------------------------------------------------------------------------------}

	alter table "fobos".rolt017
		add (n17_compania	integer		before n17_sectorial);

	alter table "fobos".rolt017
		add (n17_ano_sect	smallint	before n17_sectorial);

	alter table "fobos".rolt017
		add (n17_usuario	varchar(10,5));

	alter table "fobos".rolt017
		add (n17_fecing		datetime year to second);

	alter table "fobos".rolt027
		add (n27_ano_sect	smallint	before n27_sectorial);

	alter table "fobos".rolt030
		add (n30_ano_sect	smallint	before n30_sectorial);

{------------------------------------------------------------------------------}

{------------------------------------------------------------------------------}

	update rolt017
		set n17_compania = 1,
		    n17_ano_sect = 2003,
		    n17_usuario  = "FOBOS",
		    n17_fecing   = "2002-12-31 00:00:00"
		where 1 = 1;

	update rolt027
		set n27_ano_sect = 2003
		where n27_sectorial is not null;

	update rolt030
		set n30_ano_sect = 2003
		where 1 = 1;

{------------------------------------------------------------------------------}

{------------------------------------------------------------------------------}

	alter table "fobos".rolt017
		modify (n17_compania	integer		not null);

	alter table "fobos".rolt017
		modify (n17_ano_sect	smallint	not null);

	alter table "fobos".rolt017
		modify (n17_sectorial	char(15)	not null);

	alter table "fobos".rolt017
		modify (n17_descripcion	varchar(140,60)	not null);

	alter table "fobos".rolt017
		modify (n17_usuario	varchar(10,5)	not null);

	alter table "fobos".rolt017
		modify (n17_fecing	datetime year to second not null);

	alter table "fobos".rolt027
		modify (n27_sectorial	char(15));

	alter table "fobos".rolt030
		modify (n30_ano_sect	smallint	not null);

	alter table "fobos".rolt030
		modify (n30_sectorial	char(15)	not null);

{------------------------------------------------------------------------------}

{------------------------------------------------------------------------------}

	select n30_compania cia, n30_ano_sect anio, n30_num_doc_id cedu,
		n30_sectorial secto, n17_descripcion descrip, n17_valor val_sec
		from rolt030, rolt017
		where n30_compania  = 999
		  and n17_compania  = n30_compania
		  and n17_ano_sect  = n30_ano_sect
		  and n17_sectorial = n30_sectorial
		into temp t1;

	load from "sectorial_2009_gm.unl" insert into t1;

	select cia, anio, secto, descrip, val_sec, "FOBOS" usua, current fecing
		from t1
		group by 1, 2, 3, 4, 5, 6, 7
		into temp t2;

	load from "sect_jub.unl" insert into t2;

	update t2
		set fecing = extend(current, year to second)
		where descrip = "JUBILADO";

	insert into rolt017
		(n17_compania, n17_ano_sect, n17_sectorial, n17_descripcion,
		 n17_valor, n17_usuario, n17_fecing)
		select * from t2;

	update rolt030
		set n30_ano_sect  = (select anio
					from t1
					where cedu = n30_num_doc_id),
		    n30_sectorial = (select secto
					from t1
					where cedu = n30_num_doc_id)
		where n30_compania   = 1
		  and n30_num_doc_id in (select cedu from t1);

	update rolt030
		set n30_ano_sect  = (select anio
					from t1
					where cedu = n30_carnet_seg),
		    n30_sectorial = (select secto
					from t1
					where cedu = n30_carnet_seg)
		where n30_compania   = 1
		  and n30_carnet_seg in (select cedu from t1);

	update rolt030
		set n30_ano_sect  = (select anio
					from t2
					where descrip = "JUBILADO"),
		    n30_sectorial = (select secto
					from t2
					where descrip = "JUBILADO")
		where n30_compania = 1
		  and n30_estado   = "J";

	drop table t1;

	drop table t2;

{------------------------------------------------------------------------------}

{------------------------------------------------------------------------------}

	create unique index "fobos".i01_pk_rolt017
		on "fobos".rolt017
			(n17_compania, n17_ano_sect, n17_sectorial)
		in idxdbs;

	create index "fobos".i01_fk_rolt017
		on "fobos".rolt017
			(n17_usuario)
		in idxdbs;

	alter table "fobos".rolt017
		add constraint
			primary key (n17_compania, n17_ano_sect, n17_sectorial)
			constraint "fobos".pk_rolt017;

	alter table "fobos".rolt017
		add constraint (foreign key (n17_usuario)
			references "fobos".gent005
			constraint "fobos".fk_01_rolt017);

	create index "fobos".i04_fk_rolt027
		on "fobos".rolt027
			(n27_compania, n27_ano_sect, n27_sectorial)
		in idxdbs;

	alter table "fobos".rolt027
		add constraint (foreign key (n27_compania, n27_ano_sect,
						n27_sectorial)
			references "fobos".rolt017
			constraint "fobos".fk_04_rolt027);

	create index "fobos".i08_fk_rolt030
		on "fobos".rolt030
			(n30_compania, n30_ano_sect, n30_sectorial)
		in idxdbs;

	alter table "fobos".rolt030
		add constraint (foreign key (n30_compania, n30_ano_sect,
						n30_sectorial)
			references "fobos".rolt017
			constraint "fobos".fk_08_rolt030);

{------------------------------------------------------------------------------}

--rollback work;
commit work;
