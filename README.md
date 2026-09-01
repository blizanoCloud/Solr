# Solr Cluster State Analyzer

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
