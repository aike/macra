NAME
    macra - 汎用マクロプリプロセッサ

SYNOPSIS
    nawk -f macra.awk [ -Dvar ] [sourcefiles ...]

DESCRIPTION
    macraは、汎用プリプロセッサです。
    プログラミング言語を拡張してシンプルかつ強力なマクロ機能を付加します。

  構文
    macraでは、空白文字、改行文字、それ以外の文字の3種を識別する。
    行の先頭から空白文字を除いた最初の単語（先頭ワード）が以下の
    予約語のいずれかであった場合、macraコマンドとして処理する。

    defmacro name
        body
        ...
    endmacro
        マクロ定義。これ以降、先頭ワードがnameの行があればbodyの内容で
        置換する。マクロの展開時には引数をとることができる。マクロ定義
        のbody内に&1, &2, &3, ...のように＆付き数字で仮引数を書いておくと
        &1は第１引数、&2は第２引数、の実引数で置換される。

    defmacro name body
        マクロ定義の別記法。１行で記述できる内容を定義する。

    include "libfile"
    include <libfile>
        マクロライブラリファイルをインクルードして評価する。
        <libfile>の方は、/lib/macra/ ディレクトリから読み込む。

    #
        コメント行として無視する。

    $(name)
        インラインマクロ展開。macraでは通常先頭ワードのみ評価してマクロ
        展開するが、$(name)の記法を使うと先頭ワード以外の箇所にあっても
        マクロ展開する。

    IF_DEF name / IF_NOT_DEF name
    ELSE
    END_IF
        分岐制御文用ディレクティブ。マクロnameが定義されているかどうかで
        条件分岐をおこなう。条件が真でない場合は入力した行を出力しない。
        コマンドラインオプションに -Dname を付加した場合、マクロnameが
        定義されたものとして処理する。

HISTORY
    2011/04/03 最初のバージョン

URL
    http://github.com/aike/macra

