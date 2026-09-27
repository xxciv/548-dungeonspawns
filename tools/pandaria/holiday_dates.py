#!/usr/bin/env python3
"""Generate current `holiday_dates` rows for the pandaria_5.4.8 world database.

The shipped holiday_dates (and the client's Holidays.dbc) stop around 2019. Past the last
date the core keeps the old game_event start and repeats it every 360-362 days, so holidays
drift weeks early, show up twice in the calendar, and the Darkmoon Faire disappears.

This script writes SQL that replaces the dates of the holidays below:
  * fixed-date holidays get one "every year" date (year field 31), which never expires
  * Easter / Lunar New Year / Thanksgiving based holidays get the next 26 yearly dates
  * the Darkmoon Faire gets the first Sunday of each of the next 26 months (re-run within 2 years)

Holidays.dbc is needed for the stage lengths: an event that starts at a later holiday stage
(Brewfest and the Darkmoon Faire use stage 2) starts that many hours after the holiday date.

Usage:
  python3 holiday_dates.py ~/pandaria/server/data/dbc/Holidays.dbc > holiday_dates.sql
  mysql -u root -p world < holiday_dates.sql      # then restart worldserver
"""

import argparse
import datetime as dt
import struct
import sys

# holiday id -> (name, rule, (hour, minute), holidayStage of its game_event)
# Start times and stages match game_event in the pandaria world database.
HOLIDAYS = {
    141: ("Feast of Winter Veil", ("fixed", 12, 16), (10, 0), 1),
    181: ("Noblegarden", ("easter_monday",), (9, 0), 1),
    201: ("Children's Week", ("monday_on_or_before", 5, 2), (9, 0), 1),
    321: ("Harvest Festival", ("fixed", 9, 18), (9, 0), 1),
    324: ("Hallow's End", ("fixed", 10, 18), (9, 0), 1),
    327: ("Lunar Festival", ("lunar_new_year_minus", 7), (10, 0), 1),
    341: ("Midsummer Fire Festival", ("fixed", 6, 21), (9, 0), 1),
    372: ("Brewfest", ("fixed", 9, 20), (9, 0), 2),
    398: ("Pirates' Day", ("fixed", 9, 19), (9, 0), 1),
    404: ("Pilgrim's Bounty", ("thanksgiving_monday",), (10, 0), 1),
    409: ("Day of the Dead", ("fixed", 11, 1), (10, 0), 1),
    423: ("Love is in the Air", ("fixed", 2, 5), (10, 0), 1),
    479: ("Darkmoon Faire", ("first_sunday_monthly",), (0, 1), 2),
}

# Chinese New Year (Gregorian dates).
LUNAR_NEW_YEAR = {
    2024: (2, 10), 2025: (1, 29), 2026: (2, 17), 2027: (2, 6), 2028: (1, 26), 2029: (2, 13),
    2030: (2, 3), 2031: (1, 23), 2032: (2, 11), 2033: (1, 31), 2034: (2, 19), 2035: (2, 8),
    2036: (1, 28), 2037: (2, 15), 2038: (2, 4), 2039: (1, 24), 2040: (2, 12), 2041: (2, 1),
    2042: (1, 22), 2043: (2, 10), 2044: (1, 30), 2045: (2, 17), 2046: (2, 6), 2047: (1, 26),
    2048: (2, 14), 2049: (2, 2), 2050: (1, 23), 2051: (2, 11), 2052: (2, 1), 2053: (2, 19),
}

MAX_HOLIDAY_DATES = 26
ANY_YEAR = 31
DBC_FIELDS = 55        # Holidaysfmt in DBCfmt.h
DURATION_FIELD = 1     # Duration[10] at fields 1-10
DATE_FIELD = 11        # Date[26] at fields 11-36
LOOPING_FIELD = 38
FILTER_FIELD = 53


def pack_time(t, any_year=False):
    """WoW packed time: min | hour<<6 | weekday<<11 | (day-1)<<14 | (month-1)<<20 | (year-2000)<<24."""
    weekday = 7 if any_year else (t.isoweekday() % 7)   # 0 = Sunday; 7 = unspecified
    year = ANY_YEAR if any_year else t.year - 2000
    return t.minute | t.hour << 6 | weekday << 11 | (t.day - 1) << 14 | (t.month - 1) << 20 | year << 24


def unpack_time(v):
    year = (v >> 24) & 0x1F
    return (None if year == ANY_YEAR else 2000 + year, ((v >> 20) & 0xF) + 1, ((v >> 14) & 0x3F) + 1,
            (v >> 6) & 0x1F, v & 0x3F)


def easter(year):
    """Western Easter Sunday (anonymous Gregorian algorithm)."""
    a, b, c = year % 19, year // 100, year % 100
    d, e = divmod(b, 4)
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i, k = divmod(c, 4)
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) // 451
    month, day = divmod(h + l - 7 * m + 114, 31)
    return dt.date(year, month, day + 1)


def event_start_dates(rule, first_year, first_month):
    kind = rule[0]
    if kind == "easter_monday":
        return [easter(y) + dt.timedelta(days=1) for y in range(first_year, first_year + MAX_HOLIDAY_DATES)]
    if kind == "monday_on_or_before":
        out = []
        for y in range(first_year, first_year + MAX_HOLIDAY_DATES):
            d = dt.date(y, rule[1], rule[2])
            out.append(d - dt.timedelta(days=d.weekday()))
        return out
    if kind == "thanksgiving_monday":   # US Thanksgiving is the 4th Thursday of November
        out = []
        for y in range(first_year, first_year + MAX_HOLIDAY_DATES):
            nov1 = dt.date(y, 11, 1)
            thursday = nov1 + dt.timedelta(days=(3 - nov1.weekday()) % 7 + 21)
            out.append(thursday - dt.timedelta(days=3))
        return out
    if kind == "lunar_new_year_minus":
        years = [y for y in range(first_year, first_year + MAX_HOLIDAY_DATES) if y in LUNAR_NEW_YEAR]
        return [dt.date(y, *LUNAR_NEW_YEAR[y]) - dt.timedelta(days=rule[1]) for y in years]
    if kind == "first_sunday_monthly":
        out, y, m = [], first_year, first_month
        while len(out) < MAX_HOLIDAY_DATES:
            d = dt.date(y, m, 1)
            out.append(d + dt.timedelta(days=(6 - d.weekday()) % 7))
            y, m = (y + 1, 1) if m == 12 else (y, m + 1)
        return out
    raise ValueError(kind)


def read_holidays_dbc(path):
    with open(path, "rb") as fh:
        data = fh.read()
    if len(data) < 20:
        raise SystemExit(f"error: {path} is not a DBC file")
    magic, records, fields, record_size, _strings = struct.unpack_from("<4s4I", data, 0)
    if magic != b"WDBC" or fields != DBC_FIELDS or record_size != DBC_FIELDS * 4:
        raise SystemExit(f"error: {path} is not a 5.4.8 Holidays.dbc "
                         f"(magic {magic!r}, {fields} fields, record size {record_size})")
    out = {}
    for r in range(records):
        values = struct.unpack_from(f"<{DBC_FIELDS}I", data, 20 + r * record_size)
        out[values[0]] = {
            "durations": list(values[DURATION_FIELD:DURATION_FIELD + 10]),
            "dates": list(values[DATE_FIELD:DATE_FIELD + MAX_HOLIDAY_DATES]),
            "looping": values[LOOPING_FIELD],
            "filter": struct.unpack("<i", struct.pack("<I", values[FILTER_FIELD]))[0],
        }
    return out


def stage_offset_hours(durations, stage):
    return sum(durations[:stage - 1])


def build_rows(dbc, today):
    rows, report = [], []
    for hid, (name, rule, (hour, minute), stage) in sorted(HOLIDAYS.items()):
        entry = dbc.get(hid)
        if entry is None:
            report.append(f"-- {hid} {name}: not in Holidays.dbc, skipped")
            continue
        offset = dt.timedelta(hours=stage_offset_hours(entry["durations"], stage))
        if rule[0] == "fixed":
            # Year is ignored for "every year" dates; use a non-leap year for the stage offset maths.
            start = dt.datetime(2027, rule[1], rule[2], hour, minute)
            rows.append((hid, 0, pack_time(start - offset, any_year=True)))
            report.append(f"-- {hid} {name}: every year {start:%b %d %H:%M}"
                          + (f" (stage {stage}, holiday date {offset} earlier)" if stage > 1 else ""))
            continue
        starts = event_start_dates(rule, today.year - 1, today.month)
        starts = [dt.datetime.combine(d, dt.time(hour, minute)) for d in starts][:MAX_HOLIDAY_DATES]
        for i, start in enumerate(starts):
            rows.append((hid, i, pack_time(start - offset)))
        upcoming = [s for s in starts if s.date() >= today][:3]
        report.append(f"-- {hid} {name}: {len(starts)} dates {starts[0]:%Y-%m-%d} .. {starts[-1]:%Y-%m-%d}; "
                      f"next {', '.join(f'{s:%Y-%m-%d}' for s in upcoming)}"
                      + (f" (stage {stage}, holiday date {offset} earlier)" if stage > 1 else ""))
    return rows, report


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("dbc", help="path to Holidays.dbc extracted from the 5.4.8 client")
    p.add_argument("--today", help="pretend today is YYYY-MM-DD (testing)")
    args = p.parse_args(argv)
    today = dt.date.fromisoformat(args.today) if args.today else dt.date.today()

    dbc = read_holidays_dbc(args.dbc)
    rows, report = build_rows(dbc, today)
    ids = sorted({r[0] for r in rows})

    print(f"-- holiday_dates generated {today} by tools/pandaria/holiday_dates.py")
    print("\n".join(report))
    print(f"DELETE FROM `holiday_dates` WHERE `id` IN ({', '.join(map(str, ids))});")
    print("INSERT INTO `holiday_dates` (`id`, `date_id`, `date_value`, `holiday_duration`) VALUES")
    print(",\n".join(f"({h}, {i}, {v}, 0)" for h, i, v in rows) + ";")


if __name__ == "__main__":
    sys.exit(main())
