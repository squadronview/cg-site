FROM mhart/alpine-node:latest

WORKDIR /src
ADD package.json .

RUN apk add --no-cache --no-progress --update git g++ make python ca-certificates wget

ENV HUGO_VERSION 0.16
RUN wget https://github.com/spf13/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_linux-64bit.tgz
RUN tar xzf hugo_${HUGO_VERSION}_linux-64bit.tgz
RUN rm hugo_${HUGO_VERSION}_linux-64bit.tgz
RUN mv hugo /usr/bin/hugo

RUN npm install
