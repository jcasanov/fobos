begin work;

	alter table "fobos".cxpt051
		add (p51_cod_tran			char(2)				before p51_usuario);

	alter table "fobos".cxpt051
		add (p51_num_tran			decimal(15,0)		before p51_usuario);

	alter table "fobos".cxpt051
		add (p51_val_impto			decimal(12,2)		before p51_valor);

	alter table "fobos".cxpt051
		add (p51_num_sri			char(21)			before p51_usuario);

	alter table "fobos".cxpt051
		add (p51_num_aut			varchar(51,10)		before p51_usuario);

	alter table "fobos".cxpt051
		add (p51_fec_emi_nc			date				before p51_usuario);

	alter table "fobos".cxpt051
		add (p51_fec_emi_aut		date				before p51_usuario);

	update cxpt051
		set p51_val_impto = p51_valor / 100 * 12
		where 1 = 1;

	alter table "fobos".cxpt051
		modify (p51_val_impto		decimal(12,2)		not null);

	create index "fobos".i05_pk_cxpt051
		on "fobos".cxpt051
			(p51_compania, p51_localidad, p51_cod_tran, p51_num_tran)
		in idxdbs;

	alter table "fobos".cxpt051
		add constraint
			(foreign key (p51_compania, p51_localidad,
							p51_cod_tran, p51_num_tran)
				references "fobos".rept019
				constraint "fobos".fk_05_cxpt051);

--rollback work;
commit work;
