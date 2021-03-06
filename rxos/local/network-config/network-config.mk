################################################################################
#
# network-config
#
################################################################################

NETWORK_CONFIG_VERSION = 1.1
NETWORK_CONFIG_LICENSE = GPL
NETWORK_CONFIG_SITE = $(BR2_EXTERNAL)/local/network-config/src
NETWORK_CONFIG_SITE_METHOD = local

NETWORK_CONFIG_AP_IF = $(call qstrip,$(BR2_NETWORK_CONFIG_AP_IF))
NETWORK_CONFIG_AP_NAME = $(call qstrip,$(BR2_NETWORK_CONFIG_AP_NAME))
NETWORK_CONFIG_DHCP_START = $(call qstrip,$(BR2_NETWORK_CONFIG_DHCP_START))
NETWORK_CONFIG_DHCP_END = $(call qstrip,$(BR2_NETWORK_CONFIG_DHCP_END))
NETWORK_CONFIG_DHCP_NETMASK = $(call qstrip,$(BR2_NETWORK_CONFIG_NETMASK))

NETWORK_CONFIG_AP_IP = $(call qstrip,$(BR2_NETWORK_CONFIG_AP_IP))
NETWORK_CONFIG_IFACES = $(NETWORK_CONFIG_AP_IF)
NETWORK_CONFIG_DHCP_IFACES = $(NETWORK_CONFIG_AP_IF)
NETWORK_CONFIG_DHCP_RANGES = $(NETWORK_CONFIG_AP_IF),$(NETWORK_CONFIG_DHCP_START),$(NETWORK_CONFIG_DHCP_END),$(NETWORK_CONFIG_DHCP_NETMASK)
NETWORK_CONFIG_ALIASES = /\#/$(NETWORK_CONFIG_AP_IP)
NETWORK_CONFIG_HOSTNAME = $(call qstrip,$(BR2_TARGET_GENERIC_HOSTNAME))

NETWORK_CONFIG_PROFILES_PATH = /etc/network/profiles.d
NETWORK_CONFIG_PROFILES = $(TARGET_DIR)$(NETWORK_CONFIG_PROFILES_PATH)
NETWORK_CONFIG_IFDIR = $(TARGET_DIR)/etc/network/interfaces.d
NETWORK_CONFIG_DNSMASQ_PROFILES_PATH = /etc/conf.d/dnsmasq
NETWORK_CONFIG_DNSMASQ_PROFILES = $(TARGET_DIR)$(NETWORK_CONFIG_DNSMASQ_PROFILES_PATH)

NETWORK_CONFIG_WIRELESS_DEFAULT_MODE = AP
NETWORK_CONFIG_WIRELESS_MODE_FILE = $(TARGET_DIR)/etc/conf.d/wireless

ifeq ($(BR2_PACKAGE_NETWORK_CONFIG),y)
PERSISTENT_CONF_LIST += /etc/hostname
PERSISTENT_CONF_LIST += /etc/dropbear
PERSISTENT_CONF_LIST += /etc/network/interfaces.d
PERSISTENT_CONF_LIST += /etc/hostapd.conf
PERSISTENT_CONF_LIST += /etc/wpa_supplicant.conf
PERSISTENT_CONF_LIST += /etc/conf.d/wireless
PERSISTENT_CONF_LIST += /run/dnsmasq.leases
endif

define NETWORK_CONFIG_INSTALL_IFACE
	$(SED) '$(NETWORK_CONFIG_SUBS)' $(@D)/$1.conf;
	$(INSTALL) -Dm644 $(@D)/$1.conf $(NETWORK_CONFIG_PROFILES)/$2;
	ln -sf $(NETWORK_CONFIG_PROFILES_PATH)/$2 $(NETWORK_CONFIG_IFDIR)/$2;
endef

#
# eth0
# 
ifeq ($(BR2_NETWORK_CONFIG_HAS_ETH),y)
NETWORK_CONFIG_IFACES += eth0
define NETWORK_CONFIG_INSTALL_ETH
	$(INSTALL) -Dm755 $(@D)/ifplugd.action $(TARGET_DIR)/etc/ifplugd.action
	$(call NETWORK_CONFIG_INSTALL_IFACE,eth0,eth0)
endef
NETWORK_CONFIG_INSTALL_IFACES += NETWORK_CONFIG_INSTALL_ETH
endif # BR2_NETWORK_CONFIG_HAS_ETH

#
# usb0
# 
ifeq ($(BR2_NETWORK_CONFIG_HAS_GETH),y)
NETWORK_CONFIG_IFACES += usb0
NETWORK_CONFIG_DHCP_IFACES += usb0
NETWORK_CONFIG_ALIASES += /$(call qstrip,$(BR2_NETWORK_CONFIG_GETH_HOSTNAME))/$(call qstrip,$(BR2_NETWORK_CONFIG_GETH_IP))
NETWORK_CONFIG_GETH_DHCP_START = $(call qstrip,$(BR2_NETWORK_CONFIG_GETH_DHCP_START))
NETWORK_CONFIG_GETH_DHCP_END = $(call qstrip,$(BR2_NETWORK_CONFIG_GETH_DHCP_END))
NETWORK_CONFIG_DHCP_RANGES += usb0,$(NETWORK_CONFIG_GETH_DHCP_START),$(NETWORK_CONFIG_GETH_DHCP_END),$(NETWORK_CONFIG_DHCP_NETMASK)
define NETWORK_CONFIG_INSTALL_USB
	$(call NETWORK_CONFIG_INSTALL_IFACE,usb0,usb0)
endef
NETWORK_CONFIG_INSTALL_IFACES += NETWORK_CONFIG_INSTALL_USB
endif # BR2_NETWORK_CONFIG_HAS_GETH

#
# powersave
# 
ifeq ($(BR2_NETWORK_CONFIG_WLAN_NOPOWERSAVE),y)
define NETWORK_CONFIG_INSTALL_NOPOWERSAVE
	$(INSTALL) -Dm755 $(@D)/wlan_powersave.sh \
		$(TARGET_DIR)/usr/sbin/wlan_powersave.sh
	$(INSTALL) -Dm644 $(@D)/99-wifi.rules \
		$(TARGET_DIR)/etc/udev/rules.d/99-wifi.rules
endef
endif # BR2_NETWORK_CONFIG_WLAN_NOPOWERSAVE

#
# wlan
#
define NETWORK_CONFIG_INSTALL_WLAN
	$(NETWORK_CONFIG_INSTALL_NOPOWERSAVE)
	$(call NETWORK_CONFIG_INSTALL_IFACE,wlan,$(NETWORK_CONFIG_AP_IF))
	$(SED) '$(NETWORK_CONFIG_SUBS)' $(@D)/wlan-client.conf
	$(INSTALL) -Dm755 $(@D)/wpa.sh $(TARGET_DIR)/usr/sbin/wpa
	$(INSTALL) -Dm755 $(@D)/ap.sh $(TARGET_DIR)/usr/sbin/ap
	$(INSTALL) -Dm644 $(@D)/wlan-client.conf \
		$(NETWORK_CONFIG_PROFILES)/$(NETWORK_CONFIG_AP_IF)-client
	$(INSTALL) -Dm644 $(@D)/wpa_supplicant.conf \
		$(TARGET_DIR)/etc/wpa_supplicant.conf
endef
NETWORK_CONFIG_INSTALL_IFACES += NETWORK_CONFIG_INSTALL_WLAN

#
# sed commands
# 
NETWORK_CONFIG_DHCP_CFG = $(foreach cfg,$(NETWORK_CONFIG_DHCP_IFACES),\ninterface=$(cfg))
NETWORK_CONFIG_ALIAS_CFG = $(foreach cfg,$(NETWORK_CONFIG_ALIASES),\naddress=$(cfg))
NETWORK_CONFIG_RANGE_CFG = $(foreach cfg,$(NETWORK_CONFIG_DHCP_RANGES),\ndhcp-range=$(cfg))

NETWORK_CONFIG_SUBS += s|%IFACES%|$(NETWORK_CONFIG_IFACES)|;
NETWORK_CONFIG_SUBS += s|%IFACE%|$(NETWORK_CONFIG_AP_IF)|;
NETWORK_CONFIG_SUBS += s|%SSID%|$(NETWORK_CONFIG_AP_NAME)|;
NETWORK_CONFIG_SUBS += s|%IP%|$(NETWORK_CONFIG_AP_IP)|;
NETWORK_CONFIG_SUBS += s|%GE_IP%|$(call qstrip,$(BR2_NETWORK_CONFIG_GETH_IP))|;
NETWORK_CONFIG_SUBS += s|%NETMASK%|$(NETWORK_CONFIG_DHCP_NETMASK)|;
NETWORK_CONFIG_SUBS += s|%LDIR%|$(call qstrip,$(BR2_NETWORK_CONFIG_DHCP_LDIR))|;
NETWORK_CONFIG_SUBS += s|%DHCP_IFACES%|$(NETWORK_CONFIG_DHCP_CFG)|;
NETWORK_CONFIG_SUBS += s|%ALIASES%|$(NETWORK_CONFIG_ALIAS_CFG)|;
NETWORK_CONFIG_SUBS += s|%RANGES%|$(NETWORK_CONFIG_RANGE_CFG)|;
NETWORK_CONFIG_SUBS += s|%HOSTNAME%|$(NETWORK_CONFIG_HOSTNAME)|;

NETWORK_CONFIG_DNSMASQ_STA_SUB = s|^.*$(NETWORK_CONFIG_AP_IF).*$|||;

define NETWORK_CONFIG_INSTALL_TARGET_CMDS
	mkdir -p $(NETWORK_CONFIG_PROFILES)
	mkdir -p $(NETWORK_CONFIG_IFDIR)
	mkdir -p $(NETWORK_CONFIG_DNSMASQ_PROFILES)
	$(SED) '$(NETWORK_CONFIG_SUBS)' $(@D)/hostapd.conf $(@D)/dnsmasq.conf
	cp $(@D)/dnsmasq.conf $(@D)/dnsmasq_sta.conf
	$(SED) '$(NETWORK_CONFIG_DNSMASQ_STA_SUB)' $(@D)/dnsmasq_sta.conf
	$(INSTALL) -Dm644 $(@D)/dnsmasq.conf $(NETWORK_CONFIG_DNSMASQ_PROFILES)/ap.conf
	$(INSTALL) -Dm644 $(@D)/dnsmasq_sta.conf $(NETWORK_CONFIG_DNSMASQ_PROFILES)/sta.conf
	echo $(NETWORK_CONFIG_WIRELESS_DEFAULT_MODE) > $(NETWORK_CONFIG_WIRELESS_MODE_FILE)
	$(INSTALL) -Dm644 $(@D)/hostapd.conf $(TARGET_DIR)/etc/hostapd.conf
	$(INSTALL) -Dm755 $(@D)/check_ip_assigned \
		$(TARGET_DIR)/etc/network/if-up.d/check_ip_assigned
	$(foreach ifacecmds,$(NETWORK_CONFIG_INSTALL_IFACES),$(call $(ifacecmds)))
	$(INSTALL) -Dm755 $(@D)/wireless.sh $(TARGET_DIR)/etc/setup.d/wireless.sh
	$(INSTALL) -Dm755 $(@D)/netrestart.sh $(TARGET_DIR)/usr/sbin/netrestart
	$(INSTALL) -Dm755 $(@D)/S99netguard $(TARGET_DIR)/etc/init.d/S99netguard
endef

$(eval $(generic-package))

# The interfaces file is installed by Buildroot's built-in target finalize 
# hook, so we need to override that with our own built-in hook.
define INSTALL_NETWORK_CONFIG_OVERRIDE
	$(INSTALL) -Dm644 $(NETWORK_CONFIG_DIR)/interfaces \
		$(TARGET_DIR)/etc/network/interfaces
endef

TARGET_FINALIZE_HOOKS += INSTALL_NETWORK_CONFIG_OVERRIDE
