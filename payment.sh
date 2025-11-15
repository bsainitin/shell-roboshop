#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD
START_TIME=$(date +%s)

mkdir -p $LOG_FOLDER
echo "Script started execution at $(date)" | tee -a $LOG_FILE

USERID=$(id -u)
if [ $USERID -ne 0 ]; then
    echo -e "${R}ERROR ${N}: Run this command using root privilege or sudo" | tee -a $LOG_FILE
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

dnf install python3 gcc python3-devel -y &>> $LOG_FILE
VALIDATE $? "Installing Python3"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "user already exists ... ${Y} SKIPPING ${N}" | tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>> $LOG_FILE
VALIDATE $? "Downloading payment application"

cd /app
VALIDATE $? "changing to app directory"

rm -rf /app/* 
VALIDATE $? "Removing existing code" 

unzip /tmp/payment.zip &>> $LOG_FILE
VALIDATE $? "Unzipping payment application" 

pip3 install -r requirements.txt &>> $LOG_FILE
VALIDATE $? "Installing requirements"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>> $LOG_FILE
VALIDATE $? "Copying services" 

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Reloading" 

systemctl enable payment 
VALIDATE $? "Enabling payment" 

systemctl start payment
VALIDATE $? "Starting payment" 

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script execution completed in: ${Y}$TOTAL_TIME ${N}" | tee -a $LOG_FILE