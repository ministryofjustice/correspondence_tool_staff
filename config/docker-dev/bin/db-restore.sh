#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#    Use `make db-restore` from the host terminal to execute this script inside the container.
#
#    It restores a PostgresSQL database from a backup file created using pg_dump.
#    The backup file should be a TAR archive (file.tar.gz) that contains the database dump.
#    To restore successfully, the backup file should be located in the root directory of
#    the project, the same directory where the Makefile is located.
#
#    The script performs the following steps:
#    1. It checks if the specified backup file exists.
#    2. If the file exists, it creates a temporary directory to
#       extract the contents of the backup.
#    3. It uses the tar command to extract the database dump from the
#       backup file into the temporary directory.
#    4. It then uses the pg_restore command to restore the database from
#       the extracted dump into the target database specified in the
#       environment variable $DATABASE_NAME.
#    5. Finally, it cleans up the temporary directory and provides feedback on
#       the success or failure of the restore process.
#
#    Note: PGPASSWORD environment variable should be set in the .env file for
#    authentication with the Postgres database. A workable copy of all required
#    environment variables can be found in the .env.example file.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

clear

. ./config/docker-dev/bin/functions.sh


header "D A T A B A S E   R E S T O R E"
header_additional "${DARK_GRAY}This utility expects a TAR file (file.tar.gz) that was created using pg_dump.${NC}\n\n"

restore() {
  if [ -f "$1".tar.gz ]; then
    DIRECTORY="./$1-database-temp"
    mkdir "$DIRECTORY";
    header_additional "Unpacking database from ${YELLOW}$1.tar.gz${NC}..."
    # GNU tar supports the --directory (-C) option, which allows us to specify the
    # target directory for extraction without changing the current working directory.
    # This is more efficient and avoids potential issues with relative paths.
    tar -xzf "$1".tar.gz -C ${DIRECTORY}

    header_additional "${GREEN}Database extracted successfully to ${YELLOW}${DIRECTORY}${NC}.\n"
    sleep 2

    header_additional "Restoring database from ${YELLOW}${DIRECTORY}${NC} to ${YELLOW}$DATABASE_NAME${NC}..."
    # The -c option tells pg_restore to clean (drop) database objects before recreating them.
    # The -U option specifies the database user (postgres in this case).
    # The -h option specifies the host (db, which is the name of the database service in our Docker Compose setup).
    # The -d option specifies the target database to restore into ($DATABASE_NAME, defined in our .env file).
    pg_restore -c -U postgres -h db -d "$DATABASE_NAME" "$DIRECTORY" > ./tmp/pg_restore_output.log 2>&1

    header_additional "${GREEN}Database restore process completed successfully${NC}." "close"
    rm -rf "$DIRECTORY"
  else
    header_additional "${RED}Error:${NC} Backup file ${YELLOW}$1.tar.gz${NC} not found." "close"
    exit 1
  fi
}

## ask the user if they want to proceed with the restore
# Using printf for proper escape and color expansion; read -p does not interpret \n or colors
printf "           We will restore the database from a backup.\n           %sDo you want to proceed?%s (y/n) " "${GREEN}" "${NC}"
read -r -n 1 REPLY
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  printf "           Please enter the name of the backup to restore (e.g., the name of your file without .tar.gz): "
  read -r BACKUP_NAME
  echo
  restore "$BACKUP_NAME"
else
  header_additional "${GREEN}Database restore cancelled.${NC}" "close"
fi


