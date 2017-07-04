begin work;

update rept001
	set r01_estado = 'B'
	where r01_compania = 1
	  and r01_codigo   in (68, 73, 83, 64, 76, 74, 45);

update rept001
	set r01_tipo = 'E'
	where r01_compania = 1
	  and r01_codigo   = 77;

commit work;
