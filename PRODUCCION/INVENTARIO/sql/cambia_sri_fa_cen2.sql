--rollback work;
begin work;
select r38_num_sri
	from rept038
	where r38_num_sri[5,7]    = '002'
	  and r38_num_sri[13,15] >= '701';
update rept038
	set r38_num_sri = r38_num_sri[1,2] || '9' || r38_num_sri[4,15]
	where r38_num_sri[5,7]    = '002'
	  and r38_num_sri[13,15] >= '701';
select r38_num_sri
	from rept038
	where r38_num_sri[5,7]    = '002'
	  and r38_num_sri[13,15] >= '701';
commit work;
