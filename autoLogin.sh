#!/usr/bin/expect
set ip [lindex $argv 0]
set username [lindex $argv 1]
set mypassword [lindex $argv 2]
set timeout 10 

spawn ssh $username@$ip
#expect {                      # 返回信息匹配 
#"*yes/no" { send "yes\r"; exp_continue}  # 第一次ssh连接会提示yes/no,继续  
#"*password:" { send "h$tor!01\r" }    # 出现密码提示,发送密码  
#} 
#                expect  "
#                set timeout -1
#                expect {
#                        \"*(yes/no)*\" {send \"yes\r\";exp_continue }
#                        \"*password:\" {send \"hcd\r\";exp_continue }
#                        eof {exit 0} 
#                        }"

expect {
"yes/no" { send "yes\r";exp_continue }
"*password*" { send "$mypassword\r"}
}
interact        # 交互模式,用户会停留在远程服务器上面
