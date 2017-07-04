begin work;

	update rept010
		set r10_filtro = "MARK"
		where r10_compania = 1
		  and r10_marca    in ("MARKPE", "MARKGR");

commit work;
