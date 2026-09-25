"""End-to-end test against a real MySQL/MariaDB server.

Skipped unless SPAWNCOMPARE_TEST_MYSQL=1. Uses $MYSQL_HOST/$MYSQL_USER/$MYSQL_PWD
(defaults 127.0.0.1/root/empty) and creates the schemas sc_test_ref and sc_test_tgt.
The reference schema is shaped like the Cataclysm Preservation Project 4.3.4 world DB,
the target like SkyFire 5.4.8.
"""
import csv
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import spawncompare as sc  # noqa: E402

REF, TGT = "sc_test_ref", "sc_test_tgt"

REF_SCHEMA = """
CREATE TABLE creature (guid INT UNSIGNED PRIMARY KEY, id INT UNSIGNED, map SMALLINT UNSIGNED,
  zoneId SMALLINT UNSIGNED DEFAULT 0, areaId SMALLINT UNSIGNED DEFAULT 0, spawnMask TINYINT UNSIGNED DEFAULT 1,
  phaseUseFlags TINYINT UNSIGNED DEFAULT 0, phaseMask INT UNSIGNED DEFAULT 1, PhaseId INT UNSIGNED DEFAULT 0,
  PhaseGroup INT UNSIGNED DEFAULT 0, modelid INT UNSIGNED DEFAULT 0, equipment_id TINYINT DEFAULT 0, position_x FLOAT, position_y FLOAT,
  position_z FLOAT, orientation FLOAT, spawntimesecs INT UNSIGNED DEFAULT 120, wander_distance FLOAT DEFAULT 0,
  MovementType TINYINT UNSIGNED DEFAULT 0);
CREATE TABLE creature_addon (guid INT UNSIGNED PRIMARY KEY, waypointPathId INT UNSIGNED DEFAULT 0);
CREATE TABLE creature_template (entry INT UNSIGNED PRIMARY KEY, name CHAR(100));
CREATE TABLE gameobject (guid INT UNSIGNED PRIMARY KEY, id INT UNSIGNED, map SMALLINT UNSIGNED,
  zoneId SMALLINT UNSIGNED DEFAULT 0, spawnMask TINYINT UNSIGNED DEFAULT 1, PhaseId INT UNSIGNED DEFAULT 0,
  PhaseGroup INT UNSIGNED DEFAULT 0, position_x FLOAT, position_y FLOAT, position_z FLOAT, orientation FLOAT,
  rotation0 FLOAT DEFAULT 0, rotation1 FLOAT DEFAULT 0, rotation2 FLOAT DEFAULT 0, rotation3 FLOAT DEFAULT 0,
  spawntimesecs INT DEFAULT 0, animprogress TINYINT UNSIGNED DEFAULT 0, state TINYINT UNSIGNED DEFAULT 0);
CREATE TABLE gameobject_template (entry INT UNSIGNED PRIMARY KEY, name VARCHAR(100));
CREATE TABLE pool_members (type SMALLINT UNSIGNED, spawnId INT UNSIGNED, poolSpawnId INT UNSIGNED);
CREATE TABLE game_event_creature (eventEntry TINYINT, guid INT UNSIGNED);
CREATE TABLE instance_template (map SMALLINT UNSIGNED PRIMARY KEY);
"""

TGT_SCHEMA = """
CREATE TABLE creature (guid INT UNSIGNED PRIMARY KEY, id INT UNSIGNED, map SMALLINT UNSIGNED,
  spawnMask INT UNSIGNED DEFAULT 1, phaseId INT UNSIGNED DEFAULT 0, phaseGroup INT UNSIGNED DEFAULT 0,
  modelid INT UNSIGNED DEFAULT 0, equipment_id TINYINT DEFAULT 0, position_x FLOAT, position_y FLOAT,
  position_z FLOAT, orientation FLOAT, spawntimesecs INT UNSIGNED DEFAULT 120, spawndist FLOAT DEFAULT 5,
  currentwaypoint INT DEFAULT 0, MovementType TINYINT UNSIGNED DEFAULT 0);
CREATE TABLE creature_addon (guid INT UNSIGNED PRIMARY KEY, path_id INT UNSIGNED DEFAULT 0);
CREATE TABLE creature_template (entry INT UNSIGNED PRIMARY KEY, name CHAR(100));
CREATE TABLE gameobject (guid INT UNSIGNED PRIMARY KEY, id INT UNSIGNED, map SMALLINT UNSIGNED,
  spawnMask INT UNSIGNED DEFAULT 1, phaseId INT UNSIGNED DEFAULT 0, phaseGroup INT UNSIGNED DEFAULT 0,
  position_x FLOAT, position_y FLOAT, position_z FLOAT, orientation FLOAT, rotation0 FLOAT DEFAULT 0,
  rotation1 FLOAT DEFAULT 0, rotation2 FLOAT DEFAULT 0, rotation3 FLOAT DEFAULT 0, spawntimesecs INT DEFAULT 0,
  animprogress TINYINT UNSIGNED DEFAULT 0, state TINYINT UNSIGNED DEFAULT 0);
CREATE TABLE gameobject_template (entry INT UNSIGNED PRIMARY KEY, name VARCHAR(100));
CREATE TABLE pool_creature (guid INT UNSIGNED PRIMARY KEY, pool_entry INT UNSIGNED);
CREATE TABLE pool_gameobject (guid INT UNSIGNED PRIMARY KEY, pool_entry INT UNSIGNED);
CREATE TABLE game_event_creature (eventEntry TINYINT, guid INT UNSIGNED);
CREATE TABLE instance_template (map SMALLINT UNSIGNED PRIMARY KEY);
"""

REF_DATA = """
INSERT INTO creature_template VALUES (100,'Kobold Vermin'),(101,'Defias Thug'),(102,'Patroller'),(103,'Rare'),
  (104,'Only In Cata'),(105,'Stockade Guard'),(47162,'Glubtok');
INSERT INTO creature (guid,id,map,zoneId,spawnMask,position_x,position_y,position_z,orientation,wander_distance,MovementType) VALUES
  (1,100,0,12,1,100,100,50,0,5,1),      -- wanders; target idle -> not_wandering
  (2,100,0,12,1,120,100,50,0,0,0),      -- idle; target wanders -> should_not_wander
  (3,101,0,12,1,200,200,50,0,0,0),      -- matched fine, target has a stacked duplicate
  (4,102,0,12,1,300,300,50,0,0,2),      -- patrols; target idle -> missing_path
  (5,101,0,40,1,5000,5000,10,1.5,8,1),  -- missing in target (Westfall)
  (6,103,0,40,1,5100,5000,10,0,0,0),    -- missing but pooled -> not imported
  (7,104,0,40,1,5200,5000,10,0,0,0),    -- missing, no template in target -> not imported
  (8,105,34,0,1,10,10,-30,0,0,0),       -- Stockade, matched (teaches mask 1 -> 2)
  (9,47162,36,0,3,-190,-400,55,1,0,0),  -- Deadmines, missing (mask guessed 3 -> 6)
  (10,101,36,0,1,-100,-400,55,1,3,1),   -- Deadmines, missing
  (11,101,1,14,1,300,-4000,10,0,0,0),   -- Durotar, missing (MoP-changed zone)
  (12,101,389,0,1,0,0,-20,0,0,0),       -- Ragefire Chasm, missing (MoP-changed map)
  (13,101,0,40,1,5300,5000,10,0,0,0);   -- Westfall, missing, quest phase only (phaseMask set below)
UPDATE creature SET phaseMask = 65535 WHERE guid = 5;
UPDATE creature SET phaseMask = 4 WHERE guid = 13;
INSERT INTO creature_addon VALUES (4, 400);
INSERT INTO pool_members VALUES (0, 6, 1);
INSERT INTO instance_template VALUES (34),(36);
INSERT INTO gameobject_template VALUES (13965,'Factory Door'),(1731,'Copper Vein');
INSERT INTO gameobject (guid,id,map,zoneId,spawnMask,position_x,position_y,position_z,orientation,rotation2,rotation3,spawntimesecs,animprogress,state) VALUES
  (1,13965,36,0,3,-168,-580,19,3.1,0.99,0.03,7200,255,1),
  (2,1731,0,12,1,400,400,60,0,0,1,300,255,1);
"""

TGT_DATA = """
INSERT INTO creature_template VALUES (100,'Kobold Vermin'),(101,'Defias Thug'),(102,'Patroller'),(103,'Rare'),
  (105,'Stockade Guard'),(47162,'Glubtok'),(900,'Pet Tamer');
INSERT INTO creature (guid,id,map,spawnMask,position_x,position_y,position_z,orientation,spawndist,MovementType) VALUES
  (501,100,0,1,101,100,50,0,0,0),
  (502,100,0,1,120,101,50,0,6,1),
  (503,101,0,1,200,200,50,0,0,0),
  (504,101,0,1,200.3,200,50,0,0,0),
  (505,102,0,1,300,300,50,0,0,0),
  (506,105,34,2,10,10,-30,0,0,0),
  (507,900,0,1,150,150,50,0,0,0);
INSERT INTO instance_template VALUES (34),(36);
INSERT INTO gameobject_template VALUES (13965,'Factory Door'),(1731,'Copper Vein');
INSERT INTO gameobject (guid,id,map,position_x,position_y,position_z,orientation,rotation3,spawntimesecs,animprogress,state) VALUES
  (801,1731,0,400,400,60,0,1,300,255,1);
"""


def read_csv(path):
    with open(path, newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


@unittest.skipUnless(os.environ.get("SPAWNCOMPARE_TEST_MYSQL") == "1", "set SPAWNCOMPARE_TEST_MYSQL=1 to run")
class MySQLRoundTrip(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        import pymysql
        cls.conn_args = dict(host=os.environ.get("MYSQL_HOST", "127.0.0.1"), user=os.environ.get("MYSQL_USER", "root"),
                             password=os.environ.get("MYSQL_PWD", ""))
        cls.conn = pymysql.connect(**cls.conn_args, autocommit=True, client_flag=pymysql.constants.CLIENT.MULTI_STATEMENTS)
        with cls.conn.cursor() as cur:
            for schema, ddl, data in ((REF, REF_SCHEMA, REF_DATA), (TGT, TGT_SCHEMA, TGT_DATA)):
                cur.execute(f"DROP DATABASE IF EXISTS {schema}")
                cur.execute(f"CREATE DATABASE {schema}")
                cur.execute(f"USE {schema}")
                cls.execute_script(cur, ddl + data)

    @classmethod
    def tearDownClass(cls):
        with cls.conn.cursor() as cur:
            for schema in (REF, TGT):
                cur.execute(f"DROP DATABASE IF EXISTS {schema}")
        cls.conn.close()

    @staticmethod
    def execute_script(cur, script):
        cur.execute(script)
        while cur.nextset():
            pass

    def run_tool(self, out, *extra):
        os.environ.setdefault("MYSQL_PWD", self.conn_args["password"])
        sc.main(["--reference", REF, "--target", TGT, "--host", self.conn_args["host"], "--user",
                 self.conn_args["user"], "--maps", "all", "--out", out, *extra])

    def test_report_then_apply_sql(self):
        skip = tempfile.mkdtemp()
        self.run_tool(skip, "--skip-mop-changes")
        missing = read_csv(os.path.join(skip, "missing_creature.csv"))
        self.assertEqual(sorted(int(r["ref_guid"]) for r in missing), [5, 6, 7, 9, 10, 13])

        out = tempfile.mkdtemp()
        self.run_tool(out, "--emit-sql", "--exclude-maps", "389", "--exclude-zones", "14")

        missing = read_csv(os.path.join(out, "missing_creature.csv"))
        self.assertEqual(sorted(int(r["ref_guid"]) for r in missing), [5, 6, 7, 9, 10, 13])
        by_guid = {int(r["ref_guid"]): r for r in missing}
        self.assertEqual(by_guid[6]["pooled"], "1")
        self.assertEqual(by_guid[7]["target_has_template"], "0")
        self.assertEqual(by_guid[5]["zone"], "40")
        self.assertEqual(by_guid[13]["phaseMask"], "4")
        with open(os.path.join(out, "import_missing_creature.sql"), encoding="utf-8") as fh:
            self.assertIn("-- Skipped 1 spawns that only exist in quest phases", fh.read())

        diffs = {int(r["ref_guid"]): r["issues"] for r in read_csv(os.path.join(out, "diffs_creature.csv"))}
        self.assertEqual(diffs, {1: "not_wandering", 2: "should_not_wander", 4: "missing_path"})

        dups = read_csv(os.path.join(out, "duplicates_creature.csv"))
        self.assertEqual([(r["keep_guids"], r["extra_guids"]) for r in dups], [("503", "504")])

        extra = read_csv(os.path.join(out, "extra_creature.csv"))
        self.assertEqual(sorted(int(r["target_guid"]) for r in extra), [504, 507])
        # target has no zoneId column: zone comes from the nearest reference spawn
        self.assertEqual({r["target_guid"]: r["zone"] for r in extra}["507"], "12")

        self.assertEqual([int(r["ref_guid"]) for r in read_csv(os.path.join(out, "missing_gameobject.csv"))], [1])

        with self.conn.cursor() as cur:
            cur.execute(f"USE {TGT}")
            for name in ("import_missing_creature.sql", "import_missing_gameobject.sql", "fix_wander_creature.sql"):
                with open(os.path.join(out, name), encoding="utf-8") as fh:
                    self.execute_script(cur, fh.read())
            cur.execute("SELECT id, map, spawnMask, spawndist, MovementType FROM creature WHERE guid > 507 ORDER BY id")
            self.assertEqual([tuple(r) for r in cur.fetchall()],
                             [(101, 0, 1, 8.0, 1), (101, 36, 2, 3.0, 1), (47162, 36, 6, 0.0, 0)])
            cur.execute("SELECT guid, spawndist, MovementType FROM creature WHERE guid IN (501, 502) ORDER BY guid")
            self.assertEqual([tuple(r) for r in cur.fetchall()], [(501, 5.0, 1), (502, 0.0, 0)])
            cur.execute("SELECT id, spawnMask, rotation2, spawntimesecs FROM gameobject WHERE guid > 801")
            row = cur.fetchone()
            self.assertEqual((row[0], row[1], round(row[2], 2), row[3]), (13965, 6, 0.99, 7200))

        out2 = tempfile.mkdtemp()
        self.run_tool(out2, "--skip-mop-changes")
        remaining = sorted(int(r["ref_guid"]) for r in read_csv(os.path.join(out2, "missing_creature.csv")))
        self.assertEqual(remaining, [6, 7, 13])
        issues = [r["issues"] for r in read_csv(os.path.join(out2, "diffs_creature.csv"))]
        self.assertEqual(issues, ["missing_path"])


if __name__ == "__main__":
    unittest.main()
