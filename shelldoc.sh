#!/bin/sh
# ShellDoc - Documentation generation utility for GNU bash scripts
# Copyright (C) 2019  Tim K
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

VERSION=0.2.1
description=""
available_since=""
usage_cmd=""
args_required=""
args_method=standard
public_function=true
flist=""
breaks='<br>'
variable_doc=false
if test "$*" = ""; then
	echo "Usage: $0 <space-seperated list of paths to bash scripts>"
	exit 1
fi
for file in $*; do
    linen=0
    if test ! -f "$file"; then
        printf "[ERROR] File %s does not exist.\n" $file
        exit 1
    fi
    if test "$flist" = ""; then
        flist=$file
    else
        flist="$flist, $file"
    fi
    while read line; do
        linen=$(( $linen + 1))
        is_comment=false
        if test "${line:0:1}" = "#"; then
            is_comment=true
        fi
        if echo "$line" | grep '#@ ' > /dev/null 2>&1 && $is_comment; then
            line_uncommented=`echo "$line" | cut -d ' ' -f2-`
            if echo "$line_uncommented" | grep ':' > /dev/null 2>&1; then
                front=`echo "$line_uncommented" | cut -d ':' -f1 | sed 's/ //g' | tr '[:upper:]' '[:lower:]'`
                back=`echo "$line_uncommented" | cut -d ':' -f2-`
                if test "$front" = "availablesince"; then
                    available_since="$back"
                elif test "$front" = "argspec_method"; then
                    args_method="$back"
                elif test "$front" = "usage"; then
                    usage_cmd="$back"
                elif test "$front" = "arguments"; then
                    args_required="$back"
                elif test "$front" = "variable"; then
                    back_nospace=`echo "$back" | sed 's/ //g' | tr '[:upper:]' '[:lower:]'`
                    if test "$back_nospace" = "yes" || test "$back_nospace" = "true"; then
                        variable_doc=true
                    else
                        variable_doc=false
                    fi
                elif test "$front" = "internal"; then
                    back_nospace=`echo "$back" | sed 's/ //g' | tr '[:upper:]' '[:lower:]'`
                    if test "$back_nospace" = "yes" || test "$back_nospace" = "true"; then
                        public_function=false
                    else
                        public_function=true
                    fi
                else
                    description="$description$breaks\n$line_uncommented"
                    description=`echo "$description" | sed 's/%/%%/g'`
                fi
            else
                description="$description$breaks\n$line_uncommented"
                description=`echo "$description" | sed 's/%/%%/g'`
            fi
        elif echo "$line" | grep '()' > /dev/null 2>&1 && test "$is_comment" = "false"; then
            func_name=`echo "$line" | cut -d '(' -f1 | sed 's/ //g'`
            if $public_function; then
                echo "# \`\`$func_name\`\`"
                if test "$description" = ""; then
                    description="None specified."
                fi
                if test "$available_since" = ""; then
                    available_since="First public release"
                fi
                if test "$args_required" = ""; then
                    args_required="None (all arguments are optional)"
                fi
                if test "$usage_cmd" = ""; then
                    usage_cmd="$func_name"
                fi
                if test "$args_method" = ""; then
                    args_method=standard
                fi
                echo '## Basic info'
                echo "**Appears on**: Line $linen in file \"`basename "$file"`\" $breaks"
                echo "**Available since**: $available_since $breaks"
                echo "**Required arguments:** $args_required $breaks"
                echo "**Arguments passing method:** $args_method $breaks"
                echo ''
                echo '## Usage'
                echo "\`\`\`$usage_cmd\`\`\` $breaks"
                echo ''
                echo '## Description'
                printf "$description $breaks"
                echo ''
                echo "$breaks"
                echo ''
                echo "$breaks"
                echo ''
            fi
            description=""
            available_since=""
            usage_cmd=""
            args_required=""
            args_method=standard
            public_function=true
            variable_doc=false
        elif echo "$line" | grep '=' > /dev/null 2>&1 &&  test "$is_comment" = "false"; then
            var_name=`echo "$line" | cut -d '=' -f1`
            if $variable_doc; then
                if test "$description" = ""; then
                    description="None specified."
                fi
                echo "# \`\`$var_name\`\` [*variable*]"
                echo '## Basic info'
                echo "**Appears on:**: Line $linen in file \"`basename "$file"`\" $breaks"
                echo ''
                echo '## Description'
                printf "$description $breaks"
                echo ''
                echo "$breaks"
                echo ''
                echo "$breaks"
                echo ''
            fi
            description=""
            available_since=""
            usage_cmd=""
            args_required=""
            args_method=standard
            public_function=true
            variable_doc=false
        fi
    done < "$file"
done

echo '---------------------------------------'
echo "*Automatically generated by shelldoc $VERSION from $flist on `uname` (PWD=\"$PWD\", USER=\"$USER\", `date +"%d.%m.%Y %H:%M:%S"`)*"
exit 0
