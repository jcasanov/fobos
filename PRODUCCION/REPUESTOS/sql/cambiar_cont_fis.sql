begin work;
delete from gent055 where g55_proceso in ('repp238', 'repp239');
insert into gent055
	select g55_user, g55_compania, g55_modulo, 'repp238', g55_usuario,
		g55_fecing
		from gent055
		where g55_proceso = 'cont_fis';
insert into gent055
	select g55_user, g55_compania, g55_modulo, 'repp239', g55_usuario,
		g55_fecing
		from gent055
		where g55_proceso = 'cont_fis2';
delete from gent055 where g55_proceso in ('cont_fis', 'cont_fis2');
delete from gent054 where g54_proceso in ('cont_fis', 'cont_fis2');
commit work;
