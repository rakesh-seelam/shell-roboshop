#! /bin/bash

USER_ID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

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

dnf install mysql-server -y
VALIDATE $? "installing Mysql server"

systemctl enable mysqld
systemctl start mysqld  
VALIDATE $? "enabling and starting  mysqld"

mysql_secure_installation --set-root-pass read -s PASSWORD
VALIDATE $? "Setup root password"