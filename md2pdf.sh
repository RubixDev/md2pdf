#!/bin/bash

NAME="YOUR NAME HERE"

OTHER_ARGUMENTS=()
LEFT_HEAD=""
CENTER_HEAD=""
RIGHT_HEAD=""
NAME_LOCATION="left"
PRESERVE_TEX=false

EXIT () {
    rm -r tmp
    exit "$1"
}

while test $# -gt 0; do
    case "$1" in
        -l|--left-head)
        LEFT_HEAD="$2"
        shift # Remove argument name from processing
        shift # Remove argument value from processing
        ;;
        -c|--center-head)
        CENTER_HEAD="$2"
        shift # Remove argument name from processing
        shift # Remove argument value from processing
        ;;
        -r|--right-head)
        RIGHT_HEAD="$2"
        shift # Remove argument name from processing
        shift # Remove argument value from processing
        ;;
        -n|--name-location)
        NAME_LOCATION="$2"
        shift # Remove argument name from processing
        shift # Remove argument value from processing
        ;;
        --preserve-tex)
        PRESERVE_TEX=true
        shift # Remove argument from processing
        ;;
        *)
        OTHER_ARGUMENTS+=("$1")
        shift # Remove generic argument from processing
        ;;
    esac
done

if [ -z "${OTHER_ARGUMENTS[0]}" ]; then
    echo -e "\033[1;31mYou need to specify an input and output file\033[0m"
    exit 1
elif [ -z "${OTHER_ARGUMENTS[1]}" ]; then
    echo -e "\033[1;31mYou need to specify an output file\033[0m"
    exit 1
fi

metadata () {
    yaml=$(cat << EOF
---
header-includes: |
    \usepackage{fancyhdr}
    \pagestyle{fancy}
    \lhead{LEFT_HEAD}
    \chead{CENTER_HEAD}
    \rhead{RIGHT_HEAD}
---
EOF
)
    if [ -z "$LEFT_HEAD" ] && [ "$NAME_LOCATION" == "left" ]; then
        yaml="${yaml//LEFT_HEAD/$NAME}"
    else
        yaml="${yaml//LEFT_HEAD/$LEFT_HEAD}"
    fi

    if [ -z "$CENTER_HEAD" ] && [ "$NAME_LOCATION" == "center" ]; then
        yaml="${yaml//CENTER_HEAD/$NAME}"
    else
        yaml="${yaml//CENTER_HEAD/$CENTER_HEAD}"
    fi

    if [ -z "$RIGHT_HEAD" ] && [ "$NAME_LOCATION" == "right" ]; then
        yaml="${yaml//RIGHT_HEAD/$NAME}"
    else
        yaml="${yaml//RIGHT_HEAD/$RIGHT_HEAD}"
    fi

    echo "$yaml"
}

mkdir tmp || exit 1
pandoc "${OTHER_ARGUMENTS[0]}" <(metadata) -s \
    -V geometry:a4paper \
    -V geometry:margin=2cm \
    -V mainfont="DejaVu Sans" \
    -V monofont="DejaVu Sans Mono" \
    -V block-headings \
    --pdf-engine=xelatex \
    -o "tmp/tmpfile.tex" || EXIT 1
python3 << EOF
import re

with open('tmp/tmpfile.tex', 'r') as texfile:
    tex = texfile.read()

tex = re.compile(r'(\\\\usepackage\{.*?longtable.*?\})').sub(r'\1\\\\setlength{\\\\LTleft}{0em}\\\\aboverulesep=0ex\\\\belowrulesep=0ex\\\\renewcommand{\\\\arraystretch}{1.5}', tex)

longtable_re = re.compile(r'(\\\\begin\{longtable\}\[.*\]\{@\{\})([rcl]+)(@\{\}\})', re.MULTILINE)
replacements = []
for match in longtable_re.finditer(tex):
    start, cols, end = match.groups()
    cols = f'|{"|".join(cols)}|'
    replacements.append(f'{start}{cols}{end}')
if replacements:
    tex = longtable_re.sub(lambda _: replacements.pop(0), tex)

midrules_re = re.compile(r'(\\\\endhead)([\s\S]+?)(\\\\\\\\\n?\\\\bottomrule)')
replacements = []
for match in midrules_re.finditer(tex):
    start, rows, end = match.groups()
    rows = "\\\\\\\\\n\\\\midrule".join(rows.split(r"\\\\"))
    replacements.append(f'{start}{rows}{end}')
if replacements:
    tex = midrules_re.sub(lambda _: replacements.pop(0), tex)

with open('tmp/tmpfile.tex', 'w') as texfile:
    texfile.write(tex)
EOF

xelatex tmp/tmpfile
xelatex tmp/tmpfile || EXIT 1

mv tmpfile.pdf "${OTHER_ARGUMENTS[1]}"
if [ "$PRESERVE_TEX" = true ]; then
    mv tmp/tmpfile.tex "${OTHER_ARGUMENTS[1]}.tex"
fi
rm tmpfile.aux
rm tmpfile.log
rm -r tmp
