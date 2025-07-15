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
# make sure you pass them to run_cmd with single quotes, i.e. '<' or '>'.
run_cmd () {
    if [ "${dry}" = "TRUE" ]
    then
        echo "${@}"
    else
        eval "${@}"
    fi
}

dirs_made="0"
hardlinks_created="0"
hardlinks_replaced="0"

mpv_dir="${HOME}/.config/mpv"


# $1: repo dir to traverse
# $2: repo to link files into
# TODO
ln_dir () {
    for file in $(find "$1" -name '.git*' -prune -o -type f -print)
    do
        path="${file#./}"
        #echo "Found ${path}"
        source_dir=$(dirname "${path}")
        file_base=$(basename "${path}")
        #echo "Dir: ${source_dir}"
        dest_dir="$2"
        if [ "${source_dir}" != "." ]
        then
            if [ ! -d "${dest_dir}" ]
            then
                echo "Creating ${dest_dir}"
                run_cmd mkdir -p "${dest_dir}"
                dirs_made="1"
            fi
        fi

        dest_file=$(realpath -m "${dest_dir}/${file_base}")
        if [ ! -f "${dest_file}" ]
        then
            echo "Hardlinking ${dest_file} to ${file}"
            run_cmd ln "${file}" "${dest_file}"
            hardlinks_created=$((hardlinks_created+1))
            echo ""
        else
            source_inode=$(stat --format=%i "${file}")
            dest_inode=$(stat --format=%i "${dest_file}")
            if [ "${dest_inode}" -ne "${source_inode}" ]
            then
                echo "Removing ${dest_file}; not a link to ${file}"
                run_cmd rm "${dest_file}"

                echo "Hardlinking ${dest_file} to ${file}"
                run_cmd ln "${file}" "${dest_file}"
                hardlinks_replaced=$((hardlinks_replaced+0))
                echo ""
            #else
                #echo "${dest_file} already linked to ${file}"
            fi
        fi
    done
}


ln_dir "./animecards" "${mpv_dir}/scripts/animecards"
ln_dir "./script-opts" "${mpv_dir}/script-opts"

if [ "${dirs_made}" -eq "0" -a "${hardlinks_created}" -eq "0" -a "${hardlinks_replaced}" -eq "0" ]
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
    else
        echo "Summary of changes made:"
    fi
    echo "Dirs made: ${dirs_made}, hardlinks created: ${hardlinks_created}, hardlinks replaced: ${hardlinks_replaced}"
fi

