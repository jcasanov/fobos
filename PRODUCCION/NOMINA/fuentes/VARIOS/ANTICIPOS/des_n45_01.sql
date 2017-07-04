select n45_compania cia, n45_num_prest num_prest, n45_estado estado
	from rolt045
	into temp t1;


begin work;

--------------------------------------------------------------------------------
--- ESTABLECIENDO ESTADO DE LA TABLA rolt045, PARA QUE NO SOPORTE 2 ESTADOS MAS
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
	add constraint check (n45_estado in ('A', 'P', 'E'))
		constraint "fobos".ck_01_rolt045;

--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--- QUITANDO NUEVO ENLACE CON LA rolt045 (CIRCULAR) PARA PRESTAMOS CON ESTADO
--- "T" TRANSFERIDO, CON SU NUEVO PRESTAMO "R" REDISTRIBUIDO.
--

drop index "fobos".i05_fk_rolt045;
alter table "fobos".rolt045 drop constraint "fobos".fk_05_rolt045;
drop index "fobos".i06_fk_rolt045;
alter table "fobos".rolt045 drop constraint "fobos".fk_06_rolt045;

drop index "fobos".i07_fk_rolt045;
alter table "fobos".rolt045 drop constraint "fobos".fk_07_rolt045;

alter table "fobos".rolt045 drop constraint "fobos".ck_02_rolt045;

alter table "fobos".rolt045 drop n45_tipo_pago;
alter table "fobos".rolt045 drop n45_bco_empresa;
alter table "fobos".rolt045 drop n45_cta_empresa;
alter table "fobos".rolt045 drop n45_cta_trabaj;

alter table "fobos".rolt045 drop n45_prest_tran;
alter table "fobos".rolt045 drop n45_sal_prest_ant;

drop table "fobos".rolt058;
drop table "fobos".rolt059;

--
--------------------------------------------------------------------------------

commit work;

drop table t1;
