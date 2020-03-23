---
title: install PostgreSQL on openSUSE
date: 2019-05-10T01:03:00+08:00
categories: ForFun
tags: [openSUSE, PostgreSQL]
description: RT
---
Install *PostgreSQL* on openSUSE and use *pgAdmin4* connect it.

Test on current *openSUSE Tumbleweed 20190507*


<!--more-->


# install PostgreSQL

## TL;DR

<a href="https://en.opensuse.org/SDB:PostgreSQL" target="_blank">see wiki</a>
~~RTFM~~

## self TL version
> just write my operation for example

> lines begin '#' are human read comment **Do Not Just Copy Past All Line**

```bash
# install postgresql from factory repo (oss)
sudo zypper in postgresql postgresql-server postgresql-contrib

# enable postgresql service start at boot
systemctl enable postgresql
# start postgresql service
systemctl start postgresql
```

```
# create database, user & grant super user ..
su
su postgres # switch to user 'postgres'
psql # run postgresql interactive terminal

CREATE DATABASE <database>;
CREATE USER <username> WITH ENCRYPTED PASSWORD '<passwd>';
ALTER USER <username> WITH SUPERUSER;
ALTER DATABASE <database> OWNER TO <username>;

# change default admin user 'postgres' password to login from 'pgadmin4' below
\password

# exit interactive terminal
\q

# more psql info plz check its usage (in psql interactive terminal run '\?' to get help
```

edit config file to use password connect to postgresql
use your favorite editor change `/var/ib/pgsql/data/pg_hba.conf` (*sudo needed*

---
**change**
```
# IPv4 local connections:
host    all             all             127.0.0.1/32            ident
# IPv6 local connections:
host    all             all             ::1/128                 ident
```
**to**
```

# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
```
---
```
# restart postgresql to apply change
systemctl restart postgresql
```
```
# install pgadmin for more friendly ui
sudo zypper in --no-recommends pgadmin4
# run it through application 'pgAdmin4' shortcut or just run 'pgAdmin4' from terminal
```

# connect use pgadmin4

* create a server to connect
![20190510004440083_1562003910.png](/images/2019/05/3646942119.png)

* fill in name what you like
![20190510004640937_1339893440.png](/images/2019/05/3093534281.png)

* fill in host name and other according what you set (default postgre user example
![20190510004852543_83761894.png](/images/2019/05/2414132339.png)

# more? 

* more PostgreSQL usage please check <a href="https://www.postgresql.org/docs/" target="_blank">official doc</a>

* may useful <a href="https://pgtune.leopard.in.ua/" target="_blank">link</a> optimise PostgreSQL 

---
end!
