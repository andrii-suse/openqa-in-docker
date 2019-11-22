
ENV dbname openqa
ENV dbuser geekotest

# setup webserver and fake-auth
RUN curl -s https://raw.githubusercontent.com/os-autoinst/openQA/master/script/configure-web-proxy | bash -ex
RUN sed -i -e 's/#*.*method.*=.*$/method = Fake/' /etc/openqa/openqa.ini

RUN chown "$dbuser":users /etc/openqa/database.ini
RUN chown -R "$dbuser":users /usr/share/openqa
