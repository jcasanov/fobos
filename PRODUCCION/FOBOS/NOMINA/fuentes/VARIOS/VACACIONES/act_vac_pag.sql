--rollback work;

begin work;

--------------------------------------------------------------------------------
drop index "fobos".i01_fk_rolt040;
alter table "fobos".rolt040 drop constraint "fobos".fk_01_rolt040;

drop index "fobos".i01_fk_rolt057;
alter table "fobos".rolt057 drop constraint "fobos".fk_01_rolt057;

drop index "fobos".i01_fk_rolt047;
alter table "fobos".rolt047 drop constraint "fobos".fk_01_rolt047;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
select n39_compania cia, n39_proceso proc, n39_cod_trab cod_t, n39_periodo_ini
	per_i, n39_periodo_fin per_f
	from rolt039
	where n39_proceso = 'VA'
	  and n39_tipo    = 'P'
	into temp tmp_vac;
select count(*) tot_v_p from tmp_vac;
update "fobos".rolt091
	set n91_proc_vac = 'VP'
	where exists (select * from tmp_vac
			where n91_compania    = cia
			  and n91_proc_vac    = proc
			  and n91_cod_trab    = cod_t
			  and n91_periodo_ini = per_i
			  and n91_periodo_fin = per_f);
update "fobos".rolt057
	set n57_proceso = 'VP'
	where exists (select * from tmp_vac
			where n57_compania    = cia
			  and n57_proceso     = proc
			  and n57_cod_trab    = cod_t
			  and n57_periodo_ini = per_i
			  and n57_periodo_fin = per_f);
update "fobos".rolt047
	set n47_proceso = 'VP'
	where exists (select * from tmp_vac
			where n47_compania    = cia
			  and n47_proceso     = proc
			  and n47_cod_trab    = cod_t
			  and n47_periodo_ini = per_i
			  and n47_periodo_fin = per_f);
update "fobos".rolt040
	set n40_proceso = 'VP'
	where exists (select * from tmp_vac
			where n40_compania    = cia
			  and n40_proceso     = proc
			  and n40_cod_trab    = cod_t
			  and n40_periodo_ini = per_i
			  and n40_periodo_fin = per_f);
update "fobos".rolt039
	set n39_proceso = 'VP'
	where exists (select * from tmp_vac
			where n39_compania    = cia
			  and n39_proceso     = proc
			  and n39_cod_trab    = cod_t
			  and n39_periodo_ini = per_i
			  and n39_periodo_fin = per_f);
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
create index "fobos".i01_fk_rolt040 on "fobos".rolt040
	(n40_compania, n40_proceso, n40_cod_trab, n40_periodo_ini,
		n40_periodo_fin)
	in idxdbs;

alter table "fobos".rolt040
	add constraint (foreign key (n40_compania, n40_proceso, n40_cod_trab,
				n40_periodo_ini, n40_periodo_fin)
			references "fobos".rolt039
			constraint "fobos".fk_01_rolt040);
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
create index "fobos".i01_fk_rolt047 on "fobos".rolt047
	(n47_compania, n47_proceso, n47_cod_trab, n47_periodo_ini,
		n47_periodo_fin)
	in idxdbs;

alter table "fobos".rolt047
	add constraint (foreign key (n47_compania, n47_proceso, n47_cod_trab,
				n47_periodo_ini, n47_periodo_fin)
			references "fobos".rolt039
			constraint "fobos".fk_01_rolt047);
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
create index "fobos".i01_fk_rolt057 on "fobos".rolt057
	(n57_compania, n57_proceso, n57_cod_trab, n57_periodo_ini,
		n57_periodo_fin)
	in idxdbs;

alter table "fobos".rolt057
	add constraint (foreign key (n57_compania, n57_proceso, n57_cod_trab,
				n57_periodo_ini, n57_periodo_fin)
			references "fobos".rolt039
			constraint "fobos".fk_01_rolt057);
--------------------------------------------------------------------------------

commit work;
