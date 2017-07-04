begin work;

insert into gent005
	select * from acero_gm:gent005
		where g05_usuario = 'HSALAZAR';

insert into gent052
	select * from acero_gm:gent052
		where g52_usuario = 'HSALAZAR';

insert into gent053
	select * from acero_gm:gent053
		where g53_usuario = 'HSALAZAR';

insert into gent055
	select g55_user, g55_compania, g55_modulo, g55_proceso, 'FOBOS',current
		from acero_gm:gent055
		where g55_user     = 'HSALAZAR'
		  and g55_compania = 1
		  and g55_proceso in
			(select g54_proceso from acero_qm:gent054
				where g54_estado <> 'B');

insert into gent007
	select g07_user, g07_impresora, g07_default, 'FOBOS', current
		from acero_gm:gent007
		where g07_user      = 'HSALAZAR'
		  and g07_impresora in
			(select g06_impresora from acero_qm:gent006);

commit work;
