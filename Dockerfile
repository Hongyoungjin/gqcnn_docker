# This Dockerfile is used to build an ROS + OpenGL + Gazebo + Tensorflow image based on Ubuntu 18.04
FROM nvidia/cudagl:10.0-devel-ubuntu18.04

ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

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
    python get-pip.py

# prepare default python 2.7 environment
USER root
#pip install --ignore-installed --upgrade https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.11.0-cp27-none-linux_x86_64.whl && \
RUN  pip install tensorflow-gpu==1.15.0 keras==2.3.1 matplotlib pandas scipy h5py testresources scikit-learn

# Expose Tensorboard
EXPOSE 6006

### GQ-CNN Installation

RUN apt-get update && \ 
    apt install -y ros-melodic-moveit
 
RUN mkdir -p ~/picking/src && \
    cd ~/picking/src && \
    git clone https://github.com/ssw0536/gqcnn.git  &&\
    git clone https://github.com/BerkeleyAutomation/perception.git && \
    pip install opencv-python==4.2.0.32 Autolab-core==0.0.14 && \
    cd ~/picking/src/perception && pip install -e .  && \
    pip install imageio==2.6.1 && \
    pip install pyglet==1.4.10 && \
    pip install visualization==0.1.1 && \
    pip install psutil==5.4.2 && \
    pip install gputil==1.4.0 && \
    pip install scikit-video==1.1.11 && \
    ~/picking/src/gqcnn/scripts/downloads/models/download_models.sh 
# RUN source /opt/ros/melodic/setup.bash && \
#     cd ~/picking/ && catkin_make && \
#     cd .. && source devel/setup.bash 
