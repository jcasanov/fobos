begin work;

	alter table "fobos".gent037
		modify (g37_autorizacion		varchar(51,10)		not null);

	alter table "fobos".ordt013
		modify (c13_num_aut				varchar(51,10)		not null);

	alter table "fobos".cxpt001
		modify (p01_num_aut				varchar(51,10));

	alter table "fobos".rept095
		modify (r95_autoriz_sri			varchar(51,10)		not null);

--rollback work;
commit work;
