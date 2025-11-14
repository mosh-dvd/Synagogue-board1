[Setup]
; אתה יכול לשנות את הערכים האלה אם תרצה
AppName="שלט לבית כנסת"
AppVersion=1.0.8
AppPublisher=Mosh-DVD
DefaultDirName={autopf}\Synagogue Display
AppId={{ synagogue_display_guid }} ; מזהה ייחודי
OutputDir=Output
OutputBaseFilename=setup
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; נתיב זה נכון עבור GitHub Actions, אין צורך לשנות
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; כאן השתמשנו בשם ה-EXE הנכון
Name: "{group}\Synagogue Display"; Filename: "{app}\synagogue_display.exe"
Name: "{autodesktop}\Synagogue Display"; Filename: "{app}\synagogue_display.exe"; Tasks: desktopicon

[Run]
; וגם כאן השתמשנו בשם ה-EXE הנכון
Filename: "{app}\synagogue_display.exe"; Description: "{cm:LaunchProgram,Synagogue Display}"; Flags: nowait postinstall skipifsilent