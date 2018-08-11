begin work;

select * from ctbt012
	where b12_compania  = 2
	  and b12_tipo_comp = 'DC'
	  and b12_num_comp  = '06010001'
	into temp tmp_b12;

select * from ctbt013
	where b13_compania  = 2
	  and b13_tipo_comp = 'DC'
	  and b13_num_comp  = '06010001'
	into temp tmp_b13;

update tmp_b12
	set b12_num_comp    = '05120002',
	    b12_subtipo     = 9,
	    b12_fec_proceso = mdy(12, 31, 2005)
	where 1 = 1;

update tmp_b13
	set b13_num_comp    = '05120002',
	    b13_fec_proceso = mdy(12, 31, 2005)
	where 1 = 1;

insert into ctbt012 select * from tmp_b12;

insert into ctbt013 select * from tmp_b13;

drop table tmp_b12;

drop table tmp_b13;

commit work;
