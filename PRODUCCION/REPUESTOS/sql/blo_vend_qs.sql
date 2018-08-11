begin work;

update rept001
	set r01_estado = 'B'
	where r01_compania = 1
	  and r01_codigo   in (24, 19, 8, 2, 5, 34, 13, 33, 11, 14, 31);

update rept001
	set r01_tipo = 'E'
	where r01_compania = 1
	  and r01_codigo   = 3;

commit work;
