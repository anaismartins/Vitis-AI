#!/usr/bin/env bash

# Define variables
VERSION="${VERSION:-$(cat dockerfiles/VERSION.txt)}"
XRT_URL="${XRT_URL:-https://www.xilinx.com/bin/public/openDownload?filename=xrt_202220.2.14.418_20.04-amd64-xrt.deb}"
XRM_URL="${XRM_URL:-https://www.xilinx.com/bin/public/openDownload?filename=xrm_202220.1.5.212_20.04-x86_64.deb}"
VAI_CONDA_CHANNEL="${VAI_CONDA_CHANNEL:-https://www.xilinx.com/bin/public/openDownload?filename=conda-channel-3.5.0.tar.gz}"

# Create Apptainer definition file
cat <<EOF > vitis-ai.def
BootStrap: docker
From: nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

%environment
    export DEBIAN_FRONTEND=noninteractive
    export TZ=Etc/UTC
    export PATH=/opt/conda/bin:\$PATH
    export LD_LIBRARY_PATH=/usr/local/cuda/lib64:\$LD_LIBRARY_PATH

%post
    export DEBIAN_FRONTEND=noninteractive
    export TZ=Etc/UTC

    apt-get update && apt-get install -y \
        wget \
        curl \
        git \
        python3 \
        python3-pip \
        libopencv-dev \
        tzdata \
        && rm -rf /var/lib/apt/lists/*

    # Set the timezone
    echo "Etc/UTC" > /etc/timezone
    ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime
    dpkg-reconfigure -f noninteractive tzdata

    # Install XRT and XRM
    wget -O /tmp/xrt.deb ${XRT_URL}
    wget -O /tmp/xrm.deb ${XRM_URL}
    dpkg -i /tmp/xrt.deb /tmp/xrm.deb

    # Install Conda
    wget -O /tmp/conda-channel.tar.gz ${VAI_CONDA_CHANNEL}
    tar -xzf /tmp/conda-channel.tar.gz -C /opt
    /opt/conda/bin/conda install -y \
        pytorch=1.8.0 \
        torchvision=0.9.0 \
        cudatoolkit=11.0

    # Cleanup
    rm /tmp/xrt.deb /tmp/xrm.deb /tmp/conda-channel.tar.gz

%runscript
    exec "\$@"
EOF

# Build the Apptainer container
apptainer build vitis-ai.sif vitis-ai.def

if [ $? -eq 0 ]; then
    echo "Apptainer container built successfully: vitis-ai.sif"
else
    echo "Failed to build Apptainer container"
    exit 1
fi
