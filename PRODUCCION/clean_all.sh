for i in `ls`
do
	if [ -d $i ]; then
		if [ -d $i/fuentes ]; then
			rm -f $i/fuentes/*.42r
			rm -f $i/fuentes/*.42m
			rm -f $i/fuentes/*.sch
			rm -f $i/fuentes/*.err
		fi
		if [ -d $i/forms ]; then
			rm -f $i/forms/*.42f
			rm -f $i/forms/*.sch
			rm -f $i/forms/*.err
		fi
		if [ -d $i/sql ]; then
			rm -f $i/sql/*.42f
			rm -f $i/sql/*.42r
			rm -f $i/sql/*.42m
			rm -f $i/sql/*.sch
			rm -f $i/sql/*.err
		fi
		if [ -d $i/varios ]; then
			rm -f $i/varios/*.42f
			rm -f $i/varios/*.42r
			rm -f $i/varios/*.42m
			rm -f $i/varios/*.sch
			rm -f $i/varios/*.err
		fi
	fi
done
