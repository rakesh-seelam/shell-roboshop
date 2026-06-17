#! /bin/bash

USER_ID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
#SCRIPT_DIR=$PWD
#MONGODB_HOST=mongodb.rakesh.bond

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

dnf list installed | grep redis &>>$LOG_FILE
if [ $? -ne 0 ]; then
    dnf module disable redis -y &>>$LOG_FILE
    dnf module enable redis:7 -y
    dnf install redis -y &>>$LOG_FILE
    VALIDATE $? "Enabling and installing Redis-7"
else
    echo -e "Redis already Installed $Y SKIPPING $N "
fi 

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing remote connections"

systemctl enable redis &>>$LOG_FILE
systemctl start redis 
VALIDATE $?  "Enabling and starting Redis"
