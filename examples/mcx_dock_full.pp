# Mac MCX Test

computer { "localhost": }

mcx {
  "mcx_dock":
    ensure  => "present",
    ds_type => "group",
    ds_name => "mcx_dock",
    content => '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.dock</key>
    <dict>
        <key>AppItems-Raw</key>
        <dict>
            <key>state</key>
            <string>always</string>
            <key>upk</key>
            <dict>
                <key>mcx_input_key_names</key>
                <array>
                    <string>AppItems-Raw</string>
                </array>
                <key>mcx_output_key_name</key>
                <string>static-apps</string>
                <key>mcx_remove_duplicates</key>
                <true/>
            </dict>
            <key>value</key>
            <array>
                <dict>
                    <key>mcx_typehint</key>
                    <integer>1</integer>
                    <key>tile-data</key>
                    <dict>
                        <key>file-data</key>
                        <dict>
                            <key>_CFURLString</key>
                            <string>/Applications/Mail.app</string>
                            <key>_CFURLStringType</key>
                            <integer>0</integer>
                        </dict>
                        <key>file-label</key>
                        <string>Mail</string>
                    </dict>
                    <key>tile-type</key>
                    <string>file-tile</string>
                </dict>
                <dict>
                    <key>mcx_typehint</key>
                    <integer>1</integer>
                    <key>tile-data</key>
                    <dict>
                        <key>file-data</key>
                        <dict>
                            <key>_CFURLString</key>
                            <string>/Applications/Safari.app</string>
                            <key>_CFURLStringType</key>
                            <integer>0</integer>
                        </dict>
                        <key>file-label</key>
                        <string>Safari</string>
                    </dict>
                    <key>tile-type</key>
                    <string>file-tile</string>
                </dict>
            </array>
        </dict>
        <key>DocItems-Raw</key>
        <dict>
            <key>state</key>
            <string>always</string>
            <key>upk</key>
            <dict>
                <key>mcx_input_key_names</key>
                <array>
                    <string>DocItems-Raw</string>
                </array>
                <key>mcx_output_key_name</key>
                <string>static-others</string>
                <key>mcx_remove_duplicates</key>
                <true/>
            </dict>
            <key>value</key>
            <array/>
        </dict>
        <key>MCXDockSpecialFolders-Raw</key>
        <dict>
            <key>state</key>
            <string>always</string>
            <key>upk</key>
            <dict>
                <key>mcx_input_key_names</key>
                <array>
                    <string>MCXDockSpecialFolders-Raw</string>
                </array>
                <key>mcx_output_key_name</key>
                <string>MCXDockSpecialFolders</string>
                <key>mcx_remove_duplicates</key>
                <true/>
            </dict>
            <key>value</key>
            <array/>
        </dict>
        <key>contents-immutable</key>
        <dict>
            <key>state</key>
            <string>always</string>
            <key>value</key>
            <false/>
        </dict>
        <key>static-only</key>
        <dict>
            <key>state</key>
            <string>always</string>
            <key>value</key>
            <false/>
        </dict>
    </dict>
</dict>
</plist>
'
}
