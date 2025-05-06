FROM ubuntu:22.04 as builder

#Could be rt-mbms-tx or rt-mbms-tx-for-qrd-and-crd
ARG TYPE_TX

##### INSTALL DEPENDENCIES ######
RUN if [ "$TYPE_TX" = "rt-mbms-tx" ]; then \
        apt-get update && \ 
        apt-get install sudo && DEBIAN_FRONTEND=noninteractive \
        apt-get install -y build-essential \
        g++ cmake libfftw3-dev libmbedtls-dev libboost-program-options-dev \
        libconfig++-dev libsctp-dev git iproute2 smcroute ffmpeg systemd libuhd-dev uhd-host libuhd-dev kmod wget python3 && \
        sudo uhd_images_downloader ;\ 
    elif [ "$TYPE_TX" = "rt-mbms-tx-for-qrd-and-crd" ]; then \
        ln -snf /usr/share/zoneinfo/Europe/Madrid /etc/localtime && \
        apt-get update && \
        apt-get install -y \
        ssh g++ git cmake libboost-atomic-dev libboost-thread-dev \
        libboost-system-dev libboost-date-time-dev libboost-regex-dev \ 
        libboost-filesystem-dev libboost-random-dev libboost-chrono-dev \
        libboost-serialization-dev libwebsocketpp-dev openssl libssl-dev ninja-build \
        libspdlog-dev libmbedtls-dev libboost-all-dev libconfig++-dev libsctp-dev \
        libfftw3-dev vim libcpprest-dev libusb-1.0-0-dev net-tools smcroute python3-pip \
        clang-tidy gpsd gpsd-clients libgps-dev ffmpeg libuhd-dev uhd-host libuhd-dev sudo && \
        pip3 install cpplint psutil && \
        apt-get install -y libsoapysdr-dev soapysdr-tools && \
        apt-get install -y soapysdr-module-bladerf && \
        bladeRF-install-firmware && \
        sudo uhd_images_downloader ;\
    else \
        echo "No valid value specified"; \
    fi

##### BUILDING #####
RUN mkdir -p /opt/build/${TYPE_TX}
WORKDIR /opt/build/${TYPE_TX}

#### CLONE #####
RUN git clone --recurse-submodules https://github.com/5G-MAG/${TYPE_TX}.git . && \
    git submodule update

##### BUILD AND INSTALL #####
RUN if [ "$TYPE_TX" = "rt-mbms-tx" ]; then \
        mkdir build && cd build && \
        cmake ../ && \
        make && \
        make install && \
        srsran_install_configs.sh user ;\
    elif [ "$TYPE_TX" = "rt-mbms-tx-for-qrd-and-crd" ]; then \
        mkdir build && cd build && \
        cmake -DCMAKE_INSTALL_PREFIX=/usr -GNinja .. && \
        ninja && \
        ninja install && \
        ./srsran_install_configs.sh user ;\
    else \
        echo "No valid value specified"; \
    fi

#### COPY FILES ####
COPY conf_files/sib.conf.mbsfn /tmp/sib.conf.mbsfn
COPY conf_files/enb.conf /tmp/enb.conf

RUN if [ "$TYPE_TX" = "rt-mbms-tx" ]; then \
        cp /tmp/sib.conf.mbsfn /root/.config/srsran/sib.conf.mbsfn && \
        cp /tmp/enb.conf /root/.config/srsran/enb.conf ;\
    elif [ "$TYPE_TX" = "rt-mbms-tx-for-qrd-and-crd" ]; then \
        cp sib.conf.mbsfn /root/.config/srsran/sib.conf.mbsfn && \
        cp Config-Template/enb.conf /root/.config/srsran/enb.conf && \
        cp Config-Template/epc.conf /root/.config/srsran/epc.conf && \
        cp Config-Template/rr.conf /root/.config/srsran/rr.conf ;\
    fi

#BOTH OPTIONS
RUN mkdir -p /root/scripts
COPY full_hd.mp4 /root/Big-Buck-Bunny/BigBuckBunny480p30s.mp4

##### SCRIPTS #####
RUN if [ "$TYPE_TX" = "rt-mbms-tx" ]; then \
        echo '#!/bin/bash\n\
        cd /opt/build/rt-mbms-tx/build\n\
        ./srsenb/src/srsenb /root/.config/srsran/enb.conf --enb_files.sib_config /root/.config/srsran/sib.conf.mbsfn --rf.tx_gain 50' > /root/scripts/srsenb.sh && \
        chmod +x /root/scripts/srsenb.sh && \
        echo '#!/bin/bash\n\
        cd /opt/build/rt-mbms-tx/build\n\
        ./srsepc/src/srsmbms /root/.config/srsran/mbms.conf &' > /root/scripts/srsmbms_rt-mbms-tx.sh && \
        chmod +x /root/scripts/srsmbms_rt-mbms-tx.sh && \
        echo '#!/bin/bash\n\
        cd /opt/build/rt-mbms-tx/build\n\
        ./srsepc/src/srsepc /root/.config/srsran/epc.conf --hss.db_file /root/.config/srsran/user_db.csv &' > /root/scripts/srsepc.sh && \
        chmod +x /root/scripts/srsepc.sh && \
        echo '#!/bin/bash\n\
        smcroute -d\n\
        smcroutectl restart\n\
        smcroutectl add eth0 239.255.1.1 sgi_mb\n\
        ip route add 239.255.1.0/24 dev sgi_mb ' > /root/scripts/smcroute_rt-mbms-tx.sh && \
        chmod +x /root/scripts/smcroute_rt-mbms-tx.sh && \
        echo '#!/bin/bash\n\
        while true; do ffmpeg -re -i /root/Big-Buck-Bunny/BigBuckBunny480p30s.mp4 -c copy -map 0 -f rtp_mpegts rtp://239.255.1.1:9988; done ' > /root/scripts/ffmpeg_rt-mbms-tx.sh && \
        chmod +x /root/scripts/ffmpeg_rt-mbms-tx.sh ; \
    elif [ "$TYPE_TX" = "rt-mbms-tx-for-qrd-and-crd" ]; then \
        echo '#!/bin/bash\n\
        cd /opt/build/rt-mbms-tx-for-qrd-and-crd/build\n\
        ./srsenb/src/srsenb /root/.config/srsran/enb.conf --enb_files.sib_config /root/.config/srsran/sib.conf.mbsfn --rf.tx_gain 50' > /root/scripts/srsenb.sh && \
        chmod +x /root/scripts/srsenb.sh && \
        echo '#!/bin/bash\n\
        cd /opt/build/rt-mbms-tx-for-qrd-and-crd/build\n\
        ./srsepc/src/srsepc /root/.config/srsran/epc.conf --hss.db_file /root/.config/srsran/user_db.csv &' > /root/scripts/srsepc.sh && \
        chmod +x /root/scripts/srsepc.sh && \
        echo '#!/bin/bash\n\
        cd /opt/build/rt-mbms-tx-for-qrd-and-crd/build\n\
        ./srsepc/src/srsmbms /root/.config/srsran/mbms.conf &\n\
        route add -net 239.11.4.0 netmask 255.255.255.0 dev sgi_mb &' > /root/scripts/srsmbms_rt-mbms-tx-for-qrd-and-crd.sh && \
        chmod +x /root/scripts/srsmbms_rt-mbms-tx-for-qrd-and-crd.sh && \
        echo '#!/bin/bash\n\
        ffmpeg -stream_loop -1 -re -i /root/Big-Buck-Bunny/BigBuckBunny480p30s.mp4 -vcodec copy -an -f rtp_mpegts udp://239.11.4.50:9988' > /root/scripts/ffmpeg_rt-mbms-tx-for-qrd-and-crd.sh && \
        chmod +x /root/scripts/ffmpeg_rt-mbms-tx-for-qrd-and-crd.sh ; \
    fi

##### STARTING THE CONTAINER #####
RUN if [ "$TYPE_TX" = "rt-mbms-tx" ]; then \
    echo '#!/bin/bash\n\
    cd /root/.config/srsran && chmod 777 -R . &&\
    /root/scripts/srsmbms_rt-mbms-tx.sh &&\
    /root/scripts/srsepc.sh && ip a &&\
    /root/scripts/smcroute_rt-mbms-tx.sh &&\
    /root/scripts/srsenb.sh &\
    /root/scripts/ffmpeg_rt-mbms-tx.sh' > /root/entrypoint.sh && \
    chmod +x /root/entrypoint.sh ;\
elif [ "$TYPE_TX" = "rt-mbms-tx-for-qrd-and-crd" ]; then \
    echo '#!/bin/bash\n\
    SoapySDRUtil --find &&\
    cd /root/.config/srsran &&\
    chmod 777 -R . &&\
    /root/scripts/srsmbms_rt-mbms-tx-for-qrd-and-crd.sh &&\
    /root/scripts/srsepc.sh &&\
    /root/scripts/srsenb.sh &\
    /root/scripts/ffmpeg_rt-mbms-tx-for-qrd-and-crd.sh' > /root/entrypoint.sh && \
    chmod +x /root/entrypoint.sh ;\
else\
  echo "No valid value specified";\
fi

ENTRYPOINT ["/root/entrypoint.sh"]