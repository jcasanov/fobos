export LD_ASSUME_KERNEL=2.4.0

#fgl2p -O -o recosteo.42r recosteo.4gl libp000.42m libp001.42m

for i in *.4gl
do
	fglpc $i
done

echo 'Programas Compilados OK.'
