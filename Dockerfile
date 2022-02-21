FROM ubuntu

COPY essentials.sh /root/essentials.sh
RUN chmod +x /root/essentials.sh
RUN /root/essentials.sh
