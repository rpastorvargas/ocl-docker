awk -F'[:/]' '(($4 == "docker") && (lastId != $NF)) { lastId = $NF; print $NF; }' /proc/self/cgroup
