#!/bin/bash
#
# Import provided SQL files in to MySQL.
#
# The files in the {vvv-dir}/database/backups/ directory should be created by
# mysqldump or some other export process that generates a full set of SQL commands
# to create the necessary tables and data required by a database.
#
# For an import to work properly, the SQL file should be named `db_name.sql` in which
# `db_name` matches the name of a database.
#
# If tables already exist for a database, the import will not be attempted again. After an
# initial import, the data will remain persistent and available to MySQL on future boots
# through {vvv-dir}/database/data
#
# Let's begin...

# Move into the newly mapped backups directory, where mysqldump(ed) SQL files are stored
printf "\nStart MySQL Database Import\n"
cd /srv/database/backups/

# Parse through each file in the directory and use the file name to
# import the SQL file into the database of the same name
sql_count=`ls -1 *.sql 2>/dev/null | wc -l`
if [ $sql_count != 0 ]
then
	for file in $( ls *.sql )
	do
	pre_dot=${file%%.sql}
	mysql_cmd='SHOW TABLES FROM `'$pre_dot'`' # Required to support hypens in database names
	db_exist=`mysql -u root -proot --skip-column-names -e "$mysql_cmd"`

	# Create DB if it doesn't exist yet
	if [ "$?" != "0" ]
	then
		printf "  * Found backup for DB that doesn't exist yet. Creating $pre_dot...\n\n"
		mysql -u root -proot -e "CREATE DATABASE IF NOT EXISTS $pre_dot"
		mysql -u root -proot -e "GRANT ALL PRIVILEGES ON $pre_dot.* TO admin@localhost IDENTIFIED BY 'admin'"
	fi

	# Import .sql
	if [ "" == "$db_exist" ]
	then
		mysql -u root -proot $pre_dot < $pre_dot.sql
		printf "  * Import of $pre_dot successful\n"
	else
		printf "  * Skipped import of $pre_dot - tables exist\n"
	fi

	done
	printf "Databases imported\n"
else
	printf "No custom databases to import\n"
fi
