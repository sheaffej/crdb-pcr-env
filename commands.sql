cockroach sql --url 'postgresql://root@localhost:26257/?options=-ccluster=system&sslmode=disable'


SET CLUSTER SETTING cluster.organization = '<organization>';
SET CLUSTER SETTING enterprise.license = '<license>';
CREATE USER standby;
GRANT ADMIN TO standby;


CREATE VIRTUAL CLUSTER application LIKE template
FROM REPLICATION OF application
ON 'postgresql://standby@crdb-primary:26257/?options=-ccluster=system&sslmode=disable';


SHOW VIRTUAL CLUSTER application WITH REPLICATION STATUS;

CREATE DATABASE testdb;
use testdb;
CREATE TABLE foo (id uuid primary key default gen_random_uuid(), value string);
INSERT INTO foo (value) VALUES
('aaaaa'),
('bbbbb'),
('ccccc'),
('ddddd'),
('eeeee')
;

ALTER VIRTUAL CLUSTER application COMPLETE REPLICATION TO LATEST;
ALTER VIRTUAL CLUSTER application START SERVICE SHARED;

