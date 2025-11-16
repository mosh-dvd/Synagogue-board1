[Setup]
AppName=to
AppVersion=1.0.1
AppPublisher=Mosh-DVD
DefaultDirName={autopf}\Synagogue Display
AppId={{ synagogue_display_guid }}
OutputDir=Output
OutputBaseFilename=setup
Compression=lzma
SolidCompression=yes
; שורה זו נכונה וחשובה, נשאיר אותה
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; --- הנה התיקון: החזרנו את x64 לנתיב ---
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Synagogue Display"; Filename: "{app}\to.exe"
Name: "{autodesktop}\Synagogue Display"; Filename: "{app}\to.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\synagogue_display.exe"; Description: "{cm:LaunchProgram,Synagogue Display}"; Flags: nowait postinstall skipifsilent