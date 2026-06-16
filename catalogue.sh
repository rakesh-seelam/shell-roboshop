#! /bin/bash

USER_ID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD

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
    VALIDATE $? "Disabling nodejs"

    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "Enabling nodejs-20"

    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "Installing nodejs"
else 
  echo -e "nodejs is already installed $Y SKIPPING $N"
fi

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating System User"
else
   echo -e "Roboshop User already exists $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating temporary directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip
VALIDATE $? "Downloading Catalogue Code"

cd /app
VALIDATE $? "Moving to App directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzipping catalogue code"

npm install &>>$LOG_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalagoue service"

systemctl daemon-reload
VALIDATE $? "Reloading Daemon"

systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue
VALIDATE $? "Enabling and Starting Catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE

INDEX=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js
    VALIDATE $? "Loading products"
else
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "Restarting catalogue"