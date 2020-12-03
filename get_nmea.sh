#!/bin/bash

if [ $# -ne 1 ]
then
	echo "please input the dir"
	exit 1
fi
echo '--------- Now deal with the directory -- '"'$1'"

cd $1
if [ ! -d "./chart" ]; then
	mkdir chart
fi

for file in `ls *_F9P.ubx`
do
	F9P_file=${file%.*}".txt"
	if [ ! -f "$F9P_file" ]; then
		/home/jqiu/share/a.out $file > ${file%.*}".txt"
	fi
done
echo -e "--------- transformation ubx file to txt successful ---------------\n"

path=`pwd`

if [ ! -d "./nmea" ]; then
	mkdir nmea
	for file in `ls *.log *.ubx *.DAT`
	do
		if [ ${file##*.} == "ubx" ]
		then
			grep "E,1," $file -a > nmea/${file%.*}".tmp"
			`awk 'BEGIN{FS="GGA,"} {print $2}' nmea/${file%.*}".tmp" > nmea/${file%.*}".nmea"`
			rm nmea/${file%.*}".tmp"
			sed -i "s/^/\$GPGGA,/" nmea/${file%.*}".nmea"
		#	sed -i "s/^\(.*\)\$GN/\$GP/" nmea/${file%.*}".nmea"
		elif [ ${file##*.} == "DAT" ]
		then
			grep "E,1," $file | grep "KFP" > nmea/${file%.*}"_KF.nmea"
                        grep "E,1," $file | grep "GGA" > nmea/${file%.*}"_noKF.nmea"
                        sed -i "s/\r//g;s/ok//g" nmea/${file%.*}"_noKF.nmea"
                        sed -i "s/ok//g" nmea/${file%.*}"_KF.nmea"
		else
			grep "E,1," $file | grep "KF" > nmea/${file%.*}"_KF.nmea"
			grep "E,1," $file | grep ",\*" > nmea/${file%.*}"_noKF.nmea"
			sed -i "s/\r//g;s/ok//g" nmea/${file%.*}"_noKF.nmea"
			sed -i "s/ok//g" nmea/${file%.*}"_KF.nmea"
		fi
	done
fi
echo -e "--------- get nmea(gga) files successfully -------------\n"
/home/jqiu/PycharmProjects/data_handle/AVE_ALL_to_GGA.py $path'/' $F9P_file
mv *.gga ./nmea

/home/jqiu/PycharmProjects/data_handle/header_file.py $path'/' $F9P_file

rm kml -rf
mkdir kml
for file in `ls nmea/`
do
	/home/jqiu/nmea2kml.py "nmea/"$file > kml/${file%.*}".kml"
done
cd kml
for file in `ls *M8T.kml`
do
	sed -i '$d' $file	# delete "</Document>"
	sed -i '$d' $file	# delete "</kml>"
done
cd ..
echo -e "--------- get kml files successfully --------------\n"

cd kml
M8T_file=$(ls -l *_M8T.kml | awk '{print $9}')
cd ..


for file in `ls *.log`
do
	echo $file
	final_xyz=`grep "DEBUG R AVE, tot" -a $file | tail -n 1`
	if [ "$M8T_file" =  "" ]; then
		/home/jqiu/PycharmProjects/data_handle/analysis_final_pos.py $path'/' $F9P_file "$final_xyz"
	else
		/home/jqiu/PycharmProjects/data_handle/add_pos_to_kml.py $path'/' $F9P_file "$final_xyz" $M8T_file $file
	fi
done

if [ -n "$M8T_file" ]; then
	echo '</Document>' >> 'kml/'$M8T_file
	echo '</kml>' >> 'kml/'$M8T_file
fi
