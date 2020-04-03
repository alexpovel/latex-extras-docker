FROM debian:bullseye
MAINTAINER Alex Povel

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y \
	&& apt-get install -y \
		default-jre \
		texlive-full \
		inkscape \
		gnuplot \
		curl \
		wget \
		pandoc \
		librsvg2-bin \
