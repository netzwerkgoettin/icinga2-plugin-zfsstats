# icinga2-plugin-zfsstats
Check USED, REFER and AVAIL on ZFS dataset
* Tested in Solaris only
* GNU tools are hardcoded (may change in further releases)

### Usage
```
zfs_stats.sh [ -c <critical_space> ] [ -w <warning_space> ] -d <dataset>
```

### Example
```
$ ./zfs_stats.sh -d Data01/archives
OK: 4.08T available on Data01/archives, that's fairly enough.
Dataset information about Data01/archives:
|used=6504801769440;650480176944;325240088472;0;10995116277760 available=4490314508320;;;;10995116277760 refer=6504778126080;;;;10995116277760
```

