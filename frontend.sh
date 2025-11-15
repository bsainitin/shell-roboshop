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
echo "Script Execution started at $(date)" | tee -a $LOG_FILE

USERID=$(id -u)
if [ $USERID -ne 0 ]; then
    echo -e "${R}ERROR${N}: Run this command using root privilege or root" | tee -a $LOG_FILE
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "${2} ... ${R} FAILURE ${N}" | tee -a $LOG_FILE
    else
        echo -e "${2} ... ${G} SUCCESS ${N}" | tee -a $LOG_FILE
    fi
}

dnf module disable nginx -y &>> $LOG_FILE
VALIDATE $? "Disabling Nginx"

dnf module enable nginx:1.24 -y &>> $LOG_FILE
VALIDATE $? "Enabling Nginx 1.24 version"

dnf install nginx -y &>> $LOG_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>> $LOG_FILE
VALIDATE $? "Enabling Nginx"

rm -rf /usr/share/nginx/html/* &>> $LOG_FILE
VALIDATE $? "Removing default files"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $LOG_FILE
VALIDATE $? "Downloading Frontend Application"

cd /usr/share/nginx/html/
unzip /tmp/frontend.zip &>> $LOG_FILE
VALIDATE $? "Unzipping Frontend Application"

rm -rf /etc/nginx/nginx.conf
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>> $LOG_FILE
VALIDATE $? "Copying Nginx configuration"

systemctl start nginx &>> $LOG_FILE
VALIDATE $? "Starting Application"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script execution completed in ${Y}$TOTAL_TIME${N} seconds" | tee -a $LOG_FILE