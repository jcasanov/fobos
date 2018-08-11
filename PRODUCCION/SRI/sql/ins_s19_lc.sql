begin work;

	insert into cxct004
		(z04_tipo_doc, z04_nombre, z04_estado, z04_tipo, z04_usuario,
		 z04_fecing)
		values ("LC", "LIQ. COMPRA", "A", "D", "FOBOS", current);

	insert into srit019
		(s19_compania, s19_sec_tran, s19_cod_ident, s19_tipo_comp, s19_tipo_doc)
		values (1, '01', 'R', 3, 'LC');

	insert into srit019
		(s19_compania, s19_sec_tran, s19_cod_ident, s19_tipo_comp, s19_tipo_doc)
		values (1, '02', 'C', 3, 'LC');

--rollback work;
commit work;
