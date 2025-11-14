#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
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

###############  NODEJS  ################
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling NodeJS modules"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS version 20"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing NodeJS"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "user already exists ... ${Y} SKIPPING ${N}" | tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip  &>> $LOG_FILE
VALIDATE $? "Downloading cart application"

cd /app
VALIDATE $? "changing to app directory"

rm -rf /app/* 
VALIDATE $? "Removing existing code" 

unzip /tmp/cart.zip &>> $LOG_FILE
VALIDATE $? "Unzipping cart" 

npm install &>>$LOG_FILE
VALIDATE $? "Installing dependencies" 

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>> $LOG_FILE
VALIDATE $? "Copying systemctl services" 

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Reloading"  

systemctl enable cart &>> $LOG_FILE
VALIDATE $? "Enabling cart"

systemctl start cart &>> $LOG_FILE
VALIDATE $? "Starting cart"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script execution completed in: ${Y}$TOTAL_TIME${N} seconds" | tee -a $LOG_FILE