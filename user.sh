#!/bin/bash

USER_ID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.rakesh.bond

mkdir -p $LOG_FOLDER

if [ $USER_ID -ne 0 ]; then
   echo -e "$R Run this script as root user $N" | tee -a $LOG_FILE
   exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
      echo -e "$2: $R FAILURE $N" | tee -a $LOG_FILE
      exit 1
    else
      echo -e "$2: $G Success $N" | tee -a $LOG_FILE
    fi
}

dnf list installed | grep nodejs &>>$LOG_FILE
if [ $? -ne 0 ]; then
    dnf module disable nodejs -y &>>$LOG_FILE
    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "Enabling nodejs-20"

    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "Installing nodejs"
else
    echo -e "Nodejs already installed $Y SKIPPING $N"
fi

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  VALIDATE $? "Creating system user"
else
  echo -e "User already exist $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating App Directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
cd /app 
VALIDATE $? "Downloading User Code"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "Downloading and Unzipping user"

cd /app 
npm install &>>$LOG_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "Copying user.service"

systemctl daemon-reload
VALIDATE $? "Reloading Daemon"

systemctl enable user &>>$LOG_FILE
systemctl start user
VALIDATE $? "Enabling and Starting User"