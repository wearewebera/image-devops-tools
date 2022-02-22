FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
#ENV PYTHON_VERSION 3.10

COPY essentials.sh /root/essentials.sh
RUN chmod +x /root/essentials.sh
RUN /root/essentials.sh
