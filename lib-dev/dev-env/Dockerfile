FROM --platform=linux/amd64 golang:1.21.7-bullseye

# Replace shell with bash
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install dependencies
RUN apt-get update && apt-get -y install hwloc jq pkg-config bzr ocl-icd-opencl-dev

ENV NODE_VERSION 20

# Install nvm with node, npm and yarn
RUN curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash \
    && . ~/.nvm/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default \
    && npm i -g yarn

ENV NODE_PATH ~/.nvm/$NODE_VERSION/lib/node_modules
ENV PATH      ~/.nvm/$NODE_VERSION/bin:$PATH

# Install rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
RUN echo 'source $HOME/.cargo/env' >> $HOME/.bashrc

# Install foundry
RUN curl -L https://foundry.paradigm.xyz | bash && \
    . /root/.bashrc && \
    foundryup

ENV LOTUS_PATH=~/.lotus-local-net \
    LOTUS_MINER_PATH=~/.lotus-miner-local-net \
    LOTUS_FEVM_ENABLEETHRPC=true \
    LOTUS_SKIP_GENESIS_CHECK=_yes_ \
    CGO_CFLAGS_ALLOW="-D__BLST_PORTABLE__" \
    CGO_CFLAGS="-D__BLST_PORTABLE__" 

# Install lotus localnet
RUN git clone https://github.com/filecoin-project/lotus lotus-local-net

## Fix missing lib libhwloc.so.5
RUN ls -1 /usr/lib/*/libhwloc.so.* | head -n 1 | xargs -n1 -I {} ln -s {} /usr/lib/libhwloc.so

WORKDIR /go/lotus-local-net

RUN git checkout releases

RUN rm -rf ~/.genesis-sectors

RUN make 2k 

RUN ./lotus fetch-params 2048

RUN make lotus-shed

COPY ./*.sh /go/_scripts/

RUN chmod +x /go/_scripts/*.sh