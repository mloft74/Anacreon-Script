#!/usr/bin/sh

for arg
do
    if [ "${arg}" = "--dry" -o "${arg}" = "-d" ]
    then
        dry="TRUE"
    else
        echo "Argument ${arg} not recognized"
        exit 1
    fi
done

if [ "${dry}" = "TRUE" ]
then
    echo "Dry run..."
fi

# If using any shell special symbols like < or > (or others not listed here),
# make sure you pass them to run_cmd_always with single quotes, i.e. '<' or '>'.
run_cmd_always () {
    eval "${@}"
    if [ "${?}" -ne "0" ]
    then
        echo "Failed to run command: ${@}"
        exit "${?}"
    fi
}

# If using any shell special symbols like < or > (or others not listed here),
# make sure you pass them to run_cmd with single quotes, i.e. '<' or '>'.
run_cmd () {
    if [ "${dry}" = "TRUE" ]
    then
        echo "${@}"
    else
        run_cmd_always "${@}"
    fi
}

symlinks_created="0"
symlinks_replaced="0"

# $1: link target, $2: link name
replace_with_symlink() {
    echo "Removing ${2}; not a link to ${1}"
    run_cmd rm "${2}"

    echo "Symlinking ${2} to ${1}"
    run_cmd ln -s "${1}" "${2}"
    symlinks_replaced=$((symlinks_replaced+1))
    echo ""
}

# $1: path for file to link to
# $2: final desination for link
safe_link() {
    if [ -L "${2}" ]
    then
        realdest=$(run_cmd_always realpath -m "${2}")
        if [ "${realdest}" != "${1}" ]
        then
            echo "[NOTICE] ${2} currently links to ${realdest}"
            replace_with_symlink "${1}" "${2}"
        fi
    elif [ -f "${2}" ]
    then
        replace_with_symlink "${1}" "${2}"
    else
        echo "Symlinking ${2} to ${1}"
        run_cmd ln -s "${1}" "${2}"
        symlinks_created=$((symlinks_created+1))
        echo ""
    fi
}

if [ -z "${XDG_CONFIG_HOME:-}" ]
then
    mpv_dir="${HOME}/.config/mpv"
else
    mpv_dir="${XDG_CONFIG_HOME}/mpv"
fi
