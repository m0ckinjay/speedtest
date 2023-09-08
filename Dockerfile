ARG DEBIAN_FRONTEND=noninteractive
ARG DEBIAN_FRONTEND
ARG LOG_LEVEL=trace
ARG LOG_LEVEL

FROM debian

WORKDIR .

RUN <<EOF
#update and install ntp client
# apt-get update && apt-get install -y ntp

#unlink the timezone determining file and link it to the nairobi timezone
unlink /etc/localtime
ln -s /usr/share/zoneinfo/Africa/Nairobi /etc/localtime
EOF

#NTP not necessary as the linkage above sets the correct time
# #copy ntp conf file
# COPY ./ntp/ntp.conf /etc/ntp.conf

# #expose port to receive ntp requests
# EXPOSE 123/udp

# # Start the NTP server
# RUN ntpd -g -n&


#====================================================================#

RUN <<EOF
#install required debian packages
apt update &&  apt-get install -y curl jq gnupg1 apt-transport-https dirmngr python3 python3-pip python3-venv

#create the require project parent folder
mkdir -p /opt/speedtest

EOF

#copy speedtest script to setup environment to allow installation of speedtest package
COPY ./speedtest_Shell_scripts/speedtest.sh /opt/speedtest/

RUN <<EOF
#make script executable and execute, then strip executability - sets up speedtest repo, precursor to successful apt install speedtest
chmod +x /opt/speedtest/speedtest.sh && /opt/speedtest/speedtest.sh && chmod -x /opt/speedtest/speedtest.sh

#install speedtest
apt update && apt install -y speedtest
EOF


RUN <<EOF
#Create virtual env to install required modules
python3 -m venv /opt/speedtest/influx_write_venv
/opt/speedtest/influx_write_venv/bin/pip3 install influxdb influxdb-client
#mkdir that will later hold py script to write to db
mkdir /opt/speedtest/influx_write
EOF

#copy script to run speedtests
COPY ./speedtest_Shell_scripts/custom_speedtest.sh /opt/speedtest/

#make script executable
RUN <<EOF
chmod +x /opt/speedtest/custom_speedtest.sh
EOF

ENTRYPOINT ["/opt/speedtest/custom_speedtest.sh"]

