#!/bin/bash

#Work through the sym links back to the script's actual running directory 
SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do 
    DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
    SOURCE="$(readlink "${SOURCE}")"
    [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
declare -r DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"

#Check if all arguments are passed
if [[ ${#} -lt 2 ]]; then
    echo "Usage: poke.sh url [emails...]"
    exit 1
fi

#Grab the url and shift the arguments
declare -r URL="${1}"
shift 1

#Make diff directory, if need be
declare -r POKEDIR="${DIR}/.pokediffs"
declare -r DIFF_EXT=".diff"
declare -r TEMP_EXT=".tmp"

if [[ ! -d "${POKEDIR}" ]]; then
    mkdir "${POKEDIR}"
fi

#Generate the unique name of the the diff file
declare -r HASH_FILE="$(echo "$URL" | sha1sum)"
declare -r DIFF_FILE="${HASH_FILE}${DIFF_EXT}"
declare -r TEMP_FILE="${HASH_FILE}${TEMP_EXT}"

curl -s "${URL}" > "${POKEDIR}/${TEMP_FILE}"

if [[ -f "${POKEDIR}/${DIFF_FILE}" ]]; then
    testStr=$(diff "${POKEDIR}/${TEMP_FILE}" "${POKEDIR}/${DIFF_FILE}")

    #If the test string is not empty, there are differences. Alert the user(s) and
    #and move the temp file over
    if [[ ! -z ${testStr} ]]; then
        for elem in "${@}"; do
            echo "Update detected from this site." | mail -s "Update from ${URL}" "${elem}"
            echo "Email sent to ${elem}"
        done
        mv "${POKEDIR}/${TEMP_FILE}" "${POKEDIR}/${DIFF_FILE}"
    else
        rm "${POKEDIR}/${TEMP_FILE}"
    fi
else
    mv "${POKEDIR}/${TEMP_FILE}" "${POKEDIR}/${DIFF_FILE}"
    echo "No file to diff."
fi
