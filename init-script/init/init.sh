#!/bin/bash
sh /etc/postgresql/init-script/init.sh
touch /etc/postgresql/ready
echo "RESTART!";
kill 1