begin work;

	alter table "fobos".ordt013
		add (c13_fec_aut char(14) before c13_usuario);

commit work;
