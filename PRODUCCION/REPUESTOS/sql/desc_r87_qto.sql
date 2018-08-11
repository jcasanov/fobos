unload to "rept087.unl"
	select rept087.* from rept087, rept010
		where r87_compania  = 1
		  and r87_localidad = 3
		  and r10_compania  = r87_compania
		  and r10_codigo    = r87_item
		  and r10_marca not in('EDESA', 'ECERAM', 'FVGRIF', 'FVSANI',
                                        'KERAMI', 'PLYCEM', 'RIALTO', 'MICHEL',
                                        'ROOFTE', 'CREIN ');
