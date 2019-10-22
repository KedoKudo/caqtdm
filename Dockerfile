FROM kedokudo/synapps:latest
LABEL version="0.0.2" \
      maintainer="kedokudo <chenzhang8722@gmail.com>" \
      lastupdate="2019-10-22"
USER  root

# ENV   EPICS_ROOT="${APP_ROOT}"
# ENV   EPICS="${EPICS_ROOT}"
ENV   EPICS_BASE="${APP_ROOT}/base"
ENV   EPICSEXTENSIONS="${APP_ROOT}/extensions"
ENV   EPICSLIB="${EPICS_BASE}/lib/${EPICS_HOST_ARCH}"
ENV   EPICSINCLUDE="${EPICS_BASE}/include"
ENV   PYTHONVERSION="2.7"
ENV   PYTHONINCLUDE="/usr/include/python2.7"
ENV   PYTHONLIB="/usr/lib"
ENV   SIMDET_BIN="${AREA_DETECTOR}/ADSimDetector/iocs/simDetectorIOC/bin/${EPICS_HOST_ARCH}"
ENV   QWTLIB="/usr/lib"
ENV   PATH="${SIMDET_BIN}:${PATH}"
ENV   CAQTDMVER="V4.2.4"

RUN apt-get update  -y && apt-get upgrade -y && \
    apt-get install -y  \
    libqwt-qt5-dev \
    libqt5svg5* \
    libqt5x11extras5* \
    python-dev \
    qt5-default \
    qttools5-dev \
    qttools5-dev-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/lib
RUN ln -s libqwt-qt5.so libqwt.so

WORKDIR /opt
ADD https://github.com/caqtdm/caqtdm/archive/${CAQTDMVER}.tar.gz  /opt
RUN    tar xvf ${CAQTDMVER}.tar.gz \
    && rm ${CAQTDMVER}.tar.gz \
    && ln -s caqtdm-4.2.4 caqtdm
WORKDIR /opt/caqtdm
RUN     ["./caQtDM_BuildAll"]


# --- adjust ui files for motors ---
WORKDIR ${SUPPORT}/xxx-R6-1
RUN sed -i s:/APSshare/bin/caQtDM:caQtDM:g start_caQtDM_xxx      && \
    sed -i s/xxx:/${PREFIX}/g              xxxApp/op/adl/xxx.adl && \
    sed -i s/ioc=xxx/ioc=${PREFIX}/g       xxxApp/op/adl/xxx.adl && \
    sed -i s/XXX/`echo ${PREFIX}`/g        xxxApp/op/ui/xxx.ui   && \
    sed -i s/xxx:/${PREFIX}/g              xxxApp/op/ui/xxx.ui   && \
    sed -i s/ioc=xxx/ioc=${PREFIX}/g       xxxApp/op/ui/xxx.ui

# Grab all the ui files for all devices and put them in a centralized location
ADD https://raw.githubusercontent.com/prjemian/epics-docker/master/n3_synApps/copy_screens.sh ${SUPPORT}/
RUN bash ${SUPPORT}/copy_screens.sh ${SUPPORT} ${SUPPORT}/screens

# post-build config
ENV CAQTDM_DIR="/opt/caqtdm-4.2.4/"
ENV PATH="${CAQTDM_DIR}/caQtDM_Binaries:${PATH}"
ENV CAQTDM_DISPLAY_PATH="${SUPPORT}/screens/ui"
ENV CAQTDM_OPTIMIZE_EPICS3CONNECTIONS="TRUE"

# setup quick start GUI functions
ENV AD_PREFIX="6iddSIMDET1:"
ENV PREFIX="6iddSIM1:"
RUN echo '#! /bin/sh' >> /bin/startGUI && \
    echo 'caQtDM -macro "P=${PREFIX}"                      ${CAQTDM_DISPLAY_PATH}/xxx.ui &'         >> /bin/startGUI && \
    echo 'caQtDM -macro "P=${AD_PREFIX},R=cam1:"           ${CAQTDM_DISPLAY_PATH}/simDetector.ui &' >> /bin/startGUI && \
    echo 'caQtDM -macro "MOTOR=${PREFIX},AD=${AD_PREFIX}"  ${CAQTDM_DISPLAY_PATH}/motor_adsim.ui &' >> /bin/startGUI && \
    chmod +x /bin/startGUI

# point to ui camp
WORKDIR ${CAQTDM_DISPLAY_PATH}
ADD https://raw.githubusercontent.com/prjemian/epics-docker/master/caQtDM/motor_adsim.ui .

# --- DEV ---
# docker build -t kedokudo/caqtdm:latest .
# docker run -it --rm  kedokudo/caqtdm:latest /bin/bash

# --- GET GUI ---
# for dev only
# ifconfig en0 to get the local IP (mac required)
# 130.202.62.166 is the local IP assigned to your mac, for linux OS :0 is sufficient
# docker run -it --net=host -e DISPLAY=130.202.63.4:0 --volume="$HOME/.Xauthority:/root/.Xauthority:rw" kedokudo/caqtdm:latest /bin/bash

# --- Area Detector Control UI file lcoation
# /opt/synApps/support/areaDetector-R3-7/ADSimDetector/simDetectorApp/op/ui/autoconvert
# running:  caQtDM -macro "P=6iddSim:,R=cam1:" simDetector.ui

# motor https://github.com/prjemian/epics-docker/blob/master/n3_synApps/start_xxx.sh
# xxx.ui 

# edit st_base.cmd
# EOF 
# dbpf("xxx:m1.HLM", 5)  database put field
# dbpf("xxx:m1.LLM", 0)

# dbpr                   database print field
