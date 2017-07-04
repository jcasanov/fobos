begin work;

unload to "cambio_cuenta_ant_qto.unl" select * from ctbt041;

select * from ctbt041 order by b41_localidad, b41_modulo;

update ctbt041 set b41_ant_mb = '11210101005',
		   b41_ant_me = '11210101005'
	where b41_ant_mb = '11210104003'
	  and b41_ant_me = '11210104003';

select * from ctbt041 order by b41_localidad, b41_modulo;

commit work;
