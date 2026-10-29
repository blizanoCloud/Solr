
#!/usr/bin/env bash

# ============================================================
# Solr Cluster State Analyzer
#
# Usage:
#   ./solr_cli_analyzer.sh [--no-color] [clusterstate_file]
#
# Examples:
#   ./solr_cli_analyzer.sh clusterstate.out
#   ./solr_cli_analyzer.sh --no-color clusterstate.out
#   ./solr_cli_analyzer.sh clusterstate.out > solr_analysis.txt
#
# Requirements:
#   - Bash
#   - Python 3
# ============================================================

FILE_PATH=""
NO_COLOR_OPTION=0

# ------------------------------------------------------------
# ARGUMENT PARSING
# ------------------------------------------------------------

for arg in "$@"; do
    case "$arg" in
        --no-color)
            NO_COLOR_OPTION=1
            ;;
        *)
            if [ -z "$FILE_PATH" ]; then
                FILE_PATH="$arg"
            else
                echo "Error: Unexpected argument '$arg'"
                exit 1
            fi
            ;;
    esac
done

# ------------------------------------------------------------
# INPUT
# ------------------------------------------------------------

if [ -z "$FILE_PATH" ]; then
    read -r -p "Enter path to clusterstate file [e.g., clusterstate.out]: " FILE_PATH
fi

if [ ! -f "$FILE_PATH" ]; then
    echo -e "\033[31mError: File '$FILE_PATH' not found.\033[0m"
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: Python 3 is required but was not found."
    exit 1
fi

# ------------------------------------------------------------
# EXPORT COLOR SETTINGS
# ------------------------------------------------------------

export SOLR_NO_COLOR="$NO_COLOR_OPTION"

# ------------------------------------------------------------
# PYTHON ANALYZER
# ------------------------------------------------------------

python3 - "$FILE_PATH" <<'PYEOF'

import sys
import json
import os

# ------------------------------------------------------------
# ANSI COLOR DETECTION
# ------------------------------------------------------------

# Enable colors only when:
# 1. Output is an interactive terminal.
# 2. NO_COLOR is not configured.
# 3. --no-color was not specified.

USE_COLOR = (
    sys.stdout.isatty()
    and os.environ.get("NO_COLOR") is None
    and os.environ.get("SOLR_NO_COLOR") != "1"
)

def color(code):
    return code if USE_COLOR else ""

BOLD   = color("\033[1m")
GREEN  = color("\033[32m")
RED    = color("\033[31m")
YELLOW = color("\033[33m")
BLUE   = color("\033[34m")
CYAN   = color("\033[36m")
GRAY   = color("\033[90m")
RESET  = color("\033[0m")

# ------------------------------------------------------------
# HELPERS
# ------------------------------------------------------------

def safe_dict(value):
    return value if isinstance(value, dict) else {}

def safe_list(value):
    return value if isinstance(value, list) else []

def get_state_color(state):

    state = str(state).lower()

    if state in ("active", "recovered"):
        return GREEN

    elif state in ("recovering", "construction"):
        return YELLOW

    elif state in ("down", "recovery_failed"):
        return RED

    return GRAY

def get_health_color(health):

    health = str(health).upper()

    if health == "GREEN":
        return GREEN

    elif health == "YELLOW":
        return YELLOW

    elif health == "RED":
        return RED

    elif health == "ORANGE":
        return YELLOW

    return GRAY

def detect_storage(details):

    raw = json.dumps(details).lower()

    if (
        "hdfs://" in raw
        or "hdfsdirectoryfactory" in raw
        or "solr.hdfs.home" in raw
    ):
        return "HDFS", BLUE

    return "Unknown", YELLOW

# ------------------------------------------------------------
# READ AND PARSE JSON
# ------------------------------------------------------------

file_path = sys.argv[1]

try:

    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Support JSON files and HTTP responses containing headers.
    json_start = content.find("{")

    if json_start == -1:
        raise ValueError("No JSON object found in input file.")

    decoder = json.JSONDecoder()
    data, _ = decoder.raw_decode(content[json_start:])

    if not isinstance(data, dict):
        raise ValueError("JSON root must be an object.")

except Exception as e:

    print(f"{RED}Failed to parse cluster state: {e}{RESET}")
    sys.exit(1)

# ------------------------------------------------------------
# EXTRACT CLUSTER INFORMATION
# ------------------------------------------------------------

cluster = safe_dict(data.get("cluster", data))

collections = safe_dict(cluster.get("collections", {}))
live_nodes = safe_list(cluster.get("live_nodes", []))

# ------------------------------------------------------------
# SUMMARY METRICS
# ------------------------------------------------------------

total_collections = len(collections)
total_shards = 0
total_replicas = 0

for coll_details in collections.values():

    coll_details = safe_dict(coll_details)
    shards = safe_dict(coll_details.get("shards", {}))

    total_shards += len(shards)

    for shard_details in shards.values():

        shard_details = safe_dict(shard_details)
        replicas = safe_dict(shard_details.get("replicas", {}))

        total_replicas += len(replicas)

# ------------------------------------------------------------
# HEADER
# ------------------------------------------------------------

print()
print(f"{BOLD}{CYAN}{'=' * 90}")
print("                 SOLR CLUSTER STATE CLI SUMMARY")
print(f"{'=' * 90}{RESET}")

# ------------------------------------------------------------
# SUMMARY METRICS
# ------------------------------------------------------------

print()

print(
    f"{BOLD}LIVE NODES:{RESET} {GREEN}{len(live_nodes)}{RESET}  |  "
    f"{BOLD}COLLECTIONS:{RESET} {BLUE}{total_collections}{RESET}  |  "
    f"{BOLD}SHARDS:{RESET} {YELLOW}{total_shards}{RESET}  |  "
    f"{BOLD}REPLICAS:{RESET} {CYAN}{total_replicas}{RESET}"
)

# ------------------------------------------------------------
# LIVE NODES
# ------------------------------------------------------------

print()
print(f"{BOLD}Active Solr Nodes:{RESET}")

if live_nodes:

    for node in live_nodes:
        print(f"  {GREEN}●{RESET} {node}")

else:

    print(f"  {RED}● No active nodes reported!{RESET}")

print()
print(f"{GRAY}{'-' * 90}{RESET}")

# ------------------------------------------------------------
# COLLECTIONS AND REPLICAS
# ------------------------------------------------------------

print()
print(f"{BOLD}Collection & Replica Node Mappings:{RESET}")
print()

if not collections:

    print("  No collections found in cluster state.")

else:

    for coll_name, coll_details in collections.items():

        coll_details = safe_dict(coll_details)

        health = str(coll_details.get("health", "UNKNOWN")).upper()
        config = coll_details.get("configName", "N/A")

        shards = safe_dict(coll_details.get("shards", {}))

        storage, storage_color = detect_storage(coll_details)
        health_color = get_health_color(health)

        health_display = f"{health:<10}"

        print(
            f"{BOLD}Collection:{RESET} "
            f"{CYAN}{coll_name:<25}{RESET} "
            f"Health: {health_color}{BOLD}{health_display}{RESET} "
            f"Config: {BOLD}{config}{RESET} "
            f"Storage: {storage_color}[{storage}]{RESET}"
        )

        print()

        print(
            f"  {'Shard':<12} "
            f"{'Core Name':<35} "
            f"{'State':<18} "
            f"{'Type':<8} "
            f"{'Node / Server Name'}"
        )

        print(
            f"  {'-' * 12} {'-' * 35} "
            f"{'-' * 18} {'-' * 8} {'-' * 40}"
        )

        if not shards:
            print("  No shards found.")
            print()
            continue

        for shard_name, shard_details in shards.items():

            shard_details = safe_dict(shard_details)
            replicas = safe_dict(shard_details.get("replicas", {}))

            if not replicas:
                print(f"  {shard_name:<12} No replicas found.")
                continue

            for rep_key, rep_details in replicas.items():

                rep_details = safe_dict(rep_details)

                core = str(rep_details.get("core", "N/A"))
                state = str(rep_details.get("state", "N/A"))
                rep_type = str(rep_details.get("type", "N/A"))
                node = str(rep_details.get("node_name", "N/A"))

                is_leader = str(
                    rep_details.get("leader", "false")
                ).lower() == "true"

                state_color = get_state_color(state)
                state_display = f"{state:<10}"

                state_fmt = (
                    f"{state_color}{state_display}{RESET}"
                )

                leader_badge = (
                    f" {YELLOW}(LEADER){RESET}"
                    if is_leader else ""
                )

                print(
                    f"  {shard_name:<12} "
                    f"{core:<35} "
                    f"{state_fmt} "
                    f"{rep_type:<8} "
                    f"{node}{leader_badge}"
                )

        print()

# ------------------------------------------------------------
# FOOTER
# ------------------------------------------------------------

print(f"{BOLD}{CYAN}{'=' * 90}{RESET}")
print()

PYEOF
