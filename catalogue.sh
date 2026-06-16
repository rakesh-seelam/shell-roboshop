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
      echo -e "$R $2: FAILURE $N" | tee -a $LOG_FILE
      exit 1
    else
      echo -e "$G $2: Success $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y 
VALIDATE $? "Disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs-20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating System User"
else
   echo -e "Roboshop User already exists $Y SKIPPING $N"
fi

mkdir /app 
VALIDATE $? "Creating temporary directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zi
VALIDATE $? "Downloading Catalogue Code"

cd /app
VALIDATE $? "Moving to App directory"

unzip /tmp/catalogue.zip
VALIDATE $? "Unzipping catalogue code"

npm install
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalagoue service"

systemctl daemon-reload
VALIDATE $? "Reloading Daemon"

systemctl enable catalogue 
systemctl start catalogue
VALIDATE $? "Enabling and Starting Catalogue"

