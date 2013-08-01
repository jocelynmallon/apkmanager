#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Various ADB functions
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.0
# Sun. Oct 07, 2012
# -----------------------------------------------------------------------


# Failed to find ADB device, clear settings
adb_device_integrity_failure () {
    echo "==> BAD saved ADB device, resetting..." 1>> "$log" 2>&1
    clean_adb_device
}

adb_device_integrity_sub () {
    if [[ -z $adb_dev_choice ]]; then
        adb_device_integrity_failure
    else
        local adbstat="$(timeout3 -t 5 adb -s ${adb_dev_choice} get-state)"
        if [[ ! ${adbstat} = "device" ]]; then
            adb_saved_device_state_error
            adb_device_integrity_failure
        else
            echo "==> ADB device ${adb_dev_choice} connected" 1>> "$log" 2>&1
        fi
    fi
}

# check for connected ADB device
adb_device_integrity_check () {
    echo "adb_device_startup_check (checking for saved ADB device)" 1>> "$log"
    if [[ $adb_connect_on_start -ne 1 ]]; then :
    else
        if [[ -z $adb_dev_choice ]] || [[ -z $adb_dev_model ]] || [[ -z $adb_dev_product ]] || [[ -z $adb_dev_device ]]; then
            echo "No preferred ADB device setting found" 1>> "$log" 2>&1
        elif [[ "${adb_dev_choice}" = *List* ]] || [[ "${adb_dev_choice}" = *daemon* ]]; then
            adb_saved_device_error
            adb_device_integrity_failure
        else
            if [[ $adb_dev_choice = *.* ]]; then
                echo "saved device pref is for wireless adb, trying to connect..." 1>> "$log"
                local adb_startup_check=1
                adb_wireless_try_connect
            fi
            echo "trying to get state of saved device..." 1>> "$log"
            adb_device_integrity_sub
        fi
    fi
}

# try and retrieve saved/persistant ADB device choice
get_saved_adb_device () {
    trap - 0 ERR
    local p
    local v
    for p in "adb_dev_choice" "adb_dev_model" "adb_dev_product" "adb_dev_device"
    do
        v="$(defaults read "${plist}" ${p} 2>/dev/null)"
        if [[ $? -ne 0 ]]; then :
        else
            eval $p=\${v}
        fi
    done
    if [[ -z $adb_dev_choice ]] && [[ -z $adb_dev_model ]] && [[ -z $adb_dev_product ]] && [[ -z $adb_dev_device ]]; then
        adb_dev_choice="none"
    fi
    trap 'err_trap_handler ${LINENO} $? ${FUNCNAME}' ERR
}

# Pull a file from device with adb
adb_pull () {
    echo "adb_pull function" 1>> "$log"
    adb_multiple_devices_check
    if [[ $? -ne 0 ]]; then
        return 1
    else
        echo $bwhite"Where do you want ADB to pull the apk/jar from? ";
        echo $green"Example of input : /system/app/launcher.apk";
        echo $green"(leave blank and press enter to return to main menu)"; $rclr;
        read input
        if [[ -z $input ]]; then :
        else
            local outfile="$(basename "${input}")"
            adb -s "${adb_dev_choice}" wait-for-device pull "$input" "${maindir}/${mod_dir}/${outfile}"
            if [[ $? -ne 0 ]]; then
                echo $bred"Error: while pulling ${outfile}"; $rclr;
                pressanykey
            fi
        fi
    fi
    unset input
    echo "adb_pull function complete" 1>> "$log"
}

# Normal ADB push
norm_push () {
    adb -s "${adb_dev_choice}" wait-for-device push "${maindir}/${mod_dir}/unsigned-${capp}" "${input}"
    printf "$bwhite%s""Press any key to continue "; $rclr;
    wait
}

# Advanced ADB push
adv_push () {
    adb -s "${adb_dev_choice}" shell stop
    norm_push
    adb -s "${adb_dev_choice}" shell start
}

# Prompt for ADB push destination
push_prompt () {
    echo "push_prompt (push destination prompt) function" 1>> "$log"
    clear
    echo $bwhite"Where do you want ADB to push to and as what name: ";
    echo $green"(leave blank and press enter to return to main menu)";
    echo ""
    echo $green"Example of input : /system/app/launcher.apk "; $rclr;
    read input
    if [[ -z $input ]]; then :
    else
        echo "Attempting to push unsigned-${capp} to:"
        timeout3 -t 5 adb devices | grep "${adb_dev_choice}"
        printf "$bwhite%s""Press any key to continue "; $rclr;
        wait
        adb -s "${adb_dev_choice}" wait-for-device remount
        if [[ ${push_type} = normal ]]; then
            norm_push
        elif [[ ${push_type} = advanced ]]; then
            adv_push
        fi
    fi
    echo "push_prompt function complete" 1>> "$log"
}

# Cleanup variables used in ADB push functions
push_cleanup () {
    unset input
    unset push_type
}

# Prompt for ADB push type
adb_push () {
    echo "adb_push (push type prompt) function" 1>> "$log"
    capp_test
    if [[ ${capp} = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
        return 1
    elif [[ ! -f "${maindir}/${mod_dir}/unsigned-${capp}" ]]; then
        echo $bred"Error, cannot find file: unsigned-${capp}";
        echo $bred"Please use \"zip\" or \"compile\" options first"; $rclr;
        pressanykey
    else
        adb_multiple_devices_check
        if [[ $? -ne 0 ]]; then
            return 1
        else
            echo $bwhite"Which ADB push option would you like to perform?";
            echo $bgreen"  1 "$white"  Simple  "$green"(ADB push only)";
            echo $bgreen"  2 "$white"  Advanced  "$green"(ADB shell stop, push, shell start)";
            printf "$bwhite%s""Please make your decision: "; $rclr;
            read input
            case "$input" in
                1)  push_type="normal"; push_prompt ;;
                2)  push_type="advanced"; push_prompt ;;
                *)  input_err; adb_push ;;
            esac
        fi
    fi
    push_cleanup
    echo "adb_push function complete" 1>> "$log"
}

# generate an ADB screenshot
adb_screenshot () {
    if [[ $adb_screencap -ne 0 ]]; then
        adb_multiple_devices_check
        if [[ $? -ne 0 ]]; then
            return 1
        else
            local file="$(/bin/date +"%d-%b-%Y_%I.%M.%S").png"
            local dir="${maindir}/screencaps"
            if [[ ! -d $dir ]]; then
                mkdir -p "${dir}"
            fi
            echo $green"trying to generate an ADB screencap..."; $rclr;
            timeout3 -t 8 adb -s "${adb_dev_choice}" shell screencap -p | perl -pe 's/\x0D\x0A/\x0A/g' > "$dir/$file"
        fi
    else
        input_err
        ${ret_menu}
    fi
}

# toggle hidden SS menu option to take screenshots
adb_screencap_toggle () {
    local key="adb_screencap"
    if [[ $adb_screencap -ne 0 ]]; then
        adb_screencap=0
        local value="false"
    elif [[ $adb_screencap -eq 0 ]]; then
        adb_screencap=1
        local value="true"
    fi
    write_preference
}

# toggle hidden SS menu option to take screenshots
adb_connect_on_start_toggle () {
    local key="adb_connect_on_start"
    if [[ $adb_connect_on_start -ne 0 ]]; then
        adb_connect_on_start=0
        local value="false"
    elif [[ $adb_connect_on_start -eq 0 ]]; then
        adb_connect_on_start=1
        local value="true"
    fi
    write_preference
}

# Read ADB logcat file if it exists
read_adb_log () {
    if [[ -e "${maindir}/ADBLOG.txt" ]]; then
        txt="${maindir}/ADBLOG.txt" 2>> "$log"
        read_txt
    else
        echo $bred"ERROR: no adblog.txt file found."
        debuganykey
    fi
}

# Open an ADB shell
adb_shell () {
    if [[ $(command -v adb) ]]; then
        adb_multiple_devices_check
        if [[ $? -ne 0 ]]; then
            return 1
        else
            local apkmopt="adb -s ${adb_dev_choice} wait-for-device shell; exit"
            newttab "${apkmopt}" "$log"
        fi
    elif [[ ! $(command -v adb) ]]; then
        echo $bred"ERROR: ADB not found on the system."
        debuganykey
    fi
}

# actually try and connect to the wireless ADB device
adb_wireless_try_connect () {
    echo "adb_wireless_try_connect (try to connect to wireless ADB device)" 1>> "$log"
    if [[ -n $adb_ip ]] && [[ -n $adb_port ]]; then
        adb_dev_choice="${adb_ip}:${adb_port}"
    fi
    echo $green"Trying to connect wireless ADB on: "$bgreen"${adb_dev_choice}"
    timeout3 -t 5 adb connect "${adb_dev_choice}" 1> /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        adb_wireless_connection_error
        unset adb_dev_choice
    fi
}

# test if the IP address is valid
adb_wireless_ip_test () {
    local adb_port="${input##*:}"
    local adb_ip="${input%%:*}"
    iptest ${adb_ip} 1> /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo $bred"Error: ${adb_ip} is invalid, press any key to try again"; $rclr;
        wait
        adb_wireless_connect_prompt
    else
        if [[ ${adb_port} = ${adb_ip} ]]; then
            adb_port=5555
        fi
        adb_wireless_try_connect
    fi
}

# prompt for IP address to try and connect to
adb_wireless_connect_prompt () {
    printf "$bwhite%s""Please enter IP address of your device: "; $rclr;
    read input
    if [[ $input = [qQ] ]]; then :
    else
        adb_wireless_ip_test
    fi
    unset input
}

# setup an wireless ADB connection
adb_wireless_connect () {
    echo "adb_wireless_connect (setup wireless adb) function" 1>> "$log"
    clear
    menu_header
    echo $bgreen"-----------------------------------------Wireless ADB Setup-----------------------------------------" ; $rclr;
    echo ""
    echo $bgreen"  1)"$white" Ensure wireless ADB is running on your android device";
    echo $bgreen"  2)"$white" Make note of the IP address of the device wireless ADB is running on";
    echo $bgreen"  3)"$white" Enter the IP address, including periods/dots, when prompted.";
    echo $bgreen"  4)"$white" If you setup a non-standard port (e.g. anything other than 5555) then";
    echo $bgreen"    "$white" enter it after the IP address like normal:"$green" e.g. 192.168.1.10"$bred":5678";
    echo ""
    echo $bgreen"$apkmftr"; $rclr;
    echo $bwhite"Press "$bgreen"Q"$bwhite" and enter to go back to ADB menu.";
    adb_wireless_connect_prompt
    echo "adb_wireless_connect function complete" 1>> "$log"
}

# set time in seconds to run ADB logcat
set_adb_log_timeout () {
    if [[ ${extended_adb_log} -eq 1 ]]; then
        printf "$bwhite%s""Please enter time ("$bgreen"in seconds, up to 180"$white") to run ADB logcat: "; $rclr;
        read input
        if [[ $input = [qQ] ]]; then
            (( logtimeout=10 ))
        elif [[ ! ${input} =~ ^[0-9]+$ ]]; then
            echo $bred"Error: ${input} is not a number, press any key to try again"; $rclr;
            wait
            set_adb_log_timeout
        elif [[ ${input} -gt 180 ]]; then
            echo $bred"Error: ${input} is greater than 180 seconds, press any key to try again"; $rclr;
            wait
            set_adb_log_timeout
        else
            (( logtimeout=${input} ))
        fi
        unset input
        unset extended_adb_log
    else
        if [[ -z $logtimeout ]] || [[ $logtimeout = 0 ]]; then
            (( logtimeout=10 ))
        fi
    fi
}

# Create an ADB logcat file
adblog () {
    echo "adblog (generate ADB logcat txt file) function" 1>> "$log"
    set_adb_log_timeout
    clear
    menu_header
    echo $bgreen"----------------------------------------adblog.txt generator----------------------------------------" ; $rclr;
    echo ""
    echo $white" selected android device:";
    echo $bgreen"  ${adb_dev_choice}";
    echo ""
    echo $white" device status:";
    echo $bgreen"  ${adbstatus}";
    echo ""
    echo $white" device model/product info:";
    echo $green"  model:"$bgreen" ${adb_dev_model}";
    echo $green"  device:"$bgreen" ${adb_dev_device}";
    echo $green"  product:"$bgreen" ${adb_dev_product}";
    echo ""
    echo $bred" if it \"hangs\" on waiting for device, please unplug your device";
    echo $bred" and make sure \"usb debugging\" is enabled before reconnecting"
    echo $bred" your android device's usb cable."
    echo ""
    echo $white" it will then run ADB logcat for "$bgreen"${logtimeout}"$white" seconds."
    echo ""
    echo $bgreen"$apkmftr"; $rclr;
    echo $bwhite"Press "$bgreen"Q"$bwhite" and enter to go back to debug menu, or press";
    printf "$bwhite%s""any other key to start ADB log process... "; $rclr;
    read input
    if [[ $input = [qQ] ]]; then :
    else
        echo "running ADB logcat..."
        timeout3 -t $logtimeout adb -s ${adb_dev_choice} wait-for-device logcat 1> "${maindir}/ADBLOG.txt"
    fi
    unset logtimeout
    echo "adblog function complete" 1>> "$log"
}

# check if ADB connection is wired or wireless
adb_device_status () {
    if [[ ${adb_dev_choice} = *.* ]]; then
        if [[ "${adbstatus}" = *offline* ]]; then
            adbstatus="Wireless, OFFLINE"
        else
            adbstatus="Wireless, connected"
        fi
    else
        adbstatus="Wired, connected"
    fi
}

# check for ADB device connection
adb_log_device_check () {
    adb_multiple_devices_check
    if [[ $? -ne 0 ]]; then
        return 1
    else
        adbstatus="${adb_dev_choice##*[[:space:]]}"
        adbstatus="${adb_dev_choice##*'\n'}"
        if [[ -z "${adb_dev_choice}" ]] || [[ "${adb_dev_choice}" = *List* ]] || [[ "${adb_dev_choice}" = *daemon* ]]; then
            adb_nodevice_error
        else
            adb_device_status
            adblog
        fi
    fi
    unset adbstatus
}

# make the preferred ADB device setting persistant
adb_save_device_pref () {
    if [[ -z "${adb_dev_choice}" ]] || [[ "${adb_dev_choice}" = *List* ]] || [[ "${adb_dev_choice}" = *daemon* ]]; then
        adb_nodevice_error
    else
        if [[ -n $adb_dev_choice ]] && [[ -n $adb_dev_model ]] && [[ -n $adb_dev_product ]] && [[ -n $adb_dev_device ]]; then
            echo $green" Saving unique ADB serial..."
            local key="adb_dev_choice"
            local value="${adb_dev_choice}"
            write_preference
            echo $green" Saving device model..."
            local key="adb_dev_model"
            local value="${adb_dev_model}"
            write_preference
            echo $green" Saving device product..."
            local key="adb_dev_product"
            local value="${adb_dev_product}"
            write_preference
            echo $green" Saving device name..."
            local key="adb_dev_device"
            local value="${adb_dev_device}"
            write_preference
            echo $bgreen" Done! Press any key to return to ADB menu."
            wait
        else
            adb_device_missing_info_error
        fi
    fi
}

# actually set final adb device variables now
set_adb_device_info () {
    adb_dev_choice="${adb_dev_choice%%[[:space:]]*}"
    adb_dev_choice="${adb_dev_choice##*'\n'}"
    adb_dev_model="$(echo ${adb_dev_model} | grep -i "[[:space:]]device[[:space:]]" | sed 's/.*model://g' | cut -d ' ' -f1 )"
    adb_dev_product="$(echo ${adb_dev_product} | grep -i "[[:space:]]device[[:space:]]" | sed 's/.*product://g' | cut -d ' ' -f1 )"
    adb_dev_device="$(echo ${adb_dev_device} | grep -i "[[:space:]]device[[:space:]]" | sed 's/.*device://g' | cut -d ' ' -f1 )"
}

# setup temporary adb device if only one is connected
set_temporary_adb_device () {
    adb_dev_choice="$(populate_adb_devices)"
    adb_dev_model="$(populate_adb_devices)"
    adb_dev_product="$(populate_adb_devices)"
    adb_dev_device="$(populate_adb_devices)"
    set_adb_device_info
}

# Try and see if we have more than one ADB device connected
adb_multiple_devices_check () {
    if [[ -z $adb_dev_choice ]]; then
        adb remount 1>/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            adb_multiple_devices_error
            return 1
        else
            set_temporary_adb_device
        fi
    elif [[ $adb_dev_choice = *none* ]]; then
        adb_nodevice_error
        return 1
    fi
}
