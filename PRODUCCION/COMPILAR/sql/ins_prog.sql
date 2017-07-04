select * from source4gl where progname = 'XXX' into temp t1;
load from "source4gl.unl" insert into t1;
insert into source4gl
	select t1.* from t1
		where t1.progname not in
			(select source4gl.progname from source4gl);
select count(*) from source4gl;
drop table t1;
