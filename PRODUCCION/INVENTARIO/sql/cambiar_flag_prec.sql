begin work;

update rept010 set r10_cantveh = 0 where 1 = 1;

update rept010 set r10_cantveh = 1
	where r10_compania = 1
	  and r10_marca in ('CREIN', 'ECERAM', 'EDESA', 'FVGRIF', 'FVSAM',
				'KERAMI','KOHSAN', 'KOHGRI', 'MATEX','MICHEL',
				'PLYCEM', 'RIALTO', 'ROOFTE', 'SAKUME');

update rept010 set r10_cantveh = 1
	where r10_compania  = 1
	  and r10_marca     = 'NACION'
	  and r10_cod_clase in ('101.P250', '102.P060', '102.P080');

commit work;
