select * from talt005
	where t05_tipord in ('T', 'R')
	into temp tmp_tip;

select * from talt006
	where t06_subtipo in ('T', 'R')
	into temp tmp_sub;

update tmp_tip
	set t05_tipord = '1'
	where t05_tipord = 'T';

update tmp_tip
	set t05_tipord = '2'
	where t05_tipord = 'R';

update tmp_sub
	set t06_subtipo = '1',
	    t06_tipord  = '1'
	where t06_subtipo = 'T';

update tmp_sub
	set t06_subtipo = '2',
	    t06_tipord  = '2'
	where t06_subtipo = 'R';

begin work;

	insert into talt005
		select * from tmp_tip;

	insert into talt006
		select * from tmp_sub;

	update talt023
		set t23_tipo_ot    = '1',
		    t23_subtipo_ot = '1'
		where t23_compania = 1
		  and t23_tipo_ot  = 'T';

	update talt023
		set t23_tipo_ot    = '2',
		    t23_subtipo_ot = '2'
		where t23_compania = 1
		  and t23_tipo_ot  = 'R';

	update talt040
		set t40_tipo_orden = '1'
		where t40_compania   = 1
		  and t40_tipo_orden = 'T';

	update talt040
		set t40_tipo_orden = '2'
		where t40_compania   = 1
		  and t40_tipo_orden = 'R';

	delete from talt006
		where t06_subtipo in ('T', 'R');

	delete from talt005
		where t05_tipord in ('T', 'R');

--rollback work;
commit work;

drop table tmp_tip;

drop table tmp_sub;
