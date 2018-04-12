begin work;

	insert into srit000
		select * from jadesa:srit000;

	insert into srit001
		select * from jadesa:srit001;

	insert into srit002
		select * from jadesa:srit002;

	insert into srit003
		select * from jadesa:srit003;

	insert into srit004
		select * from jadesa:srit004;

	insert into srit005
		select * from jadesa:srit005;

	insert into srit006
		select * from jadesa:srit006;

	insert into srit008
		select * from jadesa:srit008;

	insert into srit009
		select * from jadesa:srit009;

	insert into srit010
		select * from jadesa:srit010;

	insert into srit012
		select * from jadesa:srit012;

	insert into srit014
		select * from jadesa:srit014;

	insert into srit018
		select * from jadesa:srit018;

	insert into srit019
		select * from jadesa:srit019;

	insert into srit020
		select * from jadesa:srit020;

	select * from jadesa:srit023
		into temp t1;

	update t1
		set s23_usuario = 'FOBOS'
		where 1 = 1;

	insert into srit023
		select * from t1;

	drop table t1;

	insert into srit026
		select * from jadesa:srit026;

--rollback work;
commit work;
