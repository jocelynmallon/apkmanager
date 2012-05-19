#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Basic "batch" operation functions
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.0b
# Sat. May 19, 2012
# -----------------------------------------------------------------------

# Cleanup variables used in 'batch' functions
batch_cleanup () {
    unset input
    unset infile
    unset batchnum
    unset dir
    unset file
    unset ogg_file
    unset png_file
}

# Batch zipalign apk and/or jar files
batch_zalign () {
    echo "batch_zalign (batch zipalign files) function" 1>> "$log"
    cd "${maindir}/other"
    find "${maindir}/${bat_dir}" -type f \( -iname "*.apk" -o -iname "*.jar" \) | while read infile ;
    do
        dir="$(dirname "${infile}")"
        infile="$(basename "${infile}")"
        zipalign -fv 4 "${dir}/${infile}" "${dir}/${infile}-aligned" 1>> "$log" 2>&1
        if [[ $? -eq 0 ]]; then
            echo $green"${infile} aligned ok"; $rclr;
            mv -f "${dir}/${infile}-aligned" "${dir}/${infile}"
        fi
    done
    cd "${maindir}"
    echo "batch_zalign function complete" 1>> "$log"
}

# Batch optimize png images
batch_png () {
    echo "batch_png (batch optimize png images) function" 1>> "$log"
    if [[ ${pngopts} = disabled ]];then
        echo $bred"ERROR, no png optimization program was found on your system"
        echo $bred"this option is unavailable until one is installed"; $rclr;
        pressanykey
    else
        if [[ -z ${pngtool} ]]; then
            pngtool="optipng"
        fi
        cd "${maindir}/other"
        mkdir -p "${maindir}/${bat_dir}/temp"
        find "${maindir}/${bat_dir}" -iname "*.apk" | while read infile ;
        do
            dir="$(dirname "${infile}")"
            infile="$(basename "${infile}")"
            echo "Optimizing ${infile}"
            7za x -o"${dir}/temp" "${dir}/${infile}" -y 1>> "$log" 2>&1
            find "${dir}/temp" -iname "*.png" | while read png_file ;
            do
                if [[ $(echo "${png_file}" | grep -c "\.9\.png$") -eq 0 ]]; then
                    if [[ ${pngtool} = optipng ]]; then
                        optipng -o99 "${png_file}"
                    elif [[ ${pngtool} = pngcrush ]]; then
                        pngcrush -reduce -brute "${png_file}" "opt_png.png"
                        mv -f opt_png.png "${png_file}"
                    elif [[ ${pngtool} = pngout ]]; then
                        pngout "${png_file}"
                    fi
                fi
            done
            7za a -tzip "${dir}/temp.zip" "${dir}/temp/*" -mx${uscr} -y 1>> "$log" 2>&1
            mv -f "${dir}/temp.zip" "${dir}/${infile}"
            rm -rf "${dir}/temp/*"
        done
        rm -rf "${maindir}/${bat_dir}/temp"
        cd "${maindir}"
    fi
    echo "batch_png function complete" 1>> "$log"
}

# Optimize both (z & p) check function
batch_both () {
    if [[ ${pngopts} = disabled ]];then
        echo $bred"ERROR, no png optimization program was not found on your"
        echo $bred"system. This option is unavailable until one is installed"
        echo $bwhite"Type \"Q\" to return to main menu, or type anything else"
        printf "$bwhite%s""to proceed with \"batch zipalign\" only... "; $rclr;
        read input
        case "$input" in
            [qQ]) ;;
               *) batch_zalign ;;
        esac
    else
        batch_png
        batch_zalign
    fi
}

# Batch optimize files prompt
batch_opt () {
    echo "batch_opt (batch optimize main prompt) function" 1>> "$log"
    local batchnum="$(ls -1 "${maindir}/${bat_dir}" | wc -l)"
    cd "${maindir}"
    if [[ ${batchnum} = 0 ]]; then
        echo $bred"Error, nothing to optimize"; $rclr;
        pressanykey
    else
        printf "$white%s""Do you want to zipalign "$green"(z)"$white", optimize png "$green"(p)"$white" or both "$green"(zp)"$white"? :"; $rclr;
        read input
        case "$input" in
            [zZ])  batch_zalign ;;
            [pP])  batch_png ;;
        [zZ][pP])  batch_both ;;
               *)  input_err; batch_opt ;;
        esac
    fi
    echo "batch optimize function complete" 1>> "$log"
}

# Batch sign apk files with test key
batch_sign_tk () {
    echo "batch_sign_tk (batch sign with test keys) function" 1>> "$log"
    local batchnum="$(ls -1 "${maindir}/${sig_dir}" | wc -l)"
    if [[ ${batchnum} -eq 0 ]]; then
        echo $bred"Error, nothing to sign"; $rclr;
        pressanykey
    else
        find "${maindir}/${sig_dir}" -iname "signed-*.apk" -exec mv {} ~/.Trash \;
        find "${maindir}/${sig_dir}" -iname "*.apk" | while read infile ;
        do
            dir="$(dirname "${infile}")"
            infile="$(basename "${infile}")"
            runj signapk -JXmx"${heapy}""m" -w "${libdir}/testkey.x509.pem" "${libdir}/testkey.pk8" "${dir}/${infile}" "${dir}/signed-${infile}" 1>> "$log" 2>&1
            if [[ $? -ne 0 ]]; then
                echo $bred"An error occured signing ${infile}"; $rclr;
                echo $bred"please check the log for details"; $rclr;
            else
                echo $green"${infile} signed; ok."; $rclr;
                echo "${infile} signed; ok." 1>> "$log"
            fi
        done
    fi
    echo "batch_sign_tk function complete" 1>> "$log"
}

# Batch optimize .ogg files
batch_ogg () {
    echo "batch_ogg (batch optimize ogg files) function" 1>> "$log"
    if [[ ${oggopts} = disabled ]];then
        echo $bred"ERROR, program \"sox\" was not found on your system"
        echo $bred"this option is unavailable until it is installed"; $rclr;
        pressanykey
    else
        find "${maindir}/${ogg_dir}/" -iname "*.ogg" | while read ogg_file ;
        do
            dir="$(dirname "${ogg_file}")"
            file="$(basename "${ogg_file}")"
            printf "%s" "Optimizing: ${file}"
            sox "${dir}/${file}" -C 0 "${dir}/optimized-${file}"
            if [[ $? -eq 0 ]]; then
                printf "\n"
                echo "${file} optimized ok" 1>> "$log"
            else
                printf "...%s\n" "Failed"
                echo "optimizing ${file} failed" 1>> "$log"
            fi
        done
    fi
    echo "batch_ogg function complete" 1>> "$log"
}
