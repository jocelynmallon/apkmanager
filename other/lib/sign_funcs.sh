#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# File signing functions
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.0
# Sun. Oct 07, 2012
# -----------------------------------------------------------------------

# Cleanup for advanced signing functions
signcleanup () {
    unset alias
    unset f
    unset files
    unset batchnum
    unset storenum
    unset infile
    unset input
    unset outfile
}

# Actually sign with test key
signtkey () {
    echo "signtkey, actually signing now" 1>> "$log"
    runj signapk -JXmx"${heapy}""m" -w "${libdir}/testkey.x509.pem" "${libdir}/testkey.pk8" "${infile}" "${outfile}" 1>> "$log" 2>&1
}

# Sign an apk file with test key (signapk.jar)
sign_apk_tk () {
    echo "sign_apk_tk (with test keys) function" 1>> "$log"
    capp_test
    if [[ ${capp} = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
        return 1
    elif [[ ! ${prjext} = [Aa][Pp][Kk] ]]; then
        jarext_err
    else
        infile="${maindir}/${mod_dir}/unsigned-${capp}"
        outfile="${maindir}/${mod_dir}/signed-${capp}"
        if [[ ! -f "${infile}" ]]; then
            echo $bred"Error, cannot find file: unsigned-${capp}";
            echo "Error, cannot find file: unsigned-${capp}" 1>> "$log"
            echo $bred"Please use \"zip\" or \"compile\" options first"; $rclr;
            pressanykey
        else
            signtkey
            if [[ $? -ne 0 ]]; then
                echo $bred"Error signing unsigned-${capp}, please check log"; $rclr;
                pressanykey
            else
                rm "${infile}"
            fi
        fi
        signcleanup
    fi
    echo "sign_apk_tk function complete" 1>> "$log"
}

# Check for keystore(s) and persistent setting
storecheck () {
    echo "storecheck (check for existing keystores) function" 1>> "$log"
    if [[ ! -d "${HOME}/.apkmanager/.keystores" ]]; then
        keystore="None"
        return 1
    fi
    keystore="$(defaults read "${plist}" keychoice 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        cd "${HOME}/.apkmanager/.keystores"
        local storenum="$(ls -1 *.[kK][eE][yY][sS][tT][oO][rR][eE] | wc -l)"
        if [[ ${storenum} = 0 ]]; then
            keystore="None"
        elif [[ ${storenum} -gt 1 ]]; then
            keystore="Multiple keystores found, please select one below"
        else
            keystore="$(ls -1 *.[kK][eE][yY][sS][tT][oO][rR][eE])"
        fi
        cd "${maindir}"
    fi
}

# Actually verifying signature of file/files
sigverify () {
    echo "sigverify, actually verifying now" 1>> "$log"
    local f
    for f in ${files}; do
        jarsigner -verify -verbose ${f} 1>> "$log" 2>&1
        if [[ $? -ne 0 ]]; then
            echo $bred"An error occured verifying $(basename "${f}")";
            echo $bred"please check the log for details"; $rclr;
        else
            echo $green"$(basename "${f}") verified; ok."; $rclr;
        fi
    done
    signcleanup
}

# Verify signature of a single file
single_vrfy () {
    echo "single_vrfy (verify a single file signature) function" 1>> "$log"
    capp_test
    if [[ ${capp} = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
        return 1
    elif [[ ! -f "${maindir}/${mod_dir}/signed-${capp}" ]]; then
        echo "signed-${capp} not found, nothing to verify."
        signpanykey
        echo "signed-${capp} not found, aborting."  1>> "$log"
        return 1
    else
        files="${maindir}/${mod_dir}/signed-${capp}"
        sigverify
        signpanykey
    fi
    echo "single_vrfy function complete" 1>> "$log"
}

# Batch verify signature of files
batch_vrfy () {
    echo "batch_vrfy (batch verify signature) function" 1>> "$log"
    local batchnum="$(ls -1 | wc -l)"
    if [[ ${batchnum} = 0 ]]; then
        echo $bred"Error, nothing to verify"; $rclr;
    else
        files=$(find "${maindir}/${sig_dir}" -type f \( -iname "*.apk" -o -iname "*.jar" \))
        sigverify
    fi
    signpanykey
    echo "batch_vrfy function complete" 1>> "$log"
}

# Actually sign a single file with private key
signpkey () {
    echo "signpkey, actually signing now" 1>> "$log"
    jarsigner -verbose -keystore "${HOME}/.apkmanager/.keystores/${keystore}" "${infile}" "${key}"
        if [[ $? -ne 0 ]]; then
            echo $bred"An error occured signing ${infile}";
            echo $bred"please check the log for details"; $rclr;
        else
            echo $green"$(basename "${infile}") signed; ok."; $rclr;
            cp "${infile}" "${maindir}/${mod_dir}/signed-${capp}"
            rm "${infile}"
        fi
}

# Batch-sign with private keys, actually signing
bsignpkey () {
    echo "bsignpkey, actually signing now" 1>> "$log"
    local spasswrd
    local kpasswrd
    local f
    echo ""
    printf "$white%s""Enter passphrase for keystore "$bgreen"${keystore}"$white": "; $rclr;
    read -s spasswrd
    echo ""
    printf "$white%s""Enter key password for "$bgreen"${key}"$white": "; $rclr;
    echo ""
    read -s kpasswrd
    find "${maindir}/${sig_dir}" -iname "*signed*" -exec mv {} ~/.Trash \;
    find "${maindir}/${sig_dir}" -type f \( -iname "*.apk" -o -iname "*.jar" \) | while read f ;
    do
        f="$(basename "${f}")"
        jarsigner -verbose -keystore "${HOME}/.apkmanager/.keystores/${keystore}" -storepass "${spasswrd}" -keypass "${kpasswrd}" "${maindir}/${sig_dir}/${f}" "${key}"
        if [[ $? -ne 0 ]]; then
            echo $bred"An error occured signing ${f}";
            echo $bred"please check the log for details"; $rclr;
        else
            echo $green"${f} signed; ok."; $rclr;
            cp "${maindir}/${sig_dir}/${f}" "${maindir}/${sig_dir}/signed-${f}"
            rm "${maindir}/${sig_dir}/${f}"
        fi
    done
}

# Sign with private keys info text/prompt
sign_prompt () {
    echo "sign_prompt (sign with private keys prompt) function" 1>> "$log"
    clear
    menu_header
    echo $bgreen"$apkmspr";
    echo ""
    echo $white" APK Manager will attempt to sign all apk or jar files in the";
    echo $green" \"${sig_dir}\""$white" folder, using your selected private key:"; $rclr;
    echo ""
    echo $white" Keystore: "$bgreen"${keystore}";
    echo $white" Key: "$bgreen"${key}"; $rclr;
    echo ""
    echo $blue" (you will be asked for both your keystore and key passwords)";
    echo $bgreen"$apkmftr"
    genericpanykey
}

# Sign a single file with private key initial checks
sign_apk_pk () {
    echo "sign_apk_pk (sign single file with private key) function" 1>> "$log"
    capp_test
    if [[ ${capp} = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
        return 1
    elif [[ ! ${keystore##*.} = [kK][eE][yY][sS][tT][oO][rR][eE] ]]; then
        echo $bred"Error, invalid or no keystore selected."; $rclr;
        signpanykey
    else
        storename="${keystore%%.*}"
        key="$(awk '{ print $0}' "${HOME}/.apkmanager/.keystores/.${storename}_keyname")"
        infile="${maindir}/${mod_dir}/unsigned-${capp}"
        if [[ ! -e "${infile}" ]]; then
            echo $bred"Error, Cannot find $(basename "${infile}") to sign"; $rclr;
            signpanykey
        else
            sign_prompt
            signpkey
            signpanykey
        fi
        unset infile
    fi
    echo "sign_apk_pk function complete" 1>> "$log"
}

# Batch sign files with private key initial checks
batch_sign_pk () {
    echo "batch_sign_pk (batch sign with private key) function" 1>> "$log"
    if [[ ! ${keystore##*.} = [kK][eE][yY][sS][tT][oO][rR][eE] ]]; then
        echo $bred"Error, invalid or no keystore selected."; $rclr;
        signpanykey
    else
        storename="${keystore%%.*}"
        key="$(awk '{ print $0}' "${HOME}/.apkmanager/.keystores/.${storename}_keyname")"
        local batchnum="$(ls "${maindir}/${sig_dir}" | wc -l)"
        if [[ ${batchnum} -eq 0 ]]; then
            echo $bred"Error, nothing to sign"; $rclr;
            signpanykey
        else
            sign_prompt
            bsignpkey
            signpanykey
        fi
    fi
    echo "batch_sign_pk function complete" 1>> "$log"
}

# Actually generate private key/keystore
genpkey () {
    echo "create new privte key, actually generating key now" 1>> "$log"
    keytool -genkey -v -keystore "${keystore}" -alias "${alias}" -keyalg RSA -keysize 2048 -validity 10000
    echo "$logspcr" 1>> "$log" 2>&1
    echo "created keystore: ${keystore}" 1>> "$log" 2>&1
    echo "contains private key: ${alias}" 1>> "$log" 2>&1
    echo "$logspcr" 1>> "$log" 2>&1
    echo "${alias}" 1> "${HOME}/.apkmanager/.keystores/.${keystore%%.*}_keyname"
}

# Create a private key/keystore main function
createpkey () {
    echo "createpkey (create new privte key) function" 1>> "$log"
    if [[ ! -d "${HOME}/.apkmanager/.keystores" ]]; then
        mkdir -p "${HOME}/.apkmanager/.keystores"
    fi
    cd "${HOME}/.apkmanager/.keystores"
    echo $white"Enter a name for your new keystore ("$green"e.g. myprivatekey.keystore"$white")"; $rclr;
    read input
    if [[ ! ${input##*.} = [kK][eE][yY][sS][tT][oO][rR][eE] ]]; then
        keystore="${input%%.*}.keystore"
    else
        keystore="$input"
    fi
    echo $white"Enter a unique alias name? ("$green"e.g. myprivatekey, testing, etc."$white")";
    echo $green"(Leave blank to use keystore name for alias too)"; $rclr;
    read input
    if [[ ! -z $input ]]; then
        alias="$input"
    else
    alias="${keystore%%.*}"
    fi
    echo $white"Keystore name "$bgreen"${keystore}"; $rclr;
    echo $white"Alias name: "$bgreen"${alias}"; $rclr;
    printf "$white%s""Proceed with these names? ("$bgreen"y"$white"/"$bgreen"n"$white") "; $rclr;
    read input
    case "$input" in
     [yY])  genpkey; unset keystore ;;
     [nN])  ;;
        *)  input_err; createpkey ;;
    esac
    signcleanup
    echo "createpkey function complete" 1>> "$log"
}

# Set persistent keystore selection
savekey () {
    echo "savekey (save default keystore setting) function" 1>> "$log"
    if [[ ! ${keystore##*.} = [kK][eE][yY][sS][tT][oO][rR][eE] ]]; then
        echo $bred"Error, invalid or no keystore selected."; $rclr;
        signpanykey
    else
        local key="keychoice"
        local value="${keystore}"
        write_preference
    fi
}

# Actually delete a private key/keystore
delpkey () {
    echo "delpkey, actually deleting now" 1>> "$log"
    cd "${HOME}/.apkmanager/.keystores"
    echo "removing ${keystore}" 1>> "$log" 2>&1
    rm "${keystore}"
    rm ".${keystore%%.*}_keyname"
    clean_keystore
}

# Delete a private key/keystore prompt
delkey () {
    echo "delkey (delete private key) function" 1>> "$log"
    if [[ ! ${keystore##*.} = [kK][eE][yY][sS][tT][oO][rR][eE] ]]; then
        echo $bred"Error, invalid or no keystore selected."; $rclr;
        signpanykey
    else
        storename="${keystore%%.*}"
        key="$(awk '{ print $0}' "${HOME}/.apkmanager/.keystores/.${storename}_keyname")"
        echo $bgreen"Selected keystore is: ${keystore}"; $rclr;
        printf "$white%s""Delete this keystore? ("$bgreen"y"$white"/"$bgreen"n"$white") "; $rclr;
        read input
        case "$input" in
            [yY])  delpkey ;;
            [nN])  ;;
               *)  input_err delkey ;;
        esac
    fi
    echo "delkey function complete" 1>> "$log"
}
