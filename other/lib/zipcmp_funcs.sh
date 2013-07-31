#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Zip, compile, all-in-one functions
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.1b
# Wed. Jul 31, 2013
# -----------------------------------------------------------------------

# Zip/compress a system apk file
zip_sys_apk () {
    echo "zip_sys_apk (actually zipping apk now) function" 1>> "$log"
    7za a -tzip "${maindir}/${mod_dir}/unsigned-${capp}" "${maindir}/${prj_dir}/${capp}/*" -mx${uscr} 1>> "$log" 2>&1
}

# Zip/compress non-system apk file
zip_nrm_apk () {
    echo "zip_nrm_apk (remove signature for non system-apk) function" 1>> "$log"
    rm -rf "${maindir}/${prj_dir}/${capp}/META-INF"
    zip_sys_apk
}

# Zip/compress single file, initial checks
zip_apk () {
    echo "zip_apk (main prompt) function" 1>> "$log"
    capp_test
    if [[ ${capp} = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
        return 1
    elif [[ ! ${prjext} = [Aa][Pp][Kk] ]]; then
        jarext_err
    elif [[ ! -d "${maindir}/${prj_dir}/${capp}" ]]; then
        nodir_err
    elif [[ $(ls -1 "${maindir}/${prj_dir}/${capp}" | wc -l) -eq 0 ]]; then
        nodir_err
    elif [[ ! -f "${maindir}/${prj_dir}/${capp}/resources.arsc" ]]; then
        noex_err
    else
        rm "${maindir}/${mod_dir}/signed-${capp}"
        rm "${maindir}/${mod_dir}/unsigned-${capp}"
        echo $bgreen" 1"$white"    System  apk "$green"(Retains signature)";
        echo $bgreen" 2"$white"    Regular apk "$green"(Removes signature for re-signing)";
        printf "$bwhite%s""Please select an option: "; $rclr;
        read input
        case "$input" in
            1)  zip_sys_apk ;;
            2)  zip_nrm_apk ;;
            *)  input_err; zip_apk ;;
        esac
        unset input
    fi
    echo "zip_apk function complete" 1>> "$log"
}

# Install an apk file
install_apk () {
    echo "install_apk function" 1>> "$log"
    capp_test
    if [[ ${capp} = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
        return 1
    elif [[ ! ${prjext} = [Aa][Pp][Kk] ]]; then
        jarext_err
    else
        if [[ ! -e "${maindir}/${mod_dir}/signed-${capp}" ]]; then
            echo $bred"Error, cannot find file: signed-${capp}";
            echo "Error, cannot find file: signed-${capp}" 1>> "$log"
            echo $bred"Please use \"sign apk\" option first"; $rclr;
            pressanykey
        else
            timeout3 -t 5 adb devices | grep "${adb_dev_choice}"
            echo ""
            printf "$bwhite%s""Press any key to continue "; $rclr;
            wait
            adb -s "${adb_dev_choice}" wait-for-device install -r "$mod_dir/signed-$capp"
            printf "$bwhite%s""Press any key to continue "; $rclr;
            wait
        fi
    fi
    echo "install_apk function complete" 1>> "$log"
}

# Use "keep" process
sys_yes_keep () {
    echo "sys_yes_keep (compile system apk, YES keep folder)" 1>> "$log"
    if [[ ! -d "${maindir}/keep" ]]; then
        mkdir -p "${maindir}/keep"
    fi
    7za x -o"${maindir}/keep" "${maindir}/${mod_dir}/${capp}" 1>> "$log" 2>&1
    echo ""
    echo $white"In the apk manager folder you'll find"
    echo "a "$bgreen"keep"$white" folder. Within it, delete"
    echo "everything you have modified and leave any"
    echo "files that you haven't. "$bgreen"If you have modified"
    echo "any xml, then delete resources.arsc from that"
    echo "folder as well."$white" Once done then press enter"
    echo "on this script."; $rclr;
    wait
    7za a -tzip "${maindir}/${mod_dir}/unsigned-${capp}" "${maindir}/keep/*" -mx${uscr} -r -y 1>> "$log" 2>&1
    if [[ $? -eq 0 ]]; then
        rm -rf "${maindir}/keep"
    fi
    echo "sys_yes_keep function complete" 1>> "$log"
}

# Don't use "keep" process
sys_no_keep () {
    echo "sys_no_keep (compile system apk, NO keep folder)" 1>> "$log"
    if [[ -d "${maindir}/${prj_dir}/temp" ]]; then
        rm -rf "${maindir}/${prj_dir}/temp"
        mkdir -p "${maindir}/${prj_dir}/temp"
    fi
    cd "${maindir}/other"
    7za x -o"${maindir}/${prj_dir}/temp" "${maindir}/${mod_dir}/${capp}" META-INF -r -y 1>> "$log" 2>&1
    7za x -o"${maindir}/${prj_dir}/temp" "${maindir}/${mod_dir}/${capp}" AndroidManifest.xml -y 1>> "$log" 2>&1
    7za a -tzip "${maindir}/${mod_dir}/unsigned-${capp}" "${maindir}/${prj_dir}/temp/*" -mx${uscr} -r -y 1>> "$log" 2>&1
    if [[ $? -eq 0 ]]; then
        rm -rf "${maindir}/${prj_dir}/temp"
    fi
    cd "${maindir}"
    echo "sys_no_keep function complete" 1>> "$log"
}

# System apk "keep" process prompt
sys_keep_prompt () {
    echo "sys_keep_prompt (compile system apk, keep folder prompt)" 1>> "$log"
    echo ""
    echo $bgreen"Aside from the signatures"$white", would you like to copy";
    echo $white"over any additional files that you didn't modify";
    echo $white"from the original apk in order to ensure least";
    printf "$white%s""number of errors? ("$bgreen"y"$white"/"$bgreen"n"$white") "; $rclr;
    read input
    case "$input" in
     [yY])  sys_yes_keep ;;
     [nN])  sys_no_keep ;;
        *)  input_err; sys_keep_prompt ;;
    esac
}

# Compile, system apk keep prompt
co_sys_prompt () {
    echo "co_sys_prompt (compile apk, system apk prompt)" 1>> "$log"
    printf "$white%s""Is this a system apk? ("$bgreen"y"$white"/"$bgreen"n"$white") "; $rclr;
    read input
    case "$input" in
     [yY])  sys_keep_prompt ;;
     [nN])  ;;
        *)  input_err; co_sys_prompt ;;
    esac
}

# Actually compile with smali.jar
comp_smali () {
    echo "comp_smali, actually compiling now" 1>> "$log"
    rm -rf "${maindir}/${prj_dir}/${capp}/build"
    mkdir -p "${maindir}/${prj_dir}/${capp}/build"
    touch "${maindir}/${prj_dir}/${capp}/build/classes.dex"
    runj smali -JXmx"${heapy}""m" "${maindir}/${prj_dir}/${capp}" -o "${maindir}/${prj_dir}/${capp}/build/classes.dex" 1>> "$log" 2>&1
    echo "comp_smali function complete" 1>> "$log"
}

# Actually compile an apk file with apktool
comp_apkt () {
    echo "comp_apkt, actually compiling now" 1>> "$log"
    runj apktool -JXmx"${heapy}""m" b "${maindir}/${prj_dir}/${capp}" "${maindir}/${mod_dir}/unsigned-${capp}" 1>> "$log" 2>&1
}

# Compile an apk skeleton/shell
compile_apk () {
    echo "compile_apk, (compile with apktool) function" 1>> "$log"
    echo "Compiling apk..."
    comp_apkt
    if [[ $? -ne 0 ]]; then
        echo $bred"An error occured while compiling, please check log."; $rclr;
        pressanykey
    else
        co_sys_prompt
    fi
    echo "compile_apk function complete" 1>> "$log"
}

# Advanced compile final packaging
comp_adv_final () {
    7za x -o"${maindir}/${prj_dir}/temp" "${maindir}/${mod_dir}/unsigned-${capp}" classes.dex -y 1>> "$log" 2>&1
    dex1="${maindir}/${prj_dir}/${capp}/build/classes.dex"
    dex2="${maindir}/${prj_dir}/temp/classes.dex"
    echo "comparing classes.dex to ensure the smali version is used" 1>> "$log"
    diff -s "${dex1}" "${dex2}" 1>> "$log" 2>&1
    if [[ $? -ne 0 ]]; then
        echo "copying classes.dex compiled by smali into unsigned-$capp" 1>> "$log"
        7za a -tzip "${maindir}/${mod_dir}/unsigned-${capp}" "${maindir}/${prj_dir}/${capp}/build/classes.dex" -y -mx${uscr} 1>> "$log" 2>&1
        rm -rf "${maindir}/${prj_dir}/temp"
    else
        rm -rf "${maindir}/${prj_dir}/temp"
    fi
}

# Advanced compile skeleton/shell
compile_adv () {
    echo "compile_adv function" 1>> "$log"
    echo "Compiling Code..."
    comp_smali
    if [[ $? -ne 0 ]]; then
        echo $bred"An error occured while compiling code, please check log."; $rclr;
        pressanykey
    else
        echo "Compiling Resources..."
        mkdir -p "${maindir}/${prj_dir}/${capp}/build/apk"
        cp -p "${maindir}/${prj_dir}/${capp}/build/classes.dex" "${maindir}/${prj_dir}/${capp}/build/apk/classes.dex"
        comp_apkt
        if [[ $? -ne 0 ]]; then
            echo $bred"An error occured while compiling resources, please check log."; $rclr;
            pressanykey
        else
            co_sys_prompt
            if [[ $? -ne 0 ]]; then
                echo $bred"An error occured during system-apk \"keep\" process, please check log."; $rclr;
                pressanykey
            else
                echo "Packaging APK..."
                comp_adv_final
                if [[ $? -ne 0 ]]; then
                    echo $bred"An error occured during final packaging process, please check log."; $rclr;
                    pressanykey
                fi
            fi
        fi
    fi
    echo "compile_adv function complete" 1>> "$log"
}

# Ccompile jar file skeleton/shell
compile_jar () {
    echo "compile_jar function" 1>> "$log"
    echo "Compiling jar..."
    cp -pf "${maindir}/${mod_dir}/${capp}" "${maindir}/${mod_dir}/unsigned-${capp}" 1>> "$log" 2>&1
    comp_smali
    if [[ $? -ne 0 ]]; then
        echo $bred"An error occured while compiling code, please check log."; $rclr;
        pressanykey
    else
        7za a -tzip "${maindir}/${mod_dir}/unsigned-${capp}" "${maindir}/${prj_dir}/${capp}/build/classes.dex" -mx${uscr} 1>> "$log" 2>&1
        if [[ $? -ne 0 ]]; then
            echo $bred"An error occured while zipping classes.dex, please check log."; $rclr;
            pressanykey
        fi
    fi
    echo "compile_jar function complete" 1>> "$log"
}

# Compile function, initial checks
compile () {
    echo "compile (main) function" 1>> "$log"
    capp_test
    if [[ ${capp} = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
        return 1
    elif [[ ! -d "${maindir}/${prj_dir}/${capp}" ]]; then
        nodir_err
    elif [[ -d "${maindir}/${prj_dir}/${capp}/java" ]]; then
        if [[ ! -f "${maindir}/${prj_dir}/${capp}/apktool.yml" ]]; then
            nodir_err
        fi
    elif [[ $(ls -1 "${maindir}/${prj_dir}/${capp}" | wc -l) -eq 0 ]]; then
        nodir_err
    elif [[ -f "${maindir}/${prj_dir}/${capp}/resources.arsc" ]]; then
        nodec_err
    elif [[ ! -f "${maindir}/${mod_dir}/${capp}" ]]; then
        notfound_err
    elif [[ -f "${maindir}/${prj_dir}/${capp}/.advanced" ]]; then
        compile_adv
    elif [[ ${prjext} = [Jj][Aa][Rr] ]]; then
        compile_jar
    elif [[ ${prjext} = [Aa][Pp][Kk] ]]; then
        compile_apk
    fi
    echo "compile function complete" 1>> "$log"
}

# All-in-one actually sign and install now
aio_sub_finish () {
    if [[ ${signfunc} = signpkey ]]; then
        if [[ -z ${keystore} ]]; then
            storecheck
        fi
        if [[ ! ${keystore##*.} = [kK][eE][yY][sS][tT][oO][rR][eE] ]]; then
            echo $bred"Error, invalid or no keystore selected."; $rclr;
            echo "Error, invalid or no keystore selected." 1>> "$log" 2>&1
            pressanykey
            return 1
        else
            storename="${keystore%%.*}"
            key="$(awk '{ print $0}' "${HOME}/.apkmanager/.keystores/.${storename}_keyname")"
        fi
    fi
    echo "Signing APK..."
    ${signfunc}
    if [[ $? -ne 0 ]]; then
        echo "error during signing (aio_sub_finish function)" 1>> "$log" 2>&1
        return 1
    fi
    echo "Installing APK..."
    install_apk
    if [[ $? -ne 0 ]]; then
        echo "error during install (aio_sub_finish function)" 1>> "$log" 2>&1
        return 1
    fi
}

# All-in-one, .advanced, actually compile now
aio_sub_adv () {
    echo "Compiling Code..."
    comp_smali
    if [[ $? -ne 0 ]]; then
        echo "error during compile (smali/code) (aio_sub_adv function)" 1>> "$log" 2>&1
        return 1
    fi
    echo "Compiling Resources..."
    mkdir -p "${maindir}/${prj_dir}/${capp}/build/apk"
    cp -p "${maindir}/${prj_dir}/${capp}/build/classes.dex" "${maindir}/${prj_dir}/${capp}/build/apk/classes.dex"
    comp_apkt
    if [[ $? -ne 0 ]]; then
        echo "error during compile (resources) (aio_sub_adv function)" 1>> "$log" 2>&1
        return 1
    fi
    echo "Packaging APK..."
    comp_adv_final
    if [[ $? -ne 0 ]]; then
        echo "error during compile (.advanced packaging) (aio_sub_adv function)" 1>> "$log" 2>&1
        return 1
    else
        aio_sub_finish
    fi
}

# All-in-one, actually zip/compress now
aio_sub_zip () {
    echo "Zipping up APK..."
    zip_nrm_apk
    if [[ $? -ne 0 ]]; then
        echo "error during zip (aio_sub_zip function)" 1>> "$log" 2>&1
        return 1
    else
        aio_sub_finish
    fi
}

# All-in-one, actually compile apk now
aio_sub_cmp () {
    echo "Compiling APK..."
    comp_apkt
    if [[ $? -ne 0 ]]; then
        echo "error during compile (aio_sub_cmp function)" 1>> "$log" 2>&1
        return 1
    else
        aio_sub_finish
    fi
}

# All-in-one, .advanced decompile check
aio_cmp_check () {
    if [[ -f "${maindir}/${prj_dir}/${capp}/.advanced" ]]; then
        aio_sub_adv
    else
        aio_sub_cmp
    fi
}

# Cleanup/unset variables used by 'all-in-one' functions
aio_cleanup () {
    unset signfunc
    unset aio_option
    unset storename
    unset key
    unset infile
    unset outfile
}

# Check which all-in-one sub-functions to run
aio_type_check () {
    if [[ ${aio_option} = zipapk ]]; then
        if [[ ! -e "${maindir}/${prj_dir}/${capp}/resources.arsc" ]]; then
            noex_err
        else
            aio_sub_zip
        fi
    elif [[ ${aio_option} = compapk ]]; then
        if [[ ! -e "${maindir}/${prj_dir}/${capp}/apktool.yml" ]]; then
            nodec_err
        else
            aio_cmp_check
        fi
    elif [[ ${aio_option} = advanced ]]; then
        if [[ ! -e "${maindir}/${prj_dir}/${capp}/apktool.yml" ]]; then
            aio_sub_zip
        elif [[ -e "${maindir}/${prj_dir}/${capp}/apktool.yml" ]]; then
            aio_cmp_check
        else
            echo $bred"Something went wrong, please check the log."
        fi
    fi
}

# All-in-one function(s) initial start/check
all_in_one () {
    echo "all_in_one function" 1>> "$log"
    if [[ ! ${prjext} = [Aa][Pp][Kk] ]]; then
        jarext_err
    elif [[ ! -d "${maindir}/${prj_dir}/${capp}" ]]; then
        nodir_err
    elif [[ "$(ls -1 "${maindir}/${prj_dir}/${capp}" | wc -l)" -eq 0 ]]; then
        nodir_err
    elif [[ -d "${maindir}/${prj_dir}/${capp}/java" ]]; then
        aio_java_err
    else
        aio_type_check
    fi
    aio_cleanup
    echo "all_in_one function complete" 1>> "$log" 2>&1
}

# Zip-sign-install function initial startup
zip_sign_install () {
    echo "zip_sign_install (zip, sign, install) function" 1>> "$log"
    capp_test
    if [[ ${capp} = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
        return 1
    else
        infile="${maindir}/${mod_dir}/unsigned-${capp}"
        outfile="${maindir}/${mod_dir}/signed-${capp}"
        signfunc="signtkey"
        aio_option="zipapk"
        all_in_one
    fi
    echo "zip_sign_install function complete" 1>> "$log" 2>&1
}

# Compile-sign-install function initial startup
co_sign_install () {
    echo "co_sign_install (compile, sign, install) function" 1>> "$log"
    capp_test
    if [[ ${capp} = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
        return 1
    else
        infile="${maindir}/${mod_dir}/unsigned-${capp}"
        outfile="${maindir}/${mod_dir}/signed-${capp}"
        signfunc="signtkey"
        aio_option="compapk"
        all_in_one
    fi
    echo "co_sign_install function complete" 1>> "$log" 2>&1
}

# Advanced all-in-one function initial startup
adv_all_in_one () {
    echo "adv_all_in_one (advanced all-in-one) function" 1>> "$log"
    capp_test
    if [[ ${capp} = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
        return 1
    else
        infile="${maindir}/${mod_dir}/unsigned-${capp}"
        signfunc="signpkey"
        aio_option="advanced"
        all_in_one
    fi
    echo "adv_all_in_one function complete" 1>> "$log" 2>&1
}
