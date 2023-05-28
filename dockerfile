FROM gcc as builder

RUN apt-get update && apt-get install -y git

RUN groupadd nobody && \
    useradd jsproxy -g nobody --create-home

USER jsproxy
WORKDIR /home/jsproxy

RUN cd $(mktemp -d) && \
    curl -k -O https://www.openssl.org/source/openssl-1.1.1b.tar.gz && \
    tar zxf openssl-* && \
    curl -k -O https://ftp.exim.org/pub/pcre/pcre-8.43.tar.gz && \
    tar zxf pcre-* && \
    curl -k -O https://objects.githubusercontent.com/github-production-release-asset-2e65be/2359378/7820a8bc-9fe6-445a-b1b6-c347324ea960?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20230528%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20230528T170752Z&X-Amz-Expires=300&X-Amz-Signature=60c046e8505c29d98d666a432a113bc64d0bdb1f3ef848ba6c4dcf81cc95df1e&X-Amz-SignedHeaders=host&actor_id=75114206&key_id=0&repo_id=2359378&response-content-disposition=attachment%3B%20filename%3Dzlib-1.2.13.tar.gz&response-content-type=application%2Foctet-stream && \
    tar zxf zlib-* && \
    curl -k -O https://openresty.org/download/openresty-1.15.8.1.tar.gz && \
    tar zxf openresty-* && \
    cd openresty-* && \
    export PATH=$PATH:/sbin && \
    ./configure \
        --with-openssl=../openssl-1.1.1b \
        --with-pcre=../pcre-8.43 \
        --with-zlib=../zlib-1.2.12 \
        --with-http_v2_module \
        --with-http_ssl_module \
        --with-pcre-jit \
        --prefix=$HOME/openresty && \
    make && \
    make install

RUN git clone --depth=1 https://github.com/EtherDream/jsproxy.git server && \
    cd server && \
    rm -rf www && \
    git clone -b gh-pages --depth=1 https://github.com/EtherDream/jsproxy.git www


FROM ubuntu as prod

RUN groupadd nobody && \
    useradd jsproxy -g nobody --create-home

USER jsproxy

COPY --from=builder /home/jsproxy /home/jsproxy

WORKDIR /home/jsproxy

EXPOSE 8443
EXPOSE 8080

CMD ./server/run.sh && while true; do sleep 1; done
