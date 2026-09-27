# Building pandaria_5.4.8 on Debian 13

Core: <https://github.com/alexkulya/pandaria_5.4.8> (GPL-2.0, Mists of Pandaria 5.4.8 build 18414).

This guide builds the core, creates its databases and prepares client data on a fresh Debian 13
(trixie) VM. The project documents Ubuntu 20.04/22.04 with GCC 9–11 and MySQL 8.0. Debian 13 ships
GCC 14, CMake 3.31 and no MySQL 8.0, so a few steps differ from the upstream README. Every
difference below was reproduced with the same compiler (GCC 14.2), Boost (1.83) and CMake behaviour:
the patched source compiles, `authserver` starts and serves the realm list, and `worldserver`
connects to the three databases and runs until it needs the extracted client data.

## 0. VM sizing

| | Minimum | Comfortable |
|---|---|---|
| CPU | 4 cores | 8 cores |
| RAM | 8 GB | 16 GB |
| Disk | 60 GB | 100 GB (source + build + client copy + extracted data) |

The full compile took 61 minutes on 4 cores in testing (upstream estimates about 70 minutes with 8
threads on their setup). Generating movement maps (step 6) takes several hours.

## 1. Build tools and libraries

```sh
sudo apt update
sudo apt install -y git cmake make g++ unzip tmux gnupg wget \
  libssl-dev libbz2-dev libreadline-dev libncurses-dev zlib1g-dev \
  libboost-system-dev libboost-locale-dev libboost-filesystem-dev libboost-thread-dev \
  libboost-regex-dev libboost-serialization-dev libboost-date-time-dev
```

## 2. MySQL 8.4 LTS (not MariaDB)

The core must be built against **MySQL's** client library; MariaDB's headers break the build
(`my_bool` typedef clash in `src/server/shared/Database/MySQLCompat.h`). Debian 13 only packages
MariaDB, and Oracle publishes MySQL 8.4 LTS, not 8.0, for trixie. Install server and client from
Oracle's APT repository on this VM, and do not install any MariaDB packages alongside it.

1. Download the repository setup package (it needs `gnupg`, installed in step 1) (`mysql-apt-config_*_all.deb`, version 0.8.36 or newer; 0.8.40
   works) from <https://dev.mysql.com/downloads/repo/apt/>.
2. Install it and select **mysql-8.4-lts** when asked:
   ```sh
   sudo dpkg -i mysql-apt-config_*_all.deb
   sudo apt update
   sudo apt install -y mysql-server libmysqlclient-dev
   ```
3. Server settings matching the project's own Docker setup, plus a packet size large enough for
   the database dumps:
   ```sh
   sudo tee /etc/mysql/mysql.conf.d/pandaria.cnf <<'EOF'
   [mysqld]
   sql_mode             = NO_ENGINE_SUBSTITUTION
   max_allowed_packet   = 1G
   character-set-server = utf8mb4
   collation-server     = utf8mb4_unicode_ci
   EOF
   sudo systemctl restart mysql
   ```
4. A database user for the server. Oracle's installer asks for a MySQL root password; log in
   with it (`-p` prompts for it):
   ```sh
   mysql -u root -p -e "CREATE USER 'pandaria'@'localhost' IDENTIFIED BY 'choose-a-password';
     GRANT ALL PRIVILEGES ON auth.* TO 'pandaria'@'localhost';
     GRANT ALL PRIVILEGES ON characters.* TO 'pandaria'@'localhost';
     GRANT ALL PRIVILEGES ON world.* TO 'pandaria'@'localhost';"
   ```

The project lists MySQL 5.7/8.0 as supported. It doesn't use any client function that MySQL 8.4
removed (only `my_bool`, which its compatibility header already handles), but it hasn't been tested
against 8.4 here.

## 3. Source and fixes

```sh
mkdir -p ~/pandaria && cd ~/pandaria
git clone https://github.com/alexkulya/pandaria_5.4.8.git source
git clone https://github.com/xxciv/zrpandaria548.git tools-repo
cd source
git apply ../tools-repo/tools/pandaria/pandaria-fixes.patch
```

GCC 14 rejects a few things older compilers let through, and one extractor bug only shows on Linux.
The patch fixes exactly those, plus a shutdown crash, in six files:

| File | Fix |
|---|---|
| `src/server/shared/Define.h` | add `<climits>` for `PATH_MAX` |
| `src/server/shared/Utilities/Util.cpp` | add `<arpa/inet.h>` for `inet_addr` |
| `src/server/game/World/World.cpp` | initialise two `std::atomic` statics with braces (C++14 copy-init is ill-formed) |
| `src/server/scripts/Events/hallows_end.cpp` | brace the `Position` in two Hallow's End tables |
| `src/tools/map_extractor/System.cpp` | don't keep the `\` path separator in extracted `.dbc`/`.db2` names |
| `src/server/game/Scripting/ScriptMgr.cpp` | stop double-deleting unused scripts (segfault in `ScriptMgr::Unload()` on every shutdown) |

The Hallow's End fix is also a real bug fix: `Position` has a constructor, so without inner braces
each row's coordinates spilled into the following rows, and the fire event read wrong positions.
Older compilers only warned about it.

## 4. Configure and compile

CMake 3.28 and newer reject the `exec_program` calls in the project's MySQL detection. Passing an
empty `MYSQL_CONFIG` together with explicit paths skips that code without changing any source.

```sh
cd ~/pandaria/source && mkdir -p build && cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$HOME/pandaria/server \
  -DBUILD_DEPLOY=0 \
  -DSCRIPTS=1 -DTOOLS=1 -DNOJEM=1 -DUSE_COREPCH=1 -DUSE_SCRIPTPCH=1 \
  -DMYSQL_CONFIG= \
  -DMYSQL_INCLUDE_DIR=/usr/include/mysql \
  -DMYSQL_LIBRARY=/usr/lib/x86_64-linux-gnu/libmysqlclient.so
make -j"$(nproc)" install
```

`-DBUILD_DEPLOY=0` matters: the project turns that option on by default, which adds full debug
information (`-g3`) and `-march=native`. With it on, the build directory grows to about 14 GB and
the binaries only run on CPUs like the build machine's; the project's own Dockerfile turns it off too.

Run the compile inside `tmux` so it survives a dropped SSH session. If the machine runs out of
memory, use fewer jobs (`make -j2 install`). Afterwards `~/pandaria/server/bin` contains
`authserver`, `worldserver`, `mapextractor`, `vmap4extractor`, `vmap4assembler` and
`mmaps_generator`, and `~/pandaria/server/etc` the `.conf.dist` templates.

## 5. Databases

`tools/pandaria/install_databases.sh` imports the base dumps and applies about 110 update files in
the correct order. Don't skip them: the project's own Docker import only applies `sql/updates` and
misses the 2023–2026 world updates that were moved to `sql/old`, including
`2024_08_22_00_world_faction.sql`. Without it the current core refuses to start
(`Unknown column 'faction'` / `Cannot connect to world database`).

```sh
export MYSQL_PWD='your-mysql-root-password'   # sudo mysql users: see below
MYSQL_ARGS="-u root" ~/pandaria/tools-repo/tools/pandaria/install_databases.sh ~/pandaria/source
unset MYSQL_PWD
```

If you left the root password empty during installation, root logs in through `sudo mysql`
instead; then use `sudo mysql` in step 2.4 and run the installer as
`sudo MYSQL_ARGS="" ~/pandaria/tools-repo/tools/pandaria/install_databases.sh ~/pandaria/source`.

Expected result: about 314,700 creatures and 170,100 gameobjects, and one known failure,
`old/world/2026_08_06_21_world_repair_locale_encoding.sql` (French/Spanish/Portuguese text repairs;
English is unaffected). Anything else listed as failed needs a look.

## 6. Client data

The server needs `dbc`, `maps`, `vmaps` and `mmaps` extracted from a **5.4.8 (18414)** client.
Copy the client folder (the one with `Wow.exe` and `Data/`) to the VM, then:

```sh
cd ~/wow-548-client
~/pandaria/server/bin/mapextractor                 # dbc/ and maps/
~/pandaria/server/bin/vmap4extractor               # Buildings/
mkdir -p vmaps && ~/pandaria/server/bin/vmap4assembler Buildings vmaps
mkdir -p mmaps && ~/pandaria/server/bin/mmaps_generator --threads "$(nproc)"   # several hours
mkdir -p ~/pandaria/server/data
mv dbc maps vmaps mmaps ~/pandaria/server/data/
```

Without the extractor fix, every file in `dbc/` is named with a leading backslash
(`\AreaTable.dbc`) and `worldserver` stops with `ALL required *.dbc files (168) not found`. To
repair files extracted with an unpatched `mapextractor`, rename them in place (and in any locale
subfolder):

```sh
cd ~/pandaria/server/data/dbc
for f in \\*; do mv -- "$f" "${f#\\}"; done
```

The upstream README also links a prebuilt geodata archive on Google Drive; it was made from a
Russian client (`RU dbc`), so extracting from your own client is preferable.

## 7. Configuration

```sh
cd ~/pandaria/server/etc
cp authserver.conf.dist authserver.conf
cp worldserver.conf.dist worldserver.conf
mkdir -p ~/pandaria/server/logs
```

In **both** files, point the database lines at the `pandaria` user
(`"127.0.0.1;3306;pandaria;choose-a-password;auth"`, and likewise `world` and `characters` in
`worldserver.conf`) and set `LogsDir = "/home/<you>/pandaria/server/logs"`. In `worldserver.conf`
also set `DataDir = "/home/<you>/pandaria/server/data"`.

`SOAP.Enabled = 1` is the default but only listens on `127.0.0.1`; leave it or set it to 0.

## 8. Realm address and first account

The realm list ships with `127.0.0.1`. For clients on other machines, use the VM's LAN address:

```sh
mysql -u root -p -e "UPDATE auth.realmlist SET address = '192.168.x.x' WHERE id = 1;"
```

Start both servers (each in its own `tmux` window):

```sh
cd ~/pandaria/server/bin
./authserver
./worldserver
```

At the worldserver console:

```
account create myname mypassword
account set gmlevel myname 3 -1
```

Open TCP ports 3724 (auth) and 8085 (world) if the VM has a firewall.

If `worldserver` stops with `Correct *.map files not found`, `DataDir` doesn't point at the folder
from step 6 (it must contain `dbc`, `maps`, `vmaps` and `mmaps`).

## 9. Client

Set `realmlist.wtf` in the client's `Data/enUS` (or your locale) folder to
`set realmlist 192.168.x.x`. A 5.4.8 client needs a connection-patched `Wow.exe` to connect to a
private server; the upstream README links one ("Client exe files"). It's an executable from a file
share, so scan it before running it.

## 10. Holiday dates (calendar and world events)

The shipped `holiday_dates` stop around 2019 (the Darkmoon Faire in 2023). Past that, the core
keeps the old start dates and repeats them every 360–362 days, so holidays drift weeks early,
appear twice in the in-game calendar, and the Darkmoon Faire vanishes. This affects when the
events actually run, not only the calendar.

`tools/pandaria/holiday_dates.py` writes fresh dates: fixed-date holidays repeat every year,
Easter / Lunar New Year / Thanksgiving based ones get 26 years of dates, and the Darkmoon Faire
gets the first Sunday of each of the next 26 months (re-run it within two years).

```sh
cd ~/pandaria/tools-repo
python3 tools/pandaria/holiday_dates.py ~/pandaria/server/data/dbc/Holidays.dbc > ~/holiday_dates.sql
mysqldump -u root -p world holiday_dates > ~/holiday_dates_backup.sql
mysql -u root -p world < ~/holiday_dates.sql
```

Restart `worldserver`, then log out and back in so the client requests a new calendar.
