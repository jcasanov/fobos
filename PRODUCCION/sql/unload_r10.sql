unload to "desc_item_gye_mar.txt"
	select r10_codigo, r10_nombre, r10_marca
		from rept010
		where r10_compania = 1
		  --and r10_marca in ('RIDGID', 'ARMSTR', 'ALLEN');
		  and r10_marca in ('ALLEN');
