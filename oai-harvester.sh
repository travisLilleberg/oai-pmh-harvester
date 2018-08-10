#!/bin/bash

#@file
# Harvests from $url, saves xml results to directory.

######## Vars ########
base_url=""
res_token_regex="<resumptionToken[^>]*>(.*)<\/resumptionToken>"
target_dir="$(pwd)/results/$(date +%Y-%m-%dH%H)"
max_harvests=0 # 0 means no maximum 
file_i=1
curl_args=(
  --fail
  # -m 300 # Maximum number of seconds before giving up on a request.
)


######## Initial Checks ########

if [ -d ${target_dir} ]; then
  echo -e "${target_dir} already exists somehow. How often are you running this?"
  exit 1
fi


######## Functions ########

##
# @function
# Uses res_token_regex to get the resumption token from the file.
#
# @param {str} 1
#   The xml contents of the oai_pmh harvest.
get_res_token() {
  if [[ "${1}" =~ $res_token_regex ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}

##
# @function
# Curls a url and dumps the xml into a file.
#
# @param {str} 1
#   The url to harvest.
# @param {str} 2
#   The file location to save the xml to.
curl_server() {
  echo -e "\n\nHarvesting: ${1}\n"
  curl "${1}" "${curl_args[@]}" -o "${2}"
  return $?
}

##
# @function
# Performs the complete harvest, including handling resumption tokens.
#
# @param {str} 1
#   The url to harvest.
oai_harvest() {
  local filename=${target_dir}/${file_i}.xml

  curl_server "${1}" "${filename}"
  if [ $? -gt 0 ]; then
    echo -e "\nHarvest failed. Exiting"
    exit 2
  fi

  local res_token=$(get_res_token "$(cat ${filename})")

  if [ $file_i -eq $max_harvests ]; then
    echo -e "\nHit max harvest limit of ${max_harvests}. Quitting."
  elif [ -z "${res_token}" ]; then
    echo -e "\nNo resumption token. End of harvesting."
  else
    local new_url="${base_url}&resumptionToken=${res_token}"
    ((file_i=file_i+1))
    oai_harvest "${new_url}"
  fi
}


######## Procedure ########

mkdir ${target_dir}
oai_harvest "${base_url}"

