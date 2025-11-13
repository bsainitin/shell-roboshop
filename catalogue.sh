#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR="$PWD"
MONGODB_HOST=mongodb.theawsdevops.space

mkdir -p $LOG_FOLDER
echo "Script started execution at $(date)" | tee -a $LOG_FILE

USERID=$(id -u)

if [ $USERID -ne 0 ]; then
    echo -e "${R}ERROR ${N}:  Please run this script as root or using sudo." | tee -a $LOG_FILE
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... ${R} FAILURE ${N}" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... ${G} SUCCESS ${N}" | tee -a $LOG_FILE
    fi
}

###############  NODEJS  ################
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling NodeJS modules"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS version 20"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing NodeJS"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop 
    VALIDATE $? "Creating system user"
else
    echo -e "user already exists ... ${Y} SKIPPING ${N}"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue application"

cd /app 
VALIDATE $? "Changing to app directory" 

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzipping catalogue"

npm install &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "Copying systemctl services"

systemctl daemon-reload
VALIDATE $? "Reloading "
 
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enabling catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying Mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB client"

INDEX=$(mongosh --host $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ "$INDEX" -eq -1 ]; then
    mongosh --host  $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Loading catalogue products"
else
    echo -e "Catalogue products already loaded ... ${Y} SKIPPING ${N}" | tee -a $LOG_FILE
fi

systemctl restart catalogue
VALIDATE $? "Restarting catalogue"