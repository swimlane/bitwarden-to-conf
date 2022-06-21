#!/bin/bash
#
# Usage:
#   init-mongodb-users
#
# Depends on:
#  mongo
#

###############################################################################
# Wrapper
###############################################################################

# Wrap everything in a function so we can start initialization in a subshell.
# See end of script for further explanation
_wrapper() {
  set -o nounset
  set -o errexit
  trap '_die printf "Aborting due to errexit on line %s. Exit code: %s" "${LINENO}" "$?" >&2' ERR
  set -o errtrace
  set -o pipefail
  IFS=$'\n\t'

  # _die()
  #
  # Usage:
  #   _die printf "Error message. Variable: %s\n" "$0"
  #
  # A simple function for exiting with an error after executing the specified
  # command. The command is expected to print a message and should typically
  # be either `echo`, `printf`, or `cat`.
  _die() {
    printf "*******************************************************************************
    
    ERROR: SWIMLANE INITIALIZATION ERROR OCCURRED
    
      ERROR DETAILS: " 1>&2
    "${@}" 1>&2
    printf "\\n\\n*******************************************************************************\\n" 1>&2
    
    exit 1
  }

  ###############################################################################
  # Program Constants
  ###############################################################################

  readonly SWIMLANE_DB_NAME="Swimlane"
  readonly SWIMLANE_HISTORY_DB_NAME="SwimlaneHistory"
  readonly TURBINE_DB_NAME="SwimlaneTurbine"

  ###############################################################################
  # Program Primary Functions
  ###############################################################################

  _init_mongodb_user() {
    local username="${1:-}"
    local password="${2:-}"
    local db_name="${3:-}"

    printf "Creating Swimlane user for %s database...\\n" "${db_name}"

    local arguments=(--host localhost --authenticationDatabase admin)
    arguments+=(--username "${MONGO_INITDB_ROOT_USERNAME}" --password "${MONGO_INITDB_ROOT_PASSWORD}")

    local script="db = db.getSiblingDB(\"${db_name}\");"
    script+="db.createUser({"
    script+="user: \"${username}\","
    script+="pwd: \"${password}\","
    script+="roles: [{role: \"dbOwner\", db: \"${db_name}\"}],"
    script+="mechanisms: [ \"SCRAM-SHA-1\" ],"
    script+="passwordDigestor: \"server\""
    script+="})"

    if ! mongo "${arguments[@]}" --eval "${script}" 2>&1; then
      _die printf "Failed to create Swimlane user for %s database." "${db_name}"
    fi

    printf "Successfully created Swimlane user for %s database.\\n\\n" "${db_name}"
  }

  _escape_json_special_chars() {
    local _string="${1:-}"

    _string=${_string//\\/\\\\} # \
    _string=${_string//\//\\\/} # /
    _string=${_string//\'/\\\'} # '
    _string=${_string//\"/\\\"} # "
    _string=${_string//   /\\t} # \t (tab)
    _string=${_string//
    /\\\n} # \n (newline)
    _string=${_string//^M/\\\r} # \r (carriage return)
    _string=${_string//^L/\\\f} # \f (form feed)
    _string=${_string//^H/\\\b} # \b (backspace)

    echo "${_string}"
  }

  ###############################################################################
  # Main
  ###############################################################################

  _main() {
    if [[ -z "${MONGO_INITDB_ROOT_USERNAME-}" ]] || \
      [[ -z "${MONGO_INITDB_ROOT_PASSWORD-}" ]] || \
      [[ -z "${SW_MONGO_INITDB_SWIMLANE_USERNAME-}" ]] || \
      [[ -z "${SW_MONGO_INITDB_SWIMLANE_PASSWORD-}" ]]
    then
      _die printf "Expected environment variables are not defined or are empty.
  Please define these environment variables:
    * MONGO_INITDB_ROOT_USERNAME
    * MONGO_INITDB_ROOT_PASSWORD
    * SW_MONGO_INITDB_SWIMLANE_USERNAME
    * SW_MONGO_INITDB_SWIMLANE_PASSWORD\\n"
    else
      printf "Starting MongoDB initialization for Swimlane...\\n"

      local escaped_username
      local escaped_password
      escaped_username=$(_escape_json_special_chars "${SW_MONGO_INITDB_SWIMLANE_USERNAME}")
      escaped_password=$(_escape_json_special_chars "${SW_MONGO_INITDB_SWIMLANE_PASSWORD}")

      # no need to guard against users already being created since the
      # mongo docker entrypoint script only runs this init script when the
      # database is not already initialized.
      _init_mongodb_user "${escaped_username}" "${escaped_password}" "${SWIMLANE_DB_NAME}"
      _init_mongodb_user "${escaped_username}" "${escaped_password}" "${SWIMLANE_HISTORY_DB_NAME}"
      _init_mongodb_user "${escaped_username}" "${escaped_password}" "${TURBINE_DB_NAME}"
      printf "Successfully completed MongoDB initialization for Swimlane.\\n"
    fi
  }

  # call main after everything is defined
  _main
}

# Call _wrapper from a subshell since mongo entrypoint sources init scripts and
# we don't want to adjust the behavior of the entrypoint (particularly
# `set -o errexit` and the trap) as we would do if we didn't run _wrapper in a
# subshell. Also guard against the mongo entrypoint exiting from its errexit
# by adding an `|| true`.
#
# Why not just use `(_wrapper) || true` instead? `set -o errexit` is ignored
# within any command of an AND/OR list other than the last.
_wrapper &
wait $! || true
