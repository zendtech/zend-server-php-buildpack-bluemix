# Overview #

nothing is a simple daemon that was written to deal with 2 problems we have when
running on CloudFoundry:

1. Bug in libdrizzle caused Zend Server daemons to not close MySQL connections
   when working against ClearDB. Since ClearDB limits number of simultaneous
   connections this led to a situation where connections were exhausted and
   ClearDB could not be accessed anymore.
2. When instance on CloudFoundry is taken down all it's processes are sent
   SIGTERM signal. There is no hook in CloudFoundry itself for instance going
   down. Additionally instances do not know anything about each other. Therefore
   when instance was going down it was not deregistered from Zend Server
   Cluster.

To fix both issues nothing daemon was written in C. To fix both problems it
connects to MySQL server and does 2 things:

1. Once per second it kills connections which are in 'Sleep' state and time more
   than 3 seconds. To prevent exhaust in number of queries per hour (ClearDB
   limits them too) on startup we create procedure that does this and later call
   it every second. Each call to procedure is counted as single query in MySQL.
2. On startup zend\_cf\_remove\_servers table is created. This table has only
   one column - ID. It is used to store IDs of nodes that must be removed from
   Zend Server Cluster. Later SIGTERM signal handler registered and all it does
   is just store current Zend Server node ID in that table and close
   connection. Additionally every second zend\_cf\_remove\_servers is checked
   and if new entry exists in it, ```zs-manage``` is called to remove cluster node.

# Compilation and installation #

To compile nothing you will need a maching running Ubunut 10.04 64-bit. Install
necessary packages on it:

```
aptitude update
aptitude install libmysqlclient-dev build-essential
```

After that copy all files in that directory to server. Enter the directory and
run in it:

```
make
```

This will compile nothing binary. After compiling it, copy it into your git repo
and commit changes.

# Running nothing and it's parameters #

nothing has following parameters:

```
./nothing <mysql-hostname> <mysql-port> <mysql-username> <mysql-password> <mysql-db-name> <server-id> <web-api-key-name> <web-api-key>
```

There are 3 options to run nothing:

1. Run it without parameters. In that case all it does almost nothing. It just
   sleeps and waits to be killed.
2. Supply only first 5 MySQL parameters. In this case nothing will only monitor
   stale MySQL connections and kill them. It won't add Zend Server node ID into
   zend\_cf\_remove\_servers on SIGTERM and won't monitor
   zend\_cf\_remove\_servers table.
3. Supply all the parameters. In this case it will monitor and kill stale
   connections and monitor zend\_cf\_remove\_servers table and insert it's own
   node ID in it on SIGTERM signal.
