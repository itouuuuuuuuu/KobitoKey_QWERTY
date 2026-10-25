# CLAUDE.md

KobitoKey (40 キー分割型、左右にトラックボール) 用の ZMK ファームウェア設定リポジトリ。
元は fork だが、itouuuuuuuuu/KobitoKey_QWERTY として独立運用している。
キーマップは zmk-config-moNa2-v2 (ローカルの ../zmk-config-moNa2-v2) と同じものを移植している。

## 絶対に守ること

- **リモートは origin (itouuuuuuuuu/KobitoKey_QWERTY) のみ**。fork 元への push・PR・issue・`gh api` など一切の操作をしない。
  `.claude/hooks/block-upstream.sh` (PreToolUse hook) が、fork 元のオーナー名を含む Bash コマンドや他リポジトリ宛ての `gh` 操作をブロックする。
  この hook は文字列一致なので、fork 元のオーナー名を含むコミットメッセージや `grep` もブロックされる。コミットメッセージには書かない。
- **main に直接コミットしない**。必ず `git checkout main && git pull` してから英語 kebab-case の feature ブランチを切る。
- マージはユーザーが行う。「マージして」と明示されたときだけ Claude がマージし、マージ後は `git checkout main && git pull` してローカルの feature ブランチを削除する。
- 実機の動作確認は Claude にはできない。PR 本文にはユーザーが確認する項目として書く。
- `gh` 操作は `-R itouuuuuuuuu/KobitoKey_QWERTY` を明示する (`gh repo set-default` も同リポジトリに設定済み)。

## ディレクトリ構成

```
build.yaml                                 GitHub Actions のビルドマトリクス (左 / 右 / settings_reset)
config/
  KobitoKey.keymap                         キーマップ本体 (レイヤー 0〜8)
  KobitoKey.json                           ZMK Studio 用の物理レイアウト定義
  west.yml                                 ZMK v0.3 と各モジュール (PMW3610 / sensor_rotation / rgbled-widget)
  boards/shields/KobitoKey/
    kobitokey.dtsi                         左右共通の devicetree (kscan、matrix transform、input listener)
    KobitoKey_left.overlay                 左手 (central): 左ボール (常時スクロール)、右ボールのオートマウスレイヤー設定
    KobitoKey_right.overlay                右手 (peripheral): 右ボール (カーソル)
    KobitoKey_left.conf / _right.conf      Kconfig。Studio・LED・BLE 設定は左
.claude/
  settings.json                            PreToolUse hook の登録
  hooks/block-upstream.sh                  fork 元への操作をブロックする hook
```

## キーマップ (config/KobitoKey.keymap)

macOS 前提 (LG = Command、LA = Option)。日本語入力は `LANG1` / `LANG2` で切り替える。
レイヤー構成・カスタム behavior (`mt_slow` / `mt_fast` / `lt_to_layer_0`) は moNa2 と同じ。

### moNa2 との差分

- moNa2 (42 キー) の 2 行目右内側 (`Cmd++` / `Cmd+-`) と 3 行目左右内側 (`[` `]` / `{` `}`) が無い。
- 親指行は左 5 + 右 5 (index 30〜39)。moNa2 左端の Tab (`&lt_to_layer_0 5 TAB`) は index 35 (右親指内側) に置いている。
- index 38 (右薬指下) は moNa2 に対応するキーが無いので、`Cmd++` (layer 0) / `Cmd+-` (layer 1) を仮置き。
- ロータリーエンコーダ無し (`sensor-bindings` 無し)。
- 左ボールは常時スクロールなので layer 5 はテンキーのみ (NUM)。
- 右ボールのオートマウスレイヤーは layer 4 (`KobitoKey_left.overlay` の `&zip_temp_layer 4 5000`)。

### 編集時の注意

- 全レイヤーの binding 数は **40**。編集後は次のスクリプトで確認する。
  ```sh
  awk '/bindings = </{c=0;f=1;next} f&&/>;/{print NR": "c; f=0} f{n=gsub(/&/,"&"); c+=n}' config/KobitoKey.keymap
  ```
- レイヤー番号は `KobitoKey_left.overlay` の `&zip_temp_layer` や `&lt 8 Q` などと結びついている。レイヤーを増減するときは参照先と `_left.conf` の `CONFIG_RGBLED_WIDGET_LAYER_n_COLOR` をすべて更新する。
- keymap を変えたら左右両方の `.uf2` を書き込む必要がある。

## 言語

- コミットメッセージ・PR タイトル・PR 本文は日本語。ブランチ名は英語の kebab-case。
- ユーザーへの返答は日本語。
