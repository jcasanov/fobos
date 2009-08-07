create table te_new_precios
       (te_item		char(15)	,
	te_nombre	varchar(40)	,
	te_fob		decimal(9,2),
	te_peso		decimal(9,3)	);

--create unique index pk_item on te_new_precios(te_item) in idxdbs;
--alter table te_new_precios add constraint (primary key (te_item));
