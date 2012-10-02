#!/bin/bash

# demo 1:
# - all servers have SBR
# - all servers are in-sync
. /usr/local/demos/create-sandboxes.inc.sh

pause_msg "We'll now stop replication in slave-1, and use it as \"upgraded\" server
to demonstrate pt-online-schema-change and pt-upgrade.  We'll see pt-osc effectively
replicating to the other nodes of the replication setup (master-passive, slave-2)
and we'll keep slave-1 as the one where upgrade is being tested.)"

# $master_active/use -v -t -e "STOP SLAVE";
# $master_passive/use -v -t -e "STOP SLAVE";
$slave_1/use -v -t -e "STOP SLAVE";


slow_log=$(get_slow_log_filename "master-active")
pt-upgrade --query "SELECT DISTINCT c FROM sbtest1 WHERE id BETWEEN 443733 AND 443733+999 ORDER BY c" h=master-active,P=13306,u=demo,p=demo,D=sbtest h=slave-1,P=13307,u=demo,p=demo,D=sbtest
