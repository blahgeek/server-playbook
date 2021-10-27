FROM instrumentisto/postfix:3

COPY postfix/main-custom.cf /etc/postfix/main.cf.d/custom.cf
COPY run.sh /bin/run.sh
RUN postalias /etc/postfix/aliases \
    && ln -s /etc/postfix/aliases /etc/aliases \
    && ln -s /etc/postfix/aliases.db /etc/aliases.db

CMD ["/bin/run.sh"]
