--rollback work;
begin work;
select r38_num_sri
	from rept038
	where r38_num_sri[11,15] >= '33703';
update rept038
	set r38_num_sri = r38_num_sri[1,6] || '2' || r38_num_sri[8,15]
	where r38_num_sri[11,15] >= '33703';
select r38_num_sri
	from rept038
	where r38_num_sri[11,15] >= '33703';
commit work;
