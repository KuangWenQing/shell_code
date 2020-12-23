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
echo $path
if [ ! -d "./nmea" ]; then
	mkdir nmea
	for file in `ls *.log *.ubx *.DAT`
	do
		if [ ${file##*.} == "ubx" ]
		then
			grep -a "E,1," $file > nmea/${file%.*}".nmea"
			`awk 'BEGIN{FS="GGA,"} {print $2}' nmea/${file%.*}".nmea" > nmea/${file%.*}".tmp"`
			`cat -v nmea/${file%.*}".tmp" > nmea/${file%.*}".nmea"`
			rm nmea/${file%.*}".tmp"
			sed -i "s/^/\$GPGGA,/" nmea/${file%.*}".nmea"
		#	sed -i "s/^\(.*\)\$GN/\$GP/" nmea/${file%.*}".nmea"
		else
			grep -a "E,1," $file | grep "KF" > nmea/${file%.*}"_KF.nmea"
			grep -a "E,1," $file | grep ",\*" | grep -v 'GPGFM' > nmea/${file%.*}"_noKF.nmea"
			grep -a "E,1," $file | grep "GPGFM," > nmea/${file%.*}"_GFM.nmea"
			sed -i "s/\r//g;s/ok//g" nmea/${file%.*}"_noKF.nmea"
			sed -i "s/ok//g" nmea/${file%.*}"_KF.nmea"
                        sed -i "s/GPGFM/GPGGA/" nmea/${file%.*}"_GFM.nmea"
		fi
	done
fi
echo -e "--------- get nmea(gga) files successfully -------------\n"

if [ "$F9P_file" =  "" ]; then
	 F9P_file='noF9P'
fi

/home/jqiu/PycharmProjects/data_handle/AVE_ALL_to_GGA.py $path'/' $F9P_file
/home/jqiu/PycharmProjects/data_handle/get_nomal_gga.py $path'/' $F9P_file
mv *.gga ./nmea

/home/jqiu/PycharmProjects/data_handle/header_file.py $path'/' $F9P_file

rm kml -rf
mkdir kml
for file in `ls nmea/`
do
	file_len=`wc -c 'nmea/'$file | awk '{print $1}'`
	if [ $file_len -eq 0 ];
        then
		rm 'nmea/'$file
	else
		echo "transformation $file 			to kml"
		/home/jqiu/nmea2kml.py "nmea/"$file > 'kml/'${file%.*}".kml"
	fi
done
echo -e "--------- get kml files successfully --------------\n"

cd kml
M8T_file=$(ls -l *M8T.kml | awk '{print $9}')
if [ "$M8T_file" =  "" ]; then
	echo 'M8T file does not exist'
else
	sed -i '$d' $M8T_file	# delete "</Document>"
	sed -i '$d' $M8T_file	# delete "</kml>"
fi
cd ..


for file in `ls *.log`
do
	echo $file
	final_xyz=`grep -a "DEBUG R AVE, tot" $file | tail -n 1`
	if [ -n "$final_xyz" ]; then
		echo $final_xyz
	
		if [ "$M8T_file" =  "" ]; then
			/home/jqiu/PycharmProjects/data_handle/analysis_final_pos.py $path'/' $F9P_file "$final_xyz"
		else
			/home/jqiu/PycharmProjects/data_handle/add_pos_to_kml.py $path'/' $F9P_file "$final_xyz" $M8T_file $file
		fi
	fi
done

if [ -n "$M8T_file" ]; then
	echo '</Document>' >> 'kml/'$M8T_file
	echo '</kml>' >> 'kml/'$M8T_file
fi

