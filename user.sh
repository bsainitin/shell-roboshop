#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( basename $0 )
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD
START_TIME=$(date +%s)

mkdir -p $LOG_FOLDER
echo "Script started execution at $(date)" | tee -a $LOG_FILE

USERID=$(id -u)
if [ $USERID -ne 0 ]; then
    echo -e "${R}ERROR${N}: Enter this command using root privilege or sudo" | tee -a $LOG_FILE
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "${2} ... ${R} ERROR ${N}" | tee -a $LOG_FILE
    else
        echo -e "${2} ... ${G} SUCCESS ${N}" | tee -a $LOG_FILE
    fi
}

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "user already exists ... ${Y} SKIPPING ${N}" | tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>> $LOG_FILE
VALIDATE $? "Downloading user application"

cd /app
VALIDATE $? "changing to app directory"

rm -rf /app/* 
VALIDATE $? "Removing existing code" 

unzip /tmp/user.zip &>> $LOG_FILE
VALIDATE $? "Unzipping user" 

npm install &>>$LOG_FILE
VALIDATE $? "Installing dependencies" 

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>> $LOG_FILE
VALIDATE $? "Copying systemctl services" 

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Reloading"  

systemctl enable user &>> $LOG_FILE
VALIDATE $? "Enabling user"

systemctl start user &>> $LOG_FILE
VALIDATE $? "Starting user"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script execution completed in: ${Y}$TOTAL_TIME${N} seconds" | tee -a $LOG_FILE