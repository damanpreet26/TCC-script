#!/bin/bash

#################################################################
# Settings.py file changing script                              #
#                                                               #
#                                                               #
#  run in terminal, use ./auto.sh                               #
#                                                               #
# Made By : Damanpreet Singh (DEMON)                            #
# http://damanpreet.co.cc/                                      #
#                                                               #
#                                                               #
# created : 4-10-2012                                           #
# last update : 15-11-2012                                      #
# VER=1.3                                                       #
#                                                               #
#################################################################

# this script works only for python 2.7


backup()
{

cp /etc/apache2/httpd.conf Automation/other_files/   #copies httpd.conf file in Automation/other_files folder

}

run()  # the function 
{
echo ""
echo "######################################################"
echo "#                                                    #"
echo "#    INSTALLING---TCC-Automation software---         #"
echo "#                                                    #"
echo "######################################################"
echo ""
#################################################################
#
# arrays with their values.
#
#################################################################

file=Automation/settings.py

array=("enter the email address :")
array1=("email_add")
array2=("37")

#################################################################
#
#  asking user to input the mysql username
#
#################################################################

a=1
while [ $a -ne 2 ]
do
{

# inputs database name from the user
read -p "enter mysql username :" db_user
read -p "enter mysql password :" db_password


RESULT=`mysql --user="$db_user" --password="$db_password" --skip-column-names -e "SHOW DATABASES LIKE 'mysql'"` 2> /dev/null
if [ $RESULT ]; then
    echo ""
    echo "Username and password match"
    a=2
    break


else
    echo "" 
    echo "Username and password doesn't match"
    echo "re-enter the details"
    echo ""

fi
}
done

sed -i "16 s/db_user/$db_user/" $file
sed -i "17 s/db_password/$db_password/" $file
##################################################################
#
# length of the array
#
##################################################################


len=${#array[*]}

i=0

while [ $i -lt $len ]; do
	read -p "${array[$i]}" ${array1[$i]}                           #this reads input from the user
	sed -i "${array2[$i]} s/${array1[$i]}/${!array1[$i]}/" $file   #uses sed command to replace word from file to be replaced by user inputs
	let i++
done                                                    #end of for loop
        

# this part checks if database name entered is created before or not.        
a=1
while [ $a -ne 2 ]
do
{

# inputs database name from the user
read -p "enter database name you want to create :" db_name

#checks the existance of database
RESULT=`mysql --user="$db_user" --password="$db_password" --skip-column-names -e "SHOW DATABASES LIKE '$db_name'"`
if [ $RESULT ]; then
    echo "The Database exist, choose another name for database."
else
    a=2
    break

fi
}
done    

    
        sed -i "15 s/db_name/$db_name/" $file
#cat Automation/settings.py                       #reads file in terminal


#################################################################################
#
# here the username automatically gets input from the system
#
#################################################################################


NAME=$(who am i | awk '{print $1}')

sed -i "111 s/user_name/$NAME/" $file
echo "the username is $NAME"




######################################################################
#
# changes in django.wsgi file 
#
######################################################################

sed -i "s/user_name/$NAME/" Automation/apache/django.wsgi

######################################################################
#
# changes in httpd.conf file
#
#######################################################################

# need sudo power for this

cat Automation/other_files/hhtp_cont >> /etc/apache2/httpd.conf    
      #this appends the text from the file to the httpd.conf


sed -i "s/user_name/$NAME/" /etc/apache2/httpd.conf           
      #this replaces the word to the username



#######################################################################
#
# creating the database and the further changes required by the user
#
#######################################################################


mysqlbash_path='/usr/bin/mysql'             #mysql path address

mysqlbash="$mysqlbash_path --user=$db_user --password=$db_password -e"  #declaring a variable

$mysqlbash "create database $db_name "      #creates databases with the name defined by the user

  # a new database is created

echo ""
echo ""
read -p "enter 'Yes' for the demo database & 'No' for new database : "  db_yesno


#this checks for every yes condition the user might enter in.
if [ $db_yesno = y ] || [ $db_yesno = Y ] ||[ $db_yesno = yes ] ||[ $db_yesno = YES ]     
then 
echo ""
echo "now u get the demo.sql in your database"
echo "get ready to use TCC automation software"


# this imports demo.sql to the database defined by the user
mysql --user=$db_user --password=$db_password $db_name < Automation/other_files/demo.sql 

cd Automation/

# this creates a new superuser
python manage.py createsuperuser

#defined every possible no condition
elif [ $db_yesno = n ] || [ $db_yesno = N ] || [ $db_yesno = no ] || [ $db_yesno = NO ]  
then
echo ""
echo "now u get a new database"
echo "enjoy your experience"


cd Automation/
python manage.py syncdb                   #creates a blnk database for use, using django commands


# scelect count(*) , counts the number of enteries in the table
result1=`mysql --user=root --password=demon --skip-column-names -e "use ed;" -e "select count(*) from auth_user;"`

#echo $result1

# ths checks if the count is zero or not
if [ $result1 = 0 ]
then
echo ""
echo "you need to create a superuser"
#this creates a superuser
python manage.py createsuperuser

else

echo ""
fi

# there is a need to enter Organisation details in the database.
echo ""
echo "Now get ready to ADD Organisation details to your software."
echo ""

read -p "enter organisation id :" id
read -p "enter organisation name :" name
read -p "enter organisation address :" address
read -p "phone/contact number :" phone
read -p "Director of the Organisation :" dir
#read -p "logo" logo

# this Inserts into the table the input values.
mysql  --user=$db_user --password=$db_password $db_name << EOF
Insert into tcc_organisation (id, name, address, phone, director, logo_upload) values( "$id", "$name", "$address", "$phone", '$dir', "$logo");
EOF


# There is a need to enter Department details in the database.
echo ""
echo "Now get ready to ADD Departmant details to your software."
echo ""

read -p "enter the Department id :" id
read -p "enter Department name :" name
read -p "enter Department address :" address
read -p "phone/contact number :" phone
read -p "Dean of the Department:" dean
read -p "enter the fax number :" faxno

# this inserts values into corresponding fields in tcc_department table
mysql  --user=$db_user --password=$db_password $db_name << EOF
Insert into tcc_department (id, organisation_id, name, address, phone, dean, faxno) values( "$id", 1, "$name", "$address", "$phone", '$dean', "$faxno");
EOF

fi   
}

restart()
{
/etc/init.d/apache2 restart               #restarts apache
}

browser()
{
gnome-open http://localhost/automation/
}

check()
{
 echo ""
   echo "######################################################"
   echo "#                                                    #"
   echo "#    DOWNLOADING---Automation software---            #"
   echo "#                                                    #"
   echo "######################################################"
   echo ""
   
   #this clones the Automation folder from github
   git clone https://github.com/sandeepmadaan/Automation.git

   backup       #backs up important files in other_files folder(/Automation/other_files/)
   run          #runs run function
   restart      #runs browser function
   browser      #runs browser function
}

#####################################################################################
#
#
#    Script starts here
#
#
#####################################################################################

if  [ -d /usr/local/lib/python2.7/dist-packages/django ] && [ -f /usr/bin/mysql ]; 
#if django and mysql are installed on the system the function runs.

then
   echo "-------installing required packages------"
   apt-get install apache2 libapache2-mod-wsgi 
   apt-get install python-mysqldb
   sudo apt-get install python-setuptools
   easy_install pip
   echo ""
   echo "-------installing django modules---------"
   pip install django-registration
   pip install django-tagging

  

###################################################################
#
#
#checking automation folder before in home directory
#
#
###################################################################

echo "now we test if there is any folder named Automation that exists in home directory"
if (test -d Automation)              #check if the same folder exits 
  then


######################################################################
#
# this part makes sure that if there is any existing Automation folder 
# in home directory then it renames it with Automation.date.time
#
#######################################################################

#cd /home/$user_name/
 
#exercise=/home/$user_name/
 
mDate=$(date +%Y%m%d%H:%M:%S)
for mFName in $PWD/Automation
do
    mPref=${mFName%.log}
    echo $mPref | egrep -q "\.[0-9]{10}:[0-9]{2}:[0-9]{2}"
    [ $? -eq 0 ] && continue
    mv ${mFName} ${mPref}.${mDate}
    echo $PWD3
done



  check

  else
  
  check 
  
fi

else
    echo "Install Django and Mysql, before running the script"              #else exits
    exit
fi

