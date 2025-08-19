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

dirs_made="0"
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

# $1: repo dir to traverse
# $2: repo to link files into
ln_dir () {
    for file in $(find "$1" -name '.git*' -prune -o -type f -print)
    do
        path="${file#./}"
        realfile=$(run_cmd_always realpath -e "${file}")
        #echo "Found ${path}"
        source_dir=$(dirname "${path}")
        file_base=$(basename "${path}")
        #echo "Dir: ${source_dir}"
        dest_dir="$2"
        dest_dir="${dest_dir%/.}"
        if [ "${source_dir}" != "." ]
        then
            if [ ! -d "${dest_dir}" ]
            then
                echo "Creating ${dest_dir}"
                run_cmd mkdir -p "${dest_dir}"
                dirs_made=$((dirs_made+1))
            fi
        fi

        dest_file="${dest_dir}/${file_base}"

        if [ -L "${dest_file}" ]
        then
            realdest=$(run_cmd_always realpath -m "${dest_file}")
            if [ "${realdest}" != "${realfile}" ]
            then
                replace_with_symlink "${realfile}" "${dest_file}"
            fi
        elif [ -f "${dest_file}" ]
        then
            replace_with_symlink "${realfile}" "${dest_file}"
        else
            echo "Symlinking ${dest_file} to ${realfile}"
            run_cmd ln -s "${realfile}" "${dest_file}"
            symlinks_created=$((symlinks_created+1))
            echo ""
        fi
    done
}


mpv_dir="${HOME}/.config/mpv"
ln_dir "./animecards" "${mpv_dir}/scripts/animecards"
ln_dir "./script-opts" "${mpv_dir}/script-opts"

if [ "${dirs_made}" -eq "0" -a "${symlinks_created}" -eq "0" -a "${symlinks_replaced}" -eq "0" ]
then
    if [ "${dry}" = "TRUE" ]
    then
        echo "No changes will be made"
    else
        echo "No changes made"
    fi
else
    if [ "${dry}" = "TRUE" ]
    then
        echo "Summary of changes to be made:"
        echo "Dirs to make: ${dirs_made}, symlinks to create: ${symlinks_created}, symlinks to replace: ${symlinks_replaced}"
    else
        echo "Summary of changes made:"
        echo "Dirs made: ${dirs_made}, symlinks created: ${symlinks_created}, symlinks replaced: ${symlinks_replaced}"
    fi
fi
