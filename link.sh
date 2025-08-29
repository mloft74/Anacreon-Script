#!/usr/bin/sh

. ./common.sh

dirs_made="0"

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

        safe_link "${realfile}" "${dest_file}"
    done
}

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
