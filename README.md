# WiFI-setup
Automatically join a specific WiFI network that is WPA2-PSK for use by employees.  However, remove any entries for when the employee accidentally joined the "guest" WiFI.

You can export the XML you need by running this command:

  netsh wlan export profile %SSIDName% folder=c:\scripts\wifi-config.xml

See:  https://community.spiceworks.com/how_to/24989-export-import-wireless-network-info-on-windows-machines
