#!/bin/bash
#!/usr/bin/expect
function a(){

expect -c "
set timeout 10 

spawn ssh $1@$2

expect {
\"yes/no\" { send \"yes\r\";exp_continue }
\"*password*\" { send \"$3\r\"}
}
interact
"

}
a hcd 172.16.100.31 hcd hcd
