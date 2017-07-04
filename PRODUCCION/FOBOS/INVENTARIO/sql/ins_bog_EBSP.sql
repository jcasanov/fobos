begin work;

	delete from acero_gm@idsgye01:rept011
		where r11_compania = 1
		  and r11_bodega   in ('EB', 'SP');

	insert into acero_gm@idsgye01:rept011
		select * from acero_qm@idsuio01:rept011
			where r11_compania = 1
			  and r11_bodega   in ('EB', 'SP');

--rollback work;
commit work;
