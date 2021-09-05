DROP TABLE ztc_database;
CREATE TABLE ztc_database (
    version integer
);
INSERT INTO ztc_database VALUES (5);
SELECT * FROM ztc_database;

DROP TABLE ztc_network;
CREATE TABLE ztc_network (
    id text UNIQUE,
    creation_time timestamp,
    owner_id text,
    capabilities text,
    enable_broadcast BOOLEAN NOT NULL DEFAULT TRUE,
    last_modified timestamp,
    mtu text,
    multicast_limit text,
    name text,
    private BOOLEAN NOT NULL DEFAULT TRUE,
    remote_trace_level text,
    remote_trace_target text,
    revision integer,
    rules text,
    rules_source text,
    tags text,
    v4_assign_mode text,
    v6_assign_mode text,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    controller_id text
);
SELECT * FROM ztc_network;

DROP TABLE ztc_member;
CREATE TABLE ztc_member (
    id text,
    network_id text,
    active_bridge BOOLEAN NOT NULL DEFAULT FALSE,
    authorized BOOLEAN NOT NULL DEFAULT FALSE,
    capabilities text,
    identity text,
    last_authorized_time timestamp,    
    last_deauthorized_time timestamp,
    no_auto_assign_ips BOOLEAN NOT NULL DEFAULT FALSE,    
    remote_trace_level text,
    remote_trace_target text,
    revision integer,
    tags text,
    v_major text,
    v_minor text,
    v_rev text,
    v_proto text,
    creation_time timestamp,    
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    hidden BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE UNIQUE INDEX on ztc_member (network_id, id);
SELECT * FROM ztc_member;

DROP TABLE ztc_controller;
CREATE TABLE ztc_controller (
    id text UNIQUE,
    cluster_host text,
    last_alive timestamp,
    public_identity text,
    v_major text,
    v_minor text,
    v_rev text,
    v_proto text,
    v_build text,
    host_port text,
    use_redis text
);
SELECT * FROM ztc_controller;

DROP TABLE ztc_global_permissions;
CREATE TABLE ztc_global_permissions (
    user_id text,
    authorize boolean,
    del boolean,
    modify boolean,
    read boolean
);
SELECT * FROM ztc_global_permissions;

DROP TABLE ztc_network_assignment_pool;
CREATE TABLE ztc_network_assignment_pool (
    network_id text,
    ip_range_start inet,
    ip_range_end inet
);
SELECT * FROM ztc_network_assignment_pool;

DROP TABLE ztc_network_route;
CREATE TABLE ztc_network_route (
    network_id text,
    address inet,
    bits text,
    via inet
);
SELECT * FROM ztc_network_route;

DROP TABLE ztc_network_dns;
CREATE TABLE ztc_network_dns (
    network_id text,
    domain text,
    servers text
);
SELECT * FROM ztc_network_dns;


DROP TABLE ztc_member_ip_assignment;
CREATE TABLE ztc_member_ip_assignment (
    network_id text,
    member_id text,
    address inet
);
CREATE UNIQUE INDEX on ztc_member_ip_assignment (network_id, member_id, address);
SELECT * FROM ztc_member_ip_assignment;

DROP TABLE ztc_member_status;
CREATE TABLE ztc_member_status (
    network_id text,
    member_id text,
    address inet,
    last_updated text
);
CREATE UNIQUE INDEX on ztc_member_status (network_id, member_id);
SELECT * FROM ztc_member_status;
