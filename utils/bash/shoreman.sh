#!/bin/bash

set -o pipefail
set -e
set -u

#store all pids of child processes
pids=""

#pid of current child process
pid=""


function usage() {
    echo "Usage: runit [-c] [-f procfile|Procfile] [-e envfile|.env]"
}

#######################################
# Brief:
#    verify procfile and envfile, return 0 if success
# Globals:
#    None
# Arguments:
#    1: path of evn file
#    2: path of proc file
# Returns:
#    succ: 0
#    fail: 1
#######################################
function verify() {
    local evn_file=${1:-'.env'}
    local proc_file=${2:-'Procfile'}
    local fail=0
    
    #verify proc file
    if [[  -f "${proc_file}" ]]; then
        while read line || [[ -n "${line}" ]]; do
            if !( echo "${line}"|grep -qe '^\s\?\w\+:.\+$');then
                echo "ERROR: ${line}: error proc file format"
                (( fail ++ ))
            fi
        done < "${proc_file}"
    else
        echo "ERROR: ${proc_file}: no such file or directory"
        (( fail ++ ))
    fi
    
    #verify env file
    if [[ -f "${env_file}" ]]; then
       while read line || [[ -n "${line}" ]]; do
           if !( echo "${line}"|grep -qe '^\s\?\w\+=\w\+\s\?$'); then
               echo "ERROR: ${line}: error env file format"
               (( fail ++ ))
           fi
       done < "${env_file}"
    fi

    
    if [[ "${fail}" -ne "0" ]]; then
        usage
    fi
    exit "${fail}"
}

#######################################
# Brief:
#    print colorizing logs
# Globals:
#    None
# Arguments:
#    1: proc name
#    2: index for color
#    3: stdin
# Returns:
#    None
#######################################
function log() {
    local name="$1"
    local index="$2"
    local color="$(( 31 + (index % 7) ))"
    
    while read -r string || [[ -n "${string}" ]]; do
        printf "\033[0;${color}m%s %s\t|\033[0m %s\n"  "$(date +"%H:%M:%S")" "$name" "$string"
    done
}

#######################################
# Brief:
#    starts a command and store pid
# Globals:
#    pids,pid
# Arguments:
#    1: command 
#    2: proc name
#    3: index for color
# Returns:
#    None
#######################################
function run_command() {
    bash -c "$1" 2>&1 | log "$2" "$3" &
    pid="$(jobs -p %%)"
    pids="${pids} ${pid}"
}

#######################################
# Brief:
#    export environment variables
# Globals:
#    PORT and other environment variables defined in evn file
# Arguments:
#    1: path of env file
# Returns:
#    None
#######################################
function load_env_file() {
    local evn_file=${1:-'.env'}
    
    export PORT=${PORT:-8080}
    if [[  -f "$evn_file" ]]; then
        while read line; do
            eval export "${line}"
        done < <( grep "^\s\?\w\+=\w\+\s\?$" "${evn_file}")
    fi
}

#######################################
# Brief:
#    parse proc names and command from procfile and start command
# Globals:
#    None
# Arguments:
#    1: path of proc file
# Returns:
#    None
#######################################
function run_procfile() {
    local proc_file=${1:-'Procfile'}
    local index=1
    
    while read -r line || [[ -n "${line}" ]]; do
        if [[ -z "$line" ]] || !(echo "${line}"|grep -qe '^\s\?\w\+:.\+$'); then
            continue
        fi
        
        local name="${line%%:*}"
        local command="${line#*:[[:space:]]}"
        
        run_command "${command}" "${name}" "${index}"
        bash -c "echo ${command} started with pid ${pid}" | log "${name}" "${index}"

        #increase port number and index for color
        (( index ++ ))
        if ( echo  "${command}"|grep -qe 'PORT' ); then
            (( PORT ++ ))
            export PORT="${PORT}"
        fi
    done < "${proc_file}"
}

function main() {
    local is_verify
    local env_file
    local proc_file
    while getopts 'ce:f:h' opt; do
        case "${opt}" in
            c)
                local is_verify='true'
                ;;
            e)
                local env_file="$OPTARG"
                ;;
            f)
                local proc_file="$OPTARG"
                ;;
            h|*)
                usage
                exit 0
                ;;
        esac
  done
  
  if [[  "${is_verify}" = "true" ]]; then
      verify "${env_file}" "${proc_file}"
  fi

  load_env_file  "${env_file}"
  run_procfile "${proc_file}"
  
  trap 'echo "singal recived, kill ${pids}";kill -- ${pids} &> /dev/null' TERM INT
  wait
}

main "$@"
