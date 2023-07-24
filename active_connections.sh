#!/bin/bash

## Info, display at the first time 
## or when its run with -h
function show_info {
    clear
    echo "======= Active Connection ============"
    echo ""
    echo "Display every 2 seconds active connection"
    echo "with Application name, IP Address and Location"
    echo 
    echo "Available opctions:"
    echo "- select application"
    echo "- change view details with ports/location"
    echo ""
    echo "Press ENTER to continue"
    read X
    clear
    echo "Wait..."

    }

## Function to grep all application names
function get_app_names {
    lsof -i | grep -E "(LISTEN|ESTABLISHED)" | cut -d" " -f1 | sort | uniq > .cache/app_names_tmp.lst
    let i=1
    > .cache/app_names.lst
    while read l;
	do
	echo " $i-$l" >> .cache/app_names.lst
	let i=i+1
	done < .cache/app_names_tmp.lst
    rm -rf .cache/app_names_tmp.lst
    }


## Funciton to display parsed connections
function print_connections {

    prev=`cat .cache/prev_num_lines`
    dt=`cat .cache/display_type`
    lsof -i | grep -E "(LISTEN|ESTABLISHED)" | grep "$1" > .cache/connections_tmp
    > .cache/connections.lst
    while read l;
	do
	if [ "$dt" == "g" ]
	    then
	    line=`echo $l | awk '{print $2" "$1" "$3" "$5" "$8" "$9}' | awk -F">" '{print $1" "$2}' | rev | cut -d":" -f2-100 | rev | awk '{print $1" "$2" "$3" "$4" "$5" "$7}'` 
	    IP=`echo $l | awk -F">" '{print $2}' | rev | cut -d":" -f2-100 | rev | awk '{print $1}'`
	    if [ ! -f .cache/"_${IP}" ]
		then
		whois $IP > .cache/_${IP}
		fi
	    country=`cat .cache/_${IP} | grep Country | cut -d":" -f2 | xargs`
	    city=`cat .cache/_${IP} | grep City | cut -d":" -f2 | xargs`
	    address=`cat .cache/_${IP} | grep Address | cut -d":" -f2 | xargs`
	    if [ "$address" == "" ]
		then
		address=`cat .cache/_${IP} | grep address | cut -d":" -f2 | xargs`
		fi
	    echo $line" ====> "$country" "$city" "$address"">> .cache/connections.lst
	    
	    fi
	if [ "$dt" == "p" ]
	    then
	    echo $l | awk '{print $2" "$1" "$3" "$5" "$8" "$9}' >> .cache/connections.lst
	    fi
	done < .cache/connections_tmp

    clear
    cat .cache/info.txt
    echo 
    cat .cache/app_names.lst
    echo ""
    date=`date '+%Y-%m-%d_%H:%M:%S'`
    echo "===================="$date"======================"
    echo ""
    cat .cache/connections.lst | sort | uniq
    }


## first run
## create cache directory and show info
if [ ! -d .cache ]
    then
    show_info
    mkdir .cache
    fi

## display help
if [ "$1" == "-h" ]
    then
    show_into
    fi

## header
echo " q-Quit, VIEW: g-Geolocation, p-Ports " > .cache/info.txt


get_app_names
head -n1 .cache/app_names.lst | cut -d "-" -f2-10 > .cache/app_name
echo "g" > .cache/display_type

app_name=`cat .cache/app_name`


## Main loop
while [ 1 = 1 ]
    do
    app_name=`cat .cache/app_name`
    print_connections "$app_name"
    
    total=3
    count=0
    echo -e "\n\rSelect value and press ENTER: \c"
    read -t 2 name
    #test ! -z "$name"
    if [ ! -z "$name" ]
	then
	## check if variable is not digit
	re='^[0-9]+$'
	if ! [[ $name =~ $re ]]
	    then
	    if [ "$name" == "q" ]
		then
		echo "Bye"
		exit 0
		fi
	    if [ "$name" == "d" ] || [ "$name" == "g" ]
		then
		echo "$name" > .cache/display_type
		fi
	    else
	    ## if is digit, change monitoring application
	    cat .cache/app_names.lst | grep " ${name}-" | cut -d "-" -f2-10 > .cache/app_name
	    fi
	fi

    done
