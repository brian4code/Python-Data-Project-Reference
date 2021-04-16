#!/bin/bash

# This script disables, deletes, and/or archives users on the local system

ARCHIVE_DIR='/archives'

# Display the usage and exit
usage() {
  echo "Usage: ${0} [-dra] USER [USERN]..." >&2
  echo 'Disable a local Linux account.' >&2
  echo ' -d Deletes account instead of disabling them.' >&2
  echo ' -r Removes the home directory associated with the account(s).' >&2
  echo ' -a Creates an archive of the home directory associated with the account(s).' >&2
  exit 1
}

# Make sure the script is being executed with superuser
if [[ "${UID}" -ne 0 ]]
then
  echo 'Please run with sudo or as root.' >&2
  exit 1
fi

# Parse the options
while getopts dra OPTION
do 
  case ${OPTION} in
    d) DELETE_USER='true' ;;
    r) REMOVE_OPTION='-r' ;;
    a) ARCHIVE='true' ;;
    ?) usage ;;
  esac
done

# Remove the options while leaving the remaining arguments
shift "$(( OPTIND - 1 ))"

# If the user doesn't supply at least one argument, give them help
if [[ "${#}" -lt 1 ]]
then
  usage
fi

# Loop through all the usernames supplied as arguments
for USER in "${@}"
do 


  # Make sure the UID of the account is at least 1000
  echo "Processing user: ${USER}"
  if [[ "$(id -u ${USER})" -lt 1000 ]]
  then
    echo "Refusing to remove the ${USER} account with UID $(id -u ${USER})" >&2
    exit 1
  fi

  # Create an archive if requested to do so
  if [[ "${ARCHIVE}" = 'true' ]]
  then

    # Make sure the ARCHIVE_DIR directory exists
    # ls /archives &>/dev/null
    # if [[ "${?}" -ne 0 ]]
    if [[ ! -d "${ARCHIVE_DIR}" ]]
    then
      echo "Creating ${ARCHIVE_DIR} directory"
      mkdir -p ${ARCHIVE_DIR}
    fi

    # Archive the user's home directory and move it into the ARCHIVE_DIR
    HOME_DIR="/home/${USER}"
    ARCHIVE_FILE="${ARCHIVE_DIR}/${USER}.tgz"
    if [[ -d "${HOME_DIR}" ]]
    then 
      echo "Archiving ${HOME_DIR} to ${ARCHIVE_FILE}"
      tar -zcf ${ARCHIVE_FILE} ${HOME_DIR} &>/dev/null
      if [[ "${?}" -ne 0 ]]
      then
        echo "Could not create ${ARCHIVE_FILE}." >&2
        exit 1
      fi
    else
      echo "${HOME_DIR} does not exist or is not a directory." >&2
      exit 1
    fi
  fi

  # Delete the user
  if [[ "${DELETE_USER}" = 'true' ]]
  then
    userdel ${REMOVE_OPTION} "${USER}"

    # Check to see if the userdel command succeeded
    # We don't want to tell the user that an account was deleted when it hasn't been
    if [[ "${?}" -ne 0 ]]
    then
      echo "The account ${USER} cannot be deleted." >&2
      exit 1
    fi
    echo "The account ${USER} was deleted." 
  else
    
    # Disable the user account
    chage -E 0 "${USER}"

    # Check to see if the chage command succeeded
    # We don't want to tell the user that an account was disabled when it hasn't been
    if [[ "${?}" -ne 0 ]]
    then
      echo "The account ${USER} cannot be disabled." >&2
      exit 1
    fi
    echo "The account ${USER} was disabled."
  fi
done

exit 0



