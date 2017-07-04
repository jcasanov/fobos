directorio=$1
distintos=`grep "distintos: " $directorio/compara_todo.log|cut -f 2 -d":"`
i=0
total=0
for i in $distintos;
do
        total=`echo "$total + $i"|bc -l`
done
echo $total
