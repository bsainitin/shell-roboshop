#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( basename $0 )
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
START_TIME=$(date +%s)
SCRIPT_DIR=$PWD

mkdir -p $LOG_FOLDER
echo -e "Script execution started at $(date)" | tee -a $LOG_FILE

USERID=$(id -u)
if [ $USERID -ne 0 ]; then
    echo -e "${R}ERROR${N}: Run this command using root privilege or sudo" | tee -a $LOG_FILE
    exit 1
fi 

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "${2} ... ${R} FAILURE ${N}" | tee -a $LOG_FILE
    else
        echo -e "${2} ... ${G} SUCCESS ${N}" | tee -a $LOG_FILE
    fi
}

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>> $LOG_FILE
VALIDATE $? "Adding RabbitMQ repo"

dnf install rabbitmq-server -y &>> $LOG_FILE
VALIDATE $? "Installing RabbitMQ"

systemctl enable rabbitmq-server &>> $LOG_FILE
VALIDATE $? "Enabling RabbitMQ server"

systemctl start rabbitmq-server &>> $LOG_FILE
VALIDATE $? "Starting RabbitMQ server"

rabbitmqctl list_users | grep roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then 
    rabbitmqctl add_user roboshop roboshop123 &>> $LOG_FILE
    VALIDATE $? "Adding username and password"
else
    echo -e "User 'roboshop' already exists ... ${Y}SKIPPING${N}" | tee -a $LOG_FILE
fi

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOG_FILE
VALIDATE $? "Setting up permissions" 

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script execution completed in: ${Y}$TOTAL_TIME${N} seconds" | tee -a $LOG_FILE

