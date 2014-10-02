#!/bin/bash
# NAME
#     zabbix-mysql-backupconf.sh - Configuration Backup for Zabbix 2.0 w/MySQL
#
# SYNOPSIS
#     This is a MySQL configuration backup script for Zabbix v2.0 oder 2.2.
#     It does a full backup of all configuration tables, but only a schema
#     backup of large data tables.
#
#     The original script was written by Ricardo Santos and published at
#     http://zabbixzone.com/zabbix/backuping-only-the-zabbix-configuration/
#     and
#     https://github.com/xsbr/zabbixzone/blob/master/zabbix-mysql-backupconf.sh
#
#     Credits for some suggestions concerning the original script to:
#      - Ricardo Santos
#      - Oleksiy Zagorskyi (zalex)
#      - Petr Jendrejovsky
#      - Jonathan Bayer
#      - Andreas Niedermann (dre-)
#
# HISTORY
#     v0.7 - 2014-10-02 Complete overhaul so that script works with all previous Zabbix versions
#     v0.6 - 2014-09-15 Updated the table list for use with zabbix v2.2.3
#     v0.5 - 2013-05-13 Added table list comparison between database and script
#     v0.4 - 2012-03-02 Incorporated mysqldump options suggested by Jonathan Bayer
#     v0.3 - 2012-02-06 Backup of Zabbix 1.9.x / 2.0.0, removed unnecessary use of
#                       variables (DATEBIN etc) for commands that use to be in $PATH
#     v0.2 - 2011-11-05
#
# AUTHOR
#     Jens Berthold (maxhq), 2013


#
# CONFIGURATION
#

# mysql database
#DBHOST="10.251.137.201"
DBHOST="10.10.2.31"
DBNAME="zabbix"
DBUSER="zabbix"
DBPASS="pyerdagIddOdJej:"

# backup target path
#MAINDIR="/var/lib/zabbix/backupconf"
# following will store the backup in a subdirectory of the current directory
MAINDIR="`dirname \"$0\"`"

#
# CONSTANTS
#

MYSQL_CONN="-h ${DBHOST} -u ${DBUSER} -p${DBPASS} ${DBNAME}"
MYSQL_BATCH="mysql --batch --silent $MYSQL_CONN"
DUMPDIR="${MAINDIR}/`date +%Y%m%d-%H%M`"
DUMPFILE="${DUMPDIR}/zabbix-conf-backup-`date +%Y%m%d-%H%M`.sql"

#
# CHECKS
#

if [ ! -x /usr/bin/mysqldump ]; then
	echo "mysqldump not found."
	echo "(with Debian, \"apt-get install mysql-client\" will help)"
	exit 1
fi

#
# Read table list from __DATA__ section at the end of this script
# (http://stackoverflow.com/a/3477269/2983301) 
#
DATA_TABLES=()
while read line; do
	table=$(echo "$line" | cut -d" " -f1)
	echo "$line" | cut -d" " -f5 | grep -qi "DATA"
	test $? -eq 0 && DATA_TABLES+=($table)
done < <(sed '0,/^__DATA__$/d' "$0" | tr -s " ") 

# paranoid check
if [ ${#DATA_TABLES[@]} -lt 5 ]; then
	echo "ERROR: The number of large data tables configurd in this script is less than 5."
	exit 1
fi

#
# BACKUP
#

# Returns TRUE if argument 1 is part of the given array (remaining arguments)
elementIn () {
	local e
	for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
	return 1
}

mkdir -p "${DUMPDIR}"

echo "Starting table backups..."
while read table; do
	printf "%s %-25s " "-" "${table}"
	if elementIn "$table" "${DATA_TABLES[@]}"; then
		echo "only schema"
		dump_opt="--no-data"
	else
		echo "full"
		dump_opt="--extended-insert=FALSE"
	fi
	mysqldump --routines --opt --single-transaction --skip-lock-tables \
		$dump_opt $MYSQL_CONN --tables ${table} >>"${DUMPFILE}"
done < <($MYSQL_BATCH -e "SELECT table_name FROM information_schema.tables WHERE table_schema = '$DBNAME'" | sort) 

echo
echo "Compressing backup file ${DUMPFILE}..."
gzip -f "${DUMPFILE}"

echo
echo "Backup Completed - ${DUMPDIR}"

exit

################################################################################
# List of all known table names and a flag indicating data (=large) tables
#

__DATA__
acknowledges              1.3.1    - 2.4.0  DATA
actions                   1.3.1    - 2.4.0
alerts                    1.3.1    - 2.4.0  DATA
application_template      2.1.0    - 2.4.0
applications              1.3.1    - 2.4.0
auditlog                  1.3.1    - 2.4.0  DATA
auditlog_details          1.7      - 2.4.0  DATA
autoreg                   1.3.1    - 1.3.4
autoreg_host              1.7      - 2.4.0
conditions                1.3.1    - 2.4.0
config                    1.3.1    - 2.4.0
dbversion                 2.1.0    - 2.4.0
dchecks                   1.3.4    - 2.4.0
dhosts                    1.3.4    - 2.4.0
drules                    1.3.4    - 2.4.0
dservices                 1.3.4    - 2.4.0
escalations               1.5.3    - 2.4.0
events                    1.3.1    - 2.4.0  DATA
expressions               1.7      - 2.4.0
functions                 1.3.1    - 2.4.0
globalmacro               1.7      - 2.4.0
globalvars                1.9.6    - 2.4.0
graph_discovery           1.9.0    - 2.4.0
graph_theme               1.7      - 2.4.0
graphs                    1.3.1    - 2.4.0
graphs_items              1.3.1    - 2.4.0
group_discovery           2.1.4    - 2.4.0
group_prototype           2.1.4    - 2.4.0
groups                    1.3.1    - 2.4.0
help_items                1.3.1    - 2.1.8
history                   1.3.1    - 2.4.0  DATA
history_log               1.3.1    - 2.4.0  DATA
history_str               1.3.1    - 2.4.0  DATA
history_str_sync          1.3.1    - 2.2.6  DATA
history_sync              1.3.1    - 2.2.6  DATA
history_text              1.3.1    - 2.4.0  DATA
history_uint              1.3.1    - 2.4.0  DATA
history_uint_sync         1.3.1    - 2.2.6  DATA
host_discovery            2.1.4    - 2.4.0
host_inventory            1.9.6    - 2.4.0
host_profile              1.9.3    - 1.9.5
hostmacro                 1.7      - 2.4.0
hosts                     1.3.1    - 2.4.0
hosts_groups              1.3.1    - 2.4.0
hosts_profiles            1.3.1    - 1.9.2
hosts_profiles_ext        1.6      - 1.9.2
hosts_templates           1.3.1    - 2.4.0
housekeeper               1.3.1    - 2.4.0
httpstep                  1.3.3    - 2.4.0
httpstepitem              1.3.3    - 2.4.0
httptest                  1.3.3    - 2.4.0
httptestitem              1.3.3    - 2.4.0
icon_map                  1.9.6    - 2.4.0
icon_mapping              1.9.6    - 2.4.0
ids                       1.3.3    - 2.4.0
images                    1.3.1    - 2.4.0
interface                 1.9.1    - 2.4.0
interface_discovery       2.1.4    - 2.4.0
item_condition            2.3.0    - 2.4.0
item_discovery            1.9.0    - 2.4.0
items                     1.3.1    - 2.4.0
items_applications        1.3.1    - 2.4.0
maintenances              1.7      - 2.4.0
maintenances_groups       1.7      - 2.4.0
maintenances_hosts        1.7      - 2.4.0
maintenances_windows      1.7      - 2.4.0
mappings                  1.3.1    - 2.4.0
media                     1.3.1    - 2.4.0
media_type                1.3.1    - 2.4.0
node_cksum                1.3.1    - 2.2.6
node_configlog            1.3.1    - 1.4.7
nodes                     1.3.1    - 2.2.6
opcommand                 1.9.4    - 2.4.0
opcommand_grp             1.9.2    - 2.4.0
opcommand_hst             1.9.2    - 2.4.0
opconditions              1.5.3    - 2.4.0
operations                1.3.4    - 2.4.0
opgroup                   1.9.2    - 2.4.0
opmediatypes              1.7      - 1.8.21
opmessage                 1.9.2    - 2.4.0
opmessage_grp             1.9.2    - 2.4.0
opmessage_usr             1.9.2    - 2.4.0
optemplate                1.9.2    - 2.4.0
profiles                  1.3.1    - 2.4.0
proxy_autoreg_host        1.7      - 2.4.0
proxy_dhistory            1.5      - 2.4.0
proxy_history             1.5.1    - 2.4.0
regexps                   1.7      - 2.4.0
rights                    1.3.1    - 2.4.0
screens                   1.3.1    - 2.4.0
screens_items             1.3.1    - 2.4.0
scripts                   1.5      - 2.4.0
service_alarms            1.3.1    - 2.4.0
services                  1.3.1    - 2.4.0
services_links            1.3.1    - 2.4.0
services_times            1.3.1    - 2.4.0
sessions                  1.3.1    - 2.4.0
slides                    1.3.4    - 2.4.0
slideshows                1.3.4    - 2.4.0
sysmap_element_url        1.9.0    - 2.4.0
sysmap_url                1.9.0    - 2.4.0
sysmaps                   1.3.1    - 2.4.0
sysmaps_elements          1.3.1    - 2.4.0
sysmaps_link_triggers     1.5      - 2.4.0
sysmaps_links             1.3.1    - 2.4.0
timeperiods               1.7      - 2.4.0
trends                    1.3.1    - 2.4.0  DATA
trends_uint               1.5      - 2.4.0  DATA
trigger_depends           1.3.1    - 2.4.0
trigger_discovery         1.9.0    - 2.4.0
triggers                  1.3.1    - 2.4.0
user_history              1.7      - 2.4.0
users                     1.3.1    - 2.4.0
users_groups              1.3.1    - 2.4.0
usrgrp                    1.3.1    - 2.4.0
valuemaps                 1.3.1    - 2.4.0
