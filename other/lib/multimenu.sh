#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Dynamic, array-built multi-selection menu
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.2b
# Mon. Nov 4, 2013
# -----------------------------------------------------------------------

# cleanup and unset all variables used
mmcleanup () {
    unset files
    unset count
    unset input
    unset mkey
    unset pages
    unset pindex
    unset scount
    unset limit
    unset rem
    unset total
    unset pnum
    unset apktver
    unset sdkrev
    unset spasswrd
}

# keystore menu finish function
adbd_finish () {
    adb_dev_choice="${files[$input]}"
    adb_dev_model="${files[$input]}"
    adb_dev_product="${files[$input]}"
    adb_dev_device="${files[$input]}"
    set_adb_device_info
    echo "==> Selected ADB device ID is: ${adb_dev_choice}" 1>> "$log" 2>&1
    echo "==> ADB device: ${adb_dev_device}, model: ${adb_dev_model}, product: ${adb_dev_product}" 1>> "$log" 2>&1
}

# keystore menu finish function
sign_finish () {
    keystore="${files[$input]}"
    echo "==> Selected Keystore is: ${keystore}" 1>> "$log" 2>&1
}

# branch menu finish function
gitc_finish () {
    commit_detail="${files[$input]}"
    commit_detail="$(echo "${commit_detail}" | cut -d ' ' -f1)"
    commit_detail="$(echo $commit_detail | sed -E "s/\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")"
    git_commit_detail_view
    unset commit_detail
}

# branch menu finish function
gitb_finish () {
    local saved_channel="${files[$input]}"
    local key="updates_branch"
    local value="${files[$input]}"
    write_preference
    checkout_new_branch
    echo "==> Selected update branch is: ${saved_channel}" 1>> "$log" 2>&1
}

# projects menu finish function
proj_finish () {
    capp="${files[$input]}"
    prjext="${capp##*.}"
    echo "$logspr2" 1>> "$log" 2>&1
    echo "==> Selected Project file: ${capp}" 1>> "$log" 2>&1
    echo "==> Selected Project is an ${prjext} file" 1>> "$log" 2>&1
    echo "$logspr2" 1>> "$log" 2>&1
}

# apktool menu finish function
apkt_finish () {
    local apktjar="${files[$input]}"
    echo "$logspcr" 1>> "$log" 2>&1
    echo "==> Selected APKtool version is: ${apktver[$input]}" 1>> "$log" 2>&1
    echo "$logspcr" 1>> "$log" 2>&1
    ln -s -f -F "${aptdir}/${apktjar}" "${libdir}/apktool.jar"
    find "${HOME}/apktool/framework/" -type f -name "*.apk" -exec rm -rf {} \;
    getapktver
}

# android studio menu finish function
ands_finish () {
    if [[ -z $sdkrev ]]; then
        local sdkrev="${files[$input]}"
    fi
    clear
    version_banner
    echo ""
    echo $bgreen" You will need to enter your administrator password to continue."
    echo ""
    echo $green" First, APK Manager will generate a file with the fully qualified paths to the"
    echo $green" Android SDK tools embedded inside Android Studio:"
    echo ""
    echo $blue" touch \"/tmp/.android_studio\""
    echo $blue" echo \"/Applications/Android Studio.app/sdk/build-tools/${sdkrev}\" 1>> \"/tmp/.android_studio\""
    echo $blue" echo \"/Applications/Android Studio.app/sdk/tools/\" 1>> \"/tmp/.android_studio\""
    echo $blue" echo \"/Applications/Android Studio.app/sdk/platform-tools/\" 1>> \"/tmp/.android_studio\""
    echo ""
    echo $green" Then it will use SUDO/Administrator privilidges to copy the file to /etc/paths.d"
    echo ""
    echo $green" This is a special folder that the OSX path_helper tool checks whenever a new shell"
    echo $green" is opened, and adds the paths it finds to your global \$PATH variable."
    echo ""
    echo $bgreen" SUDO will be used to run the following command ONLY:"
    echo ""
    echo $blue" sudo -S cp -f \"/tmp/.android_studio\" \"/etc/paths.d/android_studio\""
    echo ""
    echo $bred" NOTE: your password is never recorded to disk, and is"
    echo $bred"       cleared from memory once this process completes."
    echo ""
    echo $bred" APK Manager will quit and need to be re-opened after this process completes."
    echo ""
    local spasswrd
    printf "$bgreen%s""Enter administrator/sudo password:"; $rclr;
    read -s spasswrd
    echo ""
    touch "/tmp/.android_studio"
    echo "/Applications/Android Studio.app/sdk/build-tools/$sdkrev" 1>> "/tmp/.android_studio"
    echo "/Applications/Android Studio.app/sdk/tools/" 1>> "/tmp/.android_studio"
    echo "/Applications/Android Studio.app/sdk/platform-tools/" 1>> "/tmp/.android_studio"
    echo $spasswrd | sudo -S cp -f "/tmp/.android_studio" "/etc/paths.d/android_studio"
    if [[ $? -ne 0 ]]; then
        echo "==> ERROR: unable to copy path file to /etc/paths.d/android_studio" 1>> "$log" 2>&1
    else
        echo "==> Copied paths file to /etc/paths.d/android_studio" 1>> "$log" 2>&1
    fi
    rm "/tmp/.android_studio"
    exit 0
}

# read and check user input
get_mmenu_input () {
    read input
    if [[ ${input} = [qQ] ]]; then
        if [[ $mkey = andstudio ]]; then
            fatal_err=$(($fatal_err+1))
        fi
        mmcleanup
    elif [[ ${input} = [qQ][qQ] ]]; then
        quit
    elif [[ ${input} = [nN] ]]; then
        if [[ ${pindex} -lt ${pages} ]]; then
            pindex="$((pindex + 1))"
            buildmenu
        else
            case ${mkey} in
                projects)  capp="None"; prjext=""; input_err; projects_menu ;;
                 apktool)  input_err; apktool_menu ;;
                 signing)  input_err; listpkeys ;;
                branches)  input_err; git_branches_menu ;;
                  adbdev)  input_err; adb_devices_menu ;;
                 commits)  input_err; git_log_menu ;;
               andstudio)  input_err; android_studio_menu ;;
            esac
        fi
    elif [[ ${input} = [bB] ]]; then
        if [[ ${pindex} -gt 1 ]]; then
            pindex="$((pindex - 1))"
            buildmenu
        else
            case ${mkey} in
                projects)  capp="None"; prjext=""; input_err; projects_menu ;;
                 apktool)  input_err; apktool_menu ;;
                 signing)  input_err; listpkeys ;;
                branches)  input_err; git_branches_menu ;;
                  adbdev)  input_err; adb_devices_menu ;;
                 commits)  input_err; git_log_menu ;;
               andstudio)  input_err; android_studio_menu ;;
            esac
        fi
    elif [[ ! ${input} =~ ^[0-9]+$ ]]; then
        case ${mkey} in
            projects)  capp="None"; prjext=""; input_err; projects_menu ;;
             apktool)  input_err; apktool_menu ;;
             signing)  input_err; listpkeys ;;
            branches)  input_err; git_branches_menu ;;
              adbdev)  input_err; adb_devices_menu ;;
             commits)  input_err; git_log_menu ;;
           andstudio)  input_err; android_studio_menu ;;
        esac
    elif [[ ${input} -lt ${scount} ]] || [[ ${input} -gt ${limit} ]]; then
        case ${mkey} in
            projects)  capp="None"; prjext=""; input_err; projects_menu ;;
             apktool)  input_err; apktool_menu ;;
             signing)  input_err; listpkeys ;;
            branches)  input_err; git_branches_menu ;;
              adbdev)  input_err; adb_devices_menu ;;
             commits)  input_err; git_log_menu ;;
           andstudio)  input_err; android_studio_menu ;;
        esac
    else
        case ${mkey} in
            projects)  proj_finish ;;
             apktool)  apkt_finish ;;
             signing)  sign_finish ;;
            branches)  gitb_finish ;;
              adbdev)  adbd_finish ;;
             commits)  gitc_finish ;;
           andstudio)  ands_finish ;;
        esac
    fi
}

# actually parse array items/files
parse_files () {
    for ((count=${scount}; count <= ${limit}; count++)); do
        if [[ ${mkey} = apktool ]]; then
            local apktvtmp1="$(java -jar "${aptdir}/${files[$count]}" | grep 'Apktool'| cut -d - -f1 | sed 's/^[ \t]*//;s/[ \t]*$//' | sed 's/\ /_/g')"
            apktver[$count]="${apktvtmp1%%-*}"
            if [[ ${count} -le 9 ]]; then
                echo $bgreen"  ${count}"$white"   ${files[$count]} "$blue"(${apktver[$count]})"; $rclr;
            elif [[ ${count} -ge 10 ]]; then
                echo $bgreen"  ${count}"$white"  ${files[$count]} "$blue"(${apktver[$count]})"; $rclr;
            fi
        else
            if [[ ${count} -le 9 ]]; then
                echo $bgreen"  ${count}"$white"   ${files[$count]}"; $rclr;
            elif [[ ${count} -ge 10 ]]; then
                echo $bgreen"  ${count}"$white"  ${files[$count]}"; $rclr;
            fi
        fi
    done
}

# set the range of items to show on the page
setup_page () {
    if [[ ${pages} -le 1 ]]; then
        pindex="${pages}"
        scount="1"
        limit="${total}"
    else
        if [[ -z ${pindex} ]]; then
            pindex="1"
        fi
        limit="$((pindex * ${pnum}))"
        scount="$((limit - $((pnum - 1))))"
        if [[ ${limit} -ge ${total} ]]; then
            if [[ ${rem} -ne 0 ]]; then
                local ldiff="$((pnum - ${rem}))"
                limit="$((limit - ${ldiff}))"
            fi
        fi
    fi
}

# check if we only need one page
page_check () {
    total="${#files[*]}"
    total="$((total -1))"
    pages="$((total / ${pnum}))"
    rem="$((total % ${pnum}))"
    if [[ ${rem} -ne 0 ]]; then
        pages="$((pages + 1))"
    fi
}

# check if menu type is set
check_mkey_set () {
    if [[ -z ${mkey} ]]; then
        return 1
    fi
}

# start building dynamic menu
buildmenu () {
    check_mkey_set
    clear
    if [[ ${mkey} = andstudio ]]; then
        version_banner
    else
        menu_header
    fi
    if [[ ${mkey} = projects ]]; then
        echo $bgreen"-----------------------------------"$bwhite"Select project file to work on"$bgreen"-----------------------------------";
    elif [[ ${mkey} = adbdev ]]; then
        debug_header
        echo $bgreen"----------------------------------------"$bwhite"Select an ADB Device"$bgreen"----------------------------------------";
        echo $bred" If Menu is empty, try reconnecting your devices USB cable, or setup a wireless adb connection."
        echo $bgreen"$apkmspr"
    elif [[ ${mkey} = apktool ]]; then
        debug_header
        echo $bgreen"------------------------------------------"$bwhite"APKtool Versions"$bgreen"------------------------------------------";
    elif [[ ${mkey} = signing ]]; then
        echo $bgreen"---------------------------------------"$bwhite"Select a keystore menu"$bgreen"---------------------------------------";
        echo $white" Current Keystore: "$bgreen"${keystore}"
        echo $bgreen"$apkmspr"
    elif [[ ${mkey} = commits ]]; then
        updates_header
        echo $bgreen"--------------------------------"$bwhite"Select commit to view detail history"$bgreen"--------------------------------";
        echo $green" Enter list number to see detailed commit information for the selected commit."
        echo $bgreen"$apkmspr"
    elif [[ ${mkey} = branches ]]; then
        updates_header
        echo $bgreen"----------------------------------------"$bwhite"Select update branch"$bgreen"----------------------------------------";
        echo $bred" Warning: APK Manager will automatically quit once the new branch has been checked out."
        echo $bgreen"$apkmspr"
    elif [[ ${mkey} = andstudio ]]; then
        echo ""
        echo $bgreen"-------------------------------"$bwhite"Select Android Studio Platform Version"$bgreen"-------------------------------";
        echo $bred" Note: due to the way updates are handled to the Android SDK, most tools (adb, zipalign, monitor,"
        echo $bred"       draw9patch) will always be from the newest platform installed, regardless of your choice."
        echo $bred"       The choice here will effect which version of \"aapt\" and other build-tools are used."
        echo $bgreen"$apkmspr"
        echo $bred" Note: the \"android-4.2.2\" option is API level 17."
        echo $bgreen"$apkmspr"
    fi
    page_check
    setup_page
    parse_files
    echo $bgreen"$apkmftr";
    if [[ ${pages} -ge 2 ]]; then
        echo $white"(use "$bgreen"N"$white" to go to next page, "$bgreen"B"$white" to go back to previous page, or "$bgreen"Q"$white" to quit)"; $rclr;
    else
        echo $white"(use "$bgreen"Q"$white" to quit)"; $rclr;
    fi
    printf "$bwhite%s""Please select an option from above: "; $rclr;
    get_mmenu_input
}

# parse the ADB devices command
populate_adb_devices () {
    adb devices -l | while read line;
    do
        if [[ "${line}" = *daemon* ]] || [[ "${line}" = *List* ]]; then
            :
        else
            echo "${line}"
        fi
    done
}

# parse the git log/commits history
populate_git_commits () {
    git log --pretty=format:"%Cred%h%Creset | %Cgreen%ad%Creset | %s" --date=short | while read line;
    do
        echo "${line}"
    done
}

# check for existing array before starting
check_files_set () {
    if [[ $files ]]; then
        unset files
    fi
}

# android studio platforms default only check
and_studio_platforms_check () {
#    if [[ ${files[1]} = "android-4.2.2" ]]; then
    if [[ ${#files[@]} -eq 2 ]]; then
        sdkrev="${files[1]}"
        ands_finish
    else
        pnum=19
        buildmenu
    fi
    mmcleanup
}

# Projects menu
projects_menu () {
    check_files_set
    mkey="projects"
    cd "${maindir}/${mod_dir}"
    files[0]="projects_menu - YOU SHOULD NOT SEE THIS"
    files+=( $(ls *.[aA][pP][kK] *.[jJ][aA][rR]) )
    pnum=29
    buildmenu
    mmcleanup
}

# Keystore menu
listpkeys () {
    check_files_set
    mkey="signing"
    cd "${HOME}/.apkmanager/.keystores"
    files[0]="listpkeys - YOU SHOULD NOT SEE THIS"
    files+=( $(ls *.[kK][eE][yY][sS][tT][oO][rR][eE]) )
    pnum=27
    buildmenu
    mmcleanup
}

# Apktool.jar menu
apktool_menu () {
    check_files_set
    mkey="apktool"
    cd "${aptdir}"
    files[0]="apktool_menu - YOU SHOULD NOT SEE THIS"
    files+=( $(ls [aA][pP][kK][tT][oO][oO][lL]_*.[jJ][aA][rR]) )
    pnum=20
    buildmenu
    mmcleanup
}

# git/update branches menu
git_branches_menu () {
    check_files_set
    mkey="branches"
    cd "${maindir}/.git/refs/remotes/origin"
    files[0]="git_branches_menu - YOU SHOULD NOT SEE THIS"
    files+=( $(ls -1) )
    pnum=20
    buildmenu
    mmcleanup
}

# git log/commit history menu
git_log_menu () {
    check_files_set
    mkey="commits"
    cd "${maindir}"
    OLDIFS=$IFS
    IFS=$'\n'
    files[0]="git_branches_menu - YOU SHOULD NOT SEE THIS"
    files+=( $(populate_git_commits) )
    IFS=$OLDIFS
    pnum=19
    buildmenu
    mmcleanup
}

# android studio platform selection menu
android_studio_menu () {
    check_files_set
    mkey="andstudio"
    cd "/Applications/Android Studio.app/sdk/build-tools"
    OLDIFS=$IFS
    IFS=$'\n'
    files[0]="android_studio_menu - YOU SHOULD NOT SEE THIS"
    files+=( $(ls | sort) )
    IFS=$OLDIFS
    and_studio_platforms_check
}

# ADB connected devices menu
adb_devices_menu () {
    check_files_set
    mkey="adbdev"
    cd "${maindir}"
    OLDIFS=$IFS
    IFS=$'\n'
    files[0]="adb_devices_menu - YOU SHOULD NOT SEE THIS"
    files+=( $(populate_adb_devices) )
    IFS=$OLDIFS
    pnum=18
    buildmenu
    mmcleanup
}
