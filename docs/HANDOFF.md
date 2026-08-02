# GameLab HANDOFF

Godotで作るシミュレーションRPG本体と、その開発規約を1つにまとめたリポジトリ。
**リポジトリはこれ1つ。** 増やさない。

## 使い方

新しいチャットの冒頭に、この `HANDOFF.md` と `docs/RULE_ART.md` と `docs/RULE_CODE.md` を貼る。

## 構成

```
GameLab/
  project.godot          ゲーム本体
  Main.tscn
  scripts/
    Main.gd              ゲームループ、入力、カメラ、UI描画
    Board.gd             マップデータと地形描画
    Fx.gd                フラッシュ・揺れ・ヒットストップ・ダメージ数字
    Units.gd    autoload ユニットのステータス定義
    Art.gd      autoload スプライトとタイルのドットデータ
    Gfx.gd      autoload ビットマップフォント、テクスチャ生成とキャッシュ
    Pal.gd      autoload 配色
  .github/workflows/build.yml
  export_presets.cfg
  debug.keystore
  deploy.sh
  docs/
    HANDOFF.md
    RULE_ART.md          画作りの規約（確定）
    RULE_CODE.md         GDScriptの規約（確定）
    LOG/001_fclab.md     検証記録
```

## ビルドと配布

```
bash ~/GameLab/deploy.sh "コメント"
```

push すると GitHub Actions が走り、Releases に `build-<番号>` として APK が出る。
**エラーの一次発見者はClaude。** ユーザーに渡るのはビルドが通ったAPKだけ。

## 現在のゲーム内容（v2.0）

タクティクスオウガ型SRPGの土台。

- 画面 640x360、タイル 32x32、ユニット 48x48（`RULE_ART.md` 準拠）
- マップ 24x18 タイル。ドラッグでスクロール
- 地形: 草原 / 道 / 水（進入不可）/ 岩（進入不可・防御+3）/ 森（移動コスト2・防御+2）/ 花
- ユニット6種: KNIGHT / LANCER / ARCHER / MAGE（味方）、ORC / WOLF（敵）
- 選択 → 移動範囲表示 → 移動 → 攻撃対象選択 → 攻撃
- 反撃あり（射程が届く場合）
- クリティカル（ダメージ1.5倍）
- ターン制、敵AIは最寄りの味方に接近して攻撃
- 勝敗判定、リスタート

## 操作

- ユニットをタップ → 青い移動範囲が出る
- 範囲内のマスをタップ → 移動
- 赤く光る敵をタップ → 攻撃。`WAIT` で待機
- 画面をドラッグ → マップスクロール
- 右下 `END TURN` → 敵ターンへ

## 次にやること

- [ ] 実機で触って、テンポ・難度・視認性を判定する
- [ ] 移動アニメーション（現在は瞬間移動）
- [ ] 攻撃モーションと演出の強化
- [ ] クラスごとの固有スキル
- [ ] 複数マップ、勝利条件のバリエーション
- [ ] 会話・ストーリー
- [ ] 日本語表示の方針決定（Godot標準フォントに日本語グリフが無い）
- [ ] `RULE_FEEL.md` の作成
