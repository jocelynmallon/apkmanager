#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v2.1+
# Private Key & User Settings Migration functions
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.0
# Sun. Oct 07, 2012
# -----------------------------------------------------------------------

# Set migration status
setmigratestatus () {
    local key="migration"
    local value="true"
    write_preference
}

# Cleanup, unset variables
finishmigrate () {
    unset f
    unset count
    unset dir
    unset needmigrate
    unset usrsetting
    unset header_shown
    setmigratestatus
}

# Error when migrating private keys
migratekey_err () {
    if [[ -e "${HOME}/.apkmanager/.migration" ]]; then
        rm -r "${HOME}/.apkmanager/.migration"
    fi
    if [[ $(defaults read "${plist}" migration) -ne 0 ]]; then
        defaults delete "${plist}" migration 2>/dev/null
    fi
    echo $bred"ERROR MIGRATING keystore(s) to VERSION 2.1 SCHEMA"
    echo $bred"PLEASE CHECK LOG FOR DETAILS AND MANUALLY MOVE"
    echo $bred"EXISTING KEY(s) AND keystore(s) TO NEW LOCATION:"
    echo $bred"${HOME}/.apkmanager/.keystores/"
    printf "$bred%s""press any key to exit"; $rclr;
    wait
    exit 1
}

# Delete old key folder on succesfull migration
finishkeymigrate () {
    echo $bred"removing old ${maindir}/other/.keystores directory"; $rclr;
    echo ""
    echo "removing old ${maindir}/other/.keystores directory" 1>> "$log"
    rm -r "${maindir}/other/.keystores"
    echo $bgreen"Succesfully migrated to v2.1+ private key schema!"; $rclr;
    echo "Succesfully migrated to v2.1+ private key schema" 1>> "$log"
}

# Actually migrate user private keys
keymigrate () {
    if [[ -d "${maindir}/other/.keystores" ]] && [[ ! -d "${HOME}/.apkmanager/.keystores" ]]; then
        echo $white" Found old private KEY(s) in:"
        echo $green" ${maindir}/other/.keystores"; $rclr;
        echo $white" Migrating private KEY(s) to:"
        echo $green" ${HOME}/.apkmanager/.keystores"; $rclr;
        echo "Migrating private KEY(s) to ${HOME}/.apkmanager/.keystores" 1>> "$log"
        cp -pRv "${maindir}/other/.keystores" "${HOME}/.apkmanager" 1>> "$log" 2>&1
        if [[ $? -ne 0 ]]; then
            echo "ERROR MIGRATING PRIVATE KEYS TO v2.1 SCHEMA" 1>> "$log"
            migratekey_err
        else
            finishkeymigrate
        fi
    elif [[ ! -d "${maindir}/other/.keystores" ]] && [[ ! -d "${HOME}/.apkmanager/.keystores" ]]; then
        echo $white"No existing keys found, creating new private key directory in:"; $rclr;
        echo $green"${HOME}/.apkmanager/.keystores"; $rclr;
        mkdir -p "$HOME/.apkmanager/.keystores"
    elif [[ -d "${maindir}/other/.keystores" ]] && [[ -d "${HOME}/.apkmanager/.keystores" ]]; then
        echo $white"Found both old private KEY(s) directory in:"
        echo $green"${maindir}/other/.keystores"; $rclr;
        echo $white"and new v2.1+ private KEY(s) directory in:"
        echo $green"${HOME}/.apkmanager/.keystores"; $rclr;
        echo $white"comparing "$bgreen"${maindir}/other/.keystores"; $rclr;
        echo $white"to "$bgreen"${HOME}/.apkmanager/.keystores"; $rclr;
        echo "comparing ${maindir}/other/.keystores to ${HOME}/.apkmanager/.keystores" 1>> "$log"
        diff -rq "${maindir}/other/.keystores" "${HOME}/.apkmanager/.keystores" 1>> "$log" 2>&1
        if [[ $? -ne 0 ]]; then
            echo "ERROR MIGRATING PRIVATE KEYS TO v2.1+ SCHEMA" 1>> "$log"
            migratekey_err
        else
            echo $bgreen"Directories match, key migration already completed."; $rclr;
            finishkeymigrate
        fi
    else
        echo $bgreen"Already using v2.1+ private key schema"; $rclr;
        echo ""
        echo "Already using v2.1+ private key schema" 1>> "$log"
    fi
}

# Actually migrate user settings
migrate_settings () {
    echo "migrate_settings (migrate settings to v3.0+ plist) function" 1>> "$log"
    if [[ ${needmigrate} = v2 ]]; then
        dir="${maindir}/other"
    else
        dir="${HOME}/.apkmanager"
    fi
    for f in ".debuginfo" ".migration" ".debug" ".colors"
    do
        if [[ -e "${dir}/${f}" ]]; then
            rm -r "${dir}/${f}"
        fi
    done
    for f in ".complvl" ".heap" ".keychoice" ".logviewapp" ".pngtool"
    do
        if [[ -e "${dir}/${f}" ]]; then
            if [[ ${f} = .complvl ]]; then
                usrsetting="persistent compression level"
            elif [[ ${f} = .heap ]]; then
                usrsetting="persistent java heap size"
            elif [[ ${f} = .keychoice ]]; then
                usrsetting="persistent private keystore selection"
            elif [[ ${f} = .logviewapp ]]; then
                usrsetting="text/log viewing application selection"
            elif [[ ${f} = .pngtool ]]; then
                usrsetting="persistent png tool setting"
            fi
            echo $white" found $(basename ${dir}/${f}) file "$bgreen"(${usrsetting})"; $rclr;
            echo $white" writing preference into plist file..."; $rclr;
            local key="${f##*.}"
            local value="$(awk '{print $0}' "${dir}/${f}")"
            write_preference
            rm -r "${dir}/${f}"
        fi
    done
    if [[ ${needmigrate} = v3 ]]; then
        unset needmigrate
    fi
    echo "migrate_settings function complete" 1>> "$log"
}

# Main migration skeleton
migrate () {
    echo "migrate (check/migrate settings & private keys) function" 1>> "$log"
    if [[ -z ${header_shown} ]]; then
        clear
        echo ""
        version_banner
        echo ""
        echo $bwhite"APK Manager OS X migrate script (migrate user settings and private keys to v3.0+ schema)"
        echo "This should only appear on first launch of APK Manager, or when manually upgrading"
        echo "individual APK Manager files to version 3.0a or greater."; $rclr;
        header_shown=1
    fi
    echo ""
    echo $bgreen"Checking for pre ${needmigrate} persistent user settings to migrate..."
    echo ""
    migrate_settings
    if [[ -z ${needmigrate} ]]; then
        echo $bgreen"v3.0+ user settings migration complete!"; $rclr;
        echo ""
        echo $bgreen"Checking for private key(s) to migrate..."; $rclr;
        keymigrate
        echo ""
    fi
    echo "migrate function complete" 1>> "$log"
}

# Check for anything post v2.1 but pre v3.0
migrate_check_two () {
    local dir="${HOME}/.apkmanager"
    local f
    local count
    for f in ".complvl" ".heap" ".keychoice" ".logviewapp" ".pngtool" ".debuginfo" ".migration" ".debug" ".colors"
    do
        if [[ -e "${dir}/${f}" ]]; then
            count=$((count+1))
        fi
    done
    if [[ $count -ne 0 ]]; then
        needmigrate="v3"
    fi
    cd "${maindir}"
}

# Check for anything pre-2.1
migrate_check_one () {
    local dir="${maindir}/other"
    local f
    local count
    for f in ".complvl" ".heap" ".keychoice" ".logviewapp" ".pngtool" ".keystores" ".debuginfo"
    do
        if [[ -e "${dir}/${f}" ]]; then
            count=$((count+1))
        fi
    done
    if [[ $count -ne 0 ]]; then
        needmigrate="v2"
    fi
    cd "${maindir}"
}

# Migration check skeleton
migratecheck () {
    user_dir_check
    migrate_check_one
    if [[ ${needmigrate} ]]; then
        migrate
    fi
    migrate_check_two
    if [[ ${needmigrate} ]]; then
        migrate
        finishmigrate
        genericpanykey
    else
        echo "Nothing to migrate" 1>> "$log" 2>&1
        finishmigrate
    fi
}

# Start
migratecheck
return 0
