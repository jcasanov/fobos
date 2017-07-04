update rept010
	set r10_filtro = "OTRAS MARC"
	where r10_compania = 1
	  and r10_filtro   in ("XIAMEN", "IPAC");
