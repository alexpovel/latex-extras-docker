FROM ubuntu:latest

RUN apt-get -y update
RUN apt-get -y install default-jre
RUN apt-get -y texlive-full
RUN apt-get clean
