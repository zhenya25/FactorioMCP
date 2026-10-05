# Talks to the running Factorio sandbox through the FactorioMCP server built in this repository.
# Keep this file ASCII-only: Windows PowerShell 5.1 reads scripts without a BOM as ANSI.
#
#   factorio.ps1 lua <file.lua> [more.lua ...]     run Lua files joined in order; bare names resolve to scripts/lua
#   factorio.ps1 call <tool> [args.json | '{..}']  call any MCP tool of the server
#   factorio.ps1 fetch <script-output file> <path under blueprint-books>   copy a file the game wrote
#   factorio.ps1 list                               show the books (folder -> label)
#   factorio.ps1 add <book> <sub-book> <file>       list a blueprint file in a sub-book of book.json
#   factorio.ps1 assemble [book]                    rebuild a book from its files and validate it in the game
#   factorio.ps1 give [book]                        assemble, then put the book into the player's inventory
#   factorio.ps1 clipboard [book]                   copy the last built import string; never touches the game
# [book] is a folder name under blueprint-books/ or the book label; optional while there is only one book.
param(
    [Parameter(Position = 0)][string]$Command,
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)][string[]]$Rest
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$utf8 = New-Object Text.UTF8Encoding($false)
$luaDir = Join-Path $PSScriptRoot 'lua'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$booksDir = Join-Path $root 'blueprint-books'
$scriptOutput = Join-Path $env:APPDATA 'Factorio\script-output'
$dllRelative = 'FactorioMCP\bin\Release\net9.0\FactorioMCP.dll'

$script:proc = $null
$script:pending = $null
$script:nextId = 10

function Send-Line([string]$text) {
    $bytes = $utf8.GetBytes($text + "`n")
    $script:proc.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
    $script:proc.StandardInput.BaseStream.Flush()
}

function Read-Response([int]$id, [double]$timeoutSec) {
    $deadline = (Get-Date).AddSeconds($timeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (-not $script:pending) { $script:pending = $script:proc.StandardOutput.ReadLineAsync() }
        $ms = [int][Math]::Max(1, ($deadline - (Get-Date)).TotalMilliseconds)
        if ($script:pending.Wait($ms)) {
            $line = $script:pending.Result
            $script:pending = $null
            if ($null -eq $line) { throw 'The MCP server exited. Is Factorio hosted with RCON on 127.0.0.1:27015?' }
            if ($line.Contains('"id":' + $id + ',"jsonrpc"')) { return $line }
        }
    }
    throw "Timed out after $timeoutSec s waiting for the MCP server."
}

function Start-Server {
    if (-not (Test-Path (Join-Path $root $dllRelative))) {
        throw "Server is not built. Run: dotnet build FactorioMCP -c Release"
    }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'cmd.exe'
    $psi.Arguments = '/c dotnet "' + $dllRelative + '" 2>NUL'
    $psi.WorkingDirectory = $root
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.StandardOutputEncoding = [Text.Encoding]::UTF8
    $psi.EnvironmentVariables['Logging__Console__LogToStandardErrorThreshold'] = 'Trace'
    $script:proc = [Diagnostics.Process]::Start($psi)
    Send-Line '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"factorio-blueprints","version":"1"}}}'
    [void](Read-Response 1 45)
    Send-Line '{"jsonrpc":"2.0","method":"notifications/initialized"}'
}

function Stop-Server {
    if ($script:proc -and -not $script:proc.HasExited) {
        & taskkill /T /F /PID $script:proc.Id 2>$null | Out-Null
    }
}

function Invoke-Tool([string]$name, $arguments, [double]$timeoutSec = 180) {
    $script:nextId++
    $request = @{ jsonrpc = '2.0'; id = $script:nextId; method = 'tools/call'; params = @{ name = $name; arguments = $arguments } }
    Send-Line (ConvertTo-Json $request -Compress -Depth 20)
    $response = (Read-Response $script:nextId $timeoutSec) | ConvertFrom-Json
    if ($response.error) { throw "MCP error: $($response.error.message)" }
    $text = (@($response.result.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join "`n"
    if ($response.result.isError) { throw "Tool '$name' failed: $text" }
    return $text.TrimEnd()
}

function Invoke-Lua([string]$code) {
    $text = Invoke-Tool 'execute_lua' @{ luaCode = $code }
    if ($text.StartsWith('Cannot execute command')) { throw "Lua failed: $text" }
    return $text
}

function Resolve-LuaFile([string]$name) {
    if (Test-Path $name) { return (Resolve-Path $name).Path }
    $inSkill = Join-Path $luaDir $name
    if (Test-Path $inSkill) { return $inSkill }
    throw "Lua file not found: $name"
}

# Lua long strings swallow nothing but a leading newline, so file contents travel unescaped.
function Send-Text([string]$key, [string]$text) {
    $size = 6000
    for ($i = 0; $i -lt $text.Length; $i += $size) {
        $chunk = $text.Substring($i, [Math]::Min($size, $text.Length - $i))
        if ($chunk.Contains(']==]')) { throw "Text for '$key' contains ']==]' and cannot be uploaded." }
        [void](Invoke-Lua ("storage.mcp_asm = storage.mcp_asm or {} local k = [==[$key]==] storage.mcp_asm[k] = (storage.mcp_asm[k] or '') .. [==[`n$chunk]==] rcon.print('ok')"))
    }
}

function Get-ManifestFiles($node) {
    if ($node.file) { return @($node.file) }
    $files = @()
    foreach ($child in @($node.children)) { if ($child) { $files += Get-ManifestFiles $child } }
    return $files
}

# A book is a folder under blueprint-books/ with a book.json; it is addressed by folder name or by label.
function Get-Books {
    Get-ChildItem $booksDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'book.json') } |
        ForEach-Object {
            $label = ([IO.File]::ReadAllText((Join-Path $_.FullName 'book.json'), $utf8) | ConvertFrom-Json).label
            [pscustomobject]@{ Name = $_.Name; Label = $label; Path = $_.FullName }
        }
}

function Resolve-Book([string]$query) {
    $books = @(Get-Books)
    $available = ($books | ForEach-Object { "$($_.Name) ($($_.Label))" }) -join '; '
    if (-not $query) {
        if ($books.Count -eq 1) { return $books[0] }
        throw "Name the book. Available: $available"
    }
    $hit = @($books | Where-Object { $_.Name -eq $query -or $_.Label -eq $query })
    if ($hit.Count -eq 0) { $hit = @($books | Where-Object { $_.Name -like "*$query*" -or $_.Label -like "*$query*" }) }
    if ($hit.Count -ne 1) { throw "'$query' matches $($hit.Count) books. Available: $available" }
    return $hit[0]
}

# Rebuild the book in the game from its files, validate it there and save the import string next to them.
function Build-Book($book) {
    $manifestText = [IO.File]::ReadAllText((Join-Path $book.Path 'book.json'), $utf8)
    $files = @(Get-ManifestFiles ($manifestText | ConvertFrom-Json) | Select-Object -Unique)
    foreach ($file in $files) {
        if (-not (Test-Path (Join-Path $book.Path $file))) { throw "book.json lists a missing file: $file" }
    }
    $listed = $files | ForEach-Object { $_.Replace('\', '/') }
    $orphans = @(Get-ChildItem (Join-Path $book.Path 'blueprints') -Recurse -Filter *.json -ErrorAction SilentlyContinue |
        ForEach-Object { $_.FullName.Substring($book.Path.Length + 1).Replace('\', '/') } |
        Where-Object { $listed -notcontains $_ })

    Start-Server
    [void](Invoke-Lua "storage.mcp_asm = {} rcon.print('ok')")
    Send-Text '__manifest' $manifestText
    foreach ($file in $files) { Send-Text $file ([IO.File]::ReadAllText((Join-Path $book.Path $file), $utf8)) }
    $summary = Invoke-Lua ([IO.File]::ReadAllText((Join-Path $luaDir 'assemble_book.lua'), $utf8))
    $summary
    if ($orphans.Count -gt 0) { "WARNING: blueprint files missing from book.json (not in the book): $($orphans -join ', ')" }
    if (-not $summary.StartsWith('OK')) { throw 'The book was not assembled.' }
    Start-Sleep -Milliseconds 500
    Copy-Item (Join-Path $scriptOutput 'mcp\book.txt') (Join-Path $book.Path 'import-string.txt') -Force
    "saved blueprint-books/$($book.Name)/import-string.txt"
}

try {
    switch ($Command) {
        'lua' {
            if (-not $Rest) { throw 'Usage: factorio.ps1 lua <file.lua> [more.lua ...]' }
            $code = ($Rest | ForEach-Object { [IO.File]::ReadAllText((Resolve-LuaFile $_), $utf8) }) -join "`n"
            Start-Server
            Invoke-Lua $code
        }
        'call' {
            if (-not $Rest) { throw 'Usage: factorio.ps1 call <tool> [args.json | inline JSON]' }
            $arguments = @{}
            if ($Rest.Count -gt 1) {
                $raw = $Rest[1]
                if (Test-Path $raw) { $raw = [IO.File]::ReadAllText((Resolve-Path $raw).Path, $utf8) }
                $arguments = $raw | ConvertFrom-Json
            }
            Start-Server
            Invoke-Tool $Rest[0] $arguments
        }
        'fetch' {
            if ($Rest.Count -lt 2) { throw 'Usage: factorio.ps1 fetch <script-output file> <path under blueprint-books>' }
            $target = Join-Path $booksDir $Rest[1]
            New-Item -ItemType Directory -Force (Split-Path $target -Parent) | Out-Null
            Copy-Item (Join-Path $scriptOutput $Rest[0]) $target -Force
            "saved blueprint-books/$($Rest[1]) ($((Get-Item $target).Length) bytes)"
        }
        'list' {
            Get-Books | ForEach-Object { "$($_.Name)  ->  $($_.Label)" }
        }
        'add' {
            # add <book> <part of a sub-book label> <file path under the book folder>
            if ($Rest.Count -lt 3) { throw 'Usage: factorio.ps1 add <book> <sub-book label part> <blueprints/...json>' }
            $book = Resolve-Book $Rest[0]
            $path = Join-Path $book.Path 'book.json'
            $tree = [IO.File]::ReadAllText($path, $utf8) | ConvertFrom-Json
            $hits = @($tree.children | Where-Object { $_.label -like "*$($Rest[1])*" })
            if ($hits.Count -ne 1) { throw "'$($Rest[1])' matches $($hits.Count) sub-books" }
            $file = $Rest[2].Replace('\', '/')
            if (-not (Test-Path (Join-Path $book.Path $file))) { throw "File not found in the book folder: $file" }
            if (@($hits[0].children | Where-Object { $_.file -eq $file }).Count -eq 0) {
                $hits[0].children = @($hits[0].children) + [pscustomobject]@{ file = $file }
                [IO.File]::WriteAllText($path, (ConvertTo-Json $tree -Depth 30), $utf8)
            }
            "$($hits[0].label): $(@($hits[0].children).Count) blueprint(s)"
        }
        'assemble' {
            Build-Book (Resolve-Book ($Rest -join ' '))
        }
        'give' {
            Build-Book (Resolve-Book ($Rest -join ' '))
            Invoke-Lua "local p = game.connected_players[1] local inv = p.get_main_inventory() or (p.character and p.character.get_main_inventory()) if not inv then rcon.print('ERROR: the player has no inventory in this mode') return end local src = storage.mcp_inv[3] local slot = nil for i = 1, #inv do local it = inv[i] if it.valid_for_read and it.is_blueprint_book and it.label == src.label then slot = it break end end local how = 'replaced the copy' if not slot then how = 'added' for i = 1, #inv do if not inv[i].valid_for_read then slot = inv[i] break end end end if slot then slot.set_stack(src) rcon.print(how .. ' in the inventory of ' .. p.name) else rcon.print('ERROR: no free inventory slot') end"
        }
        'clipboard' {
            # No game connection here on purpose: this is the way to deliver a book to a save with achievements.
            $book = Resolve-Book ($Rest -join ' ')
            $stringPath = Join-Path $book.Path 'import-string.txt'
            if (-not (Test-Path $stringPath)) { throw "No import string yet. Run 'assemble $($book.Name)' with the sandbox hosted." }
            $built = (Get-Item $stringPath).LastWriteTimeUtc
            $newer = @(Get-ChildItem $book.Path -Recurse -Filter *.json | Where-Object { $_.LastWriteTimeUtc -gt $built })
            if ($newer.Count -gt 0) { "WARNING: $($newer.Count) file(s) changed after the import string was built; run 'assemble' in the sandbox to refresh it." }
            Set-Clipboard -Value ([IO.File]::ReadAllText($stringPath).Trim())
            "copied '$($book.Label)' to the clipboard"
        }
        default { throw 'Commands: lua, call, fetch, list, assemble, give, clipboard. See the header of this file.' }
    }
}
finally {
    Stop-Server
}
