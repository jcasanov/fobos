begin work;

	alter table "fobos".rolt091
		add (n91_saldo_pend	decimal(12,2)	before n91_valor_ant);

	update rolt091
		set n91_saldo_pend = 0.00
		where 1 = 1;

	alter table "fobos".rolt091
		modify (n91_saldo_pend	decimal(12,2)	not null);

commit work;
