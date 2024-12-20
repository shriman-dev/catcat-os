import Gio from 'gi://Gio';
import GObject from 'gi://GObject';
import GLib from 'gi://GLib';
import NM from 'gi://NM';
import { gettext as _ } from 'resource:///org/gnome/shell/extensions/extension.js';
import { File } from './file.js';
import { NumTopProcs } from './monitor.js';
Gio._promisify(Gio.File.prototype, 'enumerate_children_async');
Gio._promisify(Gio.FileEnumerator.prototype, 'next_files_async');
export const SummaryIntervalDefault = 2.5; // in seconds
export const DetailsInterval = 5; // in seconds
export const MaxHistoryLen = 50;
const SECTOR_SIZE = 512; // in bytes
const RE_MEM_INFO = /:\s+(\d+)/;
const RE_NET_DEV = /^\s*(\w+):/;
const RE_NET_ACTIVITY = /:\s*(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)/;
const RE_DISK_STATS = /^\s*\d+\s+\d+\s+(\w+)\s+\d+\s+\d+\s+(\d+)\s+\d+\s+\d+\s+\d+\s+(\d+)/;
const RE_NVME_DEV = /^nvme\d+n\d+$/;
const RE_BLOCK_DEV = /^[^\d]+$/;
const RE_CMD = /\/*[^\s]*\/([^\s]*)/;
export const Vitals = GObject.registerClass({
    GTypeName: 'Vitals',
    Properties: {
        uptime: GObject.ParamSpec.int('uptime', 'System uptime', 'System uptime in seconds', GObject.ParamFlags.READWRITE, 0, 0, 0),
        'cpu-usage': GObject.ParamSpec.int('cpu-usage', 'CPU usage', 'Proportion of CPU usage as a value between 0 - 100', GObject.ParamFlags.READWRITE, 0, 100, 0),
        'cpu-model': GObject.ParamSpec.string('cpu-model', 'CPU model', 'CPU model', GObject.ParamFlags.READWRITE, ''),
        'cpu-freq': GObject.ParamSpec.int('cpu-freq', 'CPU frequency', 'Average CPU frequency across all cores', GObject.ParamFlags.READWRITE, 0, 0, 0),
        'cpu-temp': GObject.ParamSpec.int('cpu-temp', 'CPU temperature', 'CPU temperature in degrees Celsius', GObject.ParamFlags.READWRITE, 0, 0, 0),
        'cpu-history': GObject.ParamSpec.string('cpu-history', 'CPU usage history', 'CPU usage history', GObject.ParamFlags.READWRITE, ''),
        'cpu-top-procs': GObject.ParamSpec.string('cpu-top-procs', 'CPU top processes', 'Top CPU-consuming processes', GObject.ParamFlags.READWRITE, ''),
        'ram-usage': GObject.ParamSpec.int('ram-usage', 'RAM usage', 'Proportion of RAM usage as a value between 0 - 100', GObject.ParamFlags.READWRITE, 0, 100, 0),
        'ram-size': GObject.ParamSpec.int('ram-size', 'RAM size', 'Size of system memory in GB', GObject.ParamFlags.READWRITE, 0, 0, 0),
        'ram-size-free': GObject.ParamSpec.int('ram-size-free', 'RAM size free', 'Size of available system memory in GB', GObject.ParamFlags.READWRITE, 0, 0, 0),
        'swap-usage': GObject.ParamSpec.int('swap-usage', 'Swap usage', 'Proportion of swap usage as a value between 0 - 100', GObject.ParamFlags.READWRITE, 0, 100, 0),
        'swap-size': GObject.ParamSpec.int('swap-size', 'Swap size', 'Size of swap space in GB', GObject.ParamFlags.READWRITE, 0, 0, 0),
        'swap-size-free': GObject.ParamSpec.int('swap-size-free', 'Swap size free', 'Size of available swap space in GB', GObject.ParamFlags.READWRITE, 0, 0, 0),
        'mem-history': GObject.ParamSpec.string('mem-history', 'Memory usage history', 'Memory usage history', GObject.ParamFlags.READWRITE, ''),
        'mem-top-procs': GObject.ParamSpec.string('mem-top-procs', 'Memory top processes', 'Top memory-consuming processes', GObject.ParamFlags.READWRITE, ''),
        'net-recv': GObject.ParamSpec.int('net-recv', 'Network bytes received', 'Number of bytes recently received via network interfaces', GObject.ParamFlags.READWRITE, 0, 0, 0),
        'net-sent': GObject.ParamSpec.int('net-sent', 'Network bytes sent', 'Number of bytes recently sent via network interfaces', GObject.ParamFlags.READWRITE, 0, 0, 0),
        'net-recv-total': GObject.ParamSpec.int('net-recv-total', 'Total network bytes received', 'Number of bytes received via network interfaces', GObject.ParamFlags.READWRITE, 0, 0, 0),
        'net-sent-total': GObject.ParamSpec.int('net-sent-total', 'Total network bytes sent', 'Number of bytes sent via network interfaces', GObject.ParamFlags.READWRITE, 0, 0, 0),
        'net-history': GObject.ParamSpec.string('net-history', 'Network activity history', 'Network activity history', GObject.ParamFlags.READWRITE, ''),
        'disk-read': GObject.ParamSpec.int('disk-read', 'Bytes read from disk', 'Number of bytes recently read from disk', GObject.ParamFlags.READWRITE, 0, 0, 0),
        'disk-wrote': GObject.ParamSpec.int('disk-wrote', 'Bytes written to disk', 'Number of bytes recently written to disk', GObject.ParamFlags.READWRITE, 0, 0, 0),
        'disk-read-total': GObject.ParamSpec.int('disk-read-total', 'Total bytes read from disk', 'Number of bytes read from disk since system start', GObject.ParamFlags.READWRITE, 0, 0, 0),
        'disk-wrote-total': GObject.ParamSpec.int('disk-wrote-total', 'Total bytes written to disk', 'Number of bytes written to disk since system start', GObject.ParamFlags.READWRITE, 0, 0, 0),
        'disk-history': GObject.ParamSpec.string('disk-history', 'Disk activity history', 'Disk activity history', GObject.ParamFlags.READWRITE, ''),
        'disk-top-procs': GObject.ParamSpec.string('disk-top-procs', 'Disk activity top processes', 'Top processes in terms of disk activity', GObject.ParamFlags.READWRITE, ''),
        'summary-interval': GObject.ParamSpec.float('summary-interval', 'Refresh interval for the summary loop', 'Refresh interval for the summary loop, in seconds', GObject.ParamFlags.READWRITE, 0, 0, 0),
    },
}, class Vitals extends GObject.Object {
    gsettings;
    procs = new Map();
    cpuModel;
    cpuUsageHistory = new Array(MaxHistoryLen);
    cpuState;
    memInfo;
    memUsageHistory = new Array(MaxHistoryLen);
    netState;
    netActivityHistory = new Array(MaxHistoryLen);
    diskState;
    diskActivityHistory = new Array(MaxHistoryLen);
    props = new Properties();
    summaryLoop = 0;
    detailsLoop = 0;
    showCpu;
    showMem;
    showNet;
    showDisk;
    netDev;
    netDevs;
    settingSignals;
    nm;
    constructor(model, gsettings) {
        super();
        this.gsettings = gsettings;
        this.cpuModel = model;
        this.cpuState = new CpuState(model.cores, model.tempMonitors.size);
        this.memInfo = new MemInfo();
        this.netState = new NetDevState();
        this.nm = null;
        for (let i = 0; i < this.netActivityHistory.length; i++) {
            this.netActivityHistory[i] = new NetActivity();
        }
        this.diskState = new DiskState();
        for (let i = 0; i < this.diskActivityHistory.length; i++) {
            this.diskActivityHistory[i] = new DiskActivity();
        }
        this.settingSignals = new Array(0);
        this.summary_interval =
            SummaryIntervalDefault * refreshRateModifier(this.gsettings);
        let id = this.gsettings.connect('changed::refresh-rate', (settings) => {
            this.summary_interval =
                SummaryIntervalDefault * refreshRateModifier(settings);
            this.stop();
            this.start();
        });
        this.settingSignals.push(id);
        this.showCpu = gsettings.get_boolean('show-cpu');
        id = this.gsettings.connect('changed::show-cpu', (settings) => {
            this.showCpu = settings.get_boolean('show-cpu');
        });
        this.settingSignals.push(id);
        this.showMem = gsettings.get_boolean('show-mem');
        id = this.gsettings.connect('changed::show-mem', (settings) => {
            this.showMem = settings.get_boolean('show-mem');
        });
        this.settingSignals.push(id);
        this.showNet = gsettings.get_boolean('show-net');
        id = this.gsettings.connect('changed::show-net', (settings) => {
            this.showNet = settings.get_boolean('show-net');
        });
        this.settingSignals.push(id);
        this.showDisk = gsettings.get_boolean('show-disk');
        id = this.gsettings.connect('changed::show-disk', (settings) => {
            this.showDisk = settings.get_boolean('show-disk');
        });
        this.settingSignals.push(id);
        this.netDev = gsettings.get_string('network-device');
        if (this.netDev === _('Automatic')) {
            this.netDev = '';
        }
        id = this.gsettings.connect('changed::network-device', (settings) => {
            this.netDev = settings.get_string('network-device');
            if (this.netDev === _('Automatic')) {
                this.netDev = '';
            }
        });
        this.settingSignals.push(id);
        this.netDevs = new Array();
        NM.Client.new_async(null, (obj, result) => {
            if (!obj) {
                console.error('[TopHat] obj is null');
                return;
            }
            this.nm = NM.Client.new_finish(result);
            if (!this.nm) {
                console.error('[TopHat] client is null');
                return;
            }
            this.nm.connect('notify::devices', (nm) => {
                this.updateNetDevices(nm);
            });
            this.updateNetDevices(this.nm);
        });
    }
    start() {
        this.readSummaries();
        this.readDetails();
        if (this.summaryLoop === 0) {
            this.summaryLoop = GLib.timeout_add_seconds(GLib.PRIORITY_LOW, this.summary_interval, () => this.readSummaries());
        }
        if (this.detailsLoop === 0) {
            this.detailsLoop = GLib.timeout_add_seconds(GLib.PRIORITY_LOW, DetailsInterval, () => this.readDetails());
        }
    }
    stop() {
        if (this.summaryLoop > 0) {
            GLib.source_remove(this.summaryLoop);
            this.summaryLoop = 0;
        }
        if (this.detailsLoop > 0) {
            GLib.source_remove(this.detailsLoop);
            this.detailsLoop = 0;
        }
    }
    // readSummaries queries all of the info needed by the topbar widgets
    readSummaries() {
        // console.time('readSummaries()');
        if (this.showCpu) {
            this.loadStat();
        }
        if (this.showMem) {
            this.loadMeminfo();
        }
        if (this.showNet) {
            this.loadNetDev();
        }
        if (this.showDisk) {
            this.loadDiskstats();
        }
        // console.timeEnd('readSummaries()');
        return true;
    }
    // readDetails queries the info needed by the monitor menus
    readDetails() {
        // console.time('readDetails()');
        if (this.showCpu) {
            this.loadUptime();
            this.loadTemps();
            this.loadFreqs();
            this.loadStatDetails();
        }
        if (this.showCpu || this.showMem || this.showDisk) {
            this.loadProcessList();
        }
        // console.timeEnd('readDetails()');
        return true;
    }
    loadUptime() {
        const f = new File('/proc/uptime');
        f.read()
            .then((line) => {
            this.uptime = parseInt(line.substring(0, line.indexOf(' ')));
            // console.log(`[TopHat] uptime = ${this.uptime}`);
        })
            .catch((e) => {
            console.warn(`[TopHat] error in loadUptime(): ${e}`);
        });
    }
    loadStat() {
        const f = new File('/proc/stat');
        f.read()
            .then((contents) => {
            const lines = contents.split('\n');
            const usage = new CpuUsage(this.cpuModel.cores);
            lines.forEach((line) => {
                if (line.startsWith('cpu')) {
                    const re = /^cpu(\d*)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/;
                    const m = line.match(re);
                    if (m && !m[1]) {
                        // These are aggregate CPU statistics
                        const usedTime = parseInt(m[2]) + parseInt(m[4]);
                        const idleTime = parseInt(m[5]);
                        this.cpuState.update(usedTime, idleTime);
                        usage.aggregate = this.cpuState.usage();
                    }
                    else if (m) {
                        // These are per-core statistics
                        const core = parseInt(m[1]);
                        const usedTime = parseInt(m[2]) + parseInt(m[4]);
                        const idleTime = parseInt(m[5]);
                        this.cpuState.updateCore(core, usedTime, idleTime);
                        usage.core[core] = this.cpuState.coreUsage(core);
                    }
                }
                if (this.cpuUsageHistory.unshift(usage) > MaxHistoryLen) {
                    this.cpuUsageHistory.pop();
                }
            });
            this.cpu_usage = usage.aggregate;
            this.cpu_history = this.hashCpuHistory();
        })
            .catch((e) => {
            console.warn(`[TopHat] error in loadStat(): ${e}`);
        });
    }
    loadStatDetails() {
        const f = new File('/proc/stat');
        f.read()
            .then((contents) => {
            const lines = contents.split('\n');
            for (const line of lines) {
                if (line.startsWith('cpu')) {
                    const re = /^cpu(\d*)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/;
                    const m = line.match(re);
                    if (m && !m[1]) {
                        // These are aggregate CPU statistics
                        const usedTime = parseInt(m[2]) + parseInt(m[4]);
                        const idleTime = parseInt(m[5]);
                        this.cpuState.updateDetails(usedTime + idleTime);
                        break;
                    }
                }
            }
        })
            .catch((e) => {
            console.warn(`[TopHat] error in loadStatDetails(): ${e}`);
        });
    }
    loadMeminfo() {
        const f = new File('/proc/meminfo');
        f.read()
            .then((contents) => {
            const lines = contents.split('\n');
            const usage = new MemUsage();
            lines.forEach((line) => {
                if (line.startsWith('MemTotal:')) {
                    this.memInfo.total = readKb(line);
                }
                else if (line.startsWith('MemAvailable:')) {
                    this.memInfo.available = readKb(line);
                }
                else if (line.startsWith('SwapTotal:')) {
                    this.memInfo.swapTotal = readKb(line);
                }
                else if (line.startsWith('SwapFree:')) {
                    this.memInfo.swapAvailable = readKb(line);
                }
            });
            usage.usedMem =
                (this.memInfo.total - this.memInfo.available) / this.memInfo.total;
            usage.usedSwap =
                (this.memInfo.swapTotal - this.memInfo.swapAvailable) /
                    this.memInfo.swapTotal;
            if (this.memUsageHistory.unshift(usage) > MaxHistoryLen) {
                this.memUsageHistory.pop();
            }
            this.ram_usage = usage.usedMem;
            this.ram_size = this.memInfo.total * 1024;
            this.ram_size_free = this.memInfo.available * 1024;
            this.swap_usage = usage.usedSwap;
            this.swap_size = this.memInfo.swapTotal * 1024;
            this.swap_size_free = this.memInfo.swapAvailable * 1024;
            this.mem_history = this.hashMemHistory();
        })
            .catch((e) => {
            console.warn(`[TopHat] error in loadMeminfo(): ${e}`);
        });
    }
    loadNetDev() {
        const f = new File('/proc/net/dev');
        f.read()
            .then((contents) => {
            const lines = contents.split('\n');
            let bytesRecv = 0;
            let bytesSent = 0;
            lines.forEach((line) => {
                let m = line.match(RE_NET_DEV);
                if (m) {
                    const dev = m[1];
                    if ((this.netDev && this.netDev === dev) ||
                        (!this.netDev && this.netDevs.indexOf(dev) >= 0)) {
                        m = line.match(RE_NET_ACTIVITY);
                        if (m) {
                            bytesRecv += parseInt(m[1]);
                            bytesSent += parseInt(m[2]);
                        }
                    }
                }
            });
            this.netState.update(bytesRecv, bytesSent);
            this.net_recv_total = bytesRecv;
            this.net_sent_total = bytesSent;
            const netActivity = new NetActivity();
            netActivity.bytesRecv = this.netState.recvActivity();
            netActivity.bytesSent = this.netState.sentActivity();
            if (this.netActivityHistory.unshift(netActivity) > MaxHistoryLen) {
                this.netActivityHistory.pop();
            }
            this.net_recv = netActivity.bytesRecv;
            this.net_sent = netActivity.bytesSent;
            this.net_history = this.hashNetHistory();
        })
            .catch((e) => {
            console.warn(`[TopHat] error in loadNetDev(): ${e}`);
        });
    }
    loadDiskstats() {
        const f = new File('/proc/diskstats');
        f.read()
            .then((contents) => {
            const lines = contents.split('\n');
            let bytesRead = 0;
            let bytesWritten = 0;
            lines.forEach((line) => {
                const m = line.match(RE_DISK_STATS);
                if (m) {
                    const dev = m[1];
                    if (dev.startsWith('loop')) {
                        return;
                    }
                    if (dev.startsWith('nvme')) {
                        const dm = dev.match(RE_NVME_DEV);
                        if (dm) {
                            bytesRead += parseInt(m[2]) * SECTOR_SIZE;
                            bytesWritten += parseInt(m[3]) * SECTOR_SIZE;
                        }
                    }
                    else {
                        const dm = dev.match(RE_BLOCK_DEV);
                        if (dm) {
                            bytesRead += parseInt(m[2]) * SECTOR_SIZE;
                            bytesWritten += parseInt(m[3]) * SECTOR_SIZE;
                        }
                    }
                }
            });
            this.diskState.update(bytesRead, bytesWritten);
            const diskActivity = new DiskActivity();
            diskActivity.bytesRead = this.diskState.readActivity();
            diskActivity.bytesWritten = this.diskState.writeActivity();
            if (this.diskActivityHistory.unshift(diskActivity) > MaxHistoryLen) {
                this.diskActivityHistory.pop();
            }
            this.disk_read = diskActivity.bytesRead;
            this.disk_wrote = diskActivity.bytesWritten;
            this.disk_read_total = bytesRead;
            this.disk_wrote_total = bytesWritten;
            this.disk_history = this.hashDiskHistory();
        })
            .catch((e) => {
            console.warn(`[TopHat] error in loadDiskStats(): ${e}`);
        });
    }
    loadTemps() {
        this.cpuModel.tempMonitors.forEach((file, i) => {
            const f = new File(file);
            f.read()
                .then((contents) => {
                this.cpuState.temps[i] = parseInt(contents);
                if (i === 0) {
                    this.cpu_temp = this.cpuState.temps[i];
                }
            })
                .catch((e) => {
                console.warn(`[TopHat] error in loadTemp(): ${e}`);
            });
        });
    }
    loadFreqs() {
        const f = new File('/proc/cpuinfo');
        f.read()
            .then((contents) => {
            const blocks = contents.split('\n\n');
            let freq = 0;
            for (const block of blocks) {
                const m = block.match(/cpu MHz\s*:\s*(\d+)/);
                if (m) {
                    freq += parseInt(m[1]);
                }
            }
            this.cpu_freq = freq / this.cpuModel.cores;
        })
            .catch((e) => {
            console.warn(`[TopHat] error in loadFreqs(): ${e}`);
        });
    }
    async loadProcessList() {
        const curProcs = new Map();
        const directory = Gio.File.new_for_path('/proc/');
        try {
            const iter = await directory
                .enumerate_children_async(Gio.FILE_ATTRIBUTE_STANDARD_NAME, Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS, GLib.PRIORITY_DEFAULT, null)
                .catch((e) => {
                console.error(`Error enumerating children in loadProcessList(): ${e}`);
            });
            while (iter) {
                const fileInfos = await iter
                    .next_files_async(10, GLib.PRIORITY_DEFAULT, null)
                    .catch((e) => {
                    console.error(`Error calling next_files_async() in loadProcessList(): ${e}`);
                });
                if (!fileInfos || fileInfos.length === 0) {
                    break;
                }
                for (const fileInfo of fileInfos) {
                    const name = fileInfo.get_name();
                    if (name[0] == '0' ||
                        name[0] == '1' ||
                        name[0] == '2' ||
                        name[0] == '3' ||
                        name[0] == '4' ||
                        name[0] == '5' ||
                        name[0] == '6' ||
                        name[0] == '7' ||
                        name[0] == '8' ||
                        name[0] == '9') {
                        const p = await this.loadProcessStat(name);
                        curProcs.set(p.id, p);
                        p.setTotalTime(this.cpuState.totalTimeDetails -
                            this.cpuState.totalTimeDetailsPrev);
                        this.loadCmdForProcess(p);
                        if (this.showMem) {
                            await this.loadSmapsRollupForProcess(p);
                        }
                        if (this.showDisk) {
                            await this.loadIoForProcess(p);
                        }
                    }
                }
            }
            this.procs = curProcs;
            this.cpu_top_procs = this.hashTopCpuProcs();
            this.mem_top_procs = this.hashTopMemProcs();
            this.disk_top_procs = this.hashTopDiskProcs();
        }
        catch (e) {
            console.error(`[TopHat] Error in loadProcessList(): ${e}`);
        }
    }
    hashTopCpuProcs() {
        let toHash = '';
        for (const p of this.getTopCpuProcs(NumTopProcs)) {
            if (p) {
                toHash += `${p.cmd};${p.cpuUsage().toFixed(4)};`;
            }
        }
        const cs = GLib.Checksum.new(GLib.ChecksumType.MD5);
        cs.update(toHash);
        return cs.get_string();
    }
    hashTopMemProcs() {
        let toHash = '';
        for (const p of this.getTopMemProcs(NumTopProcs)) {
            if (p) {
                toHash += `${p.cmd};${p.memUsage().toFixed(0)};`;
            }
        }
        const cs = GLib.Checksum.new(GLib.ChecksumType.MD5);
        cs.update(toHash);
        return cs.get_string();
    }
    hashTopDiskProcs() {
        let toHash = '';
        for (const p of this.getTopDiskProcs(NumTopProcs)) {
            if (p) {
                toHash += `${p.cmd};${p.diskReads().toFixed(0)};${p.diskWrites().toFixed(0)};`;
            }
        }
        const cs = GLib.Checksum.new(GLib.ChecksumType.MD5);
        cs.update(toHash);
        return cs.get_string();
    }
    async loadProcessStat(name) {
        return new Promise((resolve) => {
            const f = new File('/proc/' + name + '/stat');
            f.read()
                .then((contents) => {
                let p = this.procs.get(name);
                if (p === undefined) {
                    p = new Process();
                }
                p.id = name;
                p.parseStat(contents);
                resolve(p);
            })
                .catch(() => {
                // We expect to be unable to read many of these
            });
        });
    }
    async loadSmapsRollupForProcess(p) {
        return new Promise((resolve) => {
            const f = new File('/proc/' + p.id + '/smaps_rollup');
            f.read()
                .then((contents) => {
                p.parseSmapsRollup(contents);
                resolve();
            })
                .catch(() => {
                // We expect to be unable to read many of these
                resolve();
            });
        });
    }
    async loadIoForProcess(p) {
        return new Promise((resolve) => {
            const f = new File('/proc/' + p.id + '/io');
            f.read()
                .then((contents) => {
                p.parseIo(contents);
                resolve();
            })
                .catch(() => {
                // We expect to be unable to read many of these
                resolve();
            });
        });
    }
    loadCmdForProcess(p) {
        if (p.cmdLoaded) {
            return;
        }
        const f = new File('/proc/' + p.id + '/cmdline');
        f.read()
            .then((contents) => {
            p.parseCmd(contents);
        })
            .catch(() => {
            // We expect to be unable to read many of these
        });
    }
    updateNetDevices(client) {
        const devices = client.get_devices();
        this.netDevs = new Array();
        for (const d of devices) {
            const dt = d.get_device_type();
            if (dt !== NM.DeviceType.BRIDGE && dt !== NM.DeviceType.LOOPBACK) {
                this.netDevs.push(d.get_iface());
            }
        }
    }
    getTopCpuProcs(n) {
        let top = Array.from(this.procs.values());
        top = top.sort((x, y) => {
            return x.cpuUsage() - y.cpuUsage();
        });
        top = top.reverse().slice(0, n);
        return top;
    }
    getTopMemProcs(n) {
        let top = Array.from(this.procs.values());
        top = top.sort((x, y) => {
            return x.memUsage() - y.memUsage();
        });
        top = top.reverse().slice(0, n);
        return top;
    }
    getTopDiskProcs(n) {
        let top = Array.from(this.procs.values());
        top = top.sort((x, y) => {
            return (x.diskReads() + x.diskWrites() - (y.diskReads() + y.diskWrites()));
        });
        top = top.reverse().slice(0, n);
        return top;
    }
    getCpuCoreUsage() {
        const usage = new Array(this.cpuModel.cores);
        for (let i = 0; i < usage.length; i++) {
            usage[i] = this.cpuState.coreUsage(i);
        }
        return usage;
    }
    getNetActivity() {
        return this.netActivityHistory;
    }
    getDiskActivity() {
        return this.diskActivityHistory;
    }
    hashCpuHistory() {
        let toHash = '';
        for (const u of this.cpuUsageHistory) {
            if (u) {
                toHash += u.aggregate.toFixed(3);
            }
        }
        const cs = GLib.Checksum.new(GLib.ChecksumType.MD5);
        cs.update(toHash);
        return cs.get_string();
    }
    hashMemHistory() {
        let toHash = '';
        for (const u of this.memUsageHistory) {
            if (u) {
                toHash += u.usedMem.toFixed(3);
            }
        }
        const cs = GLib.Checksum.new(GLib.ChecksumType.MD5);
        cs.update(toHash);
        return cs.get_string();
    }
    hashNetHistory() {
        let toHash = '';
        for (const u of this.netActivityHistory) {
            if (u) {
                toHash += `${u.bytesRecv.toFixed(0)};${u.bytesSent.toFixed(0)};`;
            }
        }
        const cs = GLib.Checksum.new(GLib.ChecksumType.MD5);
        cs.update(toHash);
        return cs.get_string();
    }
    hashDiskHistory() {
        let toHash = '';
        for (const u of this.diskActivityHistory) {
            if (u) {
                toHash += `${u.bytesRead.toFixed(0)};${u.bytesWritten.toFixed(0)};`;
            }
        }
        const cs = GLib.Checksum.new(GLib.ChecksumType.MD5);
        cs.update(toHash);
        return cs.get_string();
    }
    // Properties
    get cpu_usage() {
        return this.props.cpu_usage;
    }
    set cpu_usage(v) {
        if (this.cpu_usage === v) {
            return;
        }
        this.props.cpu_usage = v;
        this.notify('cpu-usage');
    }
    get cpu_model() {
        return this.cpuModel.name;
    }
    get cpu_freq() {
        return this.props.cpu_freq;
    }
    set cpu_freq(v) {
        if (this.cpu_freq === v) {
            return;
        }
        this.props.cpu_freq = v;
        this.notify('cpu-freq');
    }
    get cpu_temp() {
        return this.props.cpu_temp;
    }
    set cpu_temp(v) {
        if (this.cpu_temp === v) {
            return;
        }
        this.props.cpu_temp = v;
        this.notify('cpu-temp');
    }
    get cpu_top_procs() {
        return this.props.cpu_top_procs;
    }
    set cpu_top_procs(v) {
        if (this.cpu_top_procs === v) {
            return;
        }
        this.props.cpu_top_procs = v;
        this.notify('cpu-top-procs');
    }
    get cpu_history() {
        return this.props.cpu_history;
    }
    set cpu_history(v) {
        if (this.cpu_history === v) {
            return;
        }
        this.props.cpu_history = v;
        this.notify('cpu-history');
    }
    get ram_usage() {
        return this.props.ram_usage;
    }
    set ram_usage(v) {
        if (this.ram_usage === v) {
            return;
        }
        this.props.ram_usage = v;
        this.notify('ram-usage');
    }
    get ram_size() {
        return this.props.ram_size;
    }
    set ram_size(v) {
        if (this.ram_size === v) {
            return;
        }
        this.props.ram_size = v;
        this.notify('ram-size');
    }
    get ram_size_free() {
        return this.props.ram_size_free;
    }
    set ram_size_free(v) {
        if (this.props.ram_size_free === v) {
            return;
        }
        this.props.ram_size_free = v;
        this.notify('ram-size-free');
    }
    get swap_usage() {
        return this.props.swap_usage;
    }
    set swap_usage(v) {
        if (this.swap_usage === v) {
            return;
        }
        this.props.swap_usage = v;
        this.notify('swap-usage');
    }
    get swap_size() {
        return this.props.swap_size;
    }
    set swap_size(v) {
        if (this.swap_size === v) {
            return;
        }
        this.props.swap_size = v;
        this.notify('swap-size');
    }
    get swap_size_free() {
        return this.props.swap_size_free;
    }
    set swap_size_free(v) {
        if (this.swap_size_free === v) {
            return;
        }
        this.props.swap_size_free = v;
        this.notify('swap-size-free');
    }
    get mem_history() {
        return this.props.mem_history;
    }
    set mem_history(v) {
        if (this.mem_history === v) {
            return;
        }
        this.props.mem_history = v;
        this.notify('mem-history');
    }
    get mem_top_procs() {
        return this.props.mem_top_procs;
    }
    set mem_top_procs(v) {
        if (this.mem_top_procs === v) {
            return;
        }
        this.props.mem_top_procs = v;
        this.notify('mem-top-procs');
    }
    get net_recv() {
        return this.props.net_recv;
    }
    set net_recv(v) {
        if (this.net_recv === v) {
            return;
        }
        this.props.net_recv = v;
        this.notify('net-recv');
    }
    get net_sent() {
        return this.props.net_sent;
    }
    set net_sent(v) {
        if (this.net_sent === v) {
            return;
        }
        this.props.net_sent = v;
        this.notify('net-sent');
    }
    get net_recv_total() {
        return this.props.net_recv_total;
    }
    set net_recv_total(v) {
        if (this.net_recv_total === v) {
            return;
        }
        this.props.net_recv_total = v;
        this.notify('net-recv-total');
    }
    get net_sent_total() {
        return this.props.net_sent_total;
    }
    set net_sent_total(v) {
        if (this.net_sent_total === v) {
            return;
        }
        this.props.net_sent_total = v;
        this.notify('net-sent-total');
    }
    get net_history() {
        return this.props.net_history;
    }
    set net_history(v) {
        if (this.net_history === v) {
            return;
        }
        this.props.net_history = v;
        this.notify('net-history');
    }
    get disk_read() {
        return this.props.disk_read;
    }
    set disk_read(v) {
        if (this.disk_read === v) {
            return;
        }
        this.props.disk_read = v;
        this.notify('disk-read');
    }
    get disk_wrote() {
        return this.props.disk_wrote;
    }
    set disk_wrote(v) {
        if (this.disk_wrote === v) {
            return;
        }
        this.props.disk_wrote = v;
        this.notify('disk-wrote');
    }
    get disk_read_total() {
        return this.props.disk_read_total;
    }
    set disk_read_total(v) {
        if (this.disk_read_total === v) {
            return;
        }
        this.props.disk_read_total = v;
        this.notify('disk-read-total');
    }
    get disk_wrote_total() {
        return this.props.disk_wrote_total;
    }
    set disk_wrote_total(v) {
        if (this.disk_wrote_total === v) {
            return;
        }
        this.props.disk_wrote_total = v;
        this.notify('disk-wrote-total');
    }
    get disk_history() {
        return this.props.disk_history;
    }
    set disk_history(v) {
        if (this.disk_history === v) {
            return;
        }
        this.props.disk_history = v;
        this.notify('disk-history');
    }
    get disk_top_procs() {
        return this.props.disk_top_procs;
    }
    set disk_top_procs(v) {
        if (this.disk_top_procs === v) {
            return;
        }
        this.props.disk_top_procs = v;
        this.notify('disk-top-procs');
    }
    get uptime() {
        return this.props.uptime;
    }
    set uptime(v) {
        if (this.uptime === v) {
            return;
        }
        this.props.uptime = v;
        this.notify('uptime');
    }
    get summary_interval() {
        return this.props.summary_interval;
    }
    set summary_interval(v) {
        if (this.summary_interval === v) {
            return;
        }
        this.props.summary_interval = v;
        this.notify('summary-interval');
    }
    vfunc_dispose() {
        for (const s of this.settingSignals) {
            this.gsettings.disconnect(s);
        }
        super.vfunc_dispose();
    }
});
class Properties {
    uptime = 0;
    cpu_usage = 0;
    cpu_freq = 0;
    cpu_temp = 0;
    cpu_history = '';
    cpu_top_procs = '';
    ram_usage = 0;
    ram_size = 0;
    ram_size_free = 0;
    swap_usage = -1;
    swap_size = -1;
    swap_size_free = 0;
    mem_history = '';
    mem_top_procs = '';
    net_recv = -1;
    net_sent = -1;
    net_recv_total = 0;
    net_sent_total = 0;
    net_history = '';
    disk_read = -1;
    disk_wrote = -1;
    disk_read_total = 0;
    disk_wrote_total = 0;
    disk_history = '';
    disk_top_procs = '';
    summary_interval = 0;
}
class CpuState {
    usedTime;
    usedTimePrev;
    idleTime;
    idleTimePrev;
    coreUsedTime;
    coreUsedTimePrev;
    coreIdleTime;
    coreIdleTimePrev;
    freqs;
    temps;
    totalTimeDetails; // track for the details loop
    totalTimeDetailsPrev;
    constructor(cores, sockets, usedTime = 0, idleTime = 0) {
        this.usedTime = usedTime;
        this.usedTimePrev = 0;
        this.idleTime = idleTime;
        this.idleTimePrev = 0;
        this.totalTimeDetails = 0;
        this.totalTimeDetailsPrev = 0;
        this.coreUsedTime = new Array(cores);
        this.coreUsedTimePrev = new Array(cores);
        this.coreIdleTime = new Array(cores);
        this.coreIdleTimePrev = new Array(cores);
        for (let i = 0; i < cores; i++) {
            this.coreUsedTime[i] = 0;
            this.coreIdleTime[i] = 0;
            this.coreUsedTimePrev[i] = 0;
            this.coreIdleTimePrev[i] = 0;
        }
        this.freqs = [];
        this.temps = [];
        for (let i = 0; i < sockets; i++) {
            this.freqs.push(0);
            this.temps.push(0);
        }
    }
    update(usedTime, idleTime) {
        this.usedTimePrev = this.usedTime;
        this.usedTime = usedTime;
        this.idleTimePrev = this.idleTime;
        this.idleTime = idleTime;
    }
    updateCore(core, usedTime, idleTime) {
        this.coreUsedTimePrev[core] = this.coreUsedTime[core];
        this.coreUsedTime[core] = usedTime;
        this.coreIdleTimePrev[core] = this.coreIdleTime[core];
        this.coreIdleTime[core] = idleTime;
    }
    updateDetails(totalTime) {
        this.totalTimeDetailsPrev = this.totalTimeDetails;
        this.totalTimeDetails = totalTime;
    }
    usage() {
        const usedTimeDelta = this.usedTime - this.usedTimePrev;
        const idleTimeDelta = this.idleTime - this.idleTimePrev;
        return usedTimeDelta / (usedTimeDelta + idleTimeDelta);
    }
    coreUsage(core) {
        const usedTimeDelta = this.coreUsedTime[core] - this.coreUsedTimePrev[core];
        const idleTimeDelta = this.coreIdleTime[core] - this.coreIdleTimePrev[core];
        return usedTimeDelta / (usedTimeDelta + idleTimeDelta);
    }
    totalTime() {
        return (this.usedTime - this.usedTimePrev + (this.idleTime - this.idleTimePrev));
    }
}
class CpuUsage {
    aggregate;
    core;
    constructor(cores) {
        this.aggregate = 0;
        this.core = new Array(cores);
        for (let i = 0; i < cores; i++) {
            this.core[i] = 0;
        }
    }
    toString() {
        let s = `aggregate: ${this.aggregate.toFixed(2)}`;
        this.core.forEach((usage, index) => {
            s += ` core[${index}]: ${this.core[index].toFixed(2)}`;
        });
        return s;
    }
}
export class CpuModel {
    name;
    cores;
    sockets;
    tempMonitors;
    constructor(name = 'Unknown', cores = 1, sockets = 1, tempMonitors) {
        this.name = name;
        this.cores = cores;
        this.sockets = sockets;
        this.tempMonitors = tempMonitors;
    }
}
class MemInfo {
    total = 0;
    available = 0;
    swapTotal = 0;
    swapAvailable = 0;
}
class MemUsage {
    usedMem = 0;
    usedSwap = 0;
    toString() {
        return `Memory usage: ${this.usedMem.toFixed(2)} Swap usage: ${this.usedSwap.toFixed(2)}`;
    }
}
class NetDevState {
    bytesRecv = -1;
    bytesRecvPrev = -1;
    bytesSent = -1;
    bytesSentPrev = -1;
    update(bytesRecv, bytesSent) {
        this.bytesRecvPrev = this.bytesRecv;
        this.bytesRecv = bytesRecv;
        this.bytesSentPrev = this.bytesSent;
        this.bytesSent = bytesSent;
    }
    // recvActivity returns the number of bytes received per second
    // during the most recent interval
    recvActivity() {
        if (this.bytesRecvPrev < 0) {
            return 0;
        }
        return (this.bytesRecv - this.bytesRecvPrev) / SummaryIntervalDefault;
    }
    // sentActivity return the number of bytes sent per second
    // during the most recent interval
    sentActivity() {
        if (this.bytesSentPrev < 0) {
            return 0;
        }
        return (this.bytesSent - this.bytesSentPrev) / SummaryIntervalDefault;
    }
}
class NetActivity {
    // TODO(fflewddur): Add a field for the duration of this measurement
    bytesRecv = 0;
    bytesSent = 0;
    val() {
        return this.bytesRecv;
    }
    valAlt() {
        return this.bytesSent;
    }
}
class DiskState {
    bytesRead = -1;
    bytesReadPrev = -1;
    bytesWritten = -1;
    bytesWrittenPrev = -1;
    update(bytesRead, bytesWritten) {
        this.bytesReadPrev = this.bytesRead;
        this.bytesRead = bytesRead;
        this.bytesWrittenPrev = this.bytesWritten;
        this.bytesWritten = bytesWritten;
    }
    // readActivity returns the number of bytes read per second
    // during the most recent interval
    readActivity() {
        if (this.bytesReadPrev < 0) {
            return 0;
        }
        return (this.bytesRead - this.bytesReadPrev) / SummaryIntervalDefault;
    }
    // writeActivity return the number of bytes written per second
    // during the most recent interval
    writeActivity() {
        if (this.bytesWrittenPrev < 0) {
            return 0;
        }
        return (this.bytesWritten - this.bytesWrittenPrev) / SummaryIntervalDefault;
    }
}
class DiskActivity {
    // TODO(fflewddur): Add a field for the duration of this measurement
    bytesRead = 0;
    bytesWritten = 0;
    val() {
        return this.bytesWritten;
    }
    valAlt() {
        return this.bytesRead;
    }
}
class Process {
    id = '';
    cmd = '';
    cmdLoaded = false;
    utime = 0;
    stime = 0;
    pss = 0;
    cpu = -1;
    cpuPrev = -1;
    cpuTotal = 0;
    diskRead = -1;
    diskWrite = -1;
    diskReadPrev = -1;
    diskWritePrev = -1;
    cpuUsage() {
        if (this.cpuPrev < 0) {
            return 0;
        }
        return (this.cpu - this.cpuPrev) / this.cpuTotal;
    }
    memUsage() {
        return this.pss;
    }
    diskReads() {
        if (this.diskReadPrev < 0) {
            return 0;
        }
        return (this.diskRead - this.diskReadPrev) / DetailsInterval;
    }
    diskWrites() {
        if (this.diskWritePrev < 0) {
            return 0;
        }
        return (this.diskWrite - this.diskWritePrev) / DetailsInterval;
    }
    setTotalTime(t) {
        this.cpuTotal = t;
    }
    parseStat(stat) {
        const open = stat.indexOf('(');
        const close = stat.indexOf(')');
        if (!this.cmd && open > 0 && close > 0) {
            this.cmd = stat.substring(open + 1, close);
        }
        const fields = stat.substring(close + 2).split(' ');
        this.utime = parseInt(fields[11]);
        this.stime = parseInt(fields[12]);
        this.cpuPrev = this.cpu;
        this.cpu = this.utime + this.stime;
    }
    parseSmapsRollup(content) {
        const lines = content.split('\n');
        lines.forEach((line) => {
            if (line.startsWith('Pss:')) {
                this.pss = readKb(line) * 1024;
            }
        });
    }
    parseIo(content) {
        const lines = content.split('\n');
        lines.forEach((line) => {
            if (line.startsWith('read_bytes:')) {
                this.diskReadPrev = this.diskRead;
                this.diskRead = readKb(line);
            }
            else if (line.startsWith('write_bytes')) {
                this.diskWritePrev = this.diskWrite;
                this.diskWrite = readKb(line);
            }
        });
    }
    parseCmd(content) {
        if (content) {
            this.cmd = content;
            // If this is an absolute cmd path, remove the path
            if (content[0] === '/') {
                const m = content.match(RE_CMD);
                if (m) {
                    // console.log(`parsing '${content}' to '${m[1]}'`);
                    this.cmd = m[1];
                }
            }
            this.cmdLoaded = true;
        }
    }
}
function readKb(line) {
    const m = line.match(RE_MEM_INFO);
    let kb = 0;
    if (m) {
        kb = parseInt(m[1]);
    }
    return kb;
}
function refreshRateModifier(settings) {
    const val = settings.get_string('refresh-rate');
    let modifier = 1.0;
    switch (val) {
        case 'slow':
            modifier = 2.0;
            break;
        case 'fast':
            modifier = 0.5;
            break;
    }
    return modifier;
}
