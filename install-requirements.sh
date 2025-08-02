#!/bin/bash
#
# Requirements Installation Script for CAmkES VM
# This script installs all necessary dependencies, tools, and libraries
# required to build the CAmkES VM project using init-build.sh
#
# Usage: ./install-requirements.sh
#

set -eu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing CAmkES VM Build Requirements${NC}"
echo "========================================"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Cannot detect OS. This script supports Ubuntu/Debian and similar distributions.${NC}"
    exit 1
fi

# Update package manager
echo -e "${YELLOW}Updating package manager...${NC}"
case $OS in
    ubuntu|debian)
        sudo apt-get update
        ;;
    fedora|centos|rhel)
        sudo dnf update -y || sudo yum update -y
        ;;
    arch|manjaro)
        sudo pacman -Sy
        ;;
    *)
        echo -e "${YELLOW}Unsupported OS: $OS. Please install packages manually.${NC}"
        ;;
esac

# Essential build tools
echo -e "${YELLOW}Installing essential build tools...${NC}"
case $OS in
    ubuntu|debian)
        sudo apt-get install -y \
            build-essential \
            gcc \
            g++ \
            cmake \
            ninja-build \
            git \
            curl \
            wget \
            pkg-config \
            autotools-dev \
            autoconf \
            automake \
            libtool
        ;;
    fedora|centos|rhel)
        sudo dnf install -y \
            gcc \
            gcc-c++ \
            cmake \
            ninja-build \
            git \
            curl \
            wget \
            pkgconfig \
            autoconf \
            automake \
            libtool \
            make || \
        sudo yum install -y \
            gcc \
            gcc-c++ \
            cmake \
            ninja-build \
            git \            curl \
            wget \
            pkgconfig \
            autoconf \
            automake \
            libtool \
            make
        ;;
    arch|manjaro)
        sudo pacman -S --needed \
            base-devel \
            gcc \
            cmake \
            ninja \
            git \
            curl \
            wget \
            pkgconf \
            autoconf \
            automake \
            libtool
        ;;
esac

# Cross-compilation toolchains
echo -e "${YELLOW}Installing cross-compilation toolchains...${NC}"
case $OS in
    ubuntu|debian)
        sudo apt-get install -y \
            gcc-arm-linux-gnueabi \
            gcc-arm-linux-gnueabihf \
            gcc-aarch64-linux-gnu \
            gcc-riscv64-linux-gnu \
            gcc-multilib \
            g++-multilib
        ;;
    fedora|centos|rhel)
        sudo dnf install -y \
            gcc-arm-linux-gnu \
            gcc-aarch64-linux-gnu \
            glibc-devel.i686 \
            libgcc.i686 || \
        sudo yum install -y \
            gcc-arm-linux-gnu \
            gcc-aarch64-linux-gnu \
            glibc-devel.i686 \
            libgcc.i686
        ;;
    arch|manjaro)
        sudo pacman -S --needed \
            arm-linux-gnueabihf-gcc \
            aarch64-linux-gnu-gcc
        ;;
esac

# Python 3 and pip
echo -e "${YELLOW}Installing Python 3 and pip...${NC}"
case $OS in
    ubuntu|debian)
        sudo apt-get install -y \
            python3 \
            python3-pip \
            python3-dev \
            python3-venv \
            python3-setuptools \
            python3-wheel
        ;;
    fedora|centos|rhel)
        sudo dnf install -y \
            python3 \
            python3-pip \
            python3-devel \
            python3-setuptools \
            python3-wheel || \
        sudo yum install -y \
            python3 \
            python3-pip \
            python3-devel \
            python3-setuptools \
            python3-wheel
        ;;
    arch|manjaro)
        sudo pacman -S --needed \
            python \
            python-pip \
            python-setuptools \
            python-wheel
        ;;
esac

# Python dependencies from requirements.txt
echo -e "${YELLOW}Installing Python dependencies...${NC}"
if [ -f "projects/capdl/python-capdl-tool/requirements.txt" ]; then
    pip3 install --user -r projects/capdl/python-capdl-tool/requirements.txt
else
    # Install known Python dependencies
    pip3 install --user \
        aenum \
        ordered-set \
        pyelftools \
        six \
        sortedcontainers \
        concurrencytest \
        hypothesis \
        future
fi

# Additional development libraries
echo -e "${YELLOW}Installing additional development libraries...${NC}"
case $OS in
    ubuntu|debian)
        sudo apt-get install -y \
            libxml2-dev \
            libxslt1-dev \
            zlib1g-dev \
            libc6-dev \
            libncurses5-dev \
            libssl-dev \
            libffi-dev \
            device-tree-compiler \
            u-boot-tools \
            qemu-system-arm \
            qemu-system-x86 \
            ccache
        ;;
    fedora|centos|rhel)
        sudo dnf install -y \
            libxml2-devel \
            libxslt-devel \
            zlib-devel \
            glibc-devel \
            ncurses-devel \
            openssl-devel \
            libffi-devel \
            dtc \
            uboot-tools \
            qemu-system-arm \
            qemu-system-x86 \
            ccache || \
        sudo yum install -y \
            libxml2-devel \
            libxslt-devel \
            zlib-devel \
            glibc-devel \
            ncurses-devel \
            openssl-devel \
            libffi-devel \
            dtc \
            uboot-tools \
            qemu-system-arm \
            qemu-system-x86 \
            ccache
        ;;
    arch|manjaro)
        sudo pacman -S --needed \
            libxml2 \
            libxslt \
            zlib \
            glibc \
            ncurses \
            openssl \
            libffi \
            dtc \
            uboot-tools \
            qemu-arch-extra \
            ccache
        ;;
esac

# Verify git is available and configured
echo -e "${YELLOW}Verifying git installation...${NC}"
if ! command -v git &> /dev/null; then
    echo -e "${RED}Git is not installed or not in PATH${NC}"
    exit 1
fi

# Check git configuration
if [ -z "$(git config --global user.name 2>/dev/null)" ] || [ -z "$(git config --global user.email 2>/dev/null)" ]; then
    echo -e "${YELLOW}Git user not configured. Please run:${NC}"
    echo "  git config --global user.name 'Your Name'"
    echo "  git config --global user.email 'your.email@example.com'"
fi

# Verify ninja is available
echo -e "${YELLOW}Verifying ninja build system...${NC}"
if ! command -v ninja &> /dev/null; then
    echo -e "${RED}Ninja build system is not installed or not in PATH${NC}"
    exit 1
fi

# Verify cmake is available and check version
echo -e "${YELLOW}Verifying CMake installation...${NC}"
if ! command -v cmake &> /dev/null; then
    echo -e "${RED}CMake is not installed or not in PATH${NC}"
    exit 1
fi

CMAKE_VERSION=$(cmake --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
CMAKE_MAJOR=$(echo $CMAKE_VERSION | cut -d. -f1)
CMAKE_MINOR=$(echo $CMAKE_VERSION | cut -d. -f2)

if [ "$CMAKE_MAJOR" -lt 3 ] || ([ "$CMAKE_MAJOR" -eq 3 ] && [ "$CMAKE_MINOR" -lt 16 ]); then
    echo -e "${RED}CMake version $CMAKE_VERSION found, but version 3.16.0 or higher is required${NC}"
    exit 1
fi

# Check for cross-compilation toolchains
echo -e "${YELLOW}Verifying cross-compilation toolchains...${NC}"
TOOLCHAINS=(
    "arm-linux-gnueabi-gcc"
    "arm-linux-gnueabihf-gcc"
    "aarch64-linux-gnu-gcc"
)

for toolchain in "${TOOLCHAINS[@]}"; do
    if command -v "$toolchain" &> /dev/null; then
        echo -e "${GREEN}Found: $toolchain${NC}"
    else
        echo -e "${YELLOW}Optional toolchain not found: $toolchain${NC}"
    fi
done

# Initialize and update git submodules if .gitmodules exists
if [ -f ".gitmodules" ]; then
    echo -e "${YELLOW}Initializing and updating git submodules...${NC}"
    git submodule init
    git submodule update --recursive
fi

echo ""
echo -e "${GREEN}Requirements installation completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Create a build directory: mkdir build && cd build"
echo "2. Run the init script: ../init-build.sh -DCAMKES_VM_APP=vm_freertos -DPLATFORM=qemu-arm-virt -DSIMULATION=1"
echo "3. Build the project: ninja"
echo ""
echo "For more information, refer to: https://docs.sel4.systems/HostDependencies.html"