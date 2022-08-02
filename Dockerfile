FROM webera/base

ENV DEBIAN_FRONTEND noninteractive

COPY essentials.sh /root/essentials.sh
RUN chmod 755 /root/essentials.sh
RUN /root/essentials.sh
