# Steam・Epic・指定フォルダーのゲームを検出し、Restic が保存する一時領域へセーブを集める。
$ErrorActionPreference = 'Stop'
# 定期タスクでも Ludusavi の UTF-8 出力を正しく読み取り、日本語の文字化けを防ぐ。
$OutputEncoding = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = $OutputEncoding
$ludusavi = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\mtkennerly.ludusavi_Microsoft.Winget.Source_8wekyb3d8bbwe\ludusavi.exe'
$configDir = Join-Path $HOME '.config\ludusavi-steam'
$backupDir = Join-Path $env:LOCALAPPDATA 'ludusavi-steam-backup'

if (-not (Test-Path -LiteralPath $ludusavi)) {
    throw 'Ludusavi is not installed. Install mtkennerly.ludusavi with winget.'
}

# Ludusavi が設定を書き直すため、chezmoi は初期設定だけを管理し、未作成時にコピーする。
$configFile = Join-Path $configDir 'config.yaml'
if (-not (Test-Path -LiteralPath $configFile)) {
    Copy-Item -LiteralPath (Join-Path $configDir 'initial-config.yaml') -Destination $configFile
}

# 保存先の大文字・小文字だけが異なる項目も読み込める JSON パーサーを使う。
Add-Type -AssemblyName System.Web.Extensions
$json = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$json.MaxJsonLength = [int]::MaxValue
# 現在の設定を読み込み、利用者が変更した設定を引き継いで検出ルートを追加する。
$configText = & $ludusavi --config $configDir config show --api
if ($LASTEXITCODE -ne 0) { throw 'Could not read Ludusavi configuration.' }
$config = $json.DeserializeObject(($configText -join "`n"))
$librariesConfig = Get-Content -LiteralPath (Join-Path $configDir 'libraries.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$roots = @($config['roots'])
$customGames = @($config['customGames'])
# セーブ先データベースの更新を確認する。通信失敗時は取得済みのデータを使う。
& $ludusavi --config $configDir manifest update
if ($LASTEXITCODE -ne 0) {
    Write-Warning 'Manifest update failed; using the cached manifest if available.'
}
$manifestText = & $ludusavi --config $configDir --try-manifest-update manifest show --api
if ($LASTEXITCODE -ne 0) {
    throw 'Ludusavi could not load its manifest.'
}
try {
    $manifest = $json.DeserializeObject(($manifestText -join "`n"))
} catch {
    throw 'Ludusavi manifest JSON could not be decoded.'
}
if (-not $manifest.Count) {
    throw 'Ludusavi manifest is empty. Retry when the manifest can be downloaded.'
}
# インストール一覧と照合できるよう、Steam ID とゲーム名・フォルダー名で索引を作る。
$gamesById = @{}
$gamesByName = @{}
function Get-GameKey([string]$name) {
    # 表記の違いを吸収するため、大文字・小文字と空白・記号を正規化する。
    return ($name.ToLowerInvariant() -replace '[^\p{L}\p{Nd}]', '')
}
foreach ($title in $manifest.get_Keys()) {
    $game = $manifest.get_Item($title)
    if ($game['alias']) { continue }
    $entry = @{ title = $title; cloud = $game['cloud'] }
    $gamesByName[(Get-GameKey $title)] = $entry
    if ($game['installDir']) {
        foreach ($folder in $game['installDir'].get_Keys()) {
            $gamesByName[(Get-GameKey $folder)] = $entry
        }
    }
    if ($game['steam'] -and $game['steam']['id']) {
        $gamesById[[string]$game['steam']['id']] = $entry
        if ($game['id'] -and $game['id']['steamExtra']) {
            foreach ($extraId in $game['id']['steamExtra']) {
                $gamesById[[string]$extraId] = $entry
            }
        }
    }
}

# Steam の全ライブラリを調べ、インストール済みのゲームと配置先を取得する。
$steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath
if (-not $steam) {
    throw 'Steam installation path was not found.'
}
$libraryFile = Join-Path $steam 'steamapps\libraryfolders.vdf'
$libraries = @($steam.Replace('/', '\'))
foreach ($match in (Select-String -LiteralPath $libraryFile -Pattern '^\s*"path"\s+"([^"]+)"')) {
    $libraries += $match.Matches[0].Groups[1].Value.Replace('\\', '\').Replace('/', '\')
}
$titles = @()
$report = @()
$installed = @()
foreach ($library in ($libraries | Sort-Object -Unique)) {
    if (-not @($roots | Where-Object { $_['path'].Replace('\', '/') -eq $library.Replace('\', '/') -and $_['store'] -eq 'steam' }).Count) {
        $roots += @{ store = 'steam'; path = $library }
    }
    $appFiles = @(Get-ChildItem -Path (Join-Path $library 'steamapps\appmanifest_*.acf') -ErrorAction SilentlyContinue)
    foreach ($appFile in $appFiles) {
        $app = @{}
        foreach ($match in (Select-String -LiteralPath $appFile.FullName -Pattern '^\s*"(appid|name|installdir)"\s+"([^"]+)"')) {
            $app[$match.Matches[0].Groups[1].Value] = $match.Matches[0].Groups[2].Value
        }
        # ゲーム本体ではない Steam 共通ランタイムは対象から外す。
        if ($app.appid -eq '228980') { continue }
        $installed += @{ store = 'steam'; id = $app.appid; name = $app.name; game = $gamesById[$app.appid]; path = (Join-Path $library ('steamapps\common\' + $app.installdir)) }
    }
}

# Epic Launcher の管理情報から、実際にインストール先が存在するゲームを取得する。
$epicManifests = Join-Path $env:ProgramData 'Epic\EpicGamesLauncher\Data\Manifests'
foreach ($item in @(Get-ChildItem -LiteralPath $epicManifests -Filter '*.item' -ErrorAction SilentlyContinue)) {
    $app = Get-Content -LiteralPath $item.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not (Test-Path -LiteralPath $app.InstallLocation -PathType Container)) { continue }
    $parent = Split-Path $app.InstallLocation
    if (-not @($roots | Where-Object { $_['path'].Replace('\', '/') -eq $parent.Replace('\', '/') -and $_['store'] -eq 'epic' }).Count) {
        $roots += @{ store = 'epic'; path = $parent }
    }
    $installed += @{ store = 'epic'; id = $app.AppName; name = $app.DisplayName; game = $gamesByName[(Get-GameKey $app.DisplayName)]; path = $app.InstallLocation }
}

# N:\pf などの指定フォルダーを調べ、日本語名の対応表と個別の保存ルールを適用する。
foreach ($folderRoot in $librariesConfig.folders) {
    if (-not (Test-Path -LiteralPath $folderRoot -PathType Container)) {
        Write-Warning "Game folder unavailable: $folderRoot"
        continue
    }
    if (-not @($roots | Where-Object { $_['path'].Replace('\', '/') -eq $folderRoot.Replace('\', '/') -and $_['store'] -eq 'other' }).Count) {
        $roots += @{ store = 'other'; path = $folderRoot }
    }
    foreach ($folder in (Get-ChildItem -LiteralPath $folderRoot -Directory)) {
        $lookup = $folder.Name
        if ($librariesConfig.aliases.PSObject.Properties[$lookup]) { $lookup = $librariesConfig.aliases.$lookup }
        $game = $gamesByName[(Get-GameKey $lookup)]
        $rule = @($librariesConfig.portableRules | Where-Object { $folder.Name -like $_.pattern })
        if ($rule.Count) {
            # データベース未登録のゲームは libraries.json に定義した保存先で登録する。
            $title = 'Portable: ' + $folder.Name
            $files = @($rule[0].files | ForEach-Object { $folder.FullName.Replace('\', '/') + '/' + $_ })
            $customGames = @($customGames | Where-Object { $_['name'] -ne $title })
            $customGames += @{ name = $title; integration = 'override'; files = $files }
            $game = @{ title = $title; cloud = $null }
        }
        $installed += @{ store = 'other'; id = $folder.FullName; name = $folder.Name; game = $game; path = $folder.FullName }
        if ($game) {
            # 既存のセーブ先ルールに、実際のインストールフォルダー名を追加する。
            $custom = @($customGames | Where-Object { $_['name'] -eq $game.title })
            if (-not $custom.Count) {
                $customGames += @{ name = $game.title; integration = 'extend'; installDir = @($folder.Name) }
            } elseif ($custom[0]['installDir'] -notcontains $folder.Name) {
                $custom[0]['installDir'] = @($custom[0]['installDir']) + $folder.Name
            }
        }
    }
}
# 検出ルートと追加ルールを反映する。Ludusavi が読み込める BOM なし UTF-8 で保存する。
$config['roots'] = $roots
$config['customGames'] = $customGames
$configJson = ConvertTo-Json -InputObject $config -Depth 100 -Compress
[IO.File]::WriteAllText($configFile, $configJson, (New-Object System.Text.UTF8Encoding($false)))

# 保存中のファイルを避けるため、起動中のゲームは次回のバックアップに回す。
$processPaths = @(Get-CimInstance Win32_Process | ForEach-Object { $_.ExecutablePath } | Where-Object { $_ })
foreach ($app in $installed) {
    $game = $app.game
    $state = 'selected'
    if (-not $game) {
        $state = 'unknown-to-ludusavi'
    } elseif ($game.cloud -and $game.cloud[$app.store] -and -not ($app.store -eq 'steam' -and $librariesConfig.includeSteamAppIds -contains [int]$app.id)) {
        # ストアごとにクラウド対応を判定する。Apex などの指定 ID は例外として保存する。
        $state = "$($app.store)-cloud"
    } else {
        $running = @($processPaths | Where-Object { $_.StartsWith($app.path.TrimEnd('\', '/') + '\', [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
        if ($app.store -eq 'steam') {
            $running = $running -or (Get-ItemProperty "HKCU:\Software\Valve\Steam\Apps\$($app.id)" -ErrorAction SilentlyContinue).Running
        }
        if ($running) { $state = 'running' } else { $titles += $game.title }
    }
    $report += [pscustomobject]@{ store = $app.store; appId = $app.id; name = $app.name; title = $game.title; state = $state }
}

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
$report | Where-Object { $_.state -eq 'selected' -or $_.state -eq 'running' } |
    Format-Table store, name, state -AutoSize | Out-Host
if ($titles.Count) {
    # ゲーム名の明示指定は Ludusavi のクラウド除外より優先されるため、除外判定は上で行う。
    & $ludusavi --config $configDir --no-manifest-update backup --force --no-cloud-sync @($titles | Sort-Object -Unique)
    if ($LASTEXITCODE -ne 0) {
        # 途中で失敗した場合は Restic の後続処理も止め、不完全な実行結果の保存を防ぐ。
        throw 'Ludusavi backup failed. Restic will not snapshot an incomplete run.'
    }
}
# 未登録・クラウド対応・起動中などの判定結果も、確認用の記録として保存する。
@{ scannedAt = (Get-Date).ToString('o'); games = $report } | ConvertTo-Json -Depth 4 |
    Set-Content -LiteralPath (Join-Path $backupDir 'scan-report.json') -Encoding UTF8
