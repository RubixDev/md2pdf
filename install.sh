#!/bin/bash
read -r -p "What is your name? " NAME

curl -fsSL "https://raw.githubusercontent.com/RubixDev/md2pdf/main/md2pdf.sh" > md2pdf || exit 1
chmod +x md2pdf
sed -i "s/YOUR NAME HERE/$NAME/g" md2pdf

sudo mv md2pdf /usr/local/bin/
sudo chown root:root /usr/local/bin/md2pdf
