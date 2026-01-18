# OSC 8 ハイパーリンク対応メモ

## OSC 8 とは

端末でクリック可能なハイパーリンクを表示するためのエスケープシーケンス。

```
ESC ] 8 ; params ; URI ST  text  ESC ] 8 ; ; ST
\e]8;params;URI\e\\       text  \e]8;;\e\\
```

- 開始: `\e]8;params;URI\e\\` (または `\a` で終端)
- テキスト: リンクとして表示される部分
- 終了: `\e]8;;\e\\`

### params

`key=value` 形式でコロン区切り。主に `id=xxx` でリンクのグループ化に使用。

```
\e]8;id=link1;https://example.com\e\\Click\e]8;;\e\\
```

## 現状の Text::ANSI::Fold

### OSC 正規表現 (65-70行目)

```perl
our $osc_re = qr{
    (?: \e\] | \x9d )           # OSC 開始
    [\x08-\x0d\x20-\x7e]*+      # コマンド部 (ECMA-48 準拠に修正済み)
    (?: \e\\ | \x9c | \a )      # 終端 (ST)
}x;
```

### OSC 処理 (348-352行目)

```perl
if (s/\A($osc_re)//) {
    $folded .= $1 unless $obj->{discard}->{OSC};
    next;
}
```

- OSC シーケンスを認識し、`discard` オプションに応じて保持/破棄
- OSC シーケンス自体は表示幅ゼロとして処理される

### SGR（色）の処理方法 (参考)

```perl
# カラーシーケンスをスタックに追加 (376-380行)
if (s/\A($color_re)//) {
    $folded .= $1;
    push @color_stack, $1;
    next;
}

# リセットでスタッククリア (361-364行)
if (s/\A($reset_re+($erase_re*))//) {
    put_reset($1);
    @bg_stack = () if $2;
    next;
}

# 折り返し時の処理 (511-514行)
if (@color_stack) {
    $folded .= SGR_RESET;                        # 前の行を閉じる
    $_ = join '', @color_stack, $_ if $_ ne '';  # 次の行で復元
}
```

## ECMA-48 仕様

### 8.3.89 OSC - OPERATING SYSTEM COMMAND

```
OSC Ps ST
```

- Ps = character string (5.6 参照)
- ST = STRING TERMINATOR (8.3.143)

### 5.6 Character String

> A character string (indicated by Ps in this Standard) consists of a sequence of any
> bit combination, except those representing SOS or STRING TERMINATOR (ST).

実質的に使用可能な文字:
- `0x08-0x0D` (BS, HT, LF, VT, FF, CR)
- `0x20-0x7E` (printable characters including `~`)

## 完了した変更

### 1. 正規表現の修正 ✅

`[\x08-\x13\x20-\x7d]` を ECMA-48 仕様に準拠するよう修正:
- `\x13` → `\x0d` (BS,HT,LF,VT,FF,CR のみ許可)
- `\x7d` → `\x7e` (`~` を含む)

これで `https://example.com/~user` のような URL も正しく認識される。

コミット: `5f4b40c Fix OSC regex to conform to ECMA-48 specification`

## テスト結果

### 折り返し動作の検証

```
入力: \e]8;;https://google.com\e\\This is a long link text\e]8;;\e\\

折り幅: 15

出力:
  Line1: \e]8;;https://google.com\e\\This is a long
  Line2: link text\e]8;;\e\\
```

### 結果

- **Line1**: OSC 8 開始あり、終了なし → **クリック可能**
- **Line2**: OSC 8 開始なし、終了あり → **クリック可能**
- 端末（iTerm2/Terminal.app）は行をまたいでもリンク状態を維持する

### 結論

**追加の状態管理は不要**

- OSC 8 シーケンス自体は分割されない（osc_re で一塊として認識）
- 端末は OSC 8 開始でリンクモードに入り、終了まで維持する
- 改行があってもリンクモードは継続する
- SGR のような「各行で閉じて再開」処理は不要

### 注意点

- 折り返された行を**別々に処理**する場合（行単位でパイプに渡す等）は問題になる可能性
- 端末によって動作が異なる可能性（未検証の端末あり）

## 将来の拡張（任意）

各行を独立させたい場合の実装案:

```perl
my $current_hyperlink;  # 現在有効なハイパーリンク開始シーケンス

# OSC 8 開始/終了の検出と状態管理
# ...

# 折り返し時の処理
if ($current_hyperlink) {
    $folded .= "\e]8;;\e\\";              # 前の行でリンクを閉じる
    $_ = $current_hyperlink . $_;          # 次の行でリンクを再開
}
```

## 参考資料

- [Hyperlinks in Terminal Emulators](https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda)
- [OSC 8 Adoption List](https://github.com/Alhadis/OSC8-Adoption)
- ECMA-48: Control Functions for Coded Character Sets

## 実装状況

1. ✅ **完了**: 正規表現の修正（URL の `~` 対応、ECMA-48 準拠）
2. ⏸️ **不要**: 状態管理と折り返し時のリンク維持（端末がリンク状態を維持するため）
3. ⏸️ **保留**: 各行独立オプション（ユースケースが出てきたら検討）
