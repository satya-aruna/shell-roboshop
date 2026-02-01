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

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>> $LOGS_FILE
VALIDATE $? "Copying rabbitmq repo"

dnf install rabbitmq-server -y &>> $LOGS_FILE
VALIDATE $? "Installing RabbitMQ"

systemctl enable rabbitmq-server &>> $LOGS_FILE
VALIDATE $? "Enable RabbitMQ"

systemctl start rabbitmq-server 
VALIDATE $? "Start RabbitMQ"

# create RabbitMQ application user

rabbitmqctl add_user roboshop roboshop123
VALIDATE $? "Creating rabbitmq application user"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Setting permissions to rabbitmq application user"
