#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Color setup and check functions
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.0b
# Fri. May 11, 2012
# -----------------------------------------------------------------------

# Set dark color scheme function
colorsetdark () {
    echo "colorsetlight (setting dark text on light bg scheme)" 1>> "$log" 2>&1
    local key="color"
    local value="alternate"
    write_preference
    white='\033[0;30m'
    bwhite='\033[1;30m'
}

# Set light color scheme function
colorsetlight () {
    echo "colorsetlight (setting light text on dark bg scheme)" 1>> "$log" 2>&1
    local key="color"
    local value="default"
    write_preference
    white='\033[0;37m'
    bwhite='\033[1;37m'
}

# Select main color scheme menu
colormenu () {
    clear
    lwhite="\033[0;37m"
    lbwhite="\033[1;37m"
    dwhite="\033[0;30m"
    dbwhite="\033[1;30m"
    echo ""
    version_banner
    echo ""
    echo $bgreen" APK Manager color setup (this should only run on very first launch)"
    echo ""
    echo $green" Setup APK Manager for the following terminal color(s)..."
    echo ""
    echo $bgreen"  1  "$lwhite"Light"$green" text on dark/black background"
    echo $bgreen"     ("$lbwhite"example of bold/bright text"$bgreen")"
    echo $bgreen"  2  "$dwhite"Dark"$green" text on light/white background"
    echo $bgreen"     ("$dbwhite"example of bold/bright text"$bgreen")"
    echo ""
    printf "$bgreen%s""Please make a selection: "; $rclr;
    read input
    case "$input" in
     [1])  colorsetlight ;;
     [2])  colorsetdark ;;
       *)  input_err; colorcheck ;;
    esac
    unset lwhite
    unset lbwhite
    unset dwhite
    unset dbwhite
}

# Start
colormenu
return 0
