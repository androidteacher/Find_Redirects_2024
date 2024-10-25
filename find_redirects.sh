#!/bin/bash

printHelp() {
  echo -e "\nUsage: find_redirects.sh --listener <listener_url>\n"
  echo -e "Example:\n./find_redirects.sh --listener http://pingb.in/p/abcde1234\n"
  echo -e "Requires ffuf, amass, gau, and gf installed and in your PATH.\n"
}

listener=''

while [ "$1" != "" ]; do
  case $1 in
    --listener ) shift; listener=$1 ;;
    * ) printHelp; exit 1 ;;
  esac
  shift
done

if [ -z "$listener" ]; then
  printHelp
  exit 1
fi

# Generate bypass list
mkdir -p output && rm -f output/*
echo $listener | tee -a output/pingb_bypass_list.txt | \
  awk -F "//" '{print "\\\\"$listener, "\\/"$listener, "/%09/"$listener, "javascript:document.location=http://"$listener, "///"$listener, "////"$listener, "/////\\"$listener}' >> output/pingb_bypass_list.txt

# Run ffuf with modified redirects
for bypass in $(cat output/pingb_bypass_list.txt); do
  cat red2.txt | qsreplace "$bypass" >> output/red2.replaced.txt
done

ffuf -u "FUZZ" -w output/red2.replaced.txt -r -v > output/ffuf_results.txt
grep -A 3 "Size: 0, Words: 1, Lines: 1" output/ffuf_results.txt | tee redirects_found.txt
