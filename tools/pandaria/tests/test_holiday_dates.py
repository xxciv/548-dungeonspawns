import datetime as dt
import os
import struct
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import holiday_dates as hd  # noqa: E402

# Stage-1 lengths (hours) for the synthetic Holidays.dbc; Brewfest and the Darkmoon Faire start at stage 2.
DURATIONS = {141: [404], 181: [168], 201: [168], 321: [168], 324: [337], 327: [336], 341: [336],
             372: [24, 384], 398: [24], 404: [167], 409: [48], 423: [336], 479: [72, 168]}


def write_dbc():
    recs = []
    for hid, durations in DURATIONS.items():
        values = [0] * hd.DBC_FIELDS
        values[0] = hid
        values[1:1 + len(durations)] = durations
        values[hd.DATE_FIELD] = hd.pack_time(dt.datetime(2013, 1, 1))   # stale client date
        recs.append(struct.pack(f"<{hd.DBC_FIELDS}I", *values))
    path = os.path.join(tempfile.mkdtemp(), "Holidays.dbc")
    with open(path, "wb") as fh:
        fh.write(struct.pack("<4s4I", b"WDBC", len(recs), hd.DBC_FIELDS, hd.DBC_FIELDS * 4, 1) + b"".join(recs) + b"\0")
    return path


def server_start(entry, stage, now):
    """Python copy of GameEventMgr::SetHolidayEventTime (start date only)."""
    dates, durations = entry["dates"], entry["durations"]
    length = dt.timedelta(hours=durations[stage - 1])
    offset = dt.timedelta(hours=hd.stage_offset_hours(durations, stage))
    single = ((dates[0] >> 24) & 0x1F) == hd.ANY_YEAR
    for value in dates:
        if not value:
            break
        year, month, day, hour, minute = hd.unpack_time(value)
        start = dt.datetime(now.year - 1 if single else year, month, day, hour, minute)
        if now < start + length:
            return start + offset
        if single:
            return dt.datetime(now.year, month, day, hour, minute) + offset
    return None


class HolidayDatesTest(unittest.TestCase):
    def schedule(self, now):
        dbc = hd.read_holidays_dbc(write_dbc())
        rows, _ = hd.build_rows(dbc, now.date())
        for hid, index, value in rows:
            dbc[hid]["dates"][index] = value
        return {hid: server_start(dbc[hid], hd.HOLIDAYS[hid][3], now) for hid in hd.HOLIDAYS}

    def test_schedule_late_september_2026(self):
        s = self.schedule(dt.datetime(2026, 9, 27, 12, 0))
        self.assertEqual(s[372], dt.datetime(2026, 9, 20, 9, 0))    # Brewfest running
        self.assertEqual(s[324], dt.datetime(2026, 10, 18, 9, 0))   # Hallow's End not early
        self.assertEqual(s[479], dt.datetime(2026, 10, 4, 0, 1))    # first Sunday of October
        self.assertEqual(s[404], dt.datetime(2026, 11, 23, 10, 0))  # Monday of Thanksgiving week
        self.assertEqual(s[141], dt.datetime(2026, 12, 16, 10, 0))
        self.assertEqual(s[327], dt.datetime(2027, 1, 30, 10, 0))   # Lunar New Year 2027-02-06 minus 7
        self.assertEqual(s[181], dt.datetime(2027, 3, 29, 9, 0))    # Easter Monday 2027

    def test_winter_veil_across_new_year(self):
        s = self.schedule(dt.datetime(2027, 1, 1, 12, 0))
        self.assertEqual(s[141], dt.datetime(2026, 12, 16, 10, 0))  # still the running 2026 event

    def test_known_dates(self):
        self.assertEqual(hd.easter(2026), dt.date(2026, 4, 5))
        self.assertEqual(hd.easter(2027), dt.date(2027, 3, 28))
        v = hd.pack_time(dt.datetime(2019, 11, 25, 0, 0))
        self.assertEqual(v & ~(7 << 11), 329646080 & ~(7 << 11))    # matches the shipped row

    def test_rejects_wrong_file(self):
        path = os.path.join(tempfile.mkdtemp(), "x.dbc")
        with open(path, "wb") as fh:
            fh.write(b"abc")
        with self.assertRaises(SystemExit):
            hd.read_holidays_dbc(path)


if __name__ == "__main__":
    unittest.main()
