#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD
MySQL_HOST=mysql.theawsdevops.space
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
        exit 1
    else
        echo -e "${2} ... ${G} SUCCESS ${N}" | tee -a $LOG_FILE
    fi
}

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing maven"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "user already exists ... ${Y} SKIPPING ${N}" | tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>> $LOG_FILE
VALIDATE $? "Downloading shipping application"

cd /app
VALIDATE $? "changing to app directory"

rm -rf /app/* 
VALIDATE $? "Removing existing code" 

unzip /tmp/shipping.zip &>> $LOG_FILE
VALIDATE $? "Unzipping shipping application" 

mvn clean package &>> $LOG_FILE
VALIDATE $? "Building Maven package"

mv target/shipping-1.0.jar shipping.jar &>> $LOG_FILE
VALIDATE $? "Moving shipping file" 

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>> $LOG_FILE
VALIDATE $? "Copying services" 

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Reloading"  

systemctl enable shipping &>> $LOG_FILE
VALIDATE $? "Enabling shipping"

dnf install mysql -y &>> $LOG_FILE
VALIDATE $? "Installing MySQL"

mysql -h $MySQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>> $LOG_FILE
if [ $? -ne 0 ]; then 
    mysql -h $MySQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>> $LOG_FILE
    VALIDATE $? "Loading schema"

    mysql -h $MySQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>> $LOG_FILE
    VALIDATE $? "Loading app user"

    mysql -h $MySQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>> $LOG_FILE
    VALIDATE $? "Loading master data"
else 
    echo -e "Shipping data is already loaded ... ${Y} SKIPPING ${N}" | tee -a $LOG_FILE
fi

systemctl restart shipping &>> $LOG_FILE
VALIDATE $? "Restarting shipping"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script execution completed in: ${Y}$TOTAL_TIME${N} seconds" | tee -a $LOG_FILE