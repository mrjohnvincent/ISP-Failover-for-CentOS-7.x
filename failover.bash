#/usr/bash
# failover
# written by John C. Vincent
# Version 1.0 for Centos 7.x
# This script depends on bash, date, ping, nslookup, ifup and ifdowm.
# This should work for most versions of Linux as long as you modify the following:
# The paths to date, ping, nslookup, etc are correct for your version of Linux and The network adapter Interfaces need to be correct for your setup.
# The two most useful commands to figure that out are "which" and "ip", as in "which date", "which ping" and "ip a".

#Define Stuff here
PrimaryISPInterface="enp0s3" #Comcast
BackupISPInterface="enp0s9" #Verizon
IPAddressPing1=4.2.2.2 #Primary IP to ping
IPAddressPing2=8.8.8.8 #Secondary IP to ping
TimeToRest=2 #Time to wait before pinging
FailedAllowed=1 #How many confirmed failers are allowed before failing over.
LogFile="/var/log/FailOver.Log"  #The log file

#Interal Vars Defined
ActiveInterface=$PrimaryISPInterface
PassiveInterface=$BackupISPInterface
Fails=0

FailOver() {
# Start Primary Interface
echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]" ` >> $LogFile 2>&1
echo "Stating Failover..." >> $LogFile 2>&1
echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]" ` >> $LogFile 2>&1
echo "ifdown $ActiveInterface" >> $LogFile 2>&1
/usr/sbin/ifdown $ActiveInterface >> $LogFile 2>&1
echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]" ` >> $LogFile 2>&1
echo "ifup $ActiveInterface" >> $LogFile 2>&1
/usr/sbin/ifup $ActiveInterface >> $LogFile 2>&1
echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]" ` >> $LogFile 2>&1
echo "ifdown $PassiveInterface" >> $LogFile 2>&1
/usr/sbin/ifdown $PassiveInterface >> $LogFile 2>&1
echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]" ` >> $LogFile 2>&1
echo "Failover Completed.  Active connection is on $ActiveInterface"  >> $LogFile 2>&1
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-" >> $LogFile 2>&1
}

CheckISP() {
if /usr/bin/ping -c 1 $IPAddressPing2 &> /dev/null && /usr/bin/nslookup $IPAddressPing2 &> /dev/null ;then
  Fails=0
  return
else
  echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]" ` >> $LogFile 2>&1
  echo "Ping or DNS reverse lookup failed for $IPAddressPing1 ...Attempting same tests using $IPAddressPing2 to confirm outage" >> $LogFile 2>&1
  if /usr/bin/ping -c 1 $IPAddressPing2 &> /dev/null && /usr/bin/nslookup $IPAddressPing2 &> /dev/null ;then
    echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]" ` >> $LogFile 2>&1
    echo "Ping and DNS successful for $IPAddressPing2 resetting fails to zero." >> $LogFile 2>&1
    Fails=0
    return
  else
    Fails=$((Fails+1))
    echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]" ` >> $LogFile 2>&1
    echo "Ping or DNS reverse lookup failed for $IPAddressPing2" >> $LogFile 2>&1
    echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]" ` >> $LogFile 2>&1
    echo "Current fail count is $Fails out $FailedAllowed allowed confirmed failures" >> $LogFile 2>&1
  fi
fi

if [ $Fails -ge $FailedAllowed ]; then
  echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]" ` >> $LogFile 2>&1
  echo "!!!ISP FAILURE DETECTED!!!  Starting $PassiveInterface Connection..." >> $LogFile 2>&1
  TempHolder=$PassiveInterface
  PassiveInterface=$ActiveInterface
  ActiveInterface=$TempHolder
  FailOver
fi
}

#Let's get them in as known good state with the Primary ISP Interface active
echo -n `/usr/bin/date +"[%m-%d %H:%M:%S]" ` >> $LogFile 2>&1
echo "Starting Default Config for FailOver" >> $LogFile 2>&1
FailOver

while [ 1 -gt 0 ]; do  #Forever Loop
sleep $TimeToRest #Let's rest a bit.
CheckISP #Checking ISP Connection
done
