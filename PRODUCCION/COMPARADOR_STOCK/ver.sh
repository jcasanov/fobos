sed "1,$ s/@@CODIGO@@/$1/g" verstock.sql > x.sql
echo "ACERO QM"
dbaccess acero_qm x.sql 2> /dev/null
echo "ACERO QS"
dbaccess acero_qs x.sql 2> /dev/null
rm x.sql

