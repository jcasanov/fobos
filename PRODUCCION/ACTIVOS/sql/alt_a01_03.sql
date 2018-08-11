begin work;

alter table "fobos".actt001
	add (a01_aux_transf	char(12)	before a01_paga_iva);

create index "fobos".i11_fk_actt001
	on "fobos".actt001
		(a01_compania, a01_aux_transf)
	in idxdbs;

alter table "fobos".actt001
	add constraint
		(foreign key (a01_compania, a01_aux_transf)
			references "fobos".ctbt010
			constraint "fobos".fk_11_actt001);

insert into ctbt010
	(b10_compania, b10_cuenta, b10_descripcion, b10_descri_alt, b10_estado,
	 b10_tipo_cta, b10_tipo_mov, b10_nivel, b10_cod_ccosto, b10_saldo_ma,
	 b10_usuario, b10_fecing)
	values (1, '12010108', 'C.T. TRANSFERENCIAS DE ACTIVOS FIJOS', null,
		'A', 'B', 'D', 5, null, 'N', 'FOBOS', current);

insert into ctbt010
	(b10_compania, b10_cuenta, b10_descripcion, b10_descri_alt, b10_estado,
	 b10_tipo_cta, b10_tipo_mov, b10_nivel, b10_cod_ccosto, b10_saldo_ma,
	 b10_usuario, b10_fecing)
	values (1, '12010108001', 'C.T. TRANSF. ACTIVOS FIJOS ACERO UIO-JTM',
		null, 'A', 'B', 'D', 6, null, 'N', 'FOBOS', current);

update actt001
	set a01_aux_transf = '12010108001'
	where 1 = 1;

commit work;
