#!/bin/bash
read -r -p "What is your name? " NAME

curl -fsSL "PLACEHOLDER" > md2pdf || exit 1
chmod +x md2pdf
sed -i "s/YOUR NAME HERE/$NAME/g" md2pdf

sudo mv md2pdf /usr/local/bin/
sudo chown root:root /usr/local/bin/md2pdf
