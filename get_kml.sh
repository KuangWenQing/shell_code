#!/bin/bash

if [ $# -ne 1 ]
then
	echo "please input the dir"
	exit 1
fi
echo '--------- Now deal with the directory -- '"'$1'"
old_path=`pwd`
cd $1

path=`pwd`
echo $path
ls
echo ''
if [ ! -d "./nmea" ]; then
	mkdir nmea
	for file in `ls *.log *.ubx *.DAT`
	do
		if [ ${file##*.} == "ubx" ]
		then
			grep -a "GGA," $file > nmea/${file%.*}".gga"
			`cat -v nmea/${file%.*}".gga" > nmea/${file%.*}".tmp"`	# 二进制转字符串
			`awk 'BEGIN{FS="GGA,"} {print $2}' nmea/${file%.*}".tmp" > nmea/${file%.*}".gga"`

			rm nmea/${file%.*}".tmp"
			sed -i "s/^/\$GPGGA,/" nmea/${file%.*}".gga"
		#	sed -i "s/^\(.*\)\$GN/\$GP/" nmea/${file%.*}".gga"
			
			grep -Ea "GGA|RMC" $file | grep -Ea ",A,|E,1" > nmea/${file%.*}".rmcgga"
			`cat -v nmea/${file%.*}".rmcgga" > nmea/${file%.*}".tmp"`
			`awk 'BEGIN{FS="GN|GP"} {print $2}' nmea/${file%.*}".tmp" > nmea/${file%.*}".rmcgga"`

			rm nmea/${file%.*}".tmp"
			sed -i "s/^/\$GP/" nmea/${file%.*}".rmcgga"
		else
			grep -a "E,1," $file | grep "KF" > nmea/${file%.*}"_KF.gga"
			grep -a "E,1," $file | grep ",\*" | grep -v 'GPGFM' > nmea/${file%.*}"_noKF.gga"
			grep -a "E,1," $file | grep "GPGFM," > nmea/${file%.*}"_GFM.gga"
			sed -i "s/\r//g;s/ok//g" nmea/${file%.*}"_noKF.gga"
			sed -i "s/ok//g" nmea/${file%.*}"_KF.gga"
                        sed -i "s/GPGFM/GPGGA/" nmea/${file%.*}"_GFM.gga"
		fi
	done
fi
echo -e "--------- get nmea(gga) files successfully -------------\n"
#exit 1

if [ "$F9P_file" =  "" ]; then
	 F9P_file='noF9P'
fi

/home/kwq/project/py/data_handle/AVE_ALL_to_GGA.py $path'/' $F9P_file
/home/kwq/project/py/data_handle/get_nomal_gga.py $path'/' $F9P_file
mv *.gga ./nmea

rm kml -rf
mkdir kml

# 注意，用了通配符寻找相应文件， $file  的值会带上文件夹 nmea/
for file in `ls nmea/*.gga`
do
	# file_len=`wc -c 'nmea/'$file | awk '{print $1}'`
	file_len=`wc -c $file | awk '{print $1}'`
	if [ $file_len -eq 0 ];
        then
		rm $file
	else
		echo "transformation $file 			to kml"
		# /home/jqiu/nmea2kml.py "nmea/"$file > 'kml/'${file%.*}".kml"
		tmp_var=${file%.*}
		/home/kwq/project/py/gga2kml/nmea2kml.py $file > 'kml/'${tmp_var#*/}".kml"
	fi
done
echo -e "--------- get kml files successfully --------------\n"

