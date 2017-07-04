unload to "division.txt"
	select * from rept003
		where r03_compania = 1;
unload to "lineas.txt"
	select * from rept070
		where r70_compania = 1;
unload to "grupos.txt"
	select * from rept071
		where r71_compania = 1;
unload to "clases.txt"
	select * from rept072
		where r72_compania = 1;
unload to "marcas.txt"
	select * from rept073
		where r73_compania = 1;
unload to "codutil.txt"
	select * from rept077
		where r77_compania = 1;
unload to "medida.txt" select * from rept005 where 1 = 1;
unload to "capitulo.txt" select * from gent038 where 1 = 1;
unload to "partidas.txt" select * from gent016 where 1 = 1;
