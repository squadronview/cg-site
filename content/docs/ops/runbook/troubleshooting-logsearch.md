---
menu:
  docs:
    parent: runbook

title: Troubleshooting Logsearch
---
## Overview
ElasticSearch is generally resilient when configured with multiple primary and  data nodes according to best practices. Typical issues observed are file systems filling up and undersized instances.

## Debugging unallocated shards

Shard allocation is disabled on elasticsearch [drain](https://github.com/cloudfoundry-community/logsearch-boshrelease/blob/develop/jobs/elasticsearch/templates/bin/drain.erb). Check that allocation was reenabled:

```bash
curl localhost:9200/_cluster/settings?pretty
```

If necessary, reenable allocation:

```bash
curl -X PUT localhost:9200/_cluster/settings -d '{"transient":{"cluster.routing.allocation.enable":"all"}}'
```

If reenabling allocation doesn't restore the cluster, [manually reassigning unallocated shards may be necessary]({{< ref "#force-reallocation" >}})


## Debugging queue memory usage
High memory usage on queue nodes is an indicator that logs are backing up in redis and not reaching ElasticSearch. [This diagram](https://github.com/cloudfoundry-community/logsearch-boshrelease/blob/develop/docs/architecture.md) illustrates how data flows through the queue to reach ElasticSearch.

### Ensure the high memory usage is from redis and not some other process
Login to the queue node, examine the list of processes and validate it is redis using the majority of memory.

Check the number of log messages waiting in redis:
```bash
/var/vcap/packages/redis/bin/redis-cli llen logsearch
```
Normally this number should be 0. If it is greater than 0 and climbing then logs are not reaching ElasticSearch and accumulating in memory.

### Check cluster health
Log into any `elasticsearch_*` node and [check the cluster health]({{< ref "#check-cluster-health">}}). If the cluster state is not green or has a high number of pending tasks then ElasticSearch cannot accept data from the redis queue.  Resolve the issues with the ElasticSearch cluster and once it's state is green, the queue should be begin to drain.

### Check parser health
If the cluster state is green, then validate the parsers are healthly:  Log into each parser node and check the system health. Review the logs for the logstash instance running on the parser which are stored in `/var/vcap/sys/log/parser/`. Restart the parsers if needed by running `monit restart parser`.

### Continue to monitor memory usage and redis queue
Once the issue has been resolved, continue to monitor the memory usage and number of messages waiting in redis and ensure both are decreasing.  Once the redis queue length has reached 0 the system has returned to normal operation.


## Reindexing data from S3

A copy of all data received by the logsearch ingestors is archived in S3.  This data can be used to restore logsearch to a known good state if the data in ElasticSearch is corrupted or lost.

### Create a custom logstash.conf for the restore operation

Log into any `parser` node and make a copy of it's current logstash configuration.
```bash
# these example commands use the bosh v2 cli
bosh -d logsearch ssh parser/0

cp /var/vcap/jobs/parser/config/logstash.conf /tmp/logstash-restore.conf
```

Edit the `/tmp/logstash-restore.conf` and make the following changes:

#### Remove the `redis` input and replace it with an `s3` input
```
  s3 {
    bucket => ":bucket:"
    region => ":region:"

    type => "syslog"
    sincedb_path => "/tmp/s3_import.sincedb"
  }

```

The values for `:bucket:` and `:region:` can be found in [cg-provision](https://github.com/18F/cg-provision/blob/master/terraform/modules/cloudfoundry/buckets.tf#L25-L30) or retrieved from the bosh manifest:
```bash
spruce merge --cherry-pick properties.logstash_ingestor.outputs <(bosh -d logsearch manifest)`
```

When run with default configuration the S3 input plugin will reindex ALL data in the bucket. To reindex a specific subset of data pass [additional options to the s3 input plugin](https://www.elastic.co/guide/en/logstash/2.3/plugins-inputs-s3.html).

For example, to reindex only data from November 15th, 1968 use an `exclude_pattern` to exclude all files EXCEPT those that match that date: `exclude_pattern => "^((?!1968-11-15).)*$"`.


#### Disable the timecop filter

The default Logsearch-for-CloudFoundry configuration will drop any messages older than 24 hours. When reindexing older data this sanity check needs to be disabled.

To disable the timecop filter set the environment variable `TIMECOP_REJECT_LESS_THAN_HOURS` to match the desired rentention policy:
```bash
export TIMECOP_REJECT_LESS_THAN_HOURS=$((180 * 24))
```

or remove this section from `/tmp/logstash-restore.conf`

```
# Unparse logs with @timestamps outside the configured acceptable range
ruby {
  code => '
    max_hours = (ENV["TIMECOP_REJECT_GREATER_THAN_HOURS"] || 1).to_i
    min_hours = (ENV["TIMECOP_REJECT_LESS_THAN_HOURS"] || 24).to_i
    max_timestamp = Time.now + 60 * 60 * max_hours
    min_timestamp = Time.new - 60 * 60 * min_hours
    if event["@timestamp"] > max_timestamp || event["@timestamp"] < min_timestamp
      event.overwrite( LogStash::Event.new( {
        "tags" => event["tags"] << "fail/timecop",
        "invalid_fields" => { "@timestamp" => event["@timestamp"] },
        "@raw" => event["@raw"],
        "@source" => event["@source"],
        "@shipper" => event["@shipper"]
      } ) )
    end
  '
}
```

#### Configure logstash to index log entries by the date in the file and not the current time.

Using the default configuration logstash will reindex documents into an index for the current day. To avoid this configure logstash to generate indexes based on the timestamps in the data being imported from S3.


Add this stanza to the end of the `filters` section in `/tmp/logstash-restore.conf`

```
mutate {
        add_field => {"index-date" => "%{@timestamp}"}
}
date {
    match => [ "index-date", "ISO8601" ]
    timezone => "UTC"
    add_field => { "[@metadata][index-date]" => "%{+YYYY.MM.dd}" }

}
mutate {
  remove_field => "index-date"
}

```

Edit the `output` section in `/tmp/logstash-restore.conf` and change `index` to:
```
index => "logs-%{@index_type}-%{[@metadata][index-date]}"
```

### Start the reindexing
Run logstash passing in your edited configuration file:

```bash
/var/vcap/packages/logstash/bin/logstash agent -f /tmp/logstash-restore.config
```

### Monitor progress

Logstash will run forever once started. Monitor the progress of the reindex, and stop logstash once the data has been reindexed. Progress can be monitored by tailing the sincedb file which logstash will update after each file it processes.

```bash
tail -f /tmp/s3_import.sincedb
```

## Other Useful ElasticSearch commands

### Check Disk Space
```shell
# df -h
```
### Check Allocation Status
```shell
curl -s 'localhost:9200/_cat/allocation?v'
```

### Check Cluster Settings
```shell
curl 'http://localhost:9200/_cluster/settings?pretty'
```

### List Indices
```shell
curl -s 'localhost:9200/_cat/indices'
```

### Check Cluster Health
```shell
curl -XGET 'http://localhost:9200/_cluster/health?pretty=true'
```

### Isolate Unassigned
```shell
curl -XGET http://localhost:9200/_cat/shards | grep UNASSIGNED | tee unassigned-shards
```

### Force Reallocation
```shell
curl -XGET http://localhost:9200/_cat/shards | grep UNASSIGNED > unassigned-shards
for line in `cat unassigned-shards | awk '{print $1 ":" $2}'`; do index=`echo $line | awk -F: '{print $1}'`; \
    shard=`echo $line | awk -F: '{print $2}'`; curl -XPOST 'localhost:9200/_cluster/reroute' -d "{
        \"commands\" : [ {
              \"allocate\" : {
                  \"index\" : \"$index\",
                  \"shard\" : \"$shard\",
                  \"node\" : \"elasticsearch_data/7\",
                  \"allow_primary\" : true
              }
            }
        ]
    }"; sleep 5; done
```
