# Compila un modulo completo
# Parametros:
# ---> Modulo

export FOBOSPROD=/FOBOS/PRODUCCION
export FOBOSDESA=/FOBOS/DESARROLLO/PRODUCCION

cp $FOBOSDESA/$1/fuentes/*4gl $FOBOSPROD/$1/fuentes/.
cp $FOBOSDESA/$1/forms/*per $FOBOSPROD/$1/forms/.

cd $FOBOSPROD/$1/forms
for i in `ls *.per`
do
	fglform $i
done
rm -f $FOBOSPROD/$1/forms/*per

cd $FOBOSPROD/$1/fuentes
for j in `ls *.4gl`
do
	fglrun compilar $j
done
rm -f $FOBOSPROD/$1/fuentes/*4gl

cd $FOBOSPROD
