# RULE_CODE.md

GDScript / Godot の書き方の規約。FcLab の開発中に実際にCIで落ちた事例から確定させた。

最終更新: v1.0（Godot 4.7.1）

---

## 1. 環境（固定）

| 項目 | 値 |
|---|---|
| Godot | 4.7.1.stable |
| レンダラー | Compatibility (`gl_compatibility`) |
| ビルド | GitHub Actions（ヘッドレスエクスポート） |
| 署名 | `debug.keystore` をリポジトリに固定。公開しないため debug のまま |
| 開発環境 | Termux + GitHub Actions のみ。Godotエディタは使わない |

Androidエクスポートには `textures/vram_compression/import_etc2_astc=true` が必須。

---

## 2. 型推論（`:=`）を使ってはいけない場面

**これがCIで落ちた原因の全て。** 以下は必ず明示型で書く。

### 2-1. 配列リテラルからのインデックス取得

```
var c := ["a", "b", "c"][i]        # NG
var c: String = ["a", "b", "c"][i] # OK
```

### 2-2. 三項演算子

```
var col := Pal.c("red") if hit else Pal.c("white")  # NG
var col: Color = Pal.c("white")                      # OK
if hit:
	col = Pal.c("red")
```

`if / else` に分けて書くのが最も安全。

### 2-3. Variantを返す組み込み関数

```
var bs := 1.0 + floor(k * 15.0)        # NG
var bs: float = 1.0 + floor(k * 15.0)  # OK
```

### 2-4. エンジンAPIの戻り値

```
var c := img.get_pixel(x, y)        # NG
var c: Color = img.get_pixel(x, y)  # OK

var small := src.duplicate()        # NG
var small: Image = src.duplicate()  # OK
```

`get_pixel` / `duplicate` / `get` / `pop_front` / `slice` / `keys` / `values` などが該当する。

### 例外

自作関数の戻り値に型宣言がある場合は `:=` で問題ない。

```
func _size() -> int: ...
var n := _size()   # OK
```

---

## 3. 変数名の衝突

**同一スコープで同じ名前を二度宣言するとパースエラーになる。**

```
func _draw() -> void:
	var r := _cv_rect()
	for r in canvas:   # NG: r が同一スコープで二重定義
		...
```

連続する別々の `for` ループで同じ変数名を使うのは問題ない（スコープが閉じるため）。

```
for i in 5:
	...
for i in 10:   # OK
	...
```

---

## 4. スクリプト間の参照

**型を付けた変数に、その型に無いプロパティ・メソッドでアクセスすると静的エラーになる。**

```
var world: Node2D
world.player = x   # NG: Node2D に player は無い

var world           # OK: 型なしなら動的解決
world.player = x
```

章やコンポーネント間の相互参照は型を付けない。

---

## 4-B. スプライトの左右反転

`draw_texture_rect_region()` の `src_rect` に**負の幅を渡す反転は効かない**。何も描画されない。

```
var src := Rect2(48.0, 0.0, -48.0, 48.0)   # NG: 描画されない
```

**反転済みのテクスチャを生成してキャッシュする。** `Gfx.art_v(name, white, flip)` がその実装。

---

## 4-C. 音声データのループ

`AudioStreamWAV` の `loop_end` に**サンプル数そのものを渡してはいけない**。配列の範囲外を読み、
ループ地点に達した瞬間にエンジンが落ちる。正しくは `n - 1`。

より安全なのは `loop_mode = LOOP_DISABLED` にして、`AudioStreamPlayer.finished` を受けて
`play()` を呼び直す方式。ネイティブのループ処理を通らないので事故らない。

`AudioStreamPlayer.stream` を再生中に差し替えるのも避け、必ず `stop()` してから代入する。

## 4-D. 画面遷移は入力処理の外で行う

Godotが入力イベントをノードツリーに伝播している最中に、ノードの生成・破棄・可視状態の切替を
行うとエンジンが落ちる。画面遷移を起こすシグナルは `CONNECT_DEFERRED` で接続し、
伝播が終わってから実行させる。

---

## 5. シーン構成

- **`.tscn` は最小限に留める。** ルートノード1つとスクリプトのアタッチのみ
- ノードの生成・配置は全てコードで行う
- 理由: `.tscn` の手書きは事故が多く、Termux環境では編集手段が限られる

---

## 6. ステートマシン

`FcLab/scripts/ch/Ch08Srpg.gd` および `GymApp/scripts/Player.gd` が基準実装。

- `enum State` と `var state: State` を持つ
- 遷移は必ず `_change_state()` を通す。`state` への直接代入は禁止
- `_enter_state()` / `_exit_state()` で入退場処理を分離
- 各状態の毎フレーム処理は `_state_xxx(delta)` に1状態1関数
- `_physics_process()` は `match state:` でディスパッチするだけ

---

## 7. 描画

- 描画は全て `_draw()` 内で行う。`queue_redraw()` を `_process()` で呼ぶ
- スプライトは `Image` から `ImageTexture` を生成し、**キャッシュする**（`Gfx.gd` 参照）
- 重い変換処理（縮小・減色）は結果をキャッシュする。毎フレーム計算しない

---

## 8. CIとエラー対応

**エラーの一次発見者はClaude。** 関口さんに渡るのはビルドが通ったAPKだけ。

ワークフローは以下の順で走る。

1. `godot --headless --import` — **スクリプトエラーはここで落ちる**
2. `godot --headless --export-debug "Android"` — APK生成
3. Releases に `build-<番号>` として公開

`import.log` に `SCRIPT ERROR` / `Parse Error` / `Failed to load script` が含まれたら失敗扱いにする。

**手作業でのパッチ（sed等）をユーザーに渡さない。** 修正は必ずZIPを作り直して配布する。

---

## 9. 配布の型（恒久ルール）

`deploy.sh` は **push とタグ発行までを1コマンドで完結**させる。GHUSER と REPO を該当リポジトリの値にする。

```
#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")"
TOKEN=$(git config --global github.token)
GHUSER=Sekiguchi-Takashi
REPO=<リポジトリ名>
API=https://api.github.com/repos/${GHUSER}/${REPO}
if [ ! -d .git ]; then git init -b main; fi
git remote remove origin 2>/dev/null
git remote add origin "https://${GHUSER}:${TOKEN}@github.com/${GHUSER}/${REPO}.git"
git add -A
git commit -m "${1:-update}"
git pull --rebase origin main
git push -u origin main
... タグ発行（最新リリースのタグを取得して +1、refs/tags を作成）
```

**必須事項**

- `actions/upload-artifact` は使わない。Artifacts の無料枠（0.5GB）が枯渇すると
  `Artifact storage quota has been hit` でビルドが失敗する。APK は Release から配布する

- `git pull --rebase origin main` が必須。カタログ管理システムがAPI経由で
  `.github/workflows/release.yml` と `ci/appathy.keystore` を直接コミットしているため、
  これが無いと push が rejected になる
- 上記2ファイルと `ci/` ディレクトリは配布ビルドに必要。**削除しない**
- タグを打つと Actions がビルドして Release を作り、自作アプリストアに更新として現れる
- 納品時に「deploy.sh に pull --rebase とタグ発行を含めた」と明記する

## 9-B. 旧・配布の型

ZIPは毎回別名。形式は `プロジェクト名_vX.X.zip`。展開後のトップレベルフォルダ名はプロジェクト名で固定。

```
cd ~
cp /sdcard/Download/プロジェクト名_vX.X.zip .
unzip -o プロジェクト名_vX.X.zip
bash ~/プロジェクト名/deploy.sh "vX.X 要約"
```

`.git` を消さないため `rm -rf` は使わない。
