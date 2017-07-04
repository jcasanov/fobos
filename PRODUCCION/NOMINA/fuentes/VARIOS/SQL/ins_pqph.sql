begin work;

	delete from rolt010
		where n10_cod_rubro in (54, 62);

	insert into rolt010
		select * from acero_gm@idsgye01:rolt010
			where n10_cod_rubro in (54, 62);

commit work;
