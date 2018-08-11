export arch1=anu_ir_proy.sql
export arch2=sel_din_ir.sql

##----------------------------------------------------------------------------##
sed "1,$ s/\<mes_p\>/$3/g" $arch1 > temporal1

sed "1,$ s/anio_p/$2/g" temporal1 > temporal2

sed "1,$ s/mes_l/$3$4/g" temporal2 > temporal1.sql
##----------------------------------------------------------------------------##


##----------------------------------------------------------------------------##
sed "1,$ s/\<mes_p\>/$3/g" $arch2 > temporal1

sed "1,$ s/anio_p/$2/g" temporal1 > temporal2

sed "1,$ s/mes_l/$3$4/g" temporal2 > temporal2.sql
##----------------------------------------------------------------------------##


##----------------------------------------------------------------------------##
time dbaccess $1 temporal1.sql
time dbaccess $1 temporal2.sql
##----------------------------------------------------------------------------##

rm temporal1*
rm temporal2*
