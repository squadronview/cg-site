---
menu:
  main:
    parent: pricing
title: What's Included
weight: 10
---

All cloud.gov access packages include the following:

- API access, CLI access, Web UI access
- Documentation/tutorial material (including continuing development)
- Web-based support during business hours (platform available 24/7, problems addressed as-possible).
- Allocation of underlying IaaS (AWS) instances
- OS security updates and regular hardening of OS image
- Regular updates to platform security
- Network security
- ATO-ready documentation of system components (compliance-masonry form)
- Regular scanning for infrastructure-level vulnerabilities/misconfiguration
- Regular security updates for supported buildpacks (run `cf buildpacks` for an up-to-date list and version info):
  + staticfile_buildpack
  + java_buildpack
  + ruby_buildpack
  + nodejs_buildpack
  + go_buildpack
  + python_buildpack
  + php_buildpack
  + binary_buildpack
- Self-service management of spaces and users within an organization
- Platform maintenance and managed service expansion overhead

FISMA Low and FISMA Moderate access packages include:

- Routes for delegated DNS (eg *appname*.*subdomain*.\*.gov)

The following are not currently available:

- Out-of-business-hours web/mail support, IM support, or phone support
- Consulting (advice, development, etc. that is custom or specific to your application/system context)
- Application-level scanning/monitoring/alerting/analytics/scaling
- Agency-specific ATO support for non-18F applications
