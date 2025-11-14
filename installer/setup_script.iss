[Setup]
AppName=Synagogue Display
AppVersion=1.0.9
AppPublisher=Mosh-DVD
DefaultDirName={autopf}\Synagogue Display
AppId={{ synagogue_display_guid }}
OutputDir=Output
OutputBaseFilename=setup
Compression=lzma
SolidCompression=yes
; --- הוספה חדשה: מגדיר את ההתקנה כ-64 ביט ---
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; --- תיקון הנתיב החשוב ---
Source: "..\build\windows\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Synagogue Display"; Filename: "{app}\synagogue_display.exe"
Name: "{autodesktop}\Synagogue Display"; Filename: "{app}\synagogue_display.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\synagogue_display.exe"; Description: "{cm:LaunchProgram,Synagogue Display}"; Flags: nowait postinstall skipifsilent