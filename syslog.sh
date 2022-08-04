#!/bin/bash

# rsyslog service manage (rsyslogshell)
# --------------------------------
# author    : SonyaCore
#	      https://github.com/SonyaCore
#

help(){
            echo "$(tput setaf 3)Rsyslog Shell$(tput sgr0)"
            echo ""
            echo "Service:"
            echo ""
            echo "[--enablesyslog] [-enable] 	Enable syslog systemd service "
            echo "[--disablesyslog] [-disable] 	Disable syslog systemd service "
            echo "[-cpconf} [--copyconfig]	Copy rsyslog default config"
            echo "[-fw]  [--firewall]		Add current port to firewall"
            echo ""
            echo "Remote Options:"
            echo ""
            echo "[-remote] [--changeremote]	Change Remote IP"
            echo "[-port] [--syslogport]		Change SysLog Port"
            echo ""
            echo "Optional Arguments:"
            echo ""
            echo "[-install] [--installsyslog]	Install rsyslog package "
            echo "[-showport] [--showsyslogport]	Show rsyslog Port"
            echo ""
}

args=( )

enablesyslog(){
   systemctl enable --now rsyslog
}

disablesyslog(){
   systemctl disable --now rsyslog
}

copyconfig(){
   cp rsyslog.conf /etc/
}

installsyslog(){
getdistro=$(awk -F= '$1=="NAME" { print $2 ;}' /etc/os-release | tr -d "\"" "")
	if [[ "$getdistro" =~ .*Ubuntu.* ]]; then
		apt update ; apt-get install -y rsyslog
	elif [[ "$getdistro" =~ .*Debian.* ]]; then
		apt update ; apt-get install -y rsyslog
	elif [[ "$getdistro" =~ .*Fedora.* ]]; then
		dnf makecache --refresh ; dnf -y install rsyslog
	elif [[ "$getdistro" =~ .*CentOS.* ]]; then
		yum makecache --refresh ; yum -y install rsyslog
fi
}

changesyslogport(){
   sed -i 's/port="[0-9]\+"/port="'$PORT'"/' /etc/rsyslog.conf
   sed -i 's/:.*/:'$PORT'/' /etc/rsyslog.conf
   systemctl restart rsyslog
}

syslogport(){
   showport=$(cat /etc/rsyslog.conf | egrep port= | head -n1 | awk -F "=" '{print $3}' | awk -F "\"" '{print $2}')
}

changeremote(){
   sed -i '0,/@.*:/{s//@'$IP':/}' /etc/rsyslog.conf
   sed -i '0,/@@.*:/{s//@@'$IP':/}' /etc/rsyslog.conf
}

allowport(){
if [ -f "/usr/sbin/ufw" ]; then ufw allow $showport/tcp ; ufw allow $showport/udp; ufw reload; fi
iptables -t filter -A INPUT -p tcp --dport $showport -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport $showport -j ACCEPT
}

#Permission
permissioncheck(){
ROOT_UID=0
if [[ $UID == $ROOT_UID ]]; then true ; else echo -e "You Must be the ROOT to Perfom this Task" ; exit 1 ; fi
}
permissioncheck


PASSWDDB="$(cat /etc/.dbenv)"

while (( $# )); do
   case $1 in
      -h | --help) help ; exit 1 ;;
      -enable  | --enablesyslog) enablesyslog ; exit 1 ;;
      -disable | --disablesyslog) disablesyslog ; exit 1 ;;
      -install | --installsyslog) installsyslog ; exit 1 ;;
      -fw | --firewall) syslogport ; allowport ; exit 1 ;;
      -port | --syslogport) declare -i PORT=$2 ; changesyslogport ; exit 1 ;;
      -remote | --changeremote)  IP=$2 changeremote exit 1 ;;
      -showport | --showsyslogport) syslogport ; echo $showport ; exit 1 ;;
      -cpconf | --copyconfig) copyconfig exit 1 ;;
      -*) echo "Error: Invalid option" >&2; exit 1 ;;
   esac
   shift
done

set -- "${args[@]}"

#/var/log/syslog - Stores all startup messages, application startup messages etc. Practically stores all global system logs.
#/var/log/$HOSTNAME/*  templates that will be used by Rsyslog for storing incoming syslog messages.
#/var/log/cron - The Cron jobs are basically kind of scheduled and automated task created in the system, that runs periodically and repeatedly. You can see what this logs directory would store.
#/var/log/kern.log - it stores kernel logs. No matter what logs they are. Event logs, errors, or warning logs.
#/var/log/auth.log - Authentication logs.
#/var/log.boot.log - System boot logs.
#/var/log/mysql.d - Mysql logs.
#/var/log/httpd - Apache logs directory.
#/var/log/maillog - Mail server logs.

#Modules:
# %syslogseverity%, %syslogfacility%, %timegenerated%, %HOSTNAME%, %syslogtag%, %msg%, %FROMHOST-IP%, %PRI%, %MSGID%, %APP-NAME%, %TIMESTAMP%, %$year%, %$month%, %$day%


#Severity:
#emerg, panic (Emergency ): Level 0 – This is the lowest log level. system is unusable
#alert (Alerts):  Level 1 – action must be taken immediately
#err (Errors): Level 3 – critical conditions
#warn (Warnings): Level 4 – warning conditions
#notice (Notification): Level 5 – normal but significant condition
#info (Information): Level 6 – informational messages
#debug (Debugging):  Level 7 – This is the highest level – debug-level messages

