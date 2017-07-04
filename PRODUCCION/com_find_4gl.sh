ls -lt `find ./*/fuentes/ -name "???p???.4gl" -print` | grep "$1" | grep -v " 201[0-9]" | sed "s/^.* \./\./"

ls -lt `find ./*/forms/ -name "???f???*.per" -print` | grep "$1" | grep -v " 201[0-9]" | sed "s/^.* \./\./"
