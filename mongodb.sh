#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOG_FOLDER
echo "This script execution started at $(date)" | tee -a $LOG_FILE

USERID=$(id -u)

if [ $USERID -ne 0 ]; then
    echo -e "${R}ERROR ${N}: Please run this command using root privilege"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "${2} ... ${R} FAILURE ${N}" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "${2} ... ${G} SUCCESS ${N}" | tee -a $LOG_FILE
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "Added Mongo repo" 

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enable MongoDB"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Start MongoDB"






