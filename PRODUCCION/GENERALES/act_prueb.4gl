database aceros



main

	call actualiza()

end main



function actualiza()

begin work

update gent056 set g56_base_datos = 'aceros' where g56_base_datos = 'acero_gm'
update gent051 set g51_default    = 'N'      where g51_basedatos  = 'acero_gm'
update gent051 set g51_default    = 'S'      where g51_basedatos  = 'aceros'

update gent002 set g02_abreviacion = 'PRUEBA JTM'
	where g02_compania  = 1
	  and g02_localidad = 1

commit work

display 'Actualizada la Base de Prueba. Ok'

end function
