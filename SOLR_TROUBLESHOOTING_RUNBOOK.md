# Apache Solr Troubleshooting & Escalation Runbook (CDP / Cloudera)

**Last updated:** Jan 2026
**Applies to:** CDP / CDH Solr, Solr-Infra, Ranger, Atlas
**Audience:** Frontline Engineers (FEs)

---

## 1. Purpose

This runbook provides a structured, end-to-end approach to troubleshooting Apache Solr in Cloudera environments. It merges real-world production incidents with a standardized escalation framework, ensuring consistent diagnostics, safe operations, and high-quality escalations.

---

## 2. Golden Rules & Pre-Triage (Read First)

Before making **any** change:

* **Identify Deployment Mode:** Standalone vs **SolrCloud**.
* **No Blind Restarts:** In SolrCloud, restarting nodes without checking cluster health can cause shard unavailability.
* **ZooKeeper is Critical:** Many Solr issues are actually ZooKeeper session, quorum, or ACL issues.
* **Time Synchronization Matters:** Time skew breaks TLS, Kerberos, and leader election. Ensure `chrony` or `ntpd` is healthy.
* **Baseline Awareness:** Always know:

  * Solr version and parcel
  * Distribution (CDP / CDH)
  * Impacted collections (all vs subset)
  * Impact type (Read, Write, or Both)

---

## 3. Mandatory System Baseline (Always Collect)

Run these commands **before** troubleshooting:

| Category      | Commands                                                        |                                                                                   |
| ------------- | --------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| Solr Status   | `solr status`, `solr version`                                   |                                                                                   |
| JVM / Process | `ps -ef                                                         | grep solr`, `jcmd <PID> VM.flags`, `jcmd <PID> VM.system_properties`              |
| Resources     | `free -m`, `vmstat 1 5`, `iostat -xz 1 5`, `df -h`, `ulimit -a` |                                                                                   |
| Network       | `ss -lntup                                                      | grep ** solr_http_port** or ** solr_https_port**`, `curl -I [http://localhost:** solr_http_port** or ** solr_https_port**/solr/`](http://localhost:** solr_http_port** or ** solr_https_port**/solr/`) |
| Time Sync     | `timedatectl`, `chronyc sources` or `ntpq -p`                   |                                                                                   |

---

## 4. Initial Solr & Cluster Triage

### 4.1 Process and Role Health

```bash
ps -Af | grep solr
ls -ltr /var/run/cloudera-scm-agent/process/*SOLR_SERVER*/logs/
```

### 4.2 Log Locations

* **Role logs:**

  * `/var/log/solr`
  * `/var/log/solr-infra`

* **GC logs:**

  * `solr_gc.log`

### 4.3 Cluster State

```bash
curl -k --negotiate -u : "http://$(hostname -f):** solr_http_port** or ** solr_https_port**/solr/admin/collections?action=CLUSTERSTATUS&wt=json&indent=on"
```

ZooKeeper validation:

```bash
echo ruok | nc <zk_host> 2181
zookeeper-client
ls /solr-infra/collections
ls /live_nodes
```

---

## 5. Cluster Topology & Storage Analysis

### Step A: Export Cluster State

```bash
solrctl cluster --get-clusterstate /tmp/clusterstate.out
```

### Step B: Determine Storage Backend

Inspect `dataDir` in `/tmp/clusterstate.out`:

* **HDFS:** `hdfs://...`

  * Validate with `hdfs dfsadmin -report`
* **Local FS:** `/var/lib/solr` or `/var/lib/solr-infra`

  * Validate with `df -h`

---

## 6. Diagnostic Data Collection (Cloudera Manager)

1. Login to **Cloudera Manager**
2. **Administration → Collect Diagnostic Data**
3. Select **Collect Diagnostic Data Globally**
4. Define time range and affected hosts
5. Download bundle after completion

---

## 7. Core Troubleshooting Scenarios

---

### 7.1 Solr Service Down / Not Starting

**Symptoms**

* Solr not listening on configured ports
* `solr status` shows DOWN

**Actions**

```bash
ps aux | grep -i solr
journalctl -u solr
```

**Checks**

* `solr.log` for startup errors
* Recent infra or config changes
* New vs previously working cluster

---

### 7.2 Collections Not Loading / Leader Election Issues

**Symptoms**

* Missing collections
* Replicas in `RECOVERING` or `DOWN`

**Actions**

```bash
curl "http://<solr_host>:<port>/solr/admin/collections?action=CLUSTERSTATUS&wt=json"
```

**ZooKeeper**

```bash
bin/solr zk ls /
```

---

### 7.3 Indexing Failures

Indexing fails when documents cannot be written to the **Lucene index** or **Transaction Log (tlog)**.

#### Symptoms

* **Hard Failure:** 4xx / 5xx on update
* **Soft Failure:** 200 OK but documents not searchable

#### Validation

**Schema Check**

```bash
curl "http://localhost:** solr_http_port** or ** solr_https_port**/solr/<collection>/schema/fields/<field>?wt=json"
```

**Field Types**

```bash
curl "http://localhost:** solr_http_port** or ** solr_https_port**/solr/<collection>/schema/fieldtypes?wt=json"
```

**Admin UI**

* Core Selector → Schema
* Check required fields and types

**Tlog Health**

* Ensure tlog directory writable
* If HDFS-backed, check NameNode latency

**Collect Configs**

```bash
solrctl instancedir --get <collection> /tmp/<collection>
```

---

### 7.4 Query Slowness / Performance Issues

* Capture full query and retry with `&debug=all` or for old SOLR versions`&debugQuery=true` as specified in https://solr.apache.org/guide/solr/latest/query-guide/common-query-parameters.html#debug-parameter
* JVM pressure:

```bash
jstat -gcutil <PID> 1s 10
```

* Review slow query and GC logs

---

### 7.5 Security (TLS / Kerberos / Auth)

```bash
openssl s_client -connect host:** solr_http_port** or ** solr_https_port** -showcerts
kinit -kt solr.keytab solr/_HOST@REALM
```

---

## 8. Known Production Failure Patterns & Fixes

### Unable to Locate Core

* Validate local core directories
* Compare with ZooKeeper `state.json`
* Restart Solr role if mismatch

### Solr-Infra Misuse

* Solr-Infra is **only** for Ranger & Atlas
* Custom collections require a separate Solr service

### 2 Billion Document Limit

* Delete old data or increase shards
* Use SPLITSHARD or recreate collection

Refer to https://lighthouse.cloudera.com/s/article/number-of-documents-in-the-index-cannot-exceed-2147483519

### Atlas Collections Missing

* Recreate `vertex_index`, `edge_index`, `fulltext_index`
* Validate `maxShardsPerNode`

### OOM / Spool Logs Growth

* Tune heap & direct memory
* Increase OS limits (fd, threads)
* Prefer Local FS (CDP ≥ 7.1.4)

---

## 9. Critical Operational Rules (Do Not Skip)

* ❌ Never delete instancedir before deleting collection
* ✅ Correct order:

```bash
solrctl collection --delete <collection>
solrctl instancedir --delete <collection>
```

* Restart Solr before recreating collections

---

## 10. Backup & Restore (Ranger Audits Example)

**Backup**

```bash
curl -k --negotiate -u : "http://<host>:** solr_http_port** or ** solr_https_port**/solr/admin/collections?action=BACKUP&collection=ranger_audits&name=rangerbak&location=hdfs:///tmp/solr_backup"
```

**Restore**

```bash
curl -k --negotiate -u : "http://<host>:** solr_http_port** or ** solr_https_port**/solr/admin/collections?action=RESTORE&collection=ranger_audits&name=rangerbak&location=hdfs:///tmp/solr_backup"
```

⚠️ Disable auditing during restore to avoid data loss.

---

## 11. Best Practices & References

* Separate Solr-Infra from custom Solr
* Keep shard counts reasonable
* Monitor document count per shard
* Always backup before destructive actions

---

## 12. Java GC / OOM / Memory Leak Issues (ENGESC Mandatory)

This section applies when Solr exhibits **GC pressure**, **OutOfMemoryErrors**, or **progressive memory growth**. These scenarios require **Engineering (ENG) involvement** and must meet the **ENGESC data collection standard**.

---

### 12.1 Typical Symptoms

* Repeated or long **Stop-The-World (STW)** GC pauses
* `java.lang.OutOfMemoryError` (Heap, Metaspace, Direct Memory)
* Solr process restarts or is killed by the OS OOM killer
* Severe query or indexing slowness without explicit Solr errors
* Memory usage continuously increases after restarts

---

### 12.2 Mandatory JVM & GC Validation

Run the following commands on the affected Solr role:

```bash
jcmd <PID> VM.flags
jcmd <PID> VM.system_properties
````

Verify:

* `-Xms` and `-Xmx` are equal
* Heap size is appropriate for shard count and workload
* GC algorithm is explicitly defined (G1GC recommended)

GC pressure check:

```bash
jstat -gcutil <PID> 1s 10
```

Indicators of concern:

* Old Gen consistently above 80%
* Frequent Full GCs
* GC time dominating application runtime

---

### 12.3 Mandatory ENGESC Evidence

The following artifacts **must be attached** to any ENG escalation involving GC, OOM, or memory leak concerns.

#### GC Logs

* Full `solr_gc.log`
* Must cover the full incident window

#### Thread Dumps (jstack)

Capture **at least three** thread dumps, spaced ~10 seconds apart:

```bash
jstack -l <PID> > jstack_1.out
sleep 10
jstack -l <PID> > jstack_2.out
sleep 10
jstack -l <PID> > jstack_3.out
```

Purpose:

* Correlate thread state with GC pauses
* Identify blocked or stalled execution paths

#### Heap Dump (HPROF)

Required for leak and retention analysis:

```bash
jmap -dump:format=b,file=heapdump.hprof <PID>
```

Note:

* Heap dumps are large; ensure sufficient disk space is available.

#### Live Object Histogram (Optional but Recommended)

```bash
jmap -histo:live <PID> > jmap_histo.out
```

Useful for identifying:

* Dominant object types
* Unexpected object retention

---

### 12.4 Collection-Specific Memory Investigation

If the issue is isolated to **specific collections or shards**, include the following:

* Affected collection name(s)
* Shard and replica details
* Whether the issue follows leadership movement

Extract collection configuration:

```bash
solrctl instancedir --get <collection> /tmp/<collection>
```

Attach:

* `managed-schema` or `schema.xml`
* `solrconfig.xml`

Rationale:

* High-cardinality fields
* Large stored fields
* Aggressive analyzers
* Heavy faceting or sorting
* Cache configurations

Valid schemas can still be **memory intensive at scale**.

---

### 12.5 Engineering Analysis Scope

Engineering uses the collected data to determine:

* Heap sizing and GC tuning issues
* Memory leaks or object retention patterns
* Query or indexing paths causing memory pressure
* Schema-driven memory amplification
* Thread-to-GC correlation

Incomplete JVM data will delay root cause analysis.

---

### 12.6 Immediate Escalation Criteria

Raise an ENGESC immediately if:

* OOM recurs after restarts
* GC consumes a significant portion of runtime
* Heap dump indicates continuous object growth
* Issue impacts **Solr-Infra (Ranger / Atlas)**
* Production availability or data integrity is at risk

---

## 13. Final Notes

This checklist provides a condensed guide for Frontline Engineers to follow before raising an Engineering Escalation (ENGESC). It focuses on the mandatory data points and rapid-triage steps required to meet the escalation quality bar.

---

### 🛑 Pre-Triage Checklist (Golden Rules)

* [ ] **Identify Mode:** Is it Standalone or SolrCloud?
* [ ] **Service Purpose:** Is this **Solr-Infra** (Ranger/Atlas only) or a custom Solr service?
* [ ] **Time Sync:** Run `timedatectl` to ensure nodes are synchronized (critical for Kerberos/Leaders).
* [ ] **Health First:** Do not perform blind restarts in SolrCloud without checking shard status.

---

### 📊 Baseline Collection (Must-Have Evidence)

| Category | Checkpoint | Command Snippet |
| --- | --- | --- |
| **Cluster State** | Shard/Replica health | `solrctl cluster --get-clusterstate /tmp/clusterstate.out` |
| **Resources** | OS Limits & RAM | `free -m`, `df -h`, and `ulimit -a` |
| **JVM Info** | Heap settings | `jcmd <PID> VM.flags` |
| **Connectivity** | Local Solr Port | `curl -I http://localhost:<port>/solr/` |
| **ZooKeeper** | Quorum Health | `echo ruok | nc <zk_host> 2181` |

---

### 📂 Storage & Diagnostics

* [ ] **Determine Backend:** Check `dataDir` in `clusterstate.out`.
* If **HDFS** (`hdfs://...`): Run `hdfs dfsadmin -report` to check for NameNode/DataNode issues.
* If **Local** (`/var/lib/solr`): Run `df -h` to check for full disks.


* [ ] **Global Bundle:** Collect via **CM → Administration → Collect Diagnostic Data** (Globally).

---

### 🛠 Scenario-Specific Rapid Triage

#### Indexing Failures (Write Impact)

* [ ] **Schema Validation:** Compare failing fields against the Schema API:
`curl "http://localhost:<port>/solr/<coll>/schema/fields/<field>?wt=json"`
* [ ] **Config Check:** Extract the collection configuration:
`solrctl instancedir --get <collection> /tmp/<collection>`
* [ ] **Document Limits:** Ensure shard count hasn't exceeded the **2.1B document limit**.

#### Query Slowness (Read Impact)

* [ ] **Explain Plan:** Retry the query with `&debug=all` or for old SOLR versions`&debugQuery=true`.
* [ ] **GC Pressure:** Check for "Stop-the-World" pauses: `jstat -gcutil <PID> 1s 10`.
* [ ] Make use if Cloudera Manager charts for SOLR servers/service and collections statistics.

#### Service Down

* [ ] **Process Check:** Is Solr actually running? `ps -Af | grep solr`.
* [ ] **Startup Logs:** Check `journalctl -u solr` and `solr.log` for initialization errors.

---

### 📤 Mandatory ESC Packet (Final Review)

Before raising the ESC, verify you have attached:

1. [ ] `/tmp/clusterstate.out`
2. [ ] Cloudera Manager Global Diagnostic Bundle
3. [ ] Storage Type confirmation (Local vs. HDFS)
4. [ ] Full `solr.log` and `solr_gc.log`
5. [ ] Clear list of **Actions Already Taken**
