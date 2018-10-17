-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Wed Oct 17 07:27:27 2018
-- 
;
--
-- Table: group
--
CREATE TABLE "group" (
  "id" serial NOT NULL,
  "name" character varying(50) NOT NULL,
  PRIMARY KEY ("id")
);

;
--
-- Table: user
--
CREATE TABLE "user" (
  "id" serial NOT NULL,
  "firstname" text,
  "surname" text,
  "email" character varying(128) NOT NULL,
  "username" character varying(128) NOT NULL,
  "password" character varying(128),
  "pwchanged" timestamp,
  "pw_reset_code" character(32),
  "lastlogin" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_idx_email" on "user" ("email");
CREATE INDEX "user_idx_username" on "user" ("username");

;
--
-- Table: host
--
CREATE TABLE "host" (
  "id" serial NOT NULL,
  "name" character varying(50) NOT NULL,
  "port" integer,
  "password" character varying(64),
  "group_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "host_idx_group_id" on "host" ("group_id");

;
--
-- Table: host_checker
--
CREATE TABLE "host_checker" (
  "id" serial NOT NULL,
  "name" character varying(50) NOT NULL,
  "host" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "host_checker_idx_host" on "host_checker" ("host");

;
--
-- Table: sshlogin
--
CREATE TABLE "sshlogin" (
  "id" serial NOT NULL,
  "host_id" integer NOT NULL,
  "username" character varying(50) NOT NULL,
  "source_ip" character varying(50) NOT NULL,
  "datetime" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "sshlogin_idx_host_id" on "sshlogin" ("host_id");

;
--
-- Table: statval
--
CREATE TABLE "statval" (
  "id" serial NOT NULL,
  "datetime" timestamp NOT NULL,
  "stattype" character varying(50) NOT NULL,
  "host" integer DEFAULT 0 NOT NULL,
  "plugin" character varying(50) NOT NULL,
  "decimal" numeric(10,3),
  "param" character varying(50),
  "failcount" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "statval_idx_host" on "statval" ("host");

;
--
-- Table: user_group
--
CREATE TABLE "user_group" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "group_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_group_idx_group_id" on "user_group" ("group_id");
CREATE INDEX "user_group_idx_user_id" on "user_group" ("user_id");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "host" ADD CONSTRAINT "host_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "group" ("id") DEFERRABLE;

;
ALTER TABLE "host_checker" ADD CONSTRAINT "host_checker_fk_host" FOREIGN KEY ("host")
  REFERENCES "host" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "sshlogin" ADD CONSTRAINT "sshlogin_fk_host_id" FOREIGN KEY ("host_id")
  REFERENCES "host" ("id") DEFERRABLE;

;
ALTER TABLE "statval" ADD CONSTRAINT "statval_fk_host" FOREIGN KEY ("host")
  REFERENCES "host" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_group" ADD CONSTRAINT "user_group_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "group" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_group" ADD CONSTRAINT "user_group_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") DEFERRABLE;

;
