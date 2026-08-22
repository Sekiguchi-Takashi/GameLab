# カタログ設定 変更依頼書

対象アプリ: **gamelab**（GameLab）
作成日: 2026-08-05
起票: GameLab 開発チャット

---

## 1. 変更内容

`gamelab` の **tagPattern** を次のとおり変更する。

| 項目 | 現在 | 変更後 |
|---|---|---|
| tagPattern | `^build-[0-9]+$` | `^v[0-9]+\.[0-9]+\.[0-9]+$` |

あわせて、**記録タグ**が `build-39` のまま残っているため、
現在の最新である `v1.3.4` に更新するか、記録を初期化する。

その他の項目（repo / packageName / assetPattern）は変更不要。

```
repo         Sekiguchi-Takashi/GameLab   （変更なし）
packageName  jp.appathy.gamelab          （変更なし）
assetPattern \.apk$                      （変更なし）
```

---

## 2. 変更が必要な理由

GameLab は当初、リポジトリ内の `build.yml` が push のたびに
`build-<実行番号>` 形式のタグと Release を作成していた。
カタログの tagPattern はこれに合わせて `^build-[0-9]+$` が設定されている。

その後、以下の理由で採番方式を変更した。

1. `actions/upload-artifact` により Artifacts 無料枠（0.5GB）が枯渇し、
   `Artifact storage quota has been hit` で全ビルドが失敗するようになった
2. 納品規約により **`build.yml` は作らず、CI は `release.yml`（タグ起動）のみ**とした
3. 採番を他の新規アプリと揃え、`v1.1.1` 起点の
   セマンティックバージョン形式に統一した

この結果、現在のタグは `v1.3.4` であり、
カタログの `^build-[0-9]+$` と一致しなくなった。

**アプリ側の対応はすべて完了しており、残るのはカタログ設定のみ。**

---

## 3. 現在の状態（診断レポート v3.8 時点）

```
[gamelab] GameLab
  repo=Sekiguchi-Takashi/GameLab
  packageName=jp.appathy.gamelab
  assetPattern=\.apk$
  最新タグ=v1.3.4
  アセット=GameLab.apk
  ！タグがパターンに不一致        ← 本依頼で解消
  sha256=4d468cf1c8f8...          ← 解消済み
  端末: v1.0.0 / 不一致 (更新あり)
  記録タグ=build-39                ← 要リセット
```

要対応は「タグがパターンに不一致」の1件のみ。

---

## 4. アプリ側で完了している対応

| 項目 | 状態 |
|---|---|
| `build.yml` の削除 | 完了 |
| `actions/upload-artifact` の廃止 | 完了 |
| `release.yml`（`v*` タグ起動）の設置 | 完了 |
| `ci/appathy.keystore` の配置 | 完了 |
| Release への APK 添付 | 完了（`GameLab.apk`） |
| Release 本文への sha256 追記 | 完了（`sha256 GameLab.apk <64桁>`） |
| `deploy.sh` のタグ発行 | 完了（`git tag --list 'v*' | sort -V` から算出しローカル発行） |

### sha256 追記について

`stamp.yml` は `on: release` で起動する設計だが、
**`GITHUB_TOKEN` で作成した Release は他のワークフローを起動しない**
（GitHub の仕様。ワークフローの無限ループ防止）。

そのため `stamp.yml` は発火しなかった。
現在は `release.yml` の最終ステップで sha256 を直接追記している。
本文形式は `stamp.yml` と同一。

```
sha256 GameLab.apk <64桁>
```

---

## 5. 変更後の確認手順

1. カタログ管理システムで `gamelab` の tagPattern を変更
2. 記録タグを `v1.3.4` に更新、または初期化
3. 診断レポートを再実行し、要対応が 0 件になることを確認
4. Appathy Store アプリで GameLab に更新が現れることを確認

---

## 6. 今後の採番

`deploy.sh` により以下の規則で自動採番される。

- `git tag --list 'v*' | sort -V` の最大値から算出
- パッチ番号を +1（`v1.3.4` → `v1.3.5`）
- タグが1件も無い場合は `v1.1.1`
- 第2引数に `notag` を渡した場合はタグを発行しない

GitHub API の heads 参照は反映遅延により
一つ前のコミットにタグが付くため使用していない。

---

## 7. 補足 — 本件の発生原因

`build.yml` を削除する際、`.github/workflows/` ディレクトリごと削除したため、
カタログ管理システムがコミットしていた `release.yml` を巻き込んで消していた。

納品規約に「`ci/` と `.github/workflows/release.yml` は削除・追跡解除しない」と
明記されていた箇所であり、開発側の作業ミスである。

現在は `release.yml` を復元済み。
再発防止として、ディレクトリ単位の削除を行わない旨を
`docs/RULE_CODE.md` に追記した。
