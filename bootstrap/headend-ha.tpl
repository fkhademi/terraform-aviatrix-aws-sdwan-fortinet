#config-version=FGTAWS-6.2.3-FW-build1066-200327:opmode=0:vdom=0:user=admin
#conf_file_ver=187393718135403
#buildno=8404
#global_vdom=1
config system global
    set hostname "${name}-headend${headend_nr}"
    set timezone 04
    set admintimeout 60
end

config system ha
    set session-pickup enable
    set session-pickup-expectation enable
    set session-pickup-connectionless enable
    unset session-sync-dev
end

config system settings
    set auxiliary-session enable
end

config system cluster-sync
    edit 1
        set peerip ${peerip}
        set ipsec-tunnel-sync disable
end

config system admin
    edit "admin"
        set accprofile "super_admin"
        set vdom "root"
        set password "${password}"
    next
end

config vpn ipsec phase1-interface
    edit "HEADEND${headend_nr}-TG"
        set interface "port1"
        set ike-version 1
        set keylife 28800
        set peertype any
        set proposal aes256-sha256
        set add-route disable
        set psksecret "${pre-shared-key}"
        set dpd-retryinterval 5
        set remote-gw ${transit_gw}
    next
    edit "HEADEND${headend_nr}-TGHA"
        set interface "port1"
        set ike-version 1
        set keylife 28800
        set peertype any
        set proposal aes256-sha256
        set add-route disable
        set psksecret "${pre-shared-key}"
        set dpd-retryinterval 5
        set remote-gw ${transit_gw_ha}
    next
end

config vpn ipsec phase2-interface
    edit "HEADEND${headend_nr}-TG"
        set phase1name "HEADEND${headend_nr}-TG"
        set proposal aes256-sha256
    next
    edit "HEADEND${headend_nr}-TGHA"
        set phase1name "HEADEND${headend_nr}-TGHA"
        set proposal aes256-sha256
    next    
end

config system interface
    edit "HEADEND${headend_nr}-TG"
        set vdom "root"
        set type tunnel
        set interface "port1"
        set ip ${tunnel1_ip} 255.255.255.255
        set remote-ip ${tunnel1_rem} ${tunnel1_mask}
        set allowaccess ping
    next
    edit "HEADEND${headend_nr}-TGHA"
        set vdom "root"
        set type tunnel
        set interface "port1"
        set ip ${tunnel2_ip} 255.255.255.255
        set remote-ip ${tunnel2_rem} ${tunnel2_mask}
        set allowaccess ping
    next    
end

config system zone
    edit TRANSIT
        set interface HEADEND${headend_nr}-TG HEADEND${headend_nr}-TGHA
    end
end

config router bgp
    set as ${ASN}
    set ibgp-multipath enable
    set ebgp-multipath enable
    set graceful-restart enable
    set additional-path enable
    set additional-path-select 4
    set graceful-restart-time 1
    set graceful-update-delay 1
    config redistribute static
    set status enable
    config neighbor
        edit "${tunnel1_rem}"
            set remote-as ${REMASN}
            set soft-reconfiguration enable
        next
        edit "${tunnel2_rem}"
            set remote-as ${REMASN}
            set soft-reconfiguration enable
        next
    end
end

config firewall policy
    edit 1
        set name "Dummy"
        set srcintf "TRANSIT"
        set dstintf "TRANSIT"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
    next
    edit 2
        set name "Dummy2"
        set srcintf "port1"
        set dstintf "TRANSIT"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
    next
    edit 1
        set name "Dummy3"
        set srcintf "TRANSIT"
        set dstintf "port1"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
    next
end   
