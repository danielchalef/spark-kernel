#
# Copyright 2014 IBM Corp.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

# If host is running squid-deb-proxy on port 8000, populate /etc/apt/apt.conf.d/30proxy
# By default, squid-deb-proxy 403s unknown sources, so apt shouldn't proxy ppa.launchpad.net
RUN route -n | awk '/^0.0.0.0/ {print $2}' > /tmp/host_ip.txt
RUN echo "HEAD /" | nc `cat /tmp/host_ip.txt` 8000 | grep squid-deb-proxy \
  && (echo "Acquire::http::Proxy \"http://$(cat /tmp/host_ip.txt):8000\";" > /etc/apt/apt.conf.d/30proxy) \
  && (echo "Acquire::http::Proxy::ppa.launchpad.net DIRECT;" >> /etc/apt/apt.conf.d/30proxy) \
  || echo "No squid-deb-proxy detected on docker host"

ENV CUDA_DEB http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-repo-ubuntu1404_7.0-28_amd64.deb

#   Setup
RUN apt-get update && apt-get install -q -y \
  wget \
  build-essential 

RUN cd /tmp && wget $CUDA_DEB && \
  dpkg -i cuda-repo-ubuntu1404_7.0-28_amd64.deb

RUN gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E56151BF
RUN echo deb http://repos.mesosphere.io/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) main >> /etc/apt/sources.list.d/mesosphere.list

RUN apt-get update
RUN apt-get --no-install-recommends -y --force-yes install openjdk-7-jre \
							mesos=0.20.1-1.0.ubuntu1404 \
							linux-image-extra-virtual \
							libzmq-dev \
							maven \
							python3 \
							python3-pip \
							python3-dev \
							cuda
# Install and setup ipython3
RUN pip3 install ipython[notebook]==3.0.0
RUN mkdir -p /root/.ipython/kernels/spark
COPY ./images-files/kernel-json /root/.ipython/kernels/spark/kernel.json
COPY ./images-files/ipython_notebook_config.py /root/.ipython/profile_default/

# Retrieve ND4J and DL4J
RUN mkdir /root/dl4j && cd /root/dl4j && \
	wget http://search.maven.org/remotecontent?filepath=org/deeplearning4j/deeplearning4j-nlp/0.0.3.3/deeplearning4j-nlp-0.0.3.3.jar && \
	wget http://search.maven.org/remotecontent?filepath=org/nd4j/nd4j-jcublas-7.0/0.0.3.5.5.3/nd4j-jcublas-7.0-0.0.3.5.5.3.jar

ENV MESOS_NATIVE_LIBRARY /usr/local/lib/libmesos.so
ENV LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-7.0/lib64
ENV JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre/
ENV PATH=$PATH:/usr/local/cuda-7.0/bin
ENV LOG_LEVEL=INFO
ENV JVM_OPT="-XX:PermSize=256m -Dlog4j.logLevel=${LOG_LEVEL} ${JVM_OPT}"

#   Install the pack elements
ADD kernel/target/pack /app
RUN chmod +x /app/bin/sparkkernel

#   Setup the binary we will run
CMD /usr/local/bin/ipython3 notebook
