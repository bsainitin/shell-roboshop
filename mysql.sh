#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( basename $0 )
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
START_TIME=$(date +%s)

mkdir -p $LOG_FOLDER
echo "Script started execution at $(date)" | tee -a $LOG_FILE

USERID=$(id -u)
if [ $USERID -ne 0 ]; then
    echo -e "${R} ERROR ${N}: Run this command using root privilege or sudo" | tee -a $LOG_FILE
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "${2} ... ${R} FAILURE ${N}" | tee -a $LOG_FILE
    else
        echo -e "${2} ... ${G} SUCCESS ${N}" | tee -a $LOG_FILE
    fi
}

dnf install mysql-server -y &>> $LOG_FILE
VALIDATE $? "Installing MySQL server"

systemctl enable mysqld &>> $LOG_FILE
VALIDATE $? "Enabling MySQL server"

systemctl start mysqld &>> $LOG_FILE
VALIDATE $? "Starting MySQL server"

mysql_secure_installation --set-root-pass RoboShop@1 &>> $LOG_FILE
VALIDATE $? "Setting up root password"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME)) 
echo -e "Script execution completed in ${Y}$TOTAL_TIME seconds ${N}" | tee -a $LOG_FILE



