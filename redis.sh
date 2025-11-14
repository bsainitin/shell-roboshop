#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
START_TIME=$(date +%s)

mkdir -p $LOG_FOLDER
echo "script started execution at $(date)" | tee -a $LOG_FILE

USERID=$(id -u) 
if [ $USERID -ne 0 ]; then
    echo -e "${R} ERROR ${N}: Run this command using root access or sudo" | tee -a $LOG_FILE
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "${2} ... ${R} FAILURE ${N}" | tee -a $LOG_FILE
    else    
        echo -e "${2} ... ${G} SUCCESS ${N}" | tee -a $LOG_FILE
    fi    
}

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disabling default Redis"

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enabling Redis 7"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Installing Redis"

sed -i 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf &>>$LOG_FILE
VALIDATE $? "Allowing Remote connection to Redis"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "Enabling Redis"

systemctl start redis &>>$LOG_FILE
VALIDATE $? "Starting Redis"

END_TIME=$(date +%s)

TOTAL_TIME=$(($END_TIME - $START_TIME))
echo "Script Execution Completed at: ${Y} $TOTAL_TIME seconds${N}"


