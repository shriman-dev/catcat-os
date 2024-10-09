#!/bin/bash
# Tweaking kernel parameters for response time consistency # archwiki
tune-response-time() {
echo 1 | tee /proc/sys/kernel/sched_autogroup_enabled
echo 3000 | tee /proc/sys/kernel/sched_cfs_bandwidth_slice_us
echo 0 | tee /proc/sys/vm/compaction_proactiveness
echo 1048576 | tee /proc/sys/vm/min_free_kbytes
echo 1 | tee /proc/sys/vm/page_lock_unfairness
echo 10 | tee /proc/sys/vm/swappiness
echo 1 | tee /proc/sys/vm/watermark_boost_factor
echo 500 | tee /proc/sys/vm/watermark_scale_factor
echo 0 | tee /proc/sys/vm/zone_reclaim_mode
echo 3000000 | tee /sys/kernel/debug/sched/base_slice_ns
echo 500000 | tee /sys/kernel/debug/sched/migration_cost_ns
echo 8 | tee /sys/kernel/debug/sched/nr_migrate
echo 5 | tee /sys/kernel/mm/lru_gen/enabled
echo always | tee /sys/kernel/mm/transparent_hugepage/enabled
echo advise | tee /sys/kernel/mm/transparent_hugepage/shmem_enabled
echo never | tee /sys/kernel/mm/transparent_hugepage/defrag
echo 0 | tee /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
}

[ "$1" == "tune" ] && tune-response-time

auto-performance-powersave() {
echo ${1/powersave/power-saver}
[ "${1/powersave/power-saver}" == "$( powerprofilesctl get )" ] || powerprofilesctl set ${1/powersave/power-saver}
#echo performance | tee /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference
scaling_governor='/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
power_policy='/sys/module/pcie_aspm/parameters/policy'
[ "$1" == "$( cat $scaling_governor | head -n1 )" ] || echo $1 | tee $scaling_governor
cat $power_policy | grep -o '\['$1'\]' || echo $1 | tee $power_policy
}

if upower -d | grep -i 'state' | grep -i 'discharging' ; then
    auto-performance-powersave powersave
else
    auto-performance-powersave performance
fi





