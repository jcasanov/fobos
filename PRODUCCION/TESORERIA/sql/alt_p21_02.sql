begin work;

	alter table "fobos".cxpt021
		add (p21_val_impto			decimal(12,2)		before p21_valor);

	alter table "fobos".cxpt021
		add (p21_num_sri			char(21)			before p21_usuario);

	alter table "fobos".cxpt021
		add (p21_num_aut			varchar(51,10)		before p21_usuario);

	alter table "fobos".cxpt021
		add (p21_fec_emi_nc			date				before p21_usuario);

	alter table "fobos".cxpt021
		add (p21_fec_emi_aut		date				before p21_usuario);

	update cxpt021
		set p21_val_impto = p21_valor / 100 * 12
		where 1 = 1;

	alter table "fobos".cxpt021
		modify (p21_val_impto		decimal(12,2)		not null);

--rollback work;
commit work;
