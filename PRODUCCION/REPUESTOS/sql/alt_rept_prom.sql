begin work;

	alter table "fobos".rept019
		modify (r19_descuento	decimal(5,2)		not null);

	alter table "fobos".rept020
		modify (r20_descuento	decimal(5,2)		not null);

	alter table "fobos".rept021
		modify (r21_descuento	decimal(5,2)		not null);

	alter table "fobos".rept022
		modify (r22_porc_descto	decimal(5,2)		not null);

	alter table "fobos".rept023
		modify (r23_descuento	decimal(5,2)		not null);

	alter table "fobos".rept024
		modify (r24_descuento	decimal(5,2)		not null);

	alter table "fobos".rept077
		modify (r77_desc_promo	decimal(5,2)		not null);

--rollback work;
commit work;
