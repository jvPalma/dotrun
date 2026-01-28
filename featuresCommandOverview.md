# Scripts

## S1. RUN script (default behaviour, if er dont specify what we want to do with the script_name, we execute it)

```bash
dr    (optional folder/path/name/) script_name
dr -s (optional folder/path/name/) script_name
```

## S2. ADD script

```bash
dr    set (optional folder/path/name/) script_name
dr -s set (optional folder/path/name/) script_name
```

## S3. MOVE script

```bash
dr    move (optional folder/path/name/) script_name
dr -s move (optional folder/path/name/) script_name
```

## S4. RENAME script (alias for move)

```bash
dr    rename (optional folder/path/name/) script_name
dr -s rename (optional folder/path/name/) script_name
```

## S5. HELP script

will print out the long documentation block inside the scriptFile, in the top LONG comment block

```bash
dr    help (optional folder/path/name/) script_name
dr -s help (optional folder/path/name/) script_name
```

## S6. LIST script

6.1. `dr    list`: assumes `list` is a script name, and fails (i dont want to add this as possibility, just adding here for documentation)
6.2. `dr    -l  (optional FOLDER_PATH)`: Lists the SCRIPTS folder, in a tree colored view, in a short format (folders + scripts names)
6.3. `dr    -L  (optional FOLDER_PATH)`: Lists the SCRIPTS folder, in a tree colored view, in a long format (folders + scripts names + script internal 1 linner description comment on top of the file)
6.4. `dr -s list`: works like 6.2
6.5. `dr -s -l  (optional FOLDER_PATH)`: doesnt work
6.6. `dr -s -L  (optional FOLDER_PATH)`: doesnt work

from that list, [6.1] and [6.4] should be removed
[6.2] and [6.5] should both work in the same way (what its implemented in [6.2])
[6.3] and [6.6] should both work in the same way (what its implemented in [6.3])

---

---

---

# TAB autocomplete shell scenarios:

## ST1

```bash
dr TAB
# OLD: line 1 : shows Hint for other features
# NEW: line 1 : shows Hint of available commands for the SCRIPTS feature
# line 2+: folders, and after all folders, all the scripts

dr -s TAB # needs to work exactly like the command without the `-s`
```

---

## ST2: command: `set`

```bash
dr set TAB
# line 1 : folders, and after all folders, all the scripts
# line 2+: N/A

dr -s set TAB # needs to work exactly like the command without the `-s`
```

---

## ST3: command: `edit` 🔴 [does not exist/to be removed], we need to remove all references of this in the code, documentation, labels, and actions if any exists

```bash
dr edit TAB
dr -s edit TAB
```

---

## ST4: command: `init` 🔴 [does not exist/to be removed], we need to remove all references of this in the code, documentation, labels, and actions if any exists

```bash
dr init TAB
dr -s init TAB
```

---

## ST5: command: `rename` 🔴 [does not exist/to be removed], we need to remove all references of this in the code, documentation, labels, and actions if any exists

removed in favor of command: `move`

```bash
dr rename TAB
dr -s rename TAB
```

---

## ST6: command: `move`

```bash
dr rename TAB # does the autocomplete correctly, just want to add preview of what will actually happen once the user submits `dr move path1/file path2/newFile` -> show the user clearlly, with colors, what is the original path, the new path, ask for confirmation with [Y/y/enter] and if so, show the success message with colors aswell.
# also, nmoticed a bug right now, if we do  `dr move folder1/file folder1/folder2/` without giving him a name in the end, the file gets renamed to nothing, the filename goes from `folder1/file.sh` to `folder1/folder2/.sh`
dr -s rename TAB # needs to work exactly like the command without the `-s`
```

---

## ST7: command: `help`

```bash
dr help TAB    # works as expected
dr -s help TAB # needs to work exactly like the command without the `-s`
```

---

## ST8: command: `rm` 🔴 does not exist, but it should!

```bash
dr rm TAB
dr -s rm TAB # needs to work exactly like the command without the `-s`
```

---

## ST9: command: `reload` 🔴 [does not exist/to be removed], we need to remove all references of this in the code, documentation, labels, and actions if any exists

```bash
dr reload TAB
# line 1 :
# line 2+:

dr -s reload TAB
# line 1 :
# line 2+:
```

---

## ST10: command: `sync` 🔴 [does not exist/to be removed], we need to remove all references of this in the code, documentation, labels, and actions if any exists

```bash
dr sync TAB
# line 1 :
# line 2+:

dr -s sync TAB
# line 1 :
# line 2+:
```

## SUMMARY

### with final version of the commands accepted, tabs, and documentation states

**DEFAULT ACTION**: `RUN SCRIPT`

removals/renames:

- remove command `edit` \*\*
- remove command `init` \*\*
- command `remove` renamed to `rm`
- remove command `reload` \*\*
- remove command `sync` \*\*

| command                                                       | name                                             | Implemented | TAB autocomplete (default) | TAB autocomplete (with filter) | help message updated info? | Project Docs updated info ? |
| ------------------------------------------------------------- | ------------------------------------------------ | :---------: | :------------------------: | :----------------------------: | :------------------------: | :-------------------------: |
| 1. `dr (optional `-s/scripts`)      (opt FOLDER/)SCRIPT_NAME` | RUN SCRIPT (DEFAULT IF NO COMMAND IS PASSED)     |     🟢      |             🟢             |               🟢               |             ❔             |             ❔              |
| 2. `dr (optional `-s/scripts`)   -l (opt FOLDER/)`            | list aliases with Tree output                    |     🟢      |             🟢             |               ❌               |             ❔             |             ❔              |
| 3. `dr (optional `-s/scripts`)   -L (opt FOLDER/)`            | list script names w/description with Tree output |     🟢      |             🟢             |               ❌               |             ❔             |             ❔              |
| 4. `dr (optional `-s/scripts`) set  (opt FOLDER/)SCRIPT_NAME` | ADD/EDIT                                         |     🟢      |             🟢             |               ❌               |             ❔             |             ❔              |
| 5. `dr (optional `-s/scripts`) move (opt FOLDER/)SCRIPT_NAME` | MOVE/RENAME                                      |     🟢      |             🟢             |               ❌               |             ❔             |             ❔              |
| 6. `dr (optional `-s/scripts`) rm   (opt FOLDER/)SCRIPT_NAME` | REMOVE                                           |     ❌      |             ❌             |               ❌               |             ❔             |             ❔              |
| 7. `dr (optional `-s/scripts`) help (opt FOLDER/)SCRIPT_NAME` | HELP                                             |     🟢      |             🟢             |               ❌               |             ❔             |             ❔              |

---

# EXTRA: we need a new command action called `reload`

`dr reload`, same as the `## ST9:` from scripts, but, it should be FEATURE agnostic, what the command should do is: `source ~/.drrc` file, to reload all dotrun entire tool

---

---

---

# ALIASES

since the ALIASES doesnt `execute` files like the SCRIPTS, the default command with ommition, its the ADD/EDIT one.

**DEFAULT ACTION**: `ADD/EDIT`

removals/renames:

- the need of explicitly using the command `set` needs to be removed as its the default behavior
- remove command `edit` \*\*
- command `remove` renamed to `rm`
- remove command `reload` \*\*
- remove command `sync` \*\*

| command                                                | name                                             | Implemented | TAB autocomplete (default) | TAB autocomplete (with filter) | help message updated info? | Project Docs updated info ? |
| ------------------------------------------------------ | ------------------------------------------------ | :---------: | :------------------------: | :----------------------------: | :------------------------: | :-------------------------: |
| 1. `dr -a/aliases      (opt FOLDER/)ALIASES_FILE_NAME` | ADD/EDIT (DEFAULT IF NO COMMAND IS PASSED)       |     🟢      |             🟢             |               ❌               |             ❔             |             ❔              |
| 2. `dr -a/aliases   -l (opt FOLDER/)`                  | list aliases with Tree output like SCRIPTS       |     ❌      |             ❌             |               ❌               |             ❔             |             ❔              |
| 3. `dr -a/aliases   -L (opt FOLDER/)`                  | list script names w/description with Tree output |     ❌      |             ❌             |               ❌               |             ❔             |             ❔              |
| 4. `dr -a/aliases move (opt FOLDER/)ALIASES_FILE_NAME` | MOVE/RENAME                                      |     🟢      |             🟢             |               ❌               |             ❔             |             ❔              |
| 5. `dr -a/aliases rm   (opt FOLDER/)ALIASES_FILE_NAME` | REMOVE                                           |     🟢      |             🟢             |               ❌               |             ❔             |             ❔              |
| 7. `dr -a/aliases help (opt FOLDER/)ALIASES_FILE_NAME` | HELP                                             |     🟢      |             🟢             |               ❌               |             ❔             |             ❔              |
| 6. `dr -a/aliases init (opt FOLDER/)ALIASES_FILE_NAME` | INIT ALIASES FOLDER STRUCT                       |     🟢      |             🟢             |               ❌               |             ❔             |             ❔              |

NOTE:
the [TAB autocomplete] output result, should be the same exact one as the same implementation in SCRIPTS, same way of displaying data, same hints, but adapted to this feature colors, icons, and commands.

---

---

---

# CONFIGS

since the CONFIGS doesnt `execute` files like the SCRIPTS, the default command with ommition, its the ADD/EDIT one.

removals/renames:

- the need of explicitly using the command `set` needs to be removed as its the default behavior
- remove command `edit` \*\*
- command `remove` renamed to `rm`
- remove command `reload` \*\*
- remove command `sync` \*\*

| command                                              | name                                             | Implemented | TAB autocomplete (default) | TAB autocomplete (with filter) | help message updated info? | Project Docs updated info ? |
| ---------------------------------------------------- | ------------------------------------------------ | :---------: | :------------------------: | :----------------------------: | :------------------------: | :-------------------------: |
| 1. `dr -c/condig      (opt FOLDER/)CONFIG_FILE_NAME` | ADD/EDIT (DEFAULT IF NO COMMAND IS PASSED)       |     🟢      |             🟢             |               ❌               |             ❔             |             ❔              |
| 2. `dr -c/condig   -l (opt FOLDER/)`                 | list condig with Tree output like SCRIPTS        |     ❌      |             ❌             |               ❌               |             ❔             |             ❔              |
| 3. `dr -c/condig   -L (opt FOLDER/)`                 | list script names w/description with Tree output |     ❌      |             ❌             |               ❌               |             ❔             |             ❔              |
| 4. `dr -c/condig move (opt FOLDER/)CONFIG_FILE_NAME` | MOVE/RENAME                                      |     🟢      |             🟢             |               ❌               |             ❔             |             ❔              |
| 5. `dr -c/condig rm   (opt FOLDER/)CONFIG_FILE_NAME` | REMOVE                                           |     🟢      |             🟢             |               ❌               |             ❔             |             ❔              |
| 7. `dr -c/condig help (opt FOLDER/)CONFIG_FILE_NAME` | HELP                                             |     🟢      |             🟢             |               ❌               |             ❔             |             ❔              |
| 6. `dr -c/condig init (opt FOLDER/)CONFIG_FILE_NAME` | INIT CONFIGS FOLDER STRUCT                       |     🟢      |             🟢             |               ❌               |             ❔             |             ❔              |

NOTE:
the [TAB autocomplete] output result, should be the same exact one as the same implementation in SCRIPTS, same way of displaying data, same hints, but adapted to this feature colors, icons, and commands.

\*\* if it exist, check on the codebase, help mesages, documentation .md files exposed on github for documentation
