begin work;

	delete from rept047
		where r47_compania    = 1
		  and r47_localidad   = 1
		  and r47_bodega_part = "EF"
		  and r47_item_part   = "100835";

--rollback work;
commit work;
