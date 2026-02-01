#!/bin/bash

# color codes in Linux, can be enabled with echo -e option
R='\e[31m'
G='\e[32m'
Y='\e[33m'
B='\e[34m'
N='\e[0m'


USERID=$(id -u) # userid of root user 0, and others non-zero
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1 # we need to exit with failure exit code
fi

mkdir -p $LOGS_FOLDER

# Functions are not executed by default, only executed when called
VALIDATE()
{
    if [ $1 -ne 0 ]; then
        echo -e "$2 ...$R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ...$G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y &>> $LOGS_FILE
VALIDATE $? "Disabling Nodejs default version"

dnf module enable nodejs:20 -y &>> $LOGS_FILE
VALIDATE $? "Enabling Nodejs version 20"

dnf install nodejs -y &>> $LOGS_FILE
VALIDATE $? "Installing Nodejs"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>> $LOGS_FILE
    VALIDATE $? "Creating Application User"
else
    echo -e "Roboshop user already exists...$Y SKIPPING $N" | tee -a $LOGS_FILE
fi

mkdir -p /app 
VALIDATE $? "Creating Application directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOGS_FILE
VALIDATE $? "Downloading Application code to temp directory"

cd /app
VALIDATE $? "Go to Application directory"

unzip /tmp/catalogue.zip  &>> $LOGS_FILE
VALIDATE $? "Unzip the application code"

cd /app
VALIDATE $? "Move to Application directory"

npm install  &>> $LOGS_FILE
VALIDATE $? "Install dependencies"

cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Setup Systemd catalogue service for systemctl"

systemctl daemon-reload
VALIDATE $? "Reload the newly created systemd catlogue service"

systemctl enable catalogue
VALIDATE $? "Enable catalogue service"

systemctl start catalogue
VALIDATE $? "Start catalogue service"