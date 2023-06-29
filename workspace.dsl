workspace {

    model {

        admin = person "Admin" "An administrator of host, pools and VMs"

        xcpng = softwareSystem "XCP-ng" "A host running the XCP-ng hypervisor" {

            xe = container "xe" "CLI to a subset of the XAPI interface" "C" {
                admin -> this "Manually administrates host and guests using"
            }

            xl = container "xl" "Lower-level Xen tool bypassing XAPI" "C" {
                admin -> this "Manually administrates host and guests using"
            }

            xapi = container "XAPI" "Centralized API to configure an XCP-ng host and its VMs" "OCaml, Python, C, […]" {
                xe -> this "Makes requests to"
                this -> xl "Configures xen using"
            }

            xen = container "Xen" "Low level microkernel hypervisor" "C, ASM" {
                xl -> this "Manages and configures"
                xapi -> this "Configures"
            }

            network = container "Network Stack" "Handle network configuration and traffic" "C" {
                ovs = component "Open vSwitch" "Network core of XCP-ng" "C" {
                    xapi -> this "Configures"
                }
                netstack = component "Host Kernel Network Stack" "Kernel Network handling" "C" {
                    xapi -> this "Configures"
                    ovs -> this "Hooks early in"
                    this -> ovs "Sends packets to"
                    this -> ovs "Routes packets to the right port"
                }
                netback = component "VIF Backend" "VIF driver running on host" "C" {
                    xapi -> this "Configures"
                    netstack -> this "Receiveds packets from"
                    this -> netstack "Sends packets to"
                }
            }

            storage = container "Storage Stack" "Handle storage and block devices" "C, Python" {
                xapi -> this "Configures"
            }
        }

        xo = softwareSystem "Xen Orchestra" "Web interface for XCP-ng hosts administration" {
            admin -> this "Administrates and backups Hosts, Pools and VMs using"
            xapi -> this "Provides information to"
            this -> xapi "Administrates and backups host and its VMs on"
        }

        xcpngcenter = softwareSystem "XCP-ng Center" "A windows based administration interface" {
            tags "external"
            admin -> this "Administrates Hosts, Pools and VMs using"
            xapi -> this "Provides information to"
            this -> xapi "Administrates host and its VMs on"
        }

        vm = softwareSystem "VMs" "PV, HVM, PVHVM virtual machines" {
            tags "external"
            this -> xen "Runs on top of"
            pv = container "PV Drivers" "Para-Virtualized drivers providing better performances" "C" {
                xapi -> this "Configures"
                storage -> this "Provides storage to"
                netfront = component "VIF Frontend" {
                    this -> netback "Receiveds packets from"
                    netback -> this "Sends packets to"
                }

            }
            guesttools = container "Guest-tools" "Tools running on guest machines to provide information and better control" "Go" {
                this -> xapi "Provides Information to"
                xapi -> this "Controls"
            }
            guestos = container "Guest OS" "An operating system" "Linux, Windows" {
                tags "external"
                this -> guesttools "Provides information to"
                pv -> this "Provides PV devices to"
                this -> pv "Uses virtual devices through"
                this -> xen "Controls"
            }
        }
    }

    views {
        systemContext xcpng {
            include * xo xcpngcenter
        }

        container xcpng {
            include element.type==container
            include admin
            exclude xcpngcenter
        }

        component network {
            include element.type==component
            include xapi netfront
        }

        theme default
        styles {
            relationship "Relationship" {
                dashed false
            }
            element "external" {
                background #aaaaaa
            }
        }
    }

}
