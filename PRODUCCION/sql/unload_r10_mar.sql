unload to "desc_item_uio_mar.txt"
	select r10_codigo, r10_nombre, r10_marca from rept010
		where r10_compania = 1
		  --and r10_marca in ('ARMSTR', 'ALLEN', 'RIDGID')
		  and r10_marca = 'ALLEN'
		order by 3
