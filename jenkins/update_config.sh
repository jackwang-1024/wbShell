#!/bin/bash

echo -e "stop hcdadmin service"
sudo service hcdadmin stop
sleep 5

echo -e "disable to automatically restart hcdadmin service"
sudo sed -i 's/Restart=on-failure/#Restart=on-failure/g' /lib/systemd/system/hcdadmin.service
sudo sed -i 's/RestartSec=15/#RestartSec=60/g' /lib/systemd/system/hcdadmin.service
sudo systemctl daemon-reload

echo -e "disable to restart hcddaelaam service"
sudo sed -i 's/Restart=on-failure/#Restart=on-failure/g' /lib/systemd/system/hcddaelaam.service
sudo sed -i 's/RestartSec=15/#RestartSec=15/g' /lib/systemd/system/hcddaelaam.service
echo -e "change LimitCORE to infinity"
sudo sed -i 's/LimitCORE=0/LimitCORE=infinity/g' /lib/systemd/system/hcddaelaam.service
sudo systemctl daemon-reload

echo -e "start hcdadmin service"
sudo service hcdadmin start
exit 0
