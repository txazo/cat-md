# 分布式 - 中间价架构

> 副本（备份、主从）、分片

## MySQL

* 主从复制（主从同步）
* 读写分离：一主多从
* 主从切换：`Keepalived`、VIP
* 主备：一主一备
* 双主：双主
* 分库分表：水平切分、垂直切分
* 代理中间件：MyCat
* 分库分表框架：Sharding-JDBC

## Redis

* 主从复制（主从同步）
* 哨兵模式
* 集群模式（Redis Cluster）
* 客户端一致性hash
* 代理中间件：Codis
