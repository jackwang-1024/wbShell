#!/bin/bash
#!/usr/bin/expect

function a(){
echo $1
echo $2
cd /home/hcd/.ssh

if [[ -f "id_rsa.pub" ]];then
   echo "id_rsa.pub already exists!"
else
   echo "id_rsa.pub didn't exist!start to generate!"
   expect -c "
   set timeout -1
   spawn ssh-keygen -t rsa
   expect {
   \"yes/no\" { send \"yes\r\";exp_continue }
   \"/home/hcd/.ssh/id_rsa\" { send \"\r\";exp_continue }
   \"passphrase\" { send \"\r\";exp_continue }
   \"again\" { send \"\r\";exp_continue }
   eof { exit 0}
  }
  "
fi

expect -c "
   set timeout -1
   spawn ssh-copy-id -i id_rsa.pub hcd@$1
   expect {
   \"yes/no\" { send \"yes\r\";exp_continue }
   \"password\" { send \"$2\r\";exp_continue }
   eof { exit 0}
  }
"
}


a 172.16.100.50 "h\\\$tor!01"
