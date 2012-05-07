#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Common error strings library
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.0b
# Fri. May 11, 2012
# -----------------------------------------------------------------------

# Unknown input error string
input_err () {
    printf "$bred%s""Unknown command: $input press any key to try again...\n"; $rclr;
    wait
    clear
}

# Unknown input error string, no new line at end
input_err_noline () {
    printf "$bred%s""Unknown command: $input press any key to try again..."; $rclr;
    wait
    clear
}

# main menu, press-any-key string
pressanykey () {
    printf "$bred%s""press any key to return to main menu...\n"; $rclr;
    wait
}

# signing menu, press-any-key string
signpanykey () {
    printf "$bred%s""press any key to return to signing menu...\n"; $rclr;
    wait
}

# generic 'continue' press-any-key string
genericpanykey () {
    printf "$bwhite%s""press any key to continue...\n"; $rclr;
    wait
}

# debug menu, press-any-key string
debuganykey () {
    printf "$bred%s""press any key to return to debug menu\n"; $rclr;
    wait
}

# updates menu, press-any-key string
updateanykey () {
    printf "$bred%s""press any key to return to updates menu\n"; $rclr;
    wait
}

# fatal error press-any-key string
fatalpanykey () {
    printf "$bred%s""press any key to exit...\n"; $rclr;
    wait
}

# .jar file extension error string
jarext_err () {
    echo $bred"Error, this option only available for APK files"; $rclr;
    echo "Error, this option only available for APK files" 1>> "$log"
    pressanykey
}

# file not found error string
notfound_err () {
    echo $bred"Selected project file $capp cannot be found"; $rclr;
    echo "Selected project file $capp cannot be found" 1>> "$log"
    pressanykey
}

# not yet extracted/decompiled error string
nodir_err () {
    echo $bred"Error, $prjext has not yet been extracted/decompiled";
    echo "Error, $prjext has not yet been extracted/decompiled" 1>> "$log"
    echo $bred"Please use \"extract\" or \"decompile\" option first"; $rclr;
    pressanykey
}

# project not decompile error string
nodec_err () {
    echo $bred"Error, project was not decompiled";
    echo "Error, project was not decompiled" 1>> "$log"
    echo $bred"Please use \"zip\" or \"advanced\" options instead"; $rclr;
    pressanykey
}

# project not extracted error string
noex_err () {
    echo $bred"Error, project was decompiled not extracted";
    echo "Error, project was decompiled not extracted" 1>> "$log"
    echo $bred"Please use \"compile\" or \"advanced\" options instead"; $rclr;
    pressanykey
}

# dex2jar, classes.dex extract error string
decj_extdex_err () {
    echo $bred"An error occured while extracting classes.dex, please check log."; $rclr;
    pressanykey
}

# dex2jar, classes.dex decompile error string
decj_process_dex_err () {
    echo $bred"An error occured while decompiling classes.dex, please check log."; $rclr;
    pressanykey
}

# dex2jar, jar extract error string
decj_extract_jar_err () {
    echo $bred"An error occured while extracting jar file, please check log."; $rclr;
    pressanykey
}

# overwrite existing project folder prompt
overwrite_prompt () {
    echo $bred"Warning, /projects/$capp exists";
    printf "$white%s""Overwrite project folder? ("$bgreen"y"$white"/"$bgreen"n"$white") "; $rclr;
}

# all-in-one 'java source' error
aio_java_err () {
    echo $bred"Error, project was decompiled to java source";
    echo $bred"Please delete the /projects/$capp/java"; $rclr;
    echo $bred"folder and try your selection again."; $rclr;
    echo "Error, project was decompiled to java source" 1>> "$log"
    pressanykey
}

# no .git directory found error string
updates_dir_err () {
    echo $bred"ERROR: APK Manager was not setup using \"git\".";
    echo $bred"If you would like to enable Automatic Updates,";
    echo $bred"please re-install APK Manager using \"git clone ...\"";
    echo $bred"Instructions can be found on github here:"; $rclr;
    echo $bred"https://github.com/jocelynmallon/apkmanager"; $rclr;
    genericpanykey
}

# 'git' not found error string
updates_git_err () {
    echo $bred"ERROR: \"git\" was not found on this system.";
    echo $bred"Unfortunately, git is required to enable and use";
    echo $bred"the included automatic update features. Please";
    echo $bred"download and instal git, or fix your \$PATH"; $rclr;
    genericpanykey
}

# failure trying to pull/update apk manager error string
git_pull_error () {
    echo $bred"FATAL ERROR: APK Manager failed trying"
    echo $bred"to run \"git pull\" to check for updates"
    echo $bred"please check the log for details."
    fatalpanykey
    defaults delete $plist update_prompt 2>/dev/null
    echo "GIT PULL EROOR: $(gen_date)" 1>> "$log" 2>&1
    echo "$apkmftr" 1>> "$log" 2>&1
    exit 1
}

# failure to checkout git branch error string
git_checkout_error () {
    echo $bred"ERROR: APK Manager failed trying to checkout"
    echo $bred"$saved_channel branch to check for updates"
    echo $bred"please check the log for details."
    fatalpanykey
}

# failure when attempting 'git config' error string
git_config_error () {
    echo $bred"ERROR: APK Manager failed trying to set"
    echo $bred"git config options to check for updates"
    echo $bred"please check the log for details."
    fatalpanykey
}

# no branches to checkout error string
no_branches_err () {
    echo $bred"ERROR: APK Manager only found one remote"
    echo $bred"branch. There's nothing to switch to."
    echo $bred"please check the log for details."
    updateanykey
}

# had to change branches message/error string
git_branch_change () {
        echo $bgreen"APK Manager had to switch branches"; $rclr;
        echo $bgreen"during the update, and will now exit."; $rclr;
}