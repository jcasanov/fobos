begin work;

	delete from actt015 where 1 = 1;
	delete from actt014 where 1 = 1;
	delete from actt013 where 1 = 1;
	delete from actt012 where 1 = 1;
	delete from actt011 where 1 = 1;
	delete from actt010 where 1 = 1;

	load from "actt010_gm.unl" insert into actt010;
	load from "actt011_gm.unl" insert into actt011;
	load from "actt012_gm.unl" insert into actt012;
	load from "actt013_gm.unl" insert into actt013;
	load from "actt014_gm.unl" insert into actt014;
	load from "actt015_gm.unl" insert into actt015;

	update actt000
		set a00_anopro = 2011,
		    a00_mespro = 1
		where 1 = 1;

commit work;
