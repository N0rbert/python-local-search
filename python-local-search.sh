#!/bin/bash
USAGE="Usage: $0 search_term"

if [ $# -lt 1 ]; then
	echo "$USAGE";
	exit 1;
fi

if [ ! -x "$(command -v aptitude)" ];
then
    echo "This script needs 'aptitude' to function properly. Please install it."
    exit 2;
fi

if [ -x "$(command -v html2text)" ] || [ -x "$(command -v pandoc)" ]; then
    if [ -x "$(command -v html2text)" ]; then
        html2text_or_pandoc=1
        second_pass_tool="html2text"
    fi
    if [ -x "$(command -v pandoc)" ]; then
        html2text_or_pandoc=2
        second_pass_tool="pandoc"
    fi
else
    echo "This script needs 'html2text' or 'pandoc' to function properly. Please install at least one of them."
    exit 3;
fi

search_term="$1"
results_list=$(mktemp)
package_list_command="aptitude search '?section(python) ?installed | ?section(doc) ?term(python) ?installed' -F '%p'"
total_packages=$(eval $package_list_command | wc -l)

echo -e "Will search for '$search_term' in the '$total_packages' installed Python documentation packages using 'grep' and '$second_pass_tool'.\n"

i=1
for pkg in $(eval $package_list_command); do 
    echo "scale=2; $i*100/$total_packages" | bc -l | awk '{printf "%6.2f", $0}'
    echo "% --- Searching in '$pkg' package"
        
    dpkg -L $pkg | grep -E '\.htm$|\.html$|\.xhtml$'  | while read file_line
    do
        if [ -f "$file_line" ]; then
            if grep -q -i "$search_term" "$file_line" --include="*.*htm*" --files-with-matches
            then
                echo -en "\tfound in: "
                echo "$file_line" | tee -a $results_list
            fi
        fi
    done

    i=$((i+1))
done

if [ -s "$results_list" ] 
then
    echo
	echo ":) Results for '$search_term' are found in the $(wc -l $results_list | awk '{print $1}') HTML-documents."
    echo ":) Now running second pass search using '$second_pass_tool' and will open the results in default web-browser (if any)."

	cat $results_list | sort -u | while read results_line
    do
        if [ $html2text_or_pandoc = 1 ]; then
            second_pass_search_command="html2text \"\$results_line\" | grep -q -i \"\$search_term\""
        else
            second_pass_search_command="pandoc \"\$results_line\" --to plain | grep -q -i \"\$search_term\"" 
        fi
            if $(eval $second_pass_search_command);
            then
                echo -e "\tfound in: $results_line"
                xdg-open $results_line 2> /dev/null > /dev/null
            fi
    done

    echo -e "\nThe search is done, now trying to find ways to ease bookmark creation for reuse..."

    doc_base_list=$(mktemp)
    devhelp_list=$(mktemp)
    others_list=$(mktemp)

    dpkg -S $(cat $results_list) | awk -F: '{print $1}' | sort -u | while read file_line
    do
        if dpkg -L $file_line | grep -v "/usr/share/doc-base/" | grep -v "/usr/share/devhelp/books/" | grep -q -E '\.htm$|\.html$|\.xhtml$'
        then
            echo $file_line >> $others_list
        fi
        if dpkg -L $file_line | grep -q "/usr/share/doc-base/";
        then
            echo $file_line >> $doc_base_list
        fi
        
        if dpkg -L $file_line | grep -q -E "/usr/share/devhelp/books/|/usr/share/gtk-doc/html";
        then
            echo $file_line >> $devhelp_list
        fi
    done

    if [ -s "$doc_base_list" ];
    then
        echo -e "\n-----\n"
        echo "Notice: some of the found Python packages have documentation available from 'dochelp' utility."
        echo -e "The full list is shown below:\n"
        cat $doc_base_list
    fi

    if [ -s "$devhelp_list" ];
    then
        echo -e "\n-----\n"
        echo "Notice: some of the found Python packages have documentation available from 'devhelp' utility."
        echo -e "The full list is shown below:\n"
        cat $devhelp_list
    fi

    if [ -s "$others_list" ];
    then
        others_list_comm=$(mktemp)
        comm -13 <(sort -u $doc_base_list $devhelp_list) <(sort -u $others_list) > $others_list_comm

        if [ -s "$others_list_comm" ] 
        then
            echo -e "\n-----\n"
            echo "Notice: some of the found Python packages have documentation only where it is."
            echo -e "The full list is shown below:\n"
            cat $others_list_comm
            echo
        fi
    fi

    if [ ! -s "$doc_base_list" ] && [ ! -s "$devhelp_list" ] && [ ! -s "$others_list" ] 
    then
       echo "... done. Can't find any bookmark method."
    fi
    
else
	echo -e "\n:( Results for '$search_term' are not found!\n"
fi