#!/bin/bash
DOCKER_NVIDIA_DEVICES="--device /dev/nvidia0:/dev/nvidia0 --device /dev/nvidiactl:/dev/nvidiactl --device /dev/nvidia-uvm:/dev/nvidia-uvm"
docker run -ti -p 8888:8888 -e IP=0.0.0.0 --name ipython-scala-spark -v /home/daniel/analytics:/data $DOCKER_NVIDIA_DEVICES danielchalef/spark-kernel-cuda /bin/bash

