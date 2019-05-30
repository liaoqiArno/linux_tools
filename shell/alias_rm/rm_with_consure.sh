#!/bin/bash
# 2018-05

curdir=$PWD

is_recursive=0
max_list_number=15
delete_opts=()
delete_files=()
list_delete_files=()

unalias rm 2>/dev/null
rm_bin=$(which rm)

_split_args() {
    for arg in "$@"; do
        if [[ "X--" == "X${arg}" ]]; then
            delete_opts=("${delete_opts[@]}" "${arg}")
            shift
            delete_files=("${delete_files[@]}" "$@")
            break
        elif [[ "X--" == "X${arg:0:2}" ]]; then
            delete_opts=("${delete_opts[@]}" "${arg}")
            shift
            continue
        elif [[ "X-" == "X${arg:0:1}" ]]; then
            if echo "$arg" | grep -qe '/' ; then
                delete_opts=("${delete_opts[@]}" "${arg}")
            else
                for split_arg in $(echo "${arg}"| tr -d  '-'| fold -w1); do
                    delete_opts=("${delete_opts[@]}" "-${split_arg}")
                done
            fi
            shift
            continue
        else
            delete_files=("${delete_files[@]}" "${arg}")
            shift
        fi
    done
}


_check_recursive() {
    for check_arg in "$@"; do 
        if [[ "${check_arg}" == "-r" ]] || [[ "${check_arg}" == "-R" ]] || [[ "${check_arg}" == "--r" ]] || [[ "${check_arg}" == "--recursive" ]]; then
            is_recursive=1
        fi
    done
}

_list_delete_files() {
    echo -e ">>> ------------------------"
    echo -e ">>> Current Directory is \e[1;31m${curdir}\e[0m" 
    if [[ ${is_recursive} -eq 0 ]]; then
        echo -e ">>> \e[1;32mRecursive Is OFF\e[0m" 
    elif [[ ${is_recursive} -eq 1 ]]; then
        echo -e ">>> \e[1;5;41mRecursive Is ON\e[0m" 
    else
        echo -e ">>> \e[1;31mSomething is wrong\e[0m"
        exit
    fi

    echo -e ">>> List The Delete Files( MAX ${max_list_number})"
    echo -e ">>> ------------------------"
    for del_file in "${delete_files[@]}"; do
        if [[ "X/" == "X${del_file:0:1}" ]]; then
            list_delete_files=("${list_delete_files[@]}" "${del_file}")
        else
            list_delete_files=("${list_delete_files[@]}" "${curdir}/${del_file}")
        fi
    done

    #ls -1dl "${list_delete_files[@]}" 2>/dev/null | head -n 15
    list_file=$(ls -1dlh --time-style=long-iso "${list_delete_files[@]}" | head -n ${max_list_number})
    if [[ "${list_file}" ]]; then
        echo -e "\e[32m${list_file}\e[0m"
    else
        echo -e ">>> \e[1;35mIt looks like there is no file to delete\e[0m"
    fi
    echo -e ">>> ------------------------"

}

_rm_with_prompt() {
    if [[ $# -eq 0 ]]; then ${rm_bin}; exit; fi 

    _split_args "$@"
    _check_recursive "$delete_opts"

    if [[ "X" == "X${delete_files[@]}" ]]; then
        ${rm_bin} -i "$@"
        exit 
    fi

    _list_delete_files 

    prompt_string=$(uuidgen| cut -d- -f1)
    echo -e ">>> The prompt string is \e[1;35m${prompt_string}\e[0m"
    count=1
    max_count=3
    while [[  ${count} -le ${max_count} ]]; do
        let ++count
        read -p ">>> Please input the prompt string: " input_string
        if [[ "${prompt_string}" == "${input_string}" ]]; then
            echo -e ">>>\e[1;34m Input correctly, start to delete\e[0m"
            echo -e ">>> ------------------------"
            ${rm_bin} -i "$@"
            exit
        else
            echo -e ">>>\e[1;31m Input error, try again\e[0m"
            continue
        fi
    done
    echo -e ">>>\e[1;31m Input error reached ${max_count} times, exit\e[0m"
    exit 1
}

_rm_with_prompt "$@"