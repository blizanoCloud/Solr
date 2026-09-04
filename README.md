# Solr Cluster State CLI Analyzer (`solrstateanalyser_cli.sh`)

A lightweight, terminal-based utility designed to parse Solr `clusterstate.out` or raw JSON cluster state responses directly inside an SSH terminal session.

It provides an immediate, color-coded breakdown of cluster health, live nodes, shard mappings, replica states, and storage detection without requiring a web browser, open network ports, or background web server processes.

---

## **Key Features**

* **Zero External Dependencies:** Runs natively using standard Bash and built-in Python 3.
* **Header Stripping:** Automatically handles and cleans HTTP headers (e.g., `HTTP/1.1 200 OK`) if raw response dumps are passed directly.
* **Color-Coded Statuses:** Highlights active nodes, replica health (`GREEN`/`RED`), leader status, and storage type at a glance.
* **Storage Type Detection:** Automatically scans cluster configurations for `hdfs://` schemas or `HDFSDirectoryFactory` directives.

---

## **Installation**

1. Create or open the script file on your target Linux machine:
```bash
nano solrstateanalyser_cli.sh
```
```bash
vi solrstateanalyser_cli.sh
```

2. Paste the script content into the file and save it.
3. Make the script executable:
```bash
chmod +x solrstateanalyser_cli.sh
```

---

## **Usage**

### **1. Direct File Execution (Recommended)**

Pass the path to your Solr cluster state file as a command-line argument:

```bash
./solrstateanalyser_cli.sh clusterstate.out
```

### **2. Interactive Prompt**

If executed without arguments, the script will prompt you to type the file path:

```bash
./solrstateanalyser_cli.sh
# Prompt: Enter path to clusterstate file [e.g., clusterstate.out]:
```

---

## **Expected Output Overview**

Upon execution, the terminal dashboard renders four core sections:

* **Top Metrics Bar:** Total count of Live Solr Nodes, Collections, Shards, and Replicas.
* **Active Solr Nodes:** Formatted list of all active nodes currently registered in ZooKeeper (`live_nodes`).
* **Collection Overview:** Collection name, health state (`GREEN`/`RED`), ZooKeeper config set (`configName`), and storage type (`[HDFS]` or `[Local Disk]`).
* **Shard & Replica Breakdown:** Table detailing shard names, core names, replica states (`active`/`down`), replica types (`NRT`/`TLOG`/`PULL`), node names, and leader designations (`LEADER`).

Example:

```bash
$ ./solrstateanalyser_cli.sh clusterstate.out

==========================================================================
               SOLR CLUSTER STATE CLI SUMMARY
==========================================================================

 LIVE NODES: 1  |  COLLECTIONS: 4  |  SHARDS: 4  |  REPLICAS: 4

Active Solr Nodes:
  ● node4.cdpbryan-blizano.coelab.cloudera.com:8993_solr

--------------------------------------------------------------------------

Collection & Replica Node Mappings:

 Collection: vertex_index         Health: GREEN Config: atlas_configs  Storage: [Local Disk]
  Shard      Core Name                        State      Type   Node / Server Name                           
  ---------- -------------------------------- ---------- ------ ---------------------------------------------
  shard1     vertex_index_shard1_replica_n1   active     NRT    node4.cdpbryan-blizano.coelab.cloudera.com:8993_solr (LEADER)

 Collection: edge_index           Health: GREEN Config: atlas_configs  Storage: [Local Disk]
  Shard      Core Name                        State      Type   Node / Server Name                           
  ---------- -------------------------------- ---------- ------ ---------------------------------------------
  shard1     edge_index_shard1_replica_n1     active     NRT    node4.cdpbryan-blizano.coelab.cloudera.com:8993_solr (LEADER)

 Collection: fulltext_index       Health: GREEN Config: atlas_configs  Storage: [Local Disk]
  Shard      Core Name                        State      Type   Node / Server Name                           
  ---------- -------------------------------- ---------- ------ ---------------------------------------------
  shard1     fulltext_index_shard1_replica_n1 active     NRT    node4.cdpbryan-blizano.coelab.cloudera.com:8993_solr (LEADER)

 Collection: ranger_audits        Health: GREEN Config: ranger_audits  Storage: [Local Disk]
  Shard      Core Name                        State      Type   Node / Server Name                           
  ---------- -------------------------------- ---------- ------ ---------------------------------------------
  shard1     ranger_audits_shard1_replica_n1  active     NRT    node4.cdpbryan-blizano.coelab.cloudera.com:8993_solr (LEADER)

==========================================================================
```

---

## **Troubleshooting**

* **`Failed to parse JSON: Expecting property name...`**
* **Cause:** Passing an HTML file (such as `cluster_report.html`) instead of the raw JSON file.
* **Fix:** Ensure you are passing the original JSON input file (e.g., `clusterstate.out`).


* **`Error: File 'clusterstate.out' not found.`**
* **Cause:** The specified file path does not exist in the current working directory.
* **Fix:** Verify your file path using `ls` or pass the absolute path (e.g., `./solrstateanalyser_cli.sh /path/to/clusterstate.out`).

------------------------------------------

# Solr Cluster State Analyzer Web Broweser

A lightweight, single-file HTML/JavaScript web tool for parsing, analyzing, and visualizing Apache Solr cluster states (`clusterstate.out` or Solr JSON API responses).

---

## 🛠️ Description

The **Solr Cluster State Analyzer** is a client-side tool designed to help DevOps engineers, Database Administrators, and Search Engineers quickly inspect the health and topology of an Apache Solr cluster .. It parses `clusterstate.out` or JSON files returned by Solr's Cluster Status API and renders an interactive dashboard ..

### Key Features
- **Key Metrics Dashboard**: Instant overview of Live Solr Nodes, Total Collections, Total Shards, and Total Replicas ..
- **Live Node Discovery**: Visual indicators showing active Solr nodes ..
- **Interactive Collection Breakdown**: View health status (GREEN/RED/UNKNOWN), storage type (HDFS vs Local Disk detection), and config set details ..
- **Drill-Down Shard & Replica Inspector**: Expandable collection rows detailing individual shards, core names, replica states (active/down), replica types (NRT, TLOG, PULL), leader status, and node assignments ..
- **Interactive Table Sorting**: Client-side sorting for all collection and replica properties ..
- **Client-Side & Secure**: Runs entirely in the browser using HTML5 FileReader API — no external server uploads required ..

---

## 🚀 How to Use

### Prerequisites
- Any modern browser (Chrome, Firefox, Edge, Safari) with Internet access (for loading jQuery via CDN) ..
- A Solr `clusterstate.out` file or JSON output from the Solr Cluster Status API ..

---

### Step-by-Step Instructions

#### 1. Obtain Your Solr Cluster State File
You can obtain a compatible cluster state JSON file in two ways:

* **From ZooKeeper**: Extract the `clusterstate.out` file directly from ZooKeeper using Solr CLI or ZK CLI ..
* **Via Solr HTTP API**: Query the Solr Collections API directly from your browser or `curl`:
  ```bash
  curl -s "http://<SOLR_HOST>:<SOLR_PORT>/solr/admin/collections?action=CLUSTERSTATUS&wt=json" -o clusterstate.json
  ```

#### 2. Open the Tool
- Double-click the `solr_analyzer.html` (or open it via your web browser) ..

#### 3. Upload & Analyze
1. Click the **📁 Choose File** button on the upload card ..
2. Select your `.out`, `.json`, or `.txt` file containing the cluster state ..
3. The dashboard will automatically parse and display the metrics ..

#### 4. Explore the Dashboard
- **Summary Cards**: Quick stats on cluster size and health ..
- **Active Nodes**: View all currently active live nodes ..
- **Collections Table**: Click on table headers (Collection Name, Health, Shards, Replicas, etc.) to sort ..
- **Expand Row Details**: Click on any collection row to expand its details and see shard leadership, replica status, core names, and underlying node hosts ..

---

## 🔒 Security & Privacy
Since this application operates completely client-side using JavaScript `FileReader`, your Solr topology data remains strictly inside your browser and is never uploaded to any remote server ..


