FROM debian:testing
MAINTAINER Alex Povel

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y \
	&& apt-get install -y \
		default-jre \
		texlive-full \
