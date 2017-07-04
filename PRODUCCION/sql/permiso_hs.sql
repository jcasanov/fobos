{
delete from acero_qm:gent055 where g55_user = 'HSALAZAR';
insert into acero_qm:gent055
	select * from gent055 where g55_user = 'HSALAZAR'
	  and g55_proceso not in('cont_fis', 'menp000c', 'menp004',
		'menp004c', 'repp555', 'repp236', 'rolp305', 'repp235');

}
select a.g54_proceso, b.g54_proceso from gent054 a, outer acero_qm:gent054 b
	where a.g54_proceso = b.g54_proceso
	order by 2
