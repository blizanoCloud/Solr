#!/usr/bin/env bash

# Usage: ./solr_cli_analyzer.sh [clusterstate_file]
FILE_PATH="$1"

if [ -z "$FILE_PATH" ]; then
    read -p "Enter path to clusterstate file [e.g., clusterstate.out]: " FILE_PATH
fi

if [ ! -f "$FILE_PATH" ]; then
    echo -e "\031[31mError: File '$FILE_PATH' not found.\033[0m"
    exit 1
fi

# ANSI Color Codes for Terminal Formatting
BOLD="\033[1m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
GRAY="\033[90m"
RESET="\033[0m"

# Extract raw JSON starting from the first '{' (strips HTTP headers if present)
JSON_DATA=$(awk 'BEGIN{found=0} {if(!found){idx=index($0,"{"); if(idx>0){$0=substr($0,idx); found=1}} if(found) print}' "$FILE_PATH")

if [ -z "$JSON_DATA" ]; then
    echo -e "${RED}Error: Could not extract valid JSON from '$FILE_PATH'.${RESET}"
    exit 1
fi

# Use Python (installed on almost all Linux nodes) for fast JSON traversal
python3 - "$JSON_DATA" << 'PYEOF'
import sys, json

raw_json = sys.argv[1]

# ANSI Escapes
BOLD = "\033[1m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
CYAN = "\033[36m"
GRAY = "\033[90m"
RESET = "\033[0m"

try:
    data = json.loads(raw_json)
except Exception as e:
    print(f"{RED}Failed to parse JSON: {e}{RESET}")
    sys.exit(1)

cluster = data.get("cluster", data)
collections = cluster.get("collections", {})
live_nodes = cluster.get("live_nodes", [])

# Calculate Top Level Summary Metrics
total_collections = len(collections)
total_shards = 0
total_replicas = 0

for coll_name, coll_details in collections.items():
    shards = coll_details.get("shards", {})
    total_shards += len(shards)
    for shard_name, shard_details in shards.items():
        replicas = shard_details.get("replicas", {})
        total_replicas += len(replicas)

# --- HEADER SECTION ---
print(f"\n{BOLD}{CYAN}==========================================================================")
print(f"               SOLR CLUSTER STATE CLI SUMMARY")
print(f"=========================================================================={RESET}\n")

# --- TOP METRICS CARDS ---
print(f" {BOLD}LIVE NODES:{RESET} {GREEN}{len(live_nodes)}{RESET}  |  {BOLD}COLLECTIONS:{RESET} {BLUE}{total_collections}{RESET}  |  {BOLD}SHARDS:{RESET} {YELLOW}{total_shards}{RESET}  |  {BOLD}REPLICAS:{RESET} {CYAN}{total_replicas}{RESET}\n")

# --- ACTIVE NODES LIST ---
print(f"{BOLD}Active Solr Nodes:{RESET}")
if live_nodes:
    for node in live_nodes:
        print(f"  {GREEN}●{RESET} {node}")
else:
    print(f"  {RED}● No active nodes reported!{RESET}")

print(f"\n{GRAY}--------------------------------------------------------------------------{RESET}\n")

# --- COLLECTIONS & REPLICAS BREAKDOWN ---
print(f"{BOLD}Collection & Replica Node Mappings:{RESET}\n")

if not collections:
    print("  No collections found in cluster state.")
else:
    for coll_name, coll_details in collections.items():
        health = coll_details.get("health", "UNKNOWN")
        config = coll_details.get("configName", "N/A")
        shards = coll_details.get("shards", {})
        
        # Determine Storage Type (HDFS vs Local Disk)
        raw_coll_str = json.dumps(coll_details).lower()
        is_hdfs = "hdfs://" in raw_coll_str or "hdfsdirectoryfactory" in raw_coll_str
        storage_type = f"{BLUE}[HDFS]{RESET}" if is_hdfs else f"{GRAY}[Local Disk]{RESET}"

        # Colorize Health Status
        health_color = GREEN if health == "GREEN" else (RED if health == "RED" else GRAY)
        health_fmt = f"{health_color}{BOLD}{health}{RESET}"

        print(f" {BOLD}Collection:{RESET} {CYAN}{coll_name:<20}{RESET} Health: {health_fmt:<17} Config: {BOLD}{config}{RESET}  Storage: {storage_type}")
        print(f"  {GRAY}{'Shard':<10} {'Core Name':<32} {'State':<10} {'Type':<6} {'Node / Server Name':<45}{RESET}")
        print(f"  {GRAY}{'-'*10} {'-'*32} {'-'*10} {'-'*6} {'-'*45}{RESET}")

        for shard_name, shard_details in shards.items():
            replicas = shard_details.get("replicas", {})
            for rep_key, rep_details in replicas.items():
                core = rep_details.get("core", "N/A")
                state = rep_details.get("state", "N/A")
                rep_type = rep_details.get("type", "N/A")
                node = rep_details.get("node_name", "N/A")
                is_leader = rep_details.get("leader") == "true"

                # Badges
                leader_badge = f" {YELLOW}(LEADER){RESET}" if is_leader else ""
                state_color = GREEN if state == "active" else RED
                state_fmt = f"{state_color}{state}{RESET}"

                print(f"  {shard_name:<10} {core:<32} {state_fmt:<19} {rep_type:<6} {node}{leader_badge}")
        print()

print(f"{BOLD}{CYAN}=========================================================================={RESET}\n")
PYEOF
