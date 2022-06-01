# This Dockerfile is used to build an ROS + OpenGL + Gazebo + Tensorflow image based on Ubuntu 18.04
FROM tensorflow/tensorflow:1.15.5-gpu

RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub

# Install sudo
RUN apt-get update && \
    apt-get install -y sudo apt-utils curl

# Environment config
ENV DEBIAN_FRONTEND=noninteractive

# Add new sudo user
ARG user=ros
ARG passwd=ros
ARG uid=1000
ARG gid=1000
ENV USER=$user
ENV PASSWD=$passwd
ENV UID=$uid
ENV GID=$gid
RUN useradd --create-home -m $USER && \
        echo "$USER:$PASSWD" | chpasswd && \
        usermod --shell /bin/bash $USER && \
        usermod -aG sudo $USER && \
        echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USER && \
        chmod 0440 /etc/sudoers.d/$USER && \
        # Replace 1000 with your user/group id
        usermod  --uid $UID $USER && \
        groupmod --gid $GID $USER

### ROS Installation
# Install other utilities
RUN apt-get update && \
    apt-get install -y vim \
    tmux \
    git \
    wget \
    lsb-release \
    lsb-core

# Install ROS
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/ros-latest.list' && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add - && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116 && \
    apt-get update && apt-get install -y ros-melodic-desktop && \
    apt-get install -y python-rosinstall && \
    apt install -y python-rosdep && \
    rosdep init

# Setup ROS
USER $USER
RUN rosdep fix-permissions && rosdep update
RUN echo "source /opt/ros/melodic/setup.bash" >> ~/.bashrc

### Tensorflow Installation
# Install pip
USER root
RUN apt-get install -y wget python-pip python-dev libgtk2.0-0 unzip libblas-dev liblapack-dev libhdf5-dev && \
    curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py && \
    python2 get-pip.py

# Expose Tensorboard
EXPOSE 6006

# Setup Tensorflow
RUN echo "export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}" >> ~/.bashrc
RUN echo 'export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda-10.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"' >> ~/.bashrc

### GQ-CNN Installation

RUN apt-get update && \ 
    apt install -y ros-melodic-moveit
 
RUN mkdir -p ~/picking/src && \
    cd ~/picking/src && \
    git clone https://github.com/ssw0536/gqcnn.git  &&\
    cd gqcnn &&\
    git checkout f8e654246c9d05794ecfc6d646f2c74da7023f06 &&\
    pip install opencv-python==4.2.0.32 autolab-core==0.0.14 && \
    pip install autolab-perception==0.0.8 && \
    pip install imageio==2.6.1 && \
    pip install pyglet==1.4.10 && \
    pip install visualization==0.1.1 && \
    pip install psutil==5.4.2 && \
    pip install gputil==1.4.0 && \
    pip install scikit-video==1.1.11 && \
    pip install . && \
    ~/picking/src/gqcnn/scripts/downloads/models/download_models.sh 
# RUN source /opt/ros/melodic/setup.bash && \
#     cd ~/picking/ && catkin_make && \
#     cd .. && source devel/setup.bash 

### Install openssh 
RUN apt-get update && apt-get install -y vim nano net-tools openssh-server
