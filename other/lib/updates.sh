#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Automatic Updates functions
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.0
# Sun. Oct 07, 2012
# -----------------------------------------------------------------------

# setup git repo address
git_origin="git://github.com/jocelynmallon/apkmanager.git"

# cleanup all variables used by update functions
updates_cleanup () {
    unset last_epoch
    unset upromptstate
    unset epoch_diff
    unset old_commit
    unset new_commit
    unset channel_ver
    unset saved_channel
    unset input
    unset last_check
    unset last_time
    unset key
    unset value
    unset commit
    unset uprompt
    unset ufreq
    unset last_check
    unset last_time
    unset updfreq
}

# get the current revision of HEAD
get_commit_ver () {
    echo $(git rev-parse -q --verify HEAD)
}

# get the current git branch
get_current_branch () {
    echo $(git symbolic-ref HEAD)
}

# Disable confirmation prompt when updating
enable_update_prompt () {
    local key="updates_prompt"
    local value="true"
    write_preference
}

# Enable confirmation prompt when updating
disable_update_prompt () {
    local key="updates_prompt"
    local value="false"
    write_preference
}

# Configure automatic updates
disable_auto_updates () {
    local key="updates"
    local value="false"
    write_preference
}

# Configure automatic updates
enable_auto_updates () {
    local key="updates"
    local value="true"
    write_preference
    if [[ ! -d "${maindir}"/.git ]]; then
        updates_init_prompt
    fi
}

# Write log message on successful git checkout
branch_change_log () {
    echo "CHECKOUT COMPLETE: $(gen_date)" 1>> "$log" 2>&1
    echo "$apkmftr" 1>> "$log" 2>&1
}

# try to checkout the selected branch
checkout_new_branch () {
    echo "checkout_new_branch (change branches now)" 1>> "$log"
    cd "${maindir}"
    echo "==> checking out branch: ${saved_channel}" 1>> "$log"
    if [[ $(git branch | grep "${saved_channel}") ]]; then
        git checkout -q "${saved_channel}" 2>> "$log"
        if [[ $? -ne 0 ]]; then
            git_checkout_error
            exit 1
        else
            branch_change_log
            exit 0
        fi
    else
        git checkout -t -q "origin/${saved_channel}" 2>> "$log"
        if [[ $? -ne 0 ]]; then
            git_checkout_error
            exit 1
        else
            branch_change_log
            exit 0
        fi
    fi
}

# placeholder - change branch
change_update_branch () {
    if [[ $(ls -1 "${maindir}"/.git/refs/remotes/origin | wc -l) -eq 1 ]]; then
        no_branches_err
        return 1
    else
        git_branches_menu
    fi
}

# Change the number of days between updates
change_update_freq () {
    printf "$white%s""Enter number of days to wait between update checks ("$bgreen"1-31"$white")\n"; $rclr;
    printf "$white%s""("$green"i.e. 1 means check every 24 hours, 2 is 48 hours, etc."$white"): "; $rclr;
    read input
    if [[ ! ${input} = *[^0-9]* ]] && [[ ${input} -ge 1 ]] && [[ ${input} -le 31 ]]; then
        local key="updates_freq"
        local value="${input}"
        write_preference
        echo "==> update frequency set to: ${input} days" 1>> "$log" 2>&1
    else
        echo $bred"Error: ${input} is not valid, press any key to try again"; $rclr;
        wait
        change_update_freq
    fi
    unset input
}

# placeholder - force update check
force_update_check () {
    echo "force_update_check (force updates check now)" 1>> "$log"
    update_apkm
    if [[ ! ${new_commit} = ${old_commit} ]]; then
        echo "force_update_check complete" 1>> "$log"
        updates_complete_log
        exit 0
    elif [[ ! ${channel_ver} = ${saved_channel} ]]; then
        echo "force_update_check complete" 1>> "$log"
        echo $bgreen"Manual/forced update check complete!"; $rclr;
        git_branch_change
        updates_complete_log
        exit 0
    else
        echo "force_update_check complete" 1>> "$log"
    fi
}

# get the date and time of the last update check
build_last_date_time () {
    last_check="$(defaults read "${plist}" updates_last_date 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        last_check="Never"
    else
        last_check="$(echo "${last_check}" | sed 's/_/\ /g')"
        last_time="$(defaults read "${plist}" updates_last_time 2>/dev/null)"
        last_time="$(echo "${last_time}" | sed 's/_/\ /g')"
        last_check="${last_check}${white} at: ${green}${last_time}"
    fi
}

# Initialize an empty repo if necessary
updates_init_repo () {
    if [[ ! -d "${maindir}"/.git ]]; then
        echo ".git repo not found, initializing repo" 1>> "$log"
        cd "${maindir}"
        echo "==> git init..." 1>> "$log"
        git init 2>> "$log"
        echo "==> git config core.autocrlf false..." 1>> "$log"
        git config core.autocrlf false 2>> "$log"
        echo "==> git config branch.autosetuprebase always..." 1>> "$log"
        git config branch.autosetuprebase always
        echo "==> git remote add origin..." 1>> "$log"
        git remote add origin "${git_origin}" 2>> "$log"
        echo "==> git remote fetch origin..." 1>> "$log"
        git fetch origin 2>> "$log"
        echo "==> git reset --hard origin/master..." 1>> "$log"
        git reset --hard origin/master 2>> "$log"
    fi
}

# prompt user to initiliaze the git repo
updates_init_prompt () {
    clear
    echo ""
    version_banner
    echo ""
    echo $white" In order to enable automatic updates, APK Manager must be set"
    echo $white" up to use git, and track a remote repository on github:"; $rclr;
    echo ""
    echo $green"  https://github.com/jocelynmallon/apkmanager"; $rclr;
    echo ""
    echo $white" APK Manager will run the following commands:"; $rclr;
    echo ""
    echo $bgreen"  1  "$green"cd ${maindir}"
    echo $bgreen"  2  "$green"git init"
    echo $bgreen"  3  "$green"git config core.autocrlf false"
    echo $bgreen"  4  "$green"git config branch.autosetuprebase always"
    echo $bgreen"  5  "$green"git remote add origin ${git_origin}"
    echo $bgreen"  6  "$green"git fetch origin"
    echo $bgreen"  7  "$green"git reset --hard origin/master"; $rclr;
    echo ""
    echo $white" To (hopefully) minimize errors with this process,"
    echo $white" APK Manager will quit automatically once completed."
    echo $bgreen"$apkmspr"
    genericpanykey
    updates_init_repo
    echo ""
    echo $bgreen"$apkmftr"
    fatalpanykey
    echo "GIT INIT COMPLETE: $(gen_date)" 1>> "$log" 2>&1
    echo "$apkmftr" 1>> "$log" 2>&1
    exit 0
}

# Make sure 'git' was used to install
updates_git_check () {
    if [[ ! $(command -v git) ]]; then
        updates_git_err
    else
        updates_menu
    fi
}

# apkmanager was updated message
yes_update_message () {
    clear
    echo ""
    version_banner
    echo $bgreen"          _    ____  _  ____  __    _    _   _    _    ____ _____ ____     ___  ____  __  __ "
    echo $bgreen"         / \  |  _ \| |/ /  \/  |  / \  | \ | |  / \  / ___| ____|  _ \   / _ \/ ___| \ \/ / "
    echo $bgreen"        / _ \ | |_) | ' /| |\/| | / _ \ |  \| | / _ \| |  _|  _| | |_) | | | | \___ \  \  /  "
    echo $bgreen"       / ___ \|  __/| . \| |  | |/ ___ \| |\  |/ ___ \ |_| | |___|  _ <  | |_| |___) | /  \  "
    echo $bgreen"      /_/   \_\_|   |_|\_\_|  |_/_/   \_\_| \_/_/   \_\____|_____|_| \_\  \___/|____/ /_/\_\ "
    echo $bgreen""
    echo $bgreen"$apkmspr"; $rclr;
    echo ""
    echo $bwhite" APK Manager for OSX succesfully updated from "$bgreen"${old_commit} "$bwhite"to "$bgreen"${new_commit} "$bwhite"!"
    echo $bwhite" APK Manager for OSX is currently on the "$bgreen"${channel_ver} "$bwhite"branch/channel"
    echo $bwhite" You can change the branch/channel for updates in the debug/settings"
    echo $bwhite" menu, and/or disable automatic updates entirely."
    echo ""
    echo $bred" APK Manager will now exit, please re-launch to complete the update."
    echo $bgreen"$apkmftr"
    echo "APK Manager updated from ${old_commit} to ${new_commit}" 1>> "$log"
    echo "==> on update branch/channel: ${saved_channel}" 1>> "$log"
    genericpanykey
}

# apkmanager wasn't updated message
no_update_message () {
    echo $bgreen"APK Manager is already up to date!"; $rclr;
    echo "APK Manager already up to date @: ${new_commit}" 1>> "$log"
    genericpanykey
}

# fancy display message on succesful update
finish_message () {
    if [[ ! ${new_commit} = ${old_commit} ]]; then
        yes_update_message
    else
        no_update_message
    fi
}

update_branch_check () {
    saved_channel="$(defaults read "${plist}" updates_branch 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        saved_channel="master"
        local key="updates_branch"
        local value="master"
        write_preference
    fi
}

# Actually checking for updates now
update_apkm () {
    echo "update_apkm (actually checking for updates now)" 1>> "$log"
    cd "${maindir}"
    echo "==> git config core.autocrlf false ..." 1>> "$log"
    git config core.autocrlf false
    if [[ $? -ne 0 ]]; then
        git_config_error
        return 1
    fi
    echo "==> git config branch.autosetuprebase always ..." 1>> "$log"
    git config branch.autosetuprebase always
    if [[ $? -ne 0 ]]; then
        git_config_error
        return 1
    fi
    channel_ver="$(get_current_branch)"
    channel_ver="${channel_ver#refs/heads/}"
    update_branch_check
    if [[ ! ${channel_ver} = ${saved_channel} ]]; then
        echo "Checking out branch: ${saved_channel}" 1>> "$log"
        git checkout -q ${saved_channel} 2>> "$log"
        if [[ $? -ne 0 ]]; then
            git_checkout_error
            return 1
        fi
    fi
    old_commit="$(get_commit_ver)"
    old_commit="${old_commit:0:8}"
    echo "==> git pull -q origin ${saved_channel} ..." 1>> "$log"
    git pull -q origin refs/heads/${saved_channel}:refs/remotes/origin/${saved_channel} 2>> "$log"
    if [[ $? -ne 0 ]]; then
        git_pull_error
        return 1
    else
        new_commit="$(get_commit_ver)"
        new_commit="${new_commit:0:8}"
        finish_message
    fi
    update_last_epoch
    echo "update_apkm complete" 1>> "$log"
}

# Generate epoch to check against
gen_epoch () {
    echo $(($(date +%s) / 60 / 60 / 24))
}

# Write last update epoch, date and time to plist
update_last_epoch () {
    local key="updates_last_epoch"
    local value="$(gen_epoch)"
    write_preference
    local key="updates_last_date"
    local value="$(date +"%b_%d_%Y")"
    write_preference
    local key="updates_last_time"
    local value="$(date +"%T_%Z")"
    write_preference
}

# Prompt user if they want to check for updates
updates_check_prompt () {
    printf "$white%s""Would you like to check for updates to APK Manager? ("$bgreen"y"$white"/"$bgreen"n"$white") "; $rclr;
    read input
    case $input in
        [yY]) update_apkm ;;
        [nN]) update_last_epoch; echo "user cancelled update check" 1>> "$log" ;;
           *) input_err; updates_check_prompt ;;
    esac
}

# Check if the update prompt is disabled
update_prompt_state () {
    upromptstate="$(defaults read "${plist}" updates_prompt 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        local key="updates_prompt"
        local value="true"
        write_preference
        upromptstate=1
    fi
}

# Check number of days to wait between updates
check_update_freq () {
    ufreq="$(defaults read "${plist}" updates_freq 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        ufreq="6"
        local key="updates_freq"
        local value="${ufreq}"
        write_preference
    fi
}

# write a log message on completion before exit
updates_complete_log () {
        echo "UPDATE COMPLETE: $(gen_date)" 1>> "$log" 2>&1
        echo "$apkmftr" 1>> "$log" 2>&1
}

# Check status of automatic updates
updates_status () {
    echo "updates_status (check for updates) function" 1>> "$log"
    if [[ ! -d "${maindir}"/.git ]]; then
        updates_init_prompt
    fi
    last_epoch="$(defaults read "${plist}" updates_last_epoch 2>/dev/null)"
    if [[ $? -ne 0 ]] || [[ -z ${last_epoch} ]]; then
        local key="updates_last_epoch"
        local value="$(gen_epoch)"
        write_preference
        return 0
    fi
    epoch_diff=$(($(gen_epoch) - ${last_epoch}))
    check_update_freq
    if [[ ${epoch_diff} -ge ${ufreq} ]]; then
        update_prompt_state
        if [[ ${upromptstate} -eq 0 ]]; then
            update_apkm
        else
            updates_check_prompt
        fi
    fi
    if [[ ! ${new_commit} = ${old_commit} ]]; then
        updates_cleanup
        echo "updates_status complete" 1>> "$log"
        updates_complete_log
        exit 0
    elif [[ ! ${channel_ver} = ${saved_channel} ]]; then
        git_branch_change
        updates_cleanup
        echo "updates_status complete" 1>> "$log"
        updates_complete_log
        exit 0
    else
        updates_cleanup
    fi
    echo "updates_status complete" 1>> "$log"
}
