#! /bin/bash

USER_ID=$(id -u)
LOG_FOLDER="/var/logs/shell-roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"


if [ $USER_ID -ne 0 ]; then
   echo "Run this script as root user" | tee -a LOG_FILE
   exit 1
fi

mkdir -p $LOG_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
      echo "$2: FAILURE"
      exit 1
    else
      echo "$2: Success"
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongo Repo"

dnf install mongodb-org -y | &>>$LOG_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod | &>>$LOG_FILE
VALIDATE $? "Enabling Mongodb"

systemctl start mongod 
VALIDATE $? "Starting Mongodb"

sed -i s/127.0.0.1/0.0.0.0/g /etc/mongod.conf
VALIDATE $? "Allowing remote connections"

systemctl restart mongod
VALIDATE $? "Restarted MongoDB"

