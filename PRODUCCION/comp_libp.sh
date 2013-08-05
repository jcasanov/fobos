export FOBOSPROD=/FOBOS/PRODUCCION
export FOBOSDESA=/FOBOS/DESARROLLO/PRODUCCION

cp $FOBOSDESA/LIBRERIAS/fuentes/globales.4gl $FOBOSPROD/LIBRERIAS/fuentes/.
cp $FOBOSDESA/LIBRERIAS/fuentes/libp00?.4gl $FOBOSPROD/LIBRERIAS/fuentes/.
cp $FOBOSDESA/compilar.4gl $FOBOSPROD/.
cp $FOBOSDESA/LIBRERIAS/forms/*per $FOBOSPROD/LIBRERIAS/forms/.

cd $FOBOSPROD/LIBRERIAS/forms

for i in `ls *per`
do
	fglform $i
done
rm -f $FOBOSPROD/LIBRERIAS/forms/*per

cd $FOBOSPROD/LIBRERIAS/fuentes

for i in `ls libp00?.4gl`
do
	fgl2p $i
done
rm -f $FOBOSPROD/LIBRERIAS/fuentes/libp00?.4gl

cd $FOBOSPROD
fgl2p -o compilar.42r compilar.4gl
#rm -f compilar.4gl

for d in `ls`
do
	if [ -d $d ]; then
		if [ -d $d/fuentes ]; then
			cp $FOBOSPROD/LIBRERIAS/fuentes/libp00?.42m $FOBOSPROD/$d/fuentes/.
			cp $FOBOSPROD/compilar.42? $FOBOSPROD/$d/fuentes/.
		fi
	fi
done
