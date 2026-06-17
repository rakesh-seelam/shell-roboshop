#!/bin/bash

USER_ID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MYSQL_HOST=mysql.rakesh.bond

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

dnf install maven -y
VALIDATE $? "Installing Maven"

id roboshop
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
else
  echo "user already exists $Y SKIPPING $N "
fi

mkdir -p /app 
VALIDATE $? "Creating App directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading ZIP code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping shipping code"

cd /app
mvn clean package &>>$LOG_FILE
VALIDATE $? "Installing and Building shipping"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Moving and Renaming shipping"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Created systemctl service

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing mysql"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
if [ $? -ne 0 ]; then

    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOGS_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loaded data into MySQL"
else
    echo -e "data is already loaded ... $Y SKIPPING $N"
fi

systemctl enable shipping &>>$LOG_FILE
systemctl start shipping
VALIDATE $? "Enabled and started shipping"