---
title: 在 GCP 上部署 Nextcloud 相关折腾
date: 2019-06-08T15:53:00+08:00
categories: ForFun
tags: [SSL,openSUSE,Mailgun,GCP,LNMP,IPv6,Nextcloud]
description: 上个月折腾上了 Google Cloud Platform 的车，记录在其上部署 Nextcloud 相关的经历
---
上个月折腾上了 Google Cloud Platform 的车，记录在其上部署 Nextcloud 相关的经历，由于成文在搭建之后回忆写出，难免有步骤缺失/错误，欢迎指正。

主要内容：在 GCP 上创建 openSUSE 实例、LNMP+Nextcloud+SSL (certbot) 、Mailgun 的一个应用场景、GCP IPV6

<!--more-->

# Install openSUSE on GCP
如果在 GCP 上建过 VM 实例，有看一看提供的镜像，就会发现并没有 openSUSE ，去 GCP <a herf="https://cloud.google.com/" target="_blank">官网</a>搜索一下就会找到<a herf="https://cloud.google.com/compute/docs/images#community_supported_images" target="_blank">这个</a> Images 页面，对应的 Community supported images 部分就有我大蜥蜴，貌似只提供了提供 gcloud 命令行工具安装的操作。

安装 gcloud 详见<a herf="https://cloud.google.com/sdk/docs/quickstart-linux" target="_blank">官方文档</a>

选择创建 openSUSE 实例
```
# 获取镜像列表，通常没有最新的，不过我大蜥蜴跨版本升级都不是事儿！
gcloud compute images list --project opensuse-cloud --no-standard-images
# 比如当前我得到如下结果
NAME                          PROJECT         FAMILY         DEPRECATED  STATUS
opensuse-leap-15-v20181106    opensuse-cloud  opensuse-leap              READY
opensuse-leap-42-3-v20180116  opensuse-cloud  opensuse-leap              READY

# 选择镜像创建，貌似没有提供选项选择镜像，默认会选新的，
# 以下 zone 可通过 gcloud compute zone list 获得
# 或者使用 http://www.gcping.com 测延迟选对应区域
gcloud compute instances create instance_name --image-family opensuse-leap --image-project opensuse-cloud --zone zone
```
没什么问题的话就会正常创建好，去网页 console 调整具体配置，添加 SSH 密钥等（当然你也可以提供刚才的创建命令指定，详情参见具体文档。

然后贴下我大蜥蜴 Leap 日常跨版本升级步骤：
1. 修改软件源为最新版本（如 Leap 15 -> Leap 15.1
```
sed -i 's/15.0/15.1/g' /etc/zypp/repos.d/*.repo
```
2. dist-upgrade
```
sudo zypper dup
```

# LNMP
> 为什么是LNMP？
> 主要是这个博客是用的 Nginx 以及当年没搞明白服务器配置，便上了不清真的面板，而现在这个被抛弃的面板，还顶着 php 5.4 ，还各种不好使了，像什么管理端口之类的东西完全没反应还让这 lj 服务器假死，还不如直接手动上 iptables ，反正都绕不过它。便决定什么时候得去掉这面板，自己动手，这个就当学习和练手了。（所以之后应该也会记录一下，看会不会翻车了。

以下操作主要参考女王几年前写的蜥蜴wiki <a herf="https://zh.opensuse.org/SDB:%E6%90%AD%E5%BB%BALNMP%E6%9C%8D%E5%8A%A1%E5%99%A8" target="_blank">SDB:搭建LNMP服务器</a>，以及自己踩的坑。

安装 Nginx，PHP-fpm，mariadb
```
sudo zypper in nginx php7-fpm
sudo zypper in mariadb mariadb-tools php7-mysql
```

利用自带脚本进行数据库安全配置，如设置管理员密码，和一些不安全设置的移除（一路`y`就行，具体执行操作可参考对应提示
```
mysql_secure_installation
```
> 如果也不会 LNMP 配置可参照上述 wiki 进行 `hello wrold` 级网站配置，先熟悉熟悉基本操作。主要是创建独立 vhosts 网站配置，解析 HTML，配合 php-fpm 解析 PHP 文件，基础 ssl 配置等等。

创建 nextcloud 网站 vhosts 配置文件（参考官方文档 <a herf="https://docs.nextcloud.com/server/16/admin_manual/installation/nginx.html" target="_blank">installation/nginx</a>
```
vim /etc/nginx/vhost.d/your.domain.conf
# 根据实际情况 copy 对应上述官方文档提供的配置文件
# 修改实际情况修改 server_name ssl_certificate ssl_certificate_key 等区域
# 根据配置注释进行一些可选修改
```

修改 php-fpm 配置文件（主配置文件 php-fpm.conf 使用默认设置即可，或者根据注释内容自行修改，www.conf 在默认配置的基础上配置用户用户组。
```
cp /etc/php7/fpm/php-fpm.conf.default /etc/php7/fpm/php-fpm.conf
cp /etc/php7/fpm/php-fpm.d/www.conf.default /etc/php7/fpm/php-fpm.d/www.conf
vim /etc/php7/fpm/php-fpm.d/www.conf
# 修改用户，用户组为 接下来要装的 nextcloud 文件的用户与用户组，保证具有访问权限
# 这里还没装可以预设一个，如 wwwrun www
# 大概在23行左右修改为
user = wwwrun
group = www
...
```

安装 Nextcloud 所需 php 模块（参考蜥蜴编译的版本 <a herf="https://build.opensuse.org/package/view_file/openSUSE:Factory/nextcloud/nextcloud.spec " target="_blank">spec文件</a>，<a herf="https://docs.nextcloud.com/server/16/admin_manual/installation/source_installation.html#prerequisites-for-manual-installation" target="_blank">官方文档</a>
```
sudo zypper in php7-curl php7-gd php7-mbstring php7 openssl php7-posix php7-zip php7-zlib php7-intl php7-bz2 php7-fileinfo php7-pear php7-openssl php7-opcache
# 还有一些可选，详见上官方文档
```

配置 LNMP 自启动
```
systemctl enable nginx
systemctl enable php-fpm
systemctl enable mysql
```

# SSL
> 早就有闻 letsencrypt ，采用对应 certbot 实现证书配置，配置自动 renew

> **使用 certbot 要求有正确配置域名解析！**

 一般域名提供商都会提供DNS解析？比如在配置这个nextcloud用的<a herf="https://www.freenom.com" target="_blank">freenom</a>免域名费 .ml 域名，就带了DNS解析，直接配置 A/AAAA 记录（IPV4/6）指向对应服务器地址即可。或者拿着域名去 <a herf="https://www.cloudflare.com" target="_blank">Cloudflare</a>，还随便上了 CDN 大船。(注意这里如果选择类似 CDN 的解析，由于其一般自带SSL证书，和普通 DNS 解析操作步骤有所不同。约定以下内容称**「普通解析」域名对应 IP 即为服务器 IP；「非普通解析」域名对应 IP 可为上层 CDN 提供的 IP**

安装 certbot 和 其 nginx 插件（如果非普通 DNS 解析还需安装对应插件 <a herf="https://certbot.eff.org/docs/packaging.html" target="_blank">参见这里</a> 名为 certbot-dns-xx 的包名
```
sudo zypper install certbot python3-certbot-nginx
# 比如 选择 cloudflare 还需安装 certbot-dns-cloudflare, 源里具体包名可先 zypper search 得到，如下 cloudflare 的
sudo zypper install python3-certbot-dns-cloudflare
```

创建证书 **「普通解析」**
```
sudo certbot --nginx
# 根据提示操作即可，可自动配置到网站配置文件
```

~~创建证书（非普通解析以 Cloudflare 为例）~~（其实还并不清楚具体区别，先用了上述方法再上的 Cloudflare

考虑到 certbot 创建的证书有效期不算久，不过 certbot 有 renew 的功能，加上我在具体操作时为了在 GCP 上实现 IPV6 访问，建立了负载均衡器，在**负载均衡器前端需要网站证书**（话说我现在上了 Cloudflare 日常访问证书已经变了，可负载均衡器貌似还在用之前默认配置的真正的证书正常运行），所以有了下面这个结合我之前弄的 Mailgun 实现的 **certbot 更新证书自动邮件通知**，并将证书作为附件发送。

## Mail notify after renewed certifacates

根据 certbot <a herf="https://certbot.eff.org/docs/" target="_blank">文档</a>中如下内容实现
> Hooks will only be run if a certificate is due for renewal
> When Certbot detects that a certificate is due for renewal, `--pre-hook` and `--post-hook` hooks run before and after each attempt to renew it. If you want your hook to run only after a successful renewal, use `--deploy-hook` in a command like this.
> You can also specify hooks by placing files in subdirectories of Certbot’s configuration directory. 

将如下脚本放置在 certbot 配置目录`/etc/letsencrypt/renewal-hooks/deploy`，每当部署 renew 证书之后便会运行该目录下脚本
```
#!/usr/bin/env bash
log_file=/var/log/letsencrypt/letsencrypt.log
cert_file=/tmp/certificates.tar.bz2

# tar certificates
tar -cjf $cert_file -C /etc/letsencrypt/live -h .

# send mail
curl -s --user 'api:YOUR-MAILGUN-KEY' \  # replace your maingun key
    https://api.mailgun.net/v3/YOUR-MAILGUN-DOMAIN/messages \ # need replace
    -F from='<YOU@YOUR_DOMAIN_NAME>' \ # need replace
    -F to='foo@example.com' \ # need replace
    -F subject='Certificates Renew Notification' \
    -F text='like subject says' \
    -F text='check the new certificates and change it on your gcp balance loader!' \
    -F attachment=@$log_file \
    -F attachment=@$cert_file

# delete certificates
[[ -f $cert_file ]] && rm -f $cert_file
```
上述脚本大致就是将当前 certbot 运行日志和所有证书文件通过 Mailgun 以邮件形式发送（已经将我的 api key 和邮箱都去掉了，上述注释 `replace` 所在行需要进行替换）。

部署上述脚本 `mail_notify.sh`，并添加 certbot 自动更新定时任务 **「普通解析」**
```
cp mail_notify.sh /etc/letsencrypt/renewal-hooks/deploy

# add to cron
sudo crontab -e
# enter follow https://certbot.eff.org/lets-encrypt/leap-nginx
0 0,12 * * * python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew
```
对应的 **「非普通解析」**，除在创建定时任务时运行命令不同外还需配置访问对应 DNS 的配置文件，以下以 Cloudflare 为例，具体得到配置文件 `cloudflare.ini` 请<a herf="https://certbot-dns-cloudflare.readthedocs.io/en/stable/index.html#module-certbot_dns_cloudflare" target="_blank">参见模块文档</a>，添加定时任务如下
```
sudo crontab -e
0 0,12 * * * python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew --dns-cloudflare --dns-cloud-flare-credentials /path/to/your/cloudflare.ini
```

---

> 由于说它证书时间不长还是有几个月的，上述脚本并没有经过实际验证，只是手动运行试过感觉良好，这不刚才为写这篇~~流水帐~~试了试，貌似它每次部署成功都会运行一次脚本，所以如果你有多个站点地址，更新成功多少次就会发多少次。。。好吧不管了，看最后一个邮件即可。（手动苦笑


# Nextcloud
> 由于源里面的 Nextcloud 绑定了 Apache 所以选择手动安装方式

以下部分<a herf="https://en.opensuse.org/SDB:Nextcloud" target="_blank">参考文档</a>

```
# sudo needed

mkdir /mnt/nextcloud_data
chmod -R 0770 /mnt/nextcloud_data
chown wwwrun /mnt/nextcloud_data

wget https://download.nextcloud.com/server/releases/latest-16.zip
wget https://download.nextcloud.com/server/releases/latest-16.zip.md5

# check md5sum
cat latest-16.zip.md5
md5sum latest-16.zip

rm latest-16.zip.md5
unzip latest-16.zip
rm latest-16.zip

cp -r nextcloud /srv/www/htdocs
chown -R wwwrun /srv/www/htdocs/nextcloud/
```
部署到对应目录之后，修改前文创建的网站配置文件 `/etc/nginx/vhost.d/your.domain.conf` 
将`root`之后路径修改为`/srv/www/htdocs/nextcloud/;`
```
    ...
    root /srv/www/htdocs/nextcloud/;
    ...
```
创建 nextcloud 数据库
```
# login
mysql -u root -p
# create database
create database nextcloud;
# create nextcloud user
create user nextclouduser@localhost identified by 'some-password-here';
# grant all privileges on nextcloud
grant all privileges on nextcloud.* to nextclouduser@localhost identified by 'some-password-here';
# exit
exit;
```

启动 LNMP 
```
systemctl start nginx
systemctl start php-fpm
systemctl start mysql
```
访问服务器地址进行 nextcloud 配置，填写用户名密码，数据库用户名密码，数据存放位置。

一切配置正常之后，删掉之前的安装文件
```
# after running check
rm -rf /mnt/nextcloud_data
```
## 玄学优化
感觉没啥好说的，参见 https://yourdomain.xx/settings/admin/overview 界面，根据提示文档安装模块调整参数进行优化即可。

# GCP IPV6
说了半天， ~~貌似并没有联系上题目的 GCP~~*联系上了，加了安装大蜥蜴的第一个环节：），* 来讲讲我在 **GCP 上利用负载均衡器实现 IPV6 访问** 走过的坑吧！

总所周知（并不），GCP 默认创建的 VM 实例默认只给了 IPV4 地址，这对于处在免费 IPV6 还算通畅的校园网环境下的我貌似就不怎么友好了，不过常见的服务应该都能通过 **「负载均衡」** 实现 IPV6 访问。（GCP 负载均衡规则按时收费，前 5 条负载平衡规则价格看地区，总的来说地区前 5 条一个价，其实主要负载均衡的收费是流量收费，按转发量收费，同样地区统一定价，详见 <a herf="https://cloud.google.com/compute/pricing#lb" target="_blank">文档</a> ）

以下以为一个网站负载均衡为例（HTTP+HTTPS）（以下内容参考自己的配置，**仅供参考**）
1. 首先得到你的 GCP 全局 IPV6 地址
    1. 在网页操控台的 「 VPC 网络」选项卡的「外部 IP 地址」子选项卡下选择「保留静态地址」，然后选择 全局 IPV6 即可。
2. 将你的「VM 实例 」添加到「实例组」
    1. 在网页操控台的 「Compute Engine」 选项卡的 「实例组」 子选项卡下选择 「创建实例组」，然后选择 「新建非托管式实例组」，取个名字，选择位置（一般选择实例所在区域）等（网络什么的默认就行）参数。
    2. 选择刚才的创建实例组，「修改组」，添加上你的 「VM 实例」。
3. 新建网站 HTTP 负载平衡器
    1. 在网页操控台的 「网络服务」 选项卡的「负载平衡」子选项卡下选择「创建负载平衡器」，选择 「HTTP(S) 负载平衡」
    2. 后端配置：
        1. 创建后端服务如 `cloud-check-80` ，协议选择 HTTP ，命名端口如 `http` ，超时默认 30 就行，后端类型选择 「实例组」，具体后端选择刚才创建实例组，填写端口号 80 ，其他可以默认，获按需修改。
        2. 然后是下面的 「运行状况检查」，新建一个如叫 `cloud-check-80` 的状况检查，填写名字，选择协议 TCP ，端口 80 无代理协议，后面默认即可。
    3. 主机和路径规则（参考下图，主机部分为你的网站域名
    ![20190608150616153_1716322239.png](/images/2019/06/33335814.png)
    4. 前端配置：
        1. 新建前端 IP 和端口，写个名字，协议 HTTP ，IP 版本选择 IPV6 ，地址选择之前创建的全局地址，端口 80 。
    5. 检查并最终确认（参考下图
    ![20190608151146809_819181156.png](/images/2019/06/2647942956.png)

4. 新建 HTTPS 负载平衡器
    1. 参考上述 HTTP 负载平衡器，将前后端以及运行状况检查的端口换成443，协议换成 HTTPS 即可。
    2. 其他不同地方主要是，HTTPS 负载平衡器前端需要提供网站证书，选择创建证书，并将自己证书 公钥、链、私钥上传创建即可。其他地方保持默认即可。（需要证书这也是前文我将 certbot renew 的证书通过邮件发送的原因）

---

当然由于前五条规则一个价格，你可以创建更多规则，如实现 SSH 的 IPV6 访问等，通过 「TCP 负载平衡」实现即可，由于 GCP 负载平衡的前端端口有限，可以指定顺眼的端口，只要转发到后端对应端口即可。

# Reference
> 感谢上述参考连接，及以下文章/档

* https://sellingfreesoftwareforaliving.blogspot.com/2018/05/opensuse-leap-423-on-google-cloud.html
* https://en.opensuse.org/SDB:Nextcloud
* https://docs.nextcloud.com/server/16/admin_manual/installation/nginx.html
* https://help.nextcloud.com/t/howto-change-move-data-directory-after-installation/17170
* https://www.scalingphpbook.com/blog/2014/02/14/best-zend-opcache-settings.html
* https://docs.nextcloud.com/server/16/admin_manual/installation/source_installation.html 
* https://certbot.eff.org/lets-encrypt/leap-nginx 
* https://certbot.eff.org/docs/using.html 
