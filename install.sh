#!/bin/bash
./skema.rb -i install install_data
cd install_data
bash script.sh
cd ..
rm -fr install_data

