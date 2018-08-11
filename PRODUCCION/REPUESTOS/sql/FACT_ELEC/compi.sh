echo " "
for i in *.4gl
	do
		if [ "$i" != "arr_mail_cli.4gl" ] &&
		   [ "$i" != "arr_mail_prov.4gl" ]; then
			echo "Compilando $i ..."
			fglpc $i
			echo " "
		fi
	done
echo " "
echo "Procesos compilados OK"
