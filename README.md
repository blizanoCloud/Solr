# Solr Cluster State Analyzer

A lightweight, single-file HTML/JavaScript web tool for parsing, analyzing, and visualizing Apache Solr cluster states (`clusterstate.out` or Solr JSON API responses).

---

## 🛠️ Description

The **Solr Cluster State Analyzer** is a client-side tool designed to help DevOps engineers, Database Administrators, and Search Engineers quickly inspect the health and topology of an Apache Solr cluster [cite: 1]. It parses `clusterstate.out` or JSON files returned by Solr's Cluster Status API and renders an interactive dashboard [cite: 1].

### Key Features
- **Key Metrics Dashboard**: Instant overview of Live Solr Nodes, Total Collections, Total Shards, and Total Replicas [cite: 1].
- **Live Node Discovery**: Visual indicators showing active Solr nodes [cite: 1].
- **Interactive Collection Breakdown**: View health status (GREEN/RED/UNKNOWN), storage type (HDFS vs Local Disk detection), and config set details [cite: 1].
- **Drill-Down Shard & Replica Inspector**: Expandable collection rows detailing individual shards, core names, replica states (active/down), replica types (NRT, TLOG, PULL), leader status, and node assignments [cite: 1].
- **Interactive Table Sorting**: Client-side sorting for all collection and replica properties [cite: 1].
- **Client-Side & Secure**: Runs entirely in the browser using HTML5 FileReader API — no external server uploads required [cite: 1].

---

## 🚀 How to Use

### Prerequisites
- Any modern browser (Chrome, Firefox, Edge, Safari) with Internet access (for loading jQuery via CDN) [cite: 1].
- A Solr `clusterstate.out` file or JSON output from the Solr Cluster Status API [cite: 1].

---

### Step-by-Step Instructions

#### 1. Obtain Your Solr Cluster State File
You can obtain a compatible cluster state JSON file in two ways:

* **From ZooKeeper**: Extract the `clusterstate.out` file directly from ZooKeeper using Solr CLI or ZK CLI [cite: 1].
* **Via Solr HTTP API**: Query the Solr Collections API directly from your browser or `curl`:
  ```bash
  curl -s "http://<SOLR_HOST>:<SOLR_PORT>/solr/admin/collections?action=CLUSTERSTATUS&wt=json" -o clusterstate.json
  ```

#### 2. Open the Tool
- Double-click the `solr_analyzer.html` (or open it via your web browser) [cite: 1].

#### 3. Upload & Analyze
1. Click the **📁 Choose File** button on the upload card [cite: 1].
2. Select your `.out`, `.json`, or `.txt` file containing the cluster state [cite: 1].
3. The dashboard will automatically parse and display the metrics [cite: 1].

#### 4. Explore the Dashboard
- **Summary Cards**: Quick stats on cluster size and health [cite: 1].
- **Active Nodes**: View all currently active live nodes [cite: 1].
- **Collections Table**: Click on table headers (Collection Name, Health, Shards, Replicas, etc.) to sort [cite: 1].
- **Expand Row Details**: Click on any collection row to expand its details and see shard leadership, replica status, core names, and underlying node hosts [cite: 1].

---

## 🔒 Security & Privacy
Since this application operates completely client-side using JavaScript `FileReader`, your Solr topology data remains strictly inside your browser and is never uploaded to any remote server [cite: 1].
