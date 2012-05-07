#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# misc/catch-all functions
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.0b
# Fri. May 11, 2012
# -----------------------------------------------------------------------

# Prompt user for android.jar location
and_sdk_err () {
    echo "and_sdk_err (request android.jar location) function" 1>> "$log"
    clear
    menu_header
    echo $bred" WARNING: APK Manager wasn't able to automatically"
    echo $bred" determine the location of the Android SDK."
    echo ""
    echo $white" APK Manager needs \"android.jar\" from the sdk in order"
    echo $white" to compile .9.png files without a working project"
    echo ""
    echo $white" If you have the Android SDK installed, you can set the"
    echo $white" location to \"android.jar\" manually now."
    echo ""
    echo $bwhite" Please drag \"android.jar\" into this window and press enter"
    echo $bwhite" or leave blank and press enter to quit."
    echo $bgreen"$apkmspr";
    read input
    if [[ -z $input ]]; then
        return 1
    else
        andjar="$input"
    fi
    unset input
    echo "and_sdk_err function complete" 1>> "$log"
}

# Try to locate android.jar
andsdk_check () {
    echo "andsdk_check (check for android sdk) function" 1>> "$log"
    if [[ $(command -v brew) ]] && [[ $(dirname $(command -v android)) = /usr/local/bin ]]; then
        local sdkrev="/usr/local/var/lib/android-sdk/platforms"
        sdkrev="$sdkrev/$(ls -1 "$sdkrev" | sort -n -r -t - -k 2 | head -n 1)"
        andjar="$sdkrev/android.jar"
    elif [[ $(command -v android) ]] && [[ ! $(dirname $(command -v android)) = /usr/local/bin ]]; then
        local sdkrev="$(dirname $(dirname $(command -v android)))"
        sdkrev="$sdkrev/platforms/$(ls -1 "$sdkrev" | sort -n -r -t - -k 2 | head -n 1)"
        andjar="$sdkrev/android.jar"
    else
        and_sdk_err
    fi
    echo "andsdk_check function complete" 1>> "$log"
}

# Generate manifest for compiling .9.png files
gen_temp_manifest () {
    cat >"$maindir/temp/AndroidManifest.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
      package="com.girlintroverted.apkmanager"
      android:versionCode="1"
      android:versionName="1.0">
</manifest>
EOF
}

# Setup ./temp dir for compiling .9.png files
temp_dir_setup () {
    echo "temp_dir_setup (create temporary folders) function" 1>> "$log"
    if [[ -d $maindir/temp ]]; then
        rm -r "$maindir/temp"
    fi
    mkdir -p "$maindir/temp"
    mkdir -p "$maindir/temp/res/drawable"
    mkdir -p "$maindir/temp/res/drawable-mdpi"
    mkdir -p "$maindir/temp/res/drawable-hdpi"
    mkdir -p "$maindir/temp/res/layout"
    echo "temp_dir_setup function complete" 1>> "$log"
}

# Compile .9.png files subroutine
compile_9png_sub () {
    andsdk_check
    if [[ -z $andjar ]]; then
        echo $bred"ERROR: cannot find android.jar, aborting."
        echo "cannot find android.jar, aborting." 1>> "$log"
        return 1
    fi
    echo $bgreen" Using android.jar found here:"
    echo $green" $andjar"; $rclr;
    echo $bgreen" generating temporary AndroidManifest.xml file..."
    gen_temp_manifest
    local tmp_zip="$(mktemp -u $maindir/temp/res-XXXXXX).zip"
    echo $bgreen" compiling resources now..."
    aapt package -v -f -M "$maindir/temp/AndroidManifest.xml" -F "$tmp_zip" -S "$maindir/temp/res" -I "$andjar" 1>> "$log" 2>&1
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    echo $bgreen" extracting compiled files to temp/compiled..."
    7za x -o"$maindir/temp/compiled" "$tmp_zip" -y 1>> "$log" 2>&1
    if [[ $? -ne 0 ]]; then
        echo "cannot extract $tmp_zip, aborting." 1>> "$log"
        return 1
    else
        echo $bgreen" removing termporary files..."
        rm -r "$tmp_zip"
        rm -r "$maindir/temp/AndroidManifest.xml"
        rm -r "$maindir/temp/compiled/AndroidManifest.xml"
        rm -r "$maindir/temp/compiled/resources.arsc"
    fi
    echo $bgreen" Resources compiled succesfully!"
    pressanykey
    unset andjar
}

# Compile .9.png files start page
compile_9patch () {
    echo "compile_9patch (compile .9.png files) function" 1>> "$log"
    temp_dir_setup
    clear
    menu_header
    echo $bgreen"-----------------------------Compile nine-patch and/or binary xml files----------------------------- "
    echo $white" APK Manager has the ability to compile \"nine-patch\" png files"
    echo $white" and binary xml files without needing a working eclipse project,"
    echo $white" or using/hijacking an already decompiled apk file."
    echo ""
    echo $white" In your main apkmanager directory, you will find a new folder"
    echo ""
    echo $green" $maindir/temp"
    echo ""
    echo $white" This folder has a few of the most common android application"
    echo $white" resource folders already created inside. ex:"
    echo ""
    echo $green"  $maindir/temp/res/drawable"
    echo $green"  $maindir/temp/res/drawable-mdpi"
    echo $green"  $maindir/temp/res/drawable-hdpi"
    echo $green"  $maindir/temp/res/layout"
    echo ""
    echo $white" Please copy your source .9.png and xml files into the appropriate"
    echo $white" folders. Feel free to create any new folders you need too."
    echo $bgreen"$apkmspr";
    echo $bwhite"Once finished, come back here and press enter to continue..."
    wait
    compile_9png_sub
    echo "compile_9patch function complete" 1>> "$log"
}

# Pull a file from device with adb
adb_pull () {
    echo "adb_pull function" 1>> "$log"
    echo $bwhite"Where do you want adb to pull the apk/jar from? ";
    echo $green"Example of input : /system/app/launcher.apk";
    echo $green"(leave blank and press enter to return to main menu)"; $rclr;
    read input
    if [[ -z $input ]]; then :
    else
        local outfile="$(basename $input)"
        adb pull "$input" "$maindir/$mod_dir/$outfile"
        if [[ $? -ne 0 ]]; then
            echo $bred"Error: while pulling $outfile"; $rclr;
            pressanykey
        fi
    fi
    unset input
    echo "adb_pull function complete" 1>> "$log"
}

# Optimize png images inisde a project folder
opt_apk_png () {
    echo "opt_apk_png (optimize images inside apk) function" 1>> "$log"
    capp_test
    if [[ $capp = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
    elif [[ $pngopts = disabled ]];then
        echo $bred"ERROR, no png optimization program was not found on your system"
        echo $bred"this option is unavailable until one is installed"; $rclr;
        pressanykey
    elif [[ ! $prjext = [Aa][Pp][Kk] ]]; then
        jarext_err
    elif [[ ! -d "$maindir/$prj_dir/$capp" ]]; then
        nodir_err
    elif [[ "$(ls -1 $maindir/$prj_dir/$capp | wc -l)" -eq 0 ]]; then
        nodir_err
    else
        if [[ -z $pngtool ]]; then
            pngtool="optipng"
        fi
        local png_file
        cd "$maindir/$prj_dir/$capp"
        find "./res" -iname "*.png" | while read png_file ;
        do
            if [[ $(echo "$png_file" | grep -c "\.9\.png$") -eq 0 ]]; then
                if [[ $pngtool = optipng ]]; then
                    optipng -o99 "$png_file"
                elif [[ $pngtool = pngcrush ]]; then
                    pngcrush -reduce -brute -ow "$png_file"
                elif [[ $pngtool = pngout ]]; then
                    pngout "$png_file"
                fi
            fi
        done
    fi
    echo "opt_apk_png function complete" 1>> "$log"
}

# Zipalign a single file
zalign_file () {
    echo "zalign_file (single file) function" 1>> "$log"
    capp_test
    if [[ $capp = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
    else
        local string
        for string in "signed" "unsigned"
        do
            if [[ -e $maindir/$mod_dir/$string-$capp ]]; then
                zipalign -fv 4 "$maindir/$mod_dir/$string-$capp" "$maindir/$mod_dir/$string-aligned-$capp"  1>> "$log" 2>&1
                if [[ $? -eq 0 ]]; then
                    mv -f "$maindir/$mod_dir/$string-aligned-$capp" "$maindir/$mod_dir/$string-$capp"
                fi
            else
                echo "zipalign: cannot find file $mod_dir/$string-$capp" 1>> "$log" 2>&1
            fi
        done
    fi
    echo "zalign_file function complete" 1>> "$log"
}

# Normal adb push
norm_push () {
    adb push "$maindir/$mod_dir/unsigned-$capp" "$input"
    printf "$bwhite%s""Press any key to continue "; $rclr;
    wait
}

# Advanced adb push
adv_push () {
    adb shell stop
    norm_push
    adb shell start
}

# Prompt for adb push destination
push_prompt () {
    echo "push_prompt (push destination prompt) function" 1>> "$log"
    clear
    echo $bwhite"Where do you want adb to push to and as what name: ";
    echo $green"(leave blank and press enter to return to main menu)";
    echo ""
    echo $green"Example of input : /system/app/launcher.apk "; $rclr;
    read input
    if [[ -z $input ]]; then :
    else
        adb devices
        printf "$bwhite%s""Press any key to continue "; $rclr;
        wait
        adb remount
        if [[ $push_type = normal ]]; then
            norm_push
        elif [[ $push_type = advanced ]]; then
            adv_push
        fi
    fi
    echo "push_prompt function complete" 1>> "$log"
}

# Cleanup variables used in adb push functions
push_cleanup () {
    unset input
    unset push_type
}

# Prompt for adb push type
adb_push () {
    echo "adb_push (push type prompt) function" 1>> "$log"
    capp_test
    if [[ $capp = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
    elif [[ ! -f "$maindir/$mod_dir/unsigned-$capp" ]]; then
        echo $bred"Error, cannot find file: unsigned-$capp";
        echo $bred"Please use \"zip\" or \"compile\" options first"; $rclr;
        pressanykey
    else
        echo $bwhite"Which adb push option would you like to perform?";
        echo $bgreen"  1 "$white"  Simple  "$green"(adb push only)";
        echo $bgreen"  2 "$white"  Advanced  "$green"(adb shell stop, push, shell start)";
        printf "$bwhite%s""Please make your decision: "; $rclr;
        read input
        case "$input" in
            1)  push_type="normal"; push_prompt ;;
            2)  push_type="advanced"; push_prompt ;;
            *)  input_err; adb_push ;;
        esac
    fi
    push_cleanup
    echo "adb_push function complete" 1>> "$log"
}

# Open a text file with log viewing app
read_txt () {
    if [[ $logviewer = "nano" ]] || [[ $logviewer = "vi" ]] || [[ $logviewer = "emacs" ]]; then
        local apkmopt="$logviewer $txt; exit"
        newttab "$apkmopt" "$log"
    else
        "$logviewer" "$txt"
    fi
    unset txt
}
