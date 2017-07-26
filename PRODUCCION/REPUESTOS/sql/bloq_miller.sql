select r10_compania, r10_estado, count(*) tot_item
	from rept010
	where r10_compania in (1, 2)
	  and r10_marca    = 'MILLER'
	group by 1, 2;
begin work;
	update rept010
		set r10_estado = 'B',
		    r10_feceli = CURRENT	-- 17/05/2007
		where r10_compania in (1, 2)
		  and r10_estado   = 'A'
		  and r10_marca    = 'MILLER';
commit work;
