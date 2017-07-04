begin work;
	update rept010
		set r10_costo_mb    = 0.05,
		    r10_usu_cosrepo = 'FOBOS',
		    r10_fec_cosrepo = current
		where r10_compania  = 1
		  and r10_estado    = 'A'
		  and r10_costo_mb  = 0
		  and r10_marca    in ('KOHSAN', 'KOHGRI')
		  and date(r10_fec_cosrepo) >= mdy(03, 01, 2011);
commit work;
