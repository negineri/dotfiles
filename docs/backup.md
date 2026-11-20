# 設定・ゲームセーブのバックアップ

Windows 用の設定ファイル、音楽ライブラリ、ゲームセーブを Restic で暗号化し、OneDrive の同期フォルダーに保存する。スケジュール管理には resticprofile、ゲームのセーブ先検出には Ludusavi を使う。

このディレクトリは `.chezmoiignore` によりホームディレクトリへの配置対象から除外している。

## 保存の流れ

アプリの設定・ライブラリは、resticprofile が保存元を直接 Restic に渡す。ゲームは先に Ludusavi が必要なファイルやレジストリを集め、その出力を Restic が保存する。

```text
アプリの設定・音楽ライブラリ ──────────────────┐
                                             ├→ Restic → OneDrive/Backups/restic
Steam・Epic・指定フォルダー → Ludusavi → 作業用コピー ┘
```

保存先は環境変数 `OneDriveConsumer`、次に `OneDrive` の順で決定する。どちらも未設定なら設定生成を中止する。クラウド側への転送は OneDrive アプリが行うため、Restic の正常終了と OneDrive の同期完了はそれぞれ確認する。

Restic のパスワードは Bitwarden の `restic` アイテムから生成する。生成先の `$HOME\.config\resticprofile\password.txt` は現在の利用者と SYSTEM にアクセスを制限する。新しい PC での復元にも同じパスワードが必要になる。

## バックアップ対象と実行時刻

時刻は Windows のローカル時刻。ユーザーがログインしている間、タスクスケジューラで実行する。

| プロファイル | 保存元 | 実行時刻 | 起動中の扱い |
| --- | --- | --- | --- |
| `apple-music` | `$HOME\Music\Apple Music` | 毎時00分 | Apple Music が起動中ならその回は中止 |
| `eac` | EAC レジストリのエクスポートと `$env:APPDATA\EAC` | 毎時05分 | EAC が起動中ならその回は中止 |
| `obs-studio` | `$env:APPDATA\obs-studio` | 毎時15分 | OBS が起動中ならその回は中止 |
| `musicbee` | `$HOME\Music\MusicBee` と Store 版の設定フォルダー | 毎時30分 | MusicBee が起動中ならその回は中止 |
| `steam-saves` | Ludusavi の作業用コピー | 毎時45分 | 起動中と判定したゲームをスキップ |

MusicBee の Store 版設定は `$env:LOCALAPPDATA\Packages\50072StevenMayall.MusicBee_kcr266et74avj\LocalCache\Roaming\MusicBee` にある。OBS はログ、クラッシュ情報、プロファイラー出力、更新用データ、一部キャッシュを除外する。

ゲーム用プロファイルの名前は、Epic と指定フォルダーを追加した後も `steam-saves` を使っている。

保持期間は全プロファイルが `base` を継承し、時間単位24件、日単位7件、週単位4件、月単位12件を残す。バックアップ後に保持ポリシーを適用し、不要なデータを prune する。これらは期間ごとの選別規則で、スナップショットの合計件数は各値の単純な合算にはならない。

## 管理ファイル

| リポジトリ内のファイル | 役割 |
| --- | --- |
| `dot_config/resticprofile/profiles.yaml.tmpl` | 保存先、プロファイル、保持期間、スケジュール |
| `dot_config/resticprofile/private_password.txt.tmpl` | Bitwarden からのパスワード生成 |
| `run_onchange_after_85-restic.ps1.tmpl` | 権限設定、リポジトリ初期化、音楽ライブラリの初回復元、タスク登録 |
| `dot_config/resticprofile/backup-steam-saves.ps1` | ゲーム検出、対象判定、Ludusavi の実行 |
| `dot_config/resticprofile/backup-eac.ps1` | 現在の EAC レジストリを保存用ファイルへエクスポート |
| `run_onchange_after_80-qaac.ps1.tmpl` | qaac・refalac と関連ファイルを共通の `C:\bin` へ配置 |
| `dot_config/ludusavi-steam/libraries.json` | 追加フォルダー、ゲーム名の対応表、個別保存ルール、Steam Cloud 除外の例外 |
| `dot_config/ludusavi-steam/initial-config.yaml.tmpl` | Ludusavi の初回設定 |
| `.chezmoidata/packages.yaml` | Restic、resticprofile、Ludusavi のインストール指定 |

`chezmoi apply` でホームディレクトリの `.config` 以下に配置する。Restic 設定が変更されると初期設定スクリプトが再実行され、定期タスクを登録する。秘密情報の復号を無効にした適用では、この初期設定スクリプトは終了する。

### Ludusavi の config.yaml

`$HOME\.config\ludusavi-steam\config.yaml` は Ludusavi が既定値を展開して書き直すため、chezmoi の追跡対象から外している。未作成の場合、バックアップスクリプトが `initial-config.yaml` をコピーする。

既存の `config.yaml` がある場合、初期設定テンプレートを変更しても、その内容は自動コピーされない。現在の設定も変更する。`libraries.json` の追加ルートと個別ルールは、スクリプトが実行のたびに既存設定へ反映する。GUI だけで加えた設定を別の PC にも引き継ぐ場合は、該当する初期設定や `libraries.json` にも記録する。

## ゲームの自動検出

毎回、Ludusavi のセーブ先データベースの更新を確認する。更新に失敗しても取得済みデータがあれば処理を継続する。

| インストール元 | 検出方法 | クラウド対応の判定 |
| --- | --- | --- |
| Steam | `libraryfolders.vdf` と各ライブラリの `appmanifest_*.acf` | Ludusavi の Steam Cloud 情報を参照 |
| Epic | `%ProgramData%\Epic\EpicGamesLauncher\Data\Manifests\*.item` | Ludusavi の Epic Cloud 情報を参照 |
| 指定フォルダー | `libraries.json` の `folders` にあるフォルダーの直下を列挙 | ローカル保存データを対象にする |

ゲーム名やインストールフォルダー名を Ludusavi の登録名と照合する。日本語名などは `aliases` で補い、データベース未登録のゲームは `portableRules` で保存先を定義できる。

Apex Legends は `includeSteamAppIds` に `1172470` を指定しており、Steam Cloud の登録にかかわらず操作・映像・プロファイル設定を保存する。クラウドの対応情報はデータベースの記載に依存する。

作業用コピーは `$env:LOCALAPPDATA\ludusavi-steam-backup` にある。`mapping.yaml` には元の保存先などが記録され、Ludusavi が復元に使う。Ludusavi 側は最新のフルバックアップ1件を保持し、過去の履歴は Restic に保存する。

ゲームが `selected` と判定されても、まだ一度もセーブしていない場合などは保存ファイルが見つからないことがある。実際の保存結果は Ludusavi の出力や Restic のファイル一覧で確認する。

## 確認・手動実行

以下は PowerShell で実行する。winget のコマンドエイリアスが未反映でも使えるよう、実行ファイルを直接指定している。

```powershell
$rp = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\creativeprojects.resticprofile_Microsoft.Winget.Source_8wekyb3d8bbwe\resticprofile.exe"
$ludusavi = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\mtkennerly.ludusavi_Microsoft.Winget.Source_8wekyb3d8bbwe\ludusavi.exe"
$config = "$HOME\.config\resticprofile\profiles.yaml"
$gameSource = "$env:LOCALAPPDATA\ludusavi-steam-backup"
```

ゲームを閉じてから、手動で検出から暗号化保存まで実行する。

```powershell
& $rp --config $config steam-saves.backup
```

スナップショットと最新ファイル一覧を確認する。リポジトリには複数プロファイルが共存するため、`latest` は保存元パスで絞る。

```powershell
& $rp --config $config steam-saves.snapshots --path $gameSource
& $rp --config $config steam-saves.ls latest --path $gameSource
```

特定の履歴を見る場合は、表示された ID を指定する。

```powershell
$snapshotId = Read-Host '確認するスナップショット ID'
& $rp --config $config steam-saves.ls $snapshotId
```

検出記録には `selected`、`running`、`unknown-to-ludusavi`、`steam-cloud`、`epic-cloud` などの状態が入る。

```powershell
$report = Get-Content "$gameSource\scan-report.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$report.games | Format-Table store, name, state -AutoSize
notepad "$HOME\.config\resticprofile\steam-saves.log"
Get-ScheduledTask -TaskPath '\resticprofile backup\' |
    Get-ScheduledTaskInfo |
    Format-Table TaskName, LastRunTime, LastTaskResult, NextRunTime
```

タスクの終了コードに加えて、ログの保存成功とスナップショット作成を確認する。GUI の設定画面は次で開く。

```powershell
& $ludusavi --config "$HOME\.config\ludusavi-steam" gui
```

## バックアップ対象を追加する

### アプリの設定フォルダーを追加する

1. `dot_config/resticprofile/profiles.yaml.tmpl` に `base` を継承するプロファイルを追加する。次は架空のアプリの例で、保存元とプロセス名を実際のものに置き換える。

   ```yaml
   example-app:
     inherit: base
     backup:
       run-before: 'powershell.exe -NoProfile -NonInteractive -Command exit ([int][bool](Get-Process ExampleApp -ErrorAction SilentlyContinue))'
       source:
         - '{{ env "APPDATA" }}\ExampleApp'
       schedule: "02:10"
   ```

2. `run_onchange_after_85-restic.ps1.tmpl` の末尾にある登録対象へ `example-app` を追加する。

   ```powershell
   foreach ($profile in ($apps.profile + @("eac", "obs-studio", "steam-saves", "example-app"))) {
   ```

3. `chezmoi apply` で反映し、アプリを閉じて手動バックアップと保存内容を確認する。

   ```powershell
   chezmoi apply
   & $rp --config $config example-app.backup
   & $rp --config $config example-app.snapshots
   ```

保存元が存在することを確認する。キャッシュやログを外す場合は `backup.exclude` を追加する。保持期間は `base`、実行時刻は各プロファイルで設定する。

### Steam・Epic のゲームを追加する

通常はインストールして一度セーブし、ゲームを終了すると次の定期実行で検出される。クラウド対応として登録されたゲームも保存したい場合、Steam は `libraries.json` の `includeSteamAppIds` に App ID を追加する。既存の Apex の値を残して追加する。

```json
"includeSteamAppIds": [1172470, 123456]
```

Epic 向けの強制保存 ID リストは現在のスクリプトにはない。Epic Cloud 対応ゲームの強制保存を追加する場合は、スクリプトのストア別除外判定にも変更が必要になる。

### 指定フォルダーを追加する

`dot_config/ludusavi-steam/libraries.json` の `folders` にゲームの親フォルダーを追加する。パスは `/` 区切りで書く。

```json
"folders": ["N:/pf", "N:/pf/上海アリス幻樂団", "D:/Games"]
```

列挙するのは各フォルダーの直下。さらに下の階層にゲームが並ぶ場合は、その親フォルダーも明示的に追加する。ネットワークドライブはタスクを実行するユーザーからアクセスできる必要がある。

### ゲーム名の対応表を追加する

フォルダー名と Ludusavi の登録名が違う場合は `aliases` に追加する。値にはデータベース上の正確なゲーム名を指定する。

```json
"aliases": {
  "東方紅魔郷": "The Embodiment of Scarlet Devil",
  "独自のフォルダー名": "Ludusavi の正式なゲーム名"
}
```

対応表が適用されると、そのゲームの既存の保存先ルールに実際のフォルダー名が加わる。上の例は既存オブジェクトへの追加部分として使う。

### 未登録ゲームのセーブ先を追加する

`portableRules` にフォルダー名のパターンと保存するファイル・ディレクトリを追加する。次は架空のゲームの例。

```json
{
  "pattern": "ExampleGame*",
  "files": ["save", "profile/*.sav", "config.ini"]
}
```

`pattern` はゲームのフォルダー名に照合する PowerShell のワイルドカード。`files` はそのゲームフォルダーからの相対パスで、Ludusavi の保存パターンとして使う。入れ子の場合は `*/save` のように実際の階層を含める。登録名は `Portable: フォルダー名` になる。

ルールはスキャンごとに設定へ反映される。ゲームフォルダー内の対応ルールがある場合は、そのルールを優先する。フォルダー外の保存先やレジストリが必要なら、Ludusavi のカスタムゲーム設定に追加し、別 PC で再現するため初期設定テンプレートにも記録する。

### 変更を反映して検証する

JSON は既存のキーや項目を保持して編集する。編集後は構文を確認し、chezmoi で反映する。

```powershell
$sourceDir = chezmoi source-path
Get-Content "$sourceDir\dot_config\ludusavi-steam\libraries.json" -Raw -Encoding UTF8 |
    ConvertFrom-Json | Out-Null
chezmoi apply
& $rp --config $config steam-saves.backup
$report = Get-Content "$gameSource\scan-report.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$report.games | Format-Table store, name, state -AutoSize
& $rp --config $config steam-saves.ls latest --path $gameSource
```

バックアップ時の個別ゲームの表示、検出記録、スナップショット内のファイルを確認する。未検出の場合は保存操作を行ったか、ゲーム名の対応表が必要か、保存先ルールに実際のファイルが一致するかを調べる。

## 復元する

Apple Music と MusicBee は、初回設定スクリプトでライブラリの目印ファイルが見つからず、対応するスナップショットがある場合に復元する。OBS とゲームは以下のように履歴を選んで手動復元する。

### EAC のレジストリ設定

EAC の設定は現在のレジストリをバックアップして管理する。従来の `.chezmoitemplates/eac.reg` と自動インポート処理は削除済み。共通のエンコーダー配置スクリプト `run_onchange_after_80-qaac.ps1.tmpl` が qaac・refalac と関連ファイルを `C:\bin` へ配置する。

このテンプレートには winget 配下の qaac の配置元パスとファイル内容から計算したハッシュを埋め込む。qaac の更新でパスや内容が変わると、次の `chezmoi apply` でスクリプトが再実行され、最新版を配置する。ハッシュの計算対象は各 `qaac_*\x64` の直下にあるファイル。実際のコピー元はバージョン番号で比較して決める。

バックアップ前に `HKCU\Software\AWSoftware\EACU` 以下を `$env:LOCALAPPDATA\eac-registry-backup\eac.reg` に書き出す。エクスポートに成功した場合に保存用ファイルを更新し、Restic が AppData の EAC フォルダーと一緒に暗号化保存する。新しい PC でキーがまだ存在しない場合は、既存のバックアップを復元するか EAC で設定してから定期バックアップを開始する。

手動バックアップと履歴確認は次で行う。

```powershell
& $rp --config $config eac.backup
& $rp --config $config eac.snapshots --path "$env:LOCALAPPDATA\eac-registry-backup"
notepad "$HOME\.config\resticprofile\eac.log"
```

復元時は EAC を終了する。スナップショット内の `eac-registry-backup` のパスを確認し、別フォルダーへ取り出す。

```powershell
$snapshotId = Read-Host '復元する EAC スナップショット ID'
& $rp --config $config eac.ls $snapshotId
$snapshotFolder = Read-Host '一覧に表示された eac-registry-backup の内部パス'
$recoveryDir = Join-Path $env:TEMP ('eac-recovery-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
& $rp --config $config eac.restore "${snapshotId}:$snapshotFolder" --target $recoveryDir
if ($LASTEXITCODE -ne 0) { throw 'EAC バックアップの取り出しに失敗しました。' }
```

取り出した `eac.reg` を確認してから、EAC を使う Windows ユーザーで手動インポートする。

```powershell
if (Get-Process EAC -ErrorAction SilentlyContinue) { throw 'EAC を終了してください。' }
reg.exe import (Join-Path $recoveryDir 'eac.reg')
if ($LASTEXITCODE -ne 0) { throw 'EAC レジストリの復元に失敗しました。' }
```

`.reg` のインポートは保存された値を既存のキーに反映する。レジストリのアクセス権は `.reg` に含まれない。プロファイルや CDDB を戻す場合は、同じスナップショットの `AppData/Roaming/EAC` も別フォルダーへ取り出し、EAC の終了中に現在の AppData の EAC フォルダーへ戻す。

### ゲームセーブ

ゲームを終了し、前述のコマンドで復元するスナップショット ID と内部パスを確認する。まず Restic から別フォルダーへ Ludusavi 形式のコピーを取り出す。

```powershell
$snapshotId = Read-Host '復元するスナップショット ID'
& $rp --config $config steam-saves.ls $snapshotId
$snapshotFolder = Read-Host '一覧に表示された ludusavi-steam-backup の内部パス'
$recoveryDir = Join-Path $env:TEMP ('game-saves-recovery-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
& $rp --config $config steam-saves.restore "${snapshotId}:$snapshotFolder" --target $recoveryDir
if ($LASTEXITCODE -ne 0) { throw 'Restic の復元に失敗しました。' }
```

内部パスは `/C/Users/ユーザー名/AppData/Local/ludusavi-steam-backup` のような表記。別 PC のバックアップでは元のユーザー名やドライブ名を使う。

取り出したフォルダーを Ludusavi に渡し、対象ゲームの復元プレビューを確認する。

```powershell
& $ludusavi --config "$HOME\.config\ludusavi-steam" restore --preview --path $recoveryDir 'Subnautica'
```

復元先が意図した保存場所であることを確認してから実行する。既存ファイルへの書き戻しが発生する。

```powershell
& $ludusavi --config "$HOME\.config\ludusavi-steam" restore --path $recoveryDir 'Subnautica'
```

ゲーム名は保存時の名前を使う。保存時と PC のユーザー名やゲームの配置先が異なる場合は、プレビューを確認し、Ludusavi のリダイレクト設定などで復元先を調整する。

### OBS などの設定

対応するプロファイルでスナップショットを選び、設定フォルダーの内部パスを指定して別フォルダーに取り出す。前述のゲーム用コマンドと同様に `obs-studio.ls`、`obs-studio.restore` を使える。アプリを終了し、取り出した内容を確認してから元の設定フォルダーへ戻す。

## 関連する公式資料

- [resticprofile のコマンドフック](https://creativeprojects.github.io/resticprofile/configuration/run_hooks/)
- [Restic の復元](https://restic.readthedocs.io/en/stable/050_restore.html)
- [Ludusavi の CLI](https://github.com/mtkennerly/ludusavi/blob/master/docs/cli.md)
- [Ludusavi の検出ルート](https://github.com/mtkennerly/ludusavi/blob/master/docs/help/roots.md)
