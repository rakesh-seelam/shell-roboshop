#!/bin/bash

USER_ID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"
SCRIPT_DIR=$PWD

mkdir -p $LOG_FOLDER

if [ $USER_ID -ne 0 ]; then
   echo "Run this script as root user" | tee -a $LOG_FILE
   exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
      echo "$2: FAILURE"
      exit 1
    else
      echo "$2: Success"
    fi
}

dnf module list nginx &>>$LOG_FILE
VALIDATE $? "listing Nginx"

dnf module disable nginx -y
VALIDATE $? "Disabling default Nginx"

dnf module enable nginx:1.24 -y 
dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing Nginx:1.24"

systemctl enable nginx &>>$LOG_FILE
systemctl start nginx 
VALIDATE $? "Enabling and Starting Nginx"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Zip code"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Unzipping the code"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copied our nginx conf file"

systemctl restart nginx
VALIDATE $? "Restarted Nginx"