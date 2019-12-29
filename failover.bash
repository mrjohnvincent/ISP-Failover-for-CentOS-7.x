#/usr/bash
#This should work for most versions of Linux as long as you modify the following:
#
#The paths to date and ping are correct for your version of Linux and The network adapter Interfaces need to be correct for your setup.
#The two most useful commands to figure that out are "which" and "ip", as in "which date", "which ping" and "ip a".

#Define Stuff here
PrimaryISPInterface="enp0s3" #Comcast
BackupISPInterface="enp0s9" #Verizon
TimeToRest=2 #Time to wait before pinging

LogFile="/root/FailOver.Log"
ActiveInterface=$PrimaryISPInterface
PassiveInterface=$BackupISPInterface


FailOver() {
# Start Primary Interface
echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]"` >> $LogFile 2>&1
echo "Stating Failover..." >> $LogFile 2>&1
echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]"` >> $LogFile 2>&1
echo "ifdown $ActiveInterface" >> $LogFile 2>&1
/usr/sbin/ifdown $ActiveInterface >> $LogFile 2>&1
echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]"` >> $LogFile 2>&1
echo "ifup $ActiveInterface" >> $LogFile 2>&1
/usr/sbin/ifup $ActiveInterface >> $LogFile 2>&1
echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]"` >> $LogFile 2>&1
echo "ifdown $PassiveInterface" >> $LogFile 2>&1
/usr/sbin/ifdown $PassiveInterface >> $LogFile 2>&1
echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]"` >> $LogFile 2>&1
echo "Failover Completed."
}

CheckISP() {
if /usr/bin/ping -c 1 8.8.8.8 &> /dev/null ;then
  return
else
  echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]"` >> $LogFile 2>&1
  echo "Ping Failed!!!  Starting $PassiveInterface Connection..." >> $LogFile 2>&1
  TempHolder=$PassiveInterface
  PassiveInterface=$ActiveInterface
  ActiveInterface=$TempHolder
  FailOver
fi
}

#Let's get them in as known good state with the Primary ISP Interface active
echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]"` >> $LogFile 2>&1
echo "Starting Default Config for FailOver" >> $LogFile 2>&1
FailOver

while [ 1 -gt 0 ]; do  #Forever Loop
  sleep $TimeToRest #Let's rest a bit.
  CheckISP #Checking ISP Connection
done
