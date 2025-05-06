FROM ubuntu:22.04 as builder
RUN apt-get update && \ 
    apt-get install sudo && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y build-essential \
    g++ cmake libfftw3-dev libmbedtls-dev libboost-program-options-dev \
    libconfig++-dev libsctp-dev git iproute2 smcroute ffmpeg systemd libuhd-dev uhd-host libuhd-dev kmod wget python3 python3-pip python3-dev libzmq3-dev netcat
RUN pip3 install zmq numpy
RUN sudo uhd_images_downloader

#Building tx------
RUN mkdir -p /opt/build/rt-mbms-tx 
WORKDIR /opt/build/rt-mbms-tx

#Clone repo
RUN git clone --recurse-submodules https://github.com/5G-MAG/rt-mbms-tx.git . && \
    git submodule update

#Build and install the LTE-based 5G Broadcast transmitter
RUN mkdir build && cd build && \
    cmake ../ && \
    make && \
    # make test && \
    make install && \
    srsran_install_configs.sh user

COPY conf_files/sib.conf.mbsfn /root/.config/srsran/sib.conf.mbsfn
COPY conf_files/enb.conf /root/.config/srsran/enb.conf
#COPY conf_files/ue.conf /root/.config/srsran/ue.conf

RUN mkdir -p /root/scripts

RUN echo '#!/bin/bash\n\
cd /opt/build/rt-mbms-tx/build\n\
./srsepc/src/srsmbms /root/.config/srsran/mbms.conf &' > /root/scripts/srsmbms.sh && \
chmod +x /root/scripts/srsmbms.sh

RUN echo '#!/bin/bash\n\
cd /opt/build/rt-mbms-tx/build\n\
./srsepc/src/srsepc /root/.config/srsran/epc.conf --hss.db_file /root/.config/srsran/user_db.csv &' > /root/scripts/srsepc.sh && \
chmod +x /root/scripts/srsepc.sh

COPY full_hd.mp4 /root/Big-Buck-Bunny/BigBuckBunny480p30s.mp4

RUN echo '#!/bin/bash\n\
smcroute -d\n\
smcroutectl restart\n\
smcroutectl add eth0 239.255.1.1 sgi_mb\n\
ip route add 239.255.1.0/24 dev sgi_mb ' > /root/scripts/smcroute.sh && \
chmod +x /root/scripts/smcroute.sh

RUN echo '#!/bin/bash\n\
cd /opt/build/rt-mbms-tx/build\n\
./srsenb/src/srsenb /root/.config/srsran/enb.conf --enb_files.sib_config /root/.config/srsran/sib.conf.mbsfn --rf.tx_gain 50' > /root/scripts/srsenb.sh && \
chmod +x /root/scripts/srsenb.sh

# RUN echo '#!/bin/bash\n\
# cd /opt/build/rt-mbms-tx/build\n\
# ./srsue/src/srsue /root/.config/srsran/ue.conf --rf.device_name=zmq --rf.device_args="tx_port=tcp://*:2001,rx_port=tcp://localhost:2000,id=ue,base_srate=23.04e6" --gw.netns=ue1' > /root/scripts/srsue.sh && \
# chmod +x /root/scripts/srsue.sh

RUN echo '#!/bin/bash\n\
while true; do ffmpeg -re -i /root/Big-Buck-Bunny/BigBuckBunny480p30s.mp4 -c copy -map 0 -f rtp_mpegts rtp://239.255.1.1:9988; done ' > /root/scripts/ffmpeg.sh && \
chmod +x /root/scripts/ffmpeg.sh

CMD ["bash", "-c", "\
  cd /root/.config/srsran &&\
  chmod 777 -R . && \
  /root/scripts/srsmbms.sh && \
  /root/scripts/srsepc.sh &&\
  ip a &&\
  /root/scripts/smcroute.sh &&\
  /root/scripts/srsenb.sh & \
  #/root/scripts/srsue.sh & \
  /root/scripts/ffmpeg.sh"]
