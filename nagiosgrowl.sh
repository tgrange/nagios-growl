# Requires growlnotify 1.2.2
#index for the data to get back found here --  http://roshamboot.org/main/?p=74


HOST=""
USER=""
PASS=""

STATUS_PATH="/nagios/cgi-bin/status.cgi"
SCRIPT_PATH=""
GROWLNOTIFY="/usr/local/Cellar/growlnotify/1.2.2/bin/growlnotify"

ALERT="0"


for i in $SCRIPT_PATH/current_alerts/*.critical; do
	# check indervidual host
	if [[ $i != "$SCRIPT_PATH/current_alerts/*.critical" ]]; then
		HOST_SERVICE=`echo ${i##*/}`
		HOST_CHECK=`echo $HOST_SERVICE | sed 's/\.critical//g' | sed 's/ --- .*//g' | sed 's/SLASH/\//g'`
		SERVICE_CHECK=`echo $HOST_SERVICE | sed 's/\.critical//g' | sed 's/.* --- //g' | sed 's/SLASH/\//g'`
		recheck_errors=`curl -Ss --data "host=$HOST_CHECK" --data "service=$SERVICE_CHECK" --data style=hostdetail http://$HOST/cgi-bin/status.cgi -u $USER:$PASS`
		recheck_errors2=`echo $recheck_errors | grep -o "CRITICAL"`
		if [[ $recheck_errors2 != "" ]]; then
			STATUS=`cat "$i"`
			if [[ $STATUS != "3" ]]; then
				echo "3" > "$i"
			fi
		else
			$GROWLNOTIFY -n "Nagios" -t "OK again" -m "$HOST_CHECK - $SERVICE_CHECK" -p-2 --image $SCRIPT_PATH/nagios.icns
			rm "$i"
		fi
	fi
done

for i in $SCRIPT_PATH/current_alerts/*.warn; do
	# check indervidual host
	if [[ $i != "$SCRIPT_PATH/current_alerts/*.warn" ]]; then
		HOST_SERVICE=`echo ${i##*/}`
		HOST_CHECK=`echo $HOST_SERVICE | sed 's/\.warn//g' | sed 's/ --- .*//g' | sed 's/SLASH/\//g'`
		SERVICE_CHECK=`echo $HOST_SERVICE | sed 's/\.warn//g' | sed 's/.* --- //g' | sed 's/SLASH/\//g'`
		recheck_warn=`curl -Ss --data "host=$HOST_CHECK" --data service="$SERVICE_CHECK" --data type=2 http://$HOST/cgi-bin/status.cgi -u $USER:$PASS`
		recheck_warn2=`echo $recheck_warn | grep -o "WARNING"`	
		if [[ $recheck_warn2 != "" ]]; then
			STATUS=`cat "$i"`
			if [[ $STATUS != "3" ]]; then
				echo "3" > "$i"
			fi
		else
			$GROWLNOTIFY -n "Nagios" -t "OK again" -m "$HOST_CHECK - $SERVICE_CHECK" -p-2 --image $SCRIPT_PATH/nagios.icns
			rm "$i"
		fi
	fi
done

#for critical
list_errors=`curl -Ss --data host=all --data servicestatustypes=16 --data style=hostdetail http://$HOST/cgi-bin/status.cgi -u $USER:$PASS | grep -o 'extinfo.cgi?type=2&host=.*' | sed 's/extinfo.cgi?type=2&host=//g' | sed "s/&se.*'>/ --- /g" | sed "s/<\/A.*//g"`
while read -r error; do
	if [[ $error != "" ]]; then
		error=`echo $error | sed 's/\//SLASH/g'`
		if [[ ! -f $SCRIPT_PATH/current_alerts/$error.critical ]]; then
			echo "0" > "$SCRIPT_PATH/current_alerts/$error.critical"
			echo "$error"
		fi
		echo "$error" >> $SCRIPT_PATH/log.txt
	fi
done <<< "$list_errors"

#for warning
list_warn=`curl -Ss --data host=all --data servicestatustypes=4 --data style=hostdetail http://$HOST/cgi-bin/status.cgi -u $USER:$PASS | grep -o 'extinfo.cgi?type=2&host=.*' | sed 's/extinfo.cgi?type=2&host=//g' | sed "s/&se.*'>/ --- /g" | sed "s/<\/A.*//g"`
while read -r warn; do
	if [[ $warn != "" ]]; then
		warn=`echo $warn | sed 's/\//SLASH/g'`
		echo $warn
		if [[ ! -f $SCRIPT_PATH/current_alerts/$warn.warn ]]; then
			echo "0" > "$SCRIPT_PATH/current_alerts/$warn.warn"
		fi
		echo "$warn" >> $SCRIPT_PATH/log.txt
	fi
done <<< "$list_warn"


STATUS=""
for z in $SCRIPT_PATH/current_alerts/*.critical; do
	AGE=""
	STATUS=`cat "$z"`
	HOST_SERVICE=`echo ${z##*/}`
	HOST_CHECK=`echo $HOST_SERVICE | sed 's/\.critical//g' | sed 's/ --- .*//g' | sed 's/SLASH/\//g'`
	SERVICE_CHECK=`echo $HOST_SERVICE | sed 's/\.critical//g' | sed 's/.* --- //g' | sed 's/SLASH/\//g'`
	if [[ $STATUS == "0" ]]; then
		echo "$z           $HOST_SERVICE            $SERVICE_CHECK                  $HOST_CHECK"
		$GROWLNOTIFY -n "Nagios" -t "Critical Error" -m "$HOST_CHECK - $SERVICE_CHECK" -p2 --image $SCRIPT_PATH/nagios.icns -s
		ALERT=1
		echo "new alert"
	fi
	if [[ $STATUS == "3" ]]; then
		echo "check old alert"
		#check age if over 5 mins run again not sticky
		AGE=`find "$z" -mmin +5`
		if [[ $AGE != "" ]]; then
			echo "old alert found"
			$GROWLNOTIFY -n "Nagios" -t "Critical Error" -m "$HOST_CHECK - $SERVICE_CHECK" -p2 --image $SCRIPT_PATH/nagios.icns
			echo "3" > "$z"
		fi
	fi
done

STATUS=""
for x in $SCRIPT_PATH/current_alerts/*.warn; do
	AGE=""
	STATUS=`cat "$x"`
	HOST_SERVICE=`echo ${x##*/}`
	HOST_CHECK=`echo $HOST_SERVICE | sed 's/\.warn//g' | sed 's/ --- .*//g' | sed 's/SLASH/\//g'`
	SERVICE_CHECK=`echo $HOST_SERVICE | sed 's/\.warn//g' | sed 's/.* --- //g' | sed 's/SLASH/\//g'`
	if [[ $STATUS == "0" ]]; then
		$GROWLNOTIFY -n "Nagios" -t "Warning" -m "$HOST_CHECK - $SERVICE_CHECK"  --image $SCRIPT_PATH/nagios.icns
		ALERT=1
		echo "new alert"
	fi
	if [[ $STATUS == "3" ]]; then
		echo "check old alert"
		#check age if over 5 mins run again not sticky
		AGE=`find "$x" -mmin +5`
		if [[ $AGE != "" ]]; then
			echo "old alert found"
			$GROWLNOTIFY -n "Nagios" -t "Warning" -m "$HOST_CHECK - $SERVICE_CHECK" --image $SCRIPT_PATH/nagios.icns
			echo "3" > "$x"
		fi
	fi
done

if [[ $ALERT = "1" ]]; then
	afplay -v 2 /System/Library/Sounds/Purr.aiff
fi
