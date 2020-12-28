-- SPDX-License-Identifier: GPL-3.0-or-later
--
-- Copyright (C) 2020 Daniel Vogelbacher
-- Written by: Daniel Vogelbacher <daniel@chaospixel.com>
--


-- Enable Foreign keys
PRAGMA foreign_keys = ON;

-- We need WAL mode
PRAGMA journal_mode=WAL;

-- Current schema version
PRAGMA user_version = 1;


-- ****************************************************************************
-- ************************************************************ profileconf ***
-- Profile configuration.
-- A trigger ensures that only one record can be inserted.
--
CREATE TABLE profileconf (
  rowid                       INTEGER       PRIMARY KEY NOT NULL,
  identity_id                 INTEGER       NOT NULL
);

CREATE TRIGGER profileconf_check
BEFORE INSERT ON profileconf
BEGIN
  SELECT CASE WHEN COUNT(*) > 0
    THEN RAISE(FAIL, 'only one profileconf record is allowed') END
  FROM profileconf;
END;


-- ****************************************************************************
-- *************************************************************** identity ***
-- We could not store the certificate here because on a sync,
-- we may sync contents from a friend that is not known yet, because
-- friends are not yet synced. The problem may arise when a user add a new
-- device and starts an initial sync.
--
CREATE TABLE identity (
  identity_id                    INTEGER       PRIMARY KEY NOT NULL,
  identity_fingerprint           TEXT          NOT NULL
);

CREATE UNIQUE INDEX identity_fingerprint_idx  ON identity(identity_fingerprint);




-- ****************************************************************************
-- ****************************************************************** owner ***
--
/*
CREATE TABLE owner (
  identity_id                    INTEGER       PRIMARY KEY NOT NULL,
  myself                      BOOLEAN       NOT NULL,
  friend_iref                 INTEGER
);

CREATE UNIQUE INDEX owner_friend_idx  ON owner(friend_iref);
*/



-- ****************************************************************************
-- ******************************************************************** inv ***
-- Master table for all inventory items.
-- These items are attached to identities.
--
CREATE TABLE inv (
  identity_id                 INTEGER       NOT NULL,
  inv_id                      INTEGER       PRIMARY KEY NOT NULL,
  inv_guid                    GUID          NOT NULL,
  inv_type                    TEXT          NOT NULL,
  inv_target                  GUID, -- attributes for other inventory records?
  inv_birth                   TIMESTAMP     NOT NULL,
  inv_updated                 TIMESTAMP,
  inv_deleted                 TIMESTAMP,
  rev_id                      INTEGER,      -- current revision revision!
  CONSTRAINT  inv_identity_fk
              FOREIGN KEY(identity_id) REFERENCES owner(identity_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX        inv_type_idx            ON inv(inv_type);
CREATE UNIQUE INDEX inv_guid_idx            ON inv(identity_id, inv_guid);
CREATE UNIQUE INDEX inv_rev_id_idx          ON inv(rev_id);


-- ****************************************************************************
-- ******************************************************************** rev ***
-- Revisions for each inventory item.
--
CREATE TABLE rev (
  inv_id                      INTEGER           NOT NULL,
  rev_id                      INTEGER           PRIMARY KEY NOT NULL,
  rev_guid                    GUID              NOT NULL,
  rev_parent_guid             GUID,
  rev_birth                   TIMESTAMP         NOT NULL,
  rev_code                    TIMESTAMP         NOT NULL, -- it's a revision code!
  rev_loaded                  BOOLEAN,
  rev_dead_marker             BOOLEAN,
  rev_encrypt_code            JSON,
  rev_raw_content             JSON,             -- stores raw representation of the revision
  rev_delta                   JSON,             -- ????
  CONSTRAINT  rev_inv_fk
              FOREIGN KEY(inv_id) REFERENCES inv(inv_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX rev_guid_idx            ON rev(inv_id, rev_guid);
CREATE UNIQUE INDEX rev_birth_idx           ON rev(rev_guid, rev_birth);


-- ****************************************************************************
-- ****************************************************************** stack ***
-- Each record is the current revision of a stack.
-- The record fields are populated by the revision raw data.
--
CREATE TABLE stack (
  inv_id                      INTEGER           NOT NULL,
  stack_id                    INTEGER           PRIMARY KEY NOT NULL,
  stack_alias                 TEXT,
  stack_title                 TEXT,
  stack_color                 INTEGER,
  stack_private               BOOLEAN,
  stack_checkable             BOOLEAN,
  stack_checkstate            BOOLEAN,
  CONSTRAINT stack_inv_fk
             FOREIGN KEY(inv_id) REFERENCES inv(inv_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX stack_inv_id_idx           ON stack(inv_id);



-- ****************************************************************************
-- ************************************************************** stackpart ***
-- Each record is the current revision of a stackpart.
-- The record fields are populated by the revision raw data.
--
-- The stack_content descriptor don't need a reference to a resource.
-- Instead, the resource descriptor contains a master_iref to a stack_content
-- inv item (here). This ensures that a resource item can only be bound
-- to exactly one stack.
--
-- The master_iref bounds the stack_content descriptor to a stack.
--
CREATE TABLE stackpart (
  inv_id                      INTEGER       NOT NULL,
  stackpart_id                INTEGER       PRIMARY KEY NOT NULL,
  stack_iref                  INTEGER       NOT NULL, -- = master_guid id
  -- The class specifies what this part contains:
  --   image, text, reminder, functions(geomap, summary, ...)
  -- Notice: There is no content_type field here because the real content-type
  -- is defined on the resource (if any). A resource record points via
  -- it's master reference to one specific stackpart. And it's possible
  -- that multiple resources with different content-types exists with the
  -- same master reference (by intention or sync issues).
  content_class               TEXT          NOT NULL,
  -- The driver is an instruction how to interpret the content.
  -- For a image-class, this may contain crop parameters or a preview area.
  -- For a reminder-class, this specify the date.
  -- Some classes may not need a driver, then the driver is an empty
  -- JSON object.
  -- A driver can only be replaced by whole new driver, it is not supported
  -- because the dependencies of the values inside a driver are unknown.
  content_driver              TEXT          NOT NULL,  /* JSON */
  -- Properties
  stackpart_alias        TEXT,
  stackpart_caption      TEXT,
  stackpart_color        INT,
  stackpart_pos          INT,
  CONSTRAINT      stackpart_inv_fk
                    FOREIGN KEY(inv_id) REFERENCES inv(inv_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT      stackpart_stack_fk
                    FOREIGN KEY(stack_iref) REFERENCES inv(inv_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX stackpart_inv_id_idx           ON stackpart(inv_id);

CREATE TRIGGER stackpart_json_check
BEFORE INSERT ON stackpart
BEGIN
  SELECT CASE WHEN NOT json_valid(new.content_driver)
    THEN RAISE(FAIL, 'invalid JSON data for content_driver') END;
  SELECT CASE WHEN json_extract(new.content_driver, '$.sm_version') IS NULL
    THEN RAISE(FAIL, 'JSON sm_version missing for content_driver') END;
END;



/*****************************************************************************/
/* Do not add anything other then information that can be extracted from
/* the binary data (size, checksum, ...)
/* The master_iref is resolved from the master_guid field from the revision
/* descriptor. This master_guid is announced with the revision sync.
/*
/* master_iref bounds the resource to exactly one other inv item
/* and is fixed. It can only be changed if the whole content is updated
/* with a new revision.
/********************************************************************** RES **/
CREATE TABLE resource (
  inv_id                      INTEGER       NOT NULL,
  resource_id                 INTEGER       PRIMARY KEY NOT NULL,
  master_iref                 INTEGER       NOT NULL, -- = master_guid mapping
  resource_bindata            BLOB          NOT NULL,
  resource_content_type       TEXT          NOT NULL,
  resource_size               INTEGER       NOT NULL,
  resource_checksum           TEXT          NOT NULL,
  CONSTRAINT resource_inv_fk
             FOREIGN KEY(inv_id) REFERENCES inv(inv_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT resource_stack_fk
             FOREIGN KEY(master_iref) REFERENCES inv(inv_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX resource_inv_id_idx           ON resource(inv_id);


/*****************************************************************************/
/********************************************************************** TAG **/
/*
 * Tags are attached to stacks, but to organize tags, metadata is required.
 * To get metadata for a tag, simply a lookup by tag-name is done.
 * So this table is not a requirement to attach a new tag to a stack.
 */
CREATE TABLE tag (
  inv_id                      INTEGER       NOT NULL,
  tag_id                      INTEGER       PRIMARY KEY NOT NULL,
  --stack_iref                  INTEGER       NOT NULL,
  tag_name                    TEXT          NOT NULL,
  synonyms                    JSON,
  CONSTRAINT tag_inv_fk
             FOREIGN KEY(inv_id) REFERENCES inv(inv_id) ON DELETE CASCADE ON UPDATE CASCADE
  --CONSTRAINT tag_stack_fk
  --           FOREIGN KEY(stack_iref) REFERENCES inv(inv_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX tag_inv_id_idx           ON tag(inv_id);



/*****************************************************************************/
/******************************************************************** BOARD **/
CREATE TABLE board (
  inv_id                      INTEGER       NOT NULL,
  board_id                    INTEGER       PRIMARY KEY NOT NULL,
  board_name                  TEXT,
  board_color                 INTEGER,
  board_private               BOOLEAN,
  CONSTRAINT board_inv_fk
             FOREIGN KEY(inv_id) REFERENCES inv(inv_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX board_inv_id_idx           ON board(inv_id);

/*****************************************************************************/
/*************************************************************** BOARDENTRY **/
CREATE TABLE boardentry (
  inv_id                      INTEGER       NOT NULL,
  boardentry_id               INTEGER       PRIMARY KEY NOT NULL,
  board_iref                  INTEGER       NOT NULL,
  stack_iref                  INTEGER       NOT NULL,
  CONSTRAINT boardentry_inv_fk
             FOREIGN KEY(inv_id) REFERENCES inv(inv_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT boardentry_board_fk
             FOREIGN KEY(board_iref) REFERENCES inv(inv_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT boardentry_stack_fk
             FOREIGN KEY(stack_iref) REFERENCES inv(inv_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX boardentry_inv_id_idx           ON boardentry(inv_id);




/*****************************************************************************/
/******************************************************************* friend **/
/*
 * Classification: sync sync-owner-only
 */

CREATE TABLE friend (
  inv_id                      INTEGER       NOT NULL,
  identity_id                 INTEGER       NOT NULL,
  friend_id                   INTEGER       PRIMARY KEY NOT NULL,
  friend_alias                TEXT          NOT NULL,
  friend_cert                 BLOB          NOT NULL,
  friend_trusted              BOOLEAN       NOT NULL,
  friend_status               TEXT          NOT NULL,
  CONSTRAINT friend_inv_fk
             FOREIGN KEY(inv_id) REFERENCES inv(inv_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT friend_identity_fk
             FOREIGN KEY(identity_id) REFERENCES identity(identity_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX friend_inv_id_idx                  ON friend(inv_id);
CREATE UNIQUE INDEX friend_identity_id_idx             ON friend(identity_id);



/*****************************************************************************/
/******************************************************************* DEVICE **/
/*
 * This table is not synced, it's just the local device state.
 */
CREATE TABLE device (
  --friend_iref                 INTEGER       NOT NULL, -- the device record is self-owned, but the device is linked to a friend
  identity_id                 INTEGER       NOT NULL,
  device_id                   INTEGER       PRIMARY KEY NOT NULL,
  device_fingerprint          TEXT          NOT NULL,
  device_alias                TEXT          NOT NULL,
  device_trusted              BOOLEAN,
  device_enabled              BOOLEAN,
  sync_epoch                  INTEGER,
  sync_seq_out                INTEGER,
  sync_seq_in                 INTEGER,
  sync_last_seen              TIMESTAMP,
  sync_first_seen             TIMESTAMP,
  CONSTRAINT device_identity_fk
             FOREIGN KEY(identity_id) REFERENCES identity(identity_id) ON DELETE CASCADE ON UPDATE CASCADE
  --CONSTRAINT device_friend_fk
  --           FOREIGN KEY(friend_iref) REFERENCES inv(inv_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX device_fingerprint_idx     ON device(device_fingerprint);




CREATE VIEW inv_stack
AS
  SELECT
    stack.*,
    inv.*,
    inv.inv_id AS stack_iref
  FROM inv INNER JOIN stack USING(rev_id);


CREATE VIEW inv_stackpart
AS
  SELECT
    stackpart.*,
    inv.*,
    inv.inv_id AS stackpart_iref
  FROM inv INNER JOIN stackpart USING(rev_id);


CREATE VIEW inv_tag
AS
  SELECT
    tag.*,
    inv.*,
    inv.inv_id AS tag_iref
  FROM inv INNER JOIN tag USING(rev_id);


CREATE VIEW inv_res
AS
  SELECT
    res.*,
    inv.*,
    inv.inv_id AS resource_iref
  FROM inv INNER JOIN res USING(rev_id);


CREATE VIEW inv_board
AS
  SELECT
    board.*,
    inv.*,
    inv.inv_id AS board_iref
  FROM inv INNER JOIN board USING(rev_id);


CREATE VIEW inv_boardentry
AS
  SELECT
    boardentry.*,
    inv.*,
    inv.inv_id AS boardentry_iref
  FROM inv INNER JOIN boardentry USING(rev_id);

CREATE VIEW inv_friend
AS
  SELECT
    friend.*,
    inv.*,
    inv.inv_id AS friend_iref
  FROM inv INNER JOIN friend USING(rev_id);



INSERT INTO identity(identity_id, identity_fingerprint) VALUES(1, 'SHA256-FINGERPRINT-MY-CERT');

INSERT INTO profileconf(rowid, identity_id) VALUES(1, 1);
