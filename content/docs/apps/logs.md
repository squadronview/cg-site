---
menu:
  docs:
    parent: apps
title: Logs
---

For logs to be captured by cloud.gov, your application should be writing them to `STDOUT`/`STDERR`, rather than a log file – see the framework-specific guidance in the menu.

## Current logs

The most direct way to view events related to your application through the deploy process is:

```bash
cf logs APPNAME
```

Used alone, `cf logs` will tail the combined stream of logs from each Cloud Foundry service involved in your application deploy. Running with the `--recent` flag will stream the entire logs buffer for your app.

```bash
cf logs APPNAME --recent
```

### Example log

  	2015-03-16T17:37:47.82-0400 [DEA/1]      OUT Starting app instance (index 0) with guid GUID
  	2015-03-16T17:37:50.85-0400 [DEA/1]      ERR Instance (index 0) failed to start accepting connections
  	2015-03-16T17:37:53.54-0400 [API/0]      OUT App instance exited with guid GUID0 payload: {"cc_partition"=>"default", "droplet"=>"GUID0", "version"=>"GUID1", "instance"=>"GUID2", "index"=>0, "reason"=>"CRASHED", "exit_status"=>127, "exit_description"=>"failed to accept connections within health check timeout", "crash_timestamp"=>1426541870}

### See also

* [Information about the log format](https://docs.cloudfoundry.org/devguide/deploy-apps/streaming-logs.html)
* [Viewing your application's logs](https://docs.cloudfoundry.org/devguide/deploy-apps/streaming-logs.html#view)

For other helpful cf CLI troubleshooting commands, including `cf events APP-NAME`, see [this Cloud Foundry list](https://docs.cloudfoundry.org/devguide/deploy-apps/troubleshoot-app-health.html#cf-commands).

### Error messages

If you receive `Error dialing trafficcontroller server`:

* This can be caused by having an old version of the `cf` CLI. Try `cf -v` and see if it's older than the [latest version](https://github.com/cloudfoundry/cli/releases). If it is, [install the latest version]({{< relref "docs/getting-started/setup.md#set-up-the-command-line" >}}) and try again.
* This can also be caused by outbound connections to port 443 being blocked on your network. Often in these situations your organization will require that your web browser use a proxy for outbound access to https:// sites. You can [set up the `cf` CLI to use that proxy as well](https://github.com/18F/cg-site/edit/error-info/content/docs/apps/logs.md?pr=/18F/cg-site/pull/829). Alternatively, talk to your network administrators about opening that port, or try a different network. 

## Web-based logs with historic log data

To view and search your logs on the web, including historic log data, visit: 

https://logs.fr.cloud.gov

Logs are currently retained for 180 days, and you will only see data for applications deployed within the [orgs](http://docs.cloudfoundry.org/concepts/roles.html#orgs) and [spaces](http://docs.cloudfoundry.org/concepts/roles.html#spaces) where you have access.

After logging in, you'll see the App Overview dashboard.

![App Overview dashboard](/img/app-overview.png)

The default time period is "Last 15 minutes". To change the time period of data that you are viewing, or to turn on auto-refresh, click on the time period in the top right menu.

![Time period selection](/img/time-period.png)

You can also view several dashboards that present different visualizations of your log data. You can select these by going to "Dashboard" at left and clicking "Open" in the top toolbar.

![Select dashboards](/img/select-dashboard.png)

These visualizations are provided via Kibana, which has a [user guide](https://www.elastic.co/guide/en/kibana/current/index.html) that explains more about how to use it and customize your views.

## How to automatically copy your logs elsewhere

If you want to set up your own storage for your application logs, you can set up [a "log drain" service](https://docs.cloudfoundry.org/devguide/services/log-management.html) that sends the logs to S3 or your preferred location.

## Troubleshooting missing logs

Not seeing the logs you expect? Here are a few questions to ask yourself to help identify the problem.

### Logs front end ([logs.fr.cloud.gov](https://logs.fr.cloud.gov))

1. Check the time period in the upper right corner, since the default is "Last 15 minutes". You may need to expand that time period to hours or days.
1. Check [cloud.gov status](https://cloudgov.statuspage.io/) to see if the the logs front end is under scheduled maintenance.
