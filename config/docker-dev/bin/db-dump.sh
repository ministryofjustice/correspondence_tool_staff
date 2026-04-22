#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#    Use `make db-dump` from the host terminal to execute this script.
#
#    It will backup a PostgresSQL database from a specified Cloud Platform pod.
#
#    Note: PGPASSWORD environment variable is created on the fly for
#    authentication with the Postgres database. This process helps to ensure that
#    the database password is not exposed in the command history or logs. The
#    script prompts the user to identify the variable name that contains the
#    database password, and then it uses that variable to set the PGPASSWORD
#    environment variable when executing the pg_dump command inside the Kubernetes
#    pod.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

clear

. ./config/docker-dev/bin/functions.sh

header "D A T A B A S E   D U M P"
header_additional "${DARK_GRAY}This utility expects an authorised kubectl command with access to live cloud resources.${NC}\n\n"

# exec into kubernetes pod and execute pg_dump command to backup the database, then copy the backup file to local machine
backup() {
  # Execute pg_dump command inside the specified pod and namespace
  kubectl exec -q -n $1 $2 -- ash -c "export PGPASSWORD=\$$5; pg_dump -U $3 -h $6 $4 -Ft -f /tmp/$4.tar && gzip -f /tmp/$4.tar"

  # Check if the pg_dump command succeeded
  if [ $? -ne 0 ]; then
    error "Failed to backup the database from pod ${YELLOW}$2${NC} in namespace ${YELLOW}$1${NC}."
    exit 1
  fi

  header_additional "\n${GREEN}Success${NC}. Database backup created successfully in pod ${YELLOW}$2${NC}, in namespace ${YELLOW}$1${NC}.${NC}\n"

  # Copy the backup file from the pod to the local machine
  kubectl cp $1/$2:/tmp/$4.tar.gz ./$4.tar.gz > /dev/null

  # Check if the kubectl cp command succeeded
  if [ $? -ne 0 ]; then
    error "Failed to copy the backup file from pod ${YELLOW}$2${NC} in namespace ${YELLOW}$1${NC} to local machine."
    exit 1
  fi

  header_additional "${GREEN}Success${NC}. Database backup copied successfully to local machine: ${YELLOW}$4.tar.gz${NC}.\n"
}

list_pods() {
  # Get the list of pods in the current namespace
  PODS=$(kubectl get pods -n $1 -o jsonpath='{.items[*].metadata.name}')

  # Check if there are any pods available
  if [ -z "$PODS" ]; then
    error "No pods found in the current namespace."
    exit 1
  fi

  # Print the list of pods for the user to choose from
  echo "Available pods:"
  for POD in $PODS; do
    echo " - $POD"
  done
}

# Redact secrets from env var listings.
# Expects input in the form of VAR=VALUE pairs, one per line.
# Usage:
#   safe_env_redact "${ENV_TEXT}"
# or pipe:
#   printf "%s" "${ENV_TEXT}" | safe_env_redact
# Behavior:
#   1) Masks values for any VAR whose name contains 'pass' or 'password' (case-insensitive) as ********
#   2) Finds those masked values and redacts any other occurrences of them elsewhere in the text
safe_env_redact() {
  local input_text

  # Read input either from argument or stdin
  if [ -t 0 ]; then
    input_text="$1"
  else
    input_text="$(cat)"
  fi

  # Phase 1: mask values where the key contains pass/password/secret.
  # This handles the most common case of password vars, and ensures we
  # don't accidentally log or show them.
  local safe_env_vars
  safe_env_vars=$(echo "$input_text" | awk -F= '{ key=$1; if (tolower(key) ~ /(pass|password|secret)/) print key"=********"; else print $0 }')

  # Phase 2: collect secret values from password-like vars
  # This is necessary, and implemented to catch cases where the password
  # value might appear in other env vars. See Phase 3.
  local -a secret_values=()
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local key=${line%%=*}
    local val=${line#*=}
    local lc_key
    lc_key=$(printf '%s' "$key" | tr '[:upper:]' '[:lower:]')
    if [[ $lc_key =~ (pass|password|secret) ]] && [[ -n "$val" ]]; then
      local already=false
      for s in "${secret_values[@]}"; do
        if [[ "$s" == "$val" ]]; then already=true; break; fi
      done
      if [[ $already == false ]]; then
        secret_values+=("$val")
      fi
    fi
  done <<< "$input_text"

  # Phase 3: redact any occurrences of the secret values found in phase 2
  # This handles cases where the password value might appear in other env
  # vars (e.g., a connection string) and ensures they are also redacted.
  local secret
  for secret in "${secret_values[@]}"; do
    if [[ -n "$secret" ]]; then
      safe_env_vars=${safe_env_vars//"$secret"/********}
    fi
  done

  printf "%s" "$safe_env_vars"
}

is_postgres() {
  CAN_PSQL=$(kubectl exec -q -n $1 $2 -- ash -c "command -v psql >/dev/null 2>&1 && echo true || echo false")
  CAN_PG_DUMP=$(kubectl exec -q -n $1 $2 -- ash -c "command -v pg_dump >/dev/null 2>&1 && echo true || echo false")

  # If both psql and pg_dump are available, we can be reasonably confident it's a Postgres database.
  if [ "$CAN_PSQL" == "true" ] && [ "$CAN_PG_DUMP" == "true" ]; then
    return 0 # true
  else
    return 1 # false
  fi
}

## ask the user if they want to proceed with the restore
# Using printf for proper escape and color expansion; read -p does not interpret \n or colors
printf "           We will backup a Postgres database from the Cloud Platform.\n           %sDo you want to proceed?%s (y/n) " "${GREEN}" "${NC}"
read -r -n 1 REPLY
if [[ $REPLY =~ ^[Yy]$ ]]; then
  printf "\n\n           Please enter %sthe namespace%s of the service you want to backup: " "${YELLOW}" "${NC}"
  read -r NAMESPACE
  echo

  if [[ $NAMESPACE =~ (production|prod|live) ]]; then
    error "The namespace entered appears to be a production environment.\nTo prevent accidental backups from production, this script will exit.\nPlease double-check the namespace and try again, especially if you intended to backup from a non-production environment."
    exit 1
  fi

  list_pods "$NAMESPACE" | indent

  printf "\n           Please enter the name of %sthe pod%s you want to access: " "${YELLOW}" "${NC}"
  read -r POD_NAME

  ## negative check; if the pod does not have psql and pg_dump installed, tell
  # the user and exit, as this utility is designed for Postgres databases
  if ! is_postgres "$NAMESPACE" "$POD_NAME"; then
    echo
    error "The specified pod does not appear to have a Postgres client installed (psql and pg_dump\n       commands were not found). This utility is designed for backing up Postgres databases.\n\n       Please double-check the pod name and ensure it is the correct one for a Postgres database. ${YELLOW}Exiting${NC}."
    exit 1
  fi

  printf "\n           We need a variable name that contains the database password.\n           The environment data related to the database can be shown. %sIs it safe, can we proceed?%s (y/n) " "${GREEN}" "${NC}"
  read -r -n 1 VARNAMES_CONFIRMED
  echo
  if [[ $VARNAMES_CONFIRMED =~ ^[Yy]$ ]]; then
    ENV_VARS=$(kubectl exec -q -n $NAMESPACE $POD_NAME -- printenv | grep -E "DATABASE|DB_|_DB")

    # Redact potentially sensitive values using shared function from functions.sh
    SAFE_ENV_VARS=$(safe_env_redact "$ENV_VARS")

    header_additional "\nEnvironment variables related to the database in the pod (passwords redacted):"
    echo "${DARK_GRAY}$SAFE_ENV_VARS${NC}" | indent
  fi

  sleep 1

  printf "\n           %sCan you identify a variable name containing the database password?%s (y/n) " "${GREEN}" "${NC}"
  read -r -n 1 USER_VARIABLE_CONFIRMED
  if [[ $USER_VARIABLE_CONFIRMED =~ ^[Yy]$ ]]; then
    printf "\n           Please enter the variable name: "
    read -r PASSWORD_VARIABLE_NAME
  else
    echo
    error "Database password variable name is required to proceed with the backup."
    exit 1
  fi

  header_additional "\n${GREEN}Ok.${NC} Now we need values, not variables."

  printf "\n           Please enter the name of the %sdatabase%s you want to backup: " "${YELLOW}" "${NC}"
  read -r DATABASE_NAME

  # Ask the user to enter the database username value.
  printf "\n           Next, enter the database username for %s${DATABASE_NAME}%s: " "${YELLOW}" "${NC}"
  read -r POSTGRES_USER

  # Ask the user to enter the database username value.
  printf "\n           Lastly, enter the database host.\n           It looks like: %scloud-platform-***.***.eu-west-2.rds.amazonaws.com%s: " "${YELLOW}" "${NC}"
  read -r DATABASE_HOST

  echo
  echo
  sub_header "Backup Summary"

  header_additional "We will execute a database backup in namespace ${YELLOW}${NAMESPACE}${NC} using the following details:"
  header_additional "  - Host:     ${YELLOW}${DATABASE_HOST}${NC}"
  header_additional "  - Database: ${YELLOW}${DATABASE_NAME}${NC}"
  header_additional "  - Username: ${YELLOW}${POSTGRES_USER}${NC}"
  header_additional "  - Password: ${YELLOW}${PASSWORD_VARIABLE_NAME}${NC}"

  header_additional "\nIn addition, we will copy the backup file from the pod to your \nlocal machine, and the backup file will be named ${YELLOW}${DATABASE_NAME}.tar.gz${NC}.\n"

  printf "\n           %sAre you happy to proceed?%s (y/n) " "${GREEN}" "${NC}"
  read -r -n 1 BACKUP_CONFIRMED
  if [[ $BACKUP_CONFIRMED =~ ^[Yy]$ ]]; then
    echo
    backup "$NAMESPACE" "$POD_NAME" "$POSTGRES_USER" "$DATABASE_NAME" "$PASSWORD_VARIABLE_NAME" "$DATABASE_HOST"

    ## all done, ask if they want to open the restore utility
    printf "\n           %sWould you like to open the %srestore utility%s? (y/n) " "${GREEN}" "${YELLOW}" "${NC}"
    read -r -n 1 RESTORE_CONFIRMED
    header_additional "\n${GREEN}Goodbye${NC}." "close"
    if [[ $RESTORE_CONFIRMED =~ ^[Yy]$ ]]; then
      make db-restore
    fi
  else
    header_additional "\n${GREEN}Database backup was cancelled.${NC}" "close"
    exit 0
  fi
else
  header_additional "\n\n${GREEN}Database backup was cancelled.${NC}" "close"
fi
