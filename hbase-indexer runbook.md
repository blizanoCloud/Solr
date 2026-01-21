# Runbook: HBase Indexer Troubleshooting

## Document Purpose
This runbook provides a structured troubleshooting flow for COEs to diagnose the **Lily HBase Indexer** (Key-Value Indexer). Follow these steps to resolve common issues or to gather required diagnostics before escalating an **ENGESC** request to the Engineering team.

---

## 1. Initial Triage & Health Check
Before deep-diving into logs, verify the basic health of the indexing pipeline components.

- [ ] **Service Status:** Are HBase, Solr, and the HBase Indexer roles "Good Health" in Cloudera Manager (CM)?
- [ ] **Replication Status:** Is HBase replication enabled globally? 
  - *Action:* Run `status 'replication'` in the HBase shell.
- [ ] **Zookeeper Registration:** Is the Indexer registered in ZNode? 
  - *Action:* `ls /ngdata/sep/indexer` in `zkCli`.
- [ ] **Lag Analysis:** Is the issue a total stop of data (Stalled) or a delay (Backlog)? 

---

## 2. Common Troubleshooting Scenarios

### Scenario A: New Data is Not Appearing in Solr
1. **Verify Replication Peers:**
   - Run `list_peers` in HBase shell. 
   - Ensure the `PEER_ID` matches your indexer name and the state is `ENABLED`.
2. **Check Table Scopes:**
   - Ensure the Column Families being indexed have `REPLICATION_SCOPE => 1`.
   - Command: `describe 'table_name'`.
3. **Inspect WAL Queues:**
   - If `sizeOfLogQueue` is increasing in `status 'replication', 'source'`, the indexer is likely failing to acknowledge batches.

### Scenario B: Indexer Service Fails to Start
1. **Zookeeper Permissions:** Check for `NoNodeException` or `AuthFailed` errors in logs, common after Kerberos hardening.
2. **JVM Heap:** Check for `java.lang.OutOfMemoryError`. Indexers handling large Morphline transformations may require increased heap sizes.

### Scenario C: Partial Data / "Missing" Records
1. **Morphline Dropped Records:** Inspect logs for "Record dropped" messages. This usually happens if a Morphline command fails to process a specific field.
2. **Solr Throughput:** Check Solr logs for `400 (Bad Request)` or `503 (Service Unavailable)`. If Solr is slow, the Indexer will backpressure and slow down.

---

## 3. Data Collection Checklist (Mandatory for ENGESC)
The following data must be collected and attached to any Engineering Escalation.

### A. Configuration Files
- [ ] `indexer-config.xml`: The XML defining the mapping.
- [ ] `morphlines.conf`: The transformation logic (if applicable).
- [ ] `solr-config.xml` & `managed-schema`: From the target Solr collection.

### B. Diagnostic Logs
- [ ] **HBase Indexer Logs:** Found at `/var/log/hbase-solr/` on the Indexer hosts.
- [ ] **HBase RegionServer Logs:** Only from the nodes hosting the source table regions (look for `ReplicationSource` threads).
- [ ] **Solr Server Logs:** Search for indexing errors/exceptions at the time of the gap.

### C. System State
- [ ] **Thread Dumps:** Take 3 `jstack` samples (30s apart) of the Indexer process if it appears "stuck."
- [ ] **Zookeeper Data:** Output of `get /ngdata/sep/indexer/<indexer_name>` from `zkCli.sh`.
- [ ] **Replication Metrics:** Screenshot of the "HBase Replication Lag" dashboard from CM.

---

## 4. Useful Commands Reference

| Goal | Command |
| :--- | :--- |
| **List Indexers** | `hbase-indexer list-indexers -z <zk_quorum>` |
| **Check Peer Status** | `hbase shell` -> `status 'replication', 'source'` |
| **Verify ZK Path** | `zkCli.sh -server <zk_host>:2181` -> `ls /ngdata/sep/indexer` |
| **Test Morphline** | `java -jar /usr/lib/hbase-solr/bin/morphline-tester.jar --morphline-file <file>` |

---

## 5. Escalation Template
**To:** Engineering (ENGESC)  
**Subject:** HBase Indexer - [Issue: Lag/Failure/Data Loss] - [Cluster Environment]

**1. Problem Description:** (Briefly describe the symptoms and when they started.)

**2. Troubleshooting Steps Taken:** (List what was verified from Section 2 of the runbook.)

**3. Logs Attached:** (Confirm that Indexer, RS, and Solr logs are attached covering the timestamp of the issue.)

**4. Impact:** (Production/Dev, data loss vs. data delay.)
