# psNetConfigParser
PowerShell Module to parse Cisco style network configuration files and produce documentation

graph TD
    CPU1["CPU 0<br>8 cores"]
    CPU2["CPU 1<br>8 cores"]
    RAM["32 GB RAM"]
    DISK1["Disk 0<br>500GB SSD"]
    DISK2["Disk 1<br>1TB HDD"]
    NIC1["NIC 0<br>1GbE"]
    NIC2["NIC 1<br>10GbE"]

    CPU1 --> RAM
    CPU2 --> RAM
    CPU1 --> DISK1
    CPU2 --> DISK2
    CPU1 --> NIC1
    CPU2 --> NIC2
