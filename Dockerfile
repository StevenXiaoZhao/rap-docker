FROM centos:6.9

MAINTAINER feig "feig2009@gmail.com"

ENV RAP_VERSION 0.14.16

# 安装各种环境，否则后面的安装包和命令都找不到
RUN yum install -y initscripts && yum clean all && yum -y install wget &&\
    wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm &&\
    rpm -ivh epel-release-6-8.noarch.rpm

# 安装服务
RUN yum install -y mysql-server nginx tomcat unzip redis

# 在数据库中创建默认数据表和用户
RUN /etc/init.d/mysqld start &&\
    mysql -u root -e "create database rap_db default charset utf8 COLLATE utf8_general_ci;"

# 下载RAP
RUN wget http://rap.taobao.org/release/RAP-${RAP_VERSION}-SNAPSHOT.war
RUN rm -rf ROOT &&\
    unzip -x RAP-${RAP_VERSION}-SNAPSHOT.war -d ROOT &&\
    rm -rf RAP.war

#由于GitHub上面的sql语句本身有问题，这里我们自己修改后再复制进去
COPY database_initialize.sql ROOT/WEB-INF/classes/database/
RUN /etc/init.d/mysqld start &&\
    mysql -u root rap_db < ROOT/WEB-INF/classes/database/database_initialize.sql

# 更改服务配置
RUN cp -rf ROOT /var/lib/tomcat/webapps
RUN chown -R tomcat. /var/lib/tomcat/webapps/ROOT
COPY rap.conf /etc/nginx/conf.d/

ENTRYPOINT /etc/init.d/redis start && /etc/init.d/mysqld start && service tomcat start && tail -f /var/log/tomcat/catalina.out

