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

### OSC 処理

```perl
if (s/\A($osc_re)//) {
    my $osc = $1;
    unless ($obj->{discard}->{OSC}) {
        $folded .= $osc;
        if ($osc =~ /^(?:\e\]|\x9d)8;[^;]*;(.*?)(?:\e\\|\x9c|\a)$/) {
            $osc8_link = $1 ne '' ? $osc : undef;
        }
    }
    next;
}
```

- OSC シーケンスを認識し、`discard` オプションに応じて保持/破棄
- OSC シーケンス自体は表示幅ゼロとして処理される
- OSC 8 ハイパーリンクの場合、開始/終了の状態を `$osc8_link` で追跡
  - URI が非空 → 開始シーケンスを保存
  - URI が空 → リンク終了（`undef`）

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

## 折り返し時の OSC 8 状態管理

### 問題

ansicolumn 等でマルチカラム表示する際、ハイパーリンクの途中で
折り返されると、閉じられていないリンクが右側のカラムに漏れてしまう。

### 解決策

SGR カラーと同様のアプローチで、fold 切断点で OSC 8 を閉じて再開する。

```perl
my $osc8_link;  # アクティブなハイパーリンク開始シーケンスを保持

# fold 切断時の処理
if (defined $osc8_link) {
    $folded .= OSC8_RESET;            # 前の行でリンクを閉じる
    $_ = $osc8_link . $_ if $_ ne ''; # 次の行でリンクを再開
}
```

### 折り返し動作の検証

```
入力: \e]8;;https://example.com\e\\ABCDEFGHIJ\e]8;;\e\\

折り幅: 5

出力:
  Line1: \e]8;;https://example.com\e\\ABCDE\e]8;;\e\\
  Line2: \e]8;;https://example.com\e\\FGHIJ\e]8;;\e\\
```

- 各行が独立した完全なハイパーリンクになる
- マルチカラム表示でリンクが他のカラムに漏れない

## 参考資料

- [Hyperlinks in Terminal Emulators](https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda)
- [OSC 8 Adoption List](https://github.com/Alhadis/OSC8-Adoption)
- ECMA-48: Control Functions for Coded Character Sets

## 実装状況

1. ✅ **完了**: 正規表現の修正（URL の `~` 対応、ECMA-48 準拠）
2. ✅ **完了**: OSC 8 状態管理（fold 切断時にリンクを閉じて再開）
