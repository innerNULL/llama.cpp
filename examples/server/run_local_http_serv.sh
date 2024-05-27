# file: run_local_http_serv.sh
# 
# Usage
# wget https://huggingface.co/TheBloke/Llama-2-7B-GGUF/resolve/main/llama-2-7b.Q2_K.gguf
#
# Use CUDA
# bash ./examples/server/run_local_http_serv.sh llama-2-7b.Q2_K.gguf
#
# CPU Only
# bash ./examples/server/run_local_http_serv.sh llama-2-7b.Q2_K.gguf '' OFF


#set -x


CURR_DIR=$(pwd)
WORKSPACE="${CURR_DIR}/_llamacpp_local_serv"
SRC_ROOT_DIR="${WORKSPACE}/llama.cpp"
BUILD_DIR="${SRC_DIR}/build"

SRC_URL="https://github.com/ggerganov/llama.cpp/archive/refs/tags/"
MAKE_CUDA_ARCHITECTURES="all-major"

DEFAULT_LLM_URL="https://huggingface.co/TheBloke/Llama-2-7B-GGUF/resolve/main/llama-2-7b.Q2_K.gguf"
DEFAULT_VERSION="b2941"
DEFAULT_LLAMA_CUDA="ON"
DEFAULT_NVCC_PATH="/usr/local/cuda/bin/nvcc"
DEFAULT_CMAKE_CUDA_ARCHITECTURE="52"

LLM_PATH=$1
VERSION=$2
LLAMA_CUDA=$3
CMAKE_CUDA_ARCHITECTURE=$4
NVCC_PATH=$5


function fetch_src() {
  mkdir -p ${SRC_ROOT_DIR} 
  cd ${SRC_ROOT_DIR}
  wget "${SRC_URL}/${VERSION}.tar.gz"
  tar -xvzf ./*.tar.gz
  rm ./*.tar.gz
  echo "${SRC_ROOT_DIR}/llama.cpp-${VERSION}"
}


function build() {
  local src_path=$1
  cd ${src_path}
  mkdir build
  cd build
  cmake ../ \
    -DLLAMA_CUDA=${LLAMA_CUDA} \
    -DCMAKE_CUDA_ARCHITECTURES=${CMAKE_CUDA_ARCHITECTURE} \
    -DCMAKE_CUDA_COMPILER=${NVCC_PATH} \
    -DLLAMA_BUILD_TESTS=OFF
  make -j8
  echo ""
}


function main() {
  echo "Starting llama.cpp simple HTTP server locally..."
  
  if [ -z ${LLM_PATH} ]
  then
    echo "'LLM_PATH' can not be empty, try get one with 'wget ${DEFAULT_LLM_URL}'"
    exit 1
  else
    echo "LLM_PATH=${LLM_PATH}"
  fi

  if [ -z "${VERSION}" ]
  then 
    VERSION=${DEFAULT_VERSION}
    echo "Defaultly have VERSION=${VERSION}"
  else
    echo "Will use llama.cpp version ${VERSION}"
  fi
  
  if [ -z ${LLAMA_CUDA} ]
  then
    LLAMA_CUDA=${DEFAULT_LLAMA_CUDA}
    echo "Defaultly have LLAMA_CUDA=${LLAMA_CUDA}"
  else
    echo "LLAMA_CUDA=${DEFAULT_LLAMA_CUDA}"
  fi

  if [ -z ${CMAKE_CUDA_ARCHITECTURE} ]
  then
    CMAKE_CUDA_ARCHITECTURE=${DEFAULT_CMAKE_CUDA_ARCHITECTURE}
    echo "Defaultly have CMAKE_CUDA_ARCHITECTURE=${CMAKE_CUDA_ARCHITECTURE}"
  else 
    echo "CMAKE_CUDA_ARCHITECTURE=${CMAKE_CUDA_ARCHITECTURE}"
  fi

  if [ -z ${NVCC_PATH} ]
  then
    NVCC_PATH=${DEFAULT_NVCC_PATH}
    echo "Defaultly have NVCC_PATH=${NVCC_PATH}"
  else
    echo "NVCC_PATH=${NVCC_PATH}"
  fi

  echo "Fetching src codes"
  local src_path=$(fetch_src | tail -n 1)
  echo "Src codes are located at '${src_path}'"

  echo "Building"
  build ${src_path}

  echo "Running server"
  cd ${CURR_DIR}
  set -x
  CUDA_VISIBLE_DEVICES=1 ${src_path}/build/bin/server -m ${LLM_PATH} -c 2048 --main-gpu 1 --n-gpu-layers 1
}


main
