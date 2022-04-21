---
title: "TypeScript，型，集合，代数的データ型，そして Tagged Union"
emoji: "👏"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["TypeScript", "関数型プログラミング", "Rust", "Elm"]
published: false
---

**代数的データ型** (Algebraic Data Type) は関数型プログラミング言語によくある言語機能だ．「よく」という雑な形容を根拠もなしに言うのはずるいのでどんな言語にあるのか調べてみたが，少なくとも Haskell, Elm, OCaml, Scala, Rust には言語機能として存在する．その名前の通り型に関する機能で，近年^[筆者は若いのでプログラマ人生のほとんどが近年であることに注意．] のマルチパラダイム言語 (Swift, Rust) が取り入れたり，それに由来する概念が突っ込まれたりしている．もっとも身近なのが Null 安全だろう．御存知の通り TypeScript も Null 安全な言語であり，それを実現するのは `T | null` というような union 型なのだが，Union 型は代数的データ型を構成する重要なパーツである．またそういった概念をより深く知るために，型を集合として捉えることが大切になる．

まあ，これを知っていても年収が直接的に増大するわけではないのだが，こういう知識を取り入れられるような余裕を持てる社会人になりたいものだなあとは思う．集合とか型とかいっても高 1 の数学 I で出てくるようなのしか扱わないので，肩の力を抜いて TypeScript Playground でも開きながら読んでほしい．

# $n$ 型 - 表現したいデータ量は非負整数になるはずだって

先述したとおり，$n$ 種類の物事を表したいならその型の値も $n$ 種類にしたほうがよい．

話の簡略化と筆者の指の保護のため，以降は $n$ 個の値をもつ型を簡単に $n$ 型 と呼ぶことにする．右手が痛い．

## $1$ 型

1 個の値をもつ型は意外とありふれてる．もっとも代表的なものが `null` と `undefined`．

```ts
const hoge: null = null;
const fuga: undefined = undefined;
```

よく考えると、`null` を直接型に書ける言語はそう多くないかもしれないが…

`null` の代わりに空タプルや空リストを使う言語もそこそこみられる．例は Rust だが Scala や Haskell も．

```rust
let point: (i32, i32) = (4, 2); // 2要素タプル
let unit: () = (); // 空タプル
```

同じように TypeScript の空タプル，`[]` あるいは `never[]` 型は唯一の値 `[]` をもつ $1$ 型になる．

:::details 配列と never
`[never]` は `never` 型の要素を 1 つもつタプルになる．
:::

### リテラル型

数値型，文字列型について，先ほどこう書いた．

> 「v4 か v6」といったようなデータを扱うのに，数値や文字列だと **_多くの言語では_** 型が `String` `&str` とか `number` `i32` に潰れてしまう．

**多くの言語では** 文字列を表す型は

TypeScript には **リテラル型** という機能がある．`42` とか `"hello"` といった数値や文字列リテラルそのものを型にでき，もちろん `42` 型には `42` しか割り当てられない．つまり、型のもつ値が $1$ つになる．数値が小数ふくめたくさん，文字列がさらにたくさんあって凄まじい数の $1$ 型をつくることができる．

```ts
const piyo: "hello" = "hello";
```

## $0$ 型

数学的な文脈だと _0 個の値をもつ型_ というような言い回しになるだろうが，これは **値をもたない** ということだ．集合論的には空集合といえる．値をもたない型なんてあるのかと思いたくなるが， TypeScript を書いているとわりと遭遇する．`never` 型と呼ばれており，おおよその意味合いは「そこに値が割り当てられることは **ありえない**」．

その 1，必ず `throw` する関数は **正常終了して値を返すことがありえない** ため返り値の型は `never`．

```ts
// () => never
const panic = () => {
  throw new Error();
};
```

または **ロジック上そこを通ることがありえない** 場合にも変数が `never` になる．これは制御フロー解析といって `if(typeof hoge === "number") { }` が真のときの分岐では `hoge` を自動で `number` 型に推論してくれるおばけのような機能．このコードでは `strOrNum` が `string` `number` である以上 `switch` のアームは上 2 つのどっちかに必ずヒットするため `default` 節が走ることはありえない^[`any` を渡す不届き者がいた場合は別]とコンパイラが理解してくれる．

```ts
const fuga = (strOrNum: string | number) => {
  switch (typeof strOrNum) {
    case "string":
      return strOrNum.length; // ここではstring
    case "number":
      return strOrNum; // number
    default:
      console.log(strOrNum); // never(ここは通らないはず)
      return 0;
  }
};
```

## $2$ 型

TypeScript に限らず「2 個の値をもつ型がある」言語は非常に多い．C でも Java でも Rust でも Ruby でも存在する．そう、boolean (真偽値) 型だ．あれは `true` か `false` で，それ以外の値をとることはない．

```ts
let bool: boolean = true;
bool = false;
```

$3$ 型，$4$ 型…と続くが省略する．

# Union 型 (合併型)

ちょっと前に出てきた Rust, Elm の `User` 型を思い出してほしい．`User` がとれる値は `Regular` か `Visitor` の **どちらか 1 つ** であることに注目しよう．こいつと似た機能が TypeScript にも存在するのだ．複数あるうちからどれか 1 つ…，そう，こいつはみんな大好き **Union 型 (合併型)** である．

Union 型は `string | number` のように書き，これは **`string` か `number` の値** を表す．

```ts
type strOrNum = string | number;

const son: strOrNum = "Hello!";
const son2: strOrNum = 42;
```

Union 型の記号である `|` は論理和でよく使われる記号だ．なぜ論理和の記号かといえば Union 型が **和集合** になるからだろう．`string | number` に含まれる値は「`string` **か** `number` に含まれる値」だ．「**か**」というのは **OR** ，つまり論理和というわけだ．適当に円をふたつ書いて，_number_ _string_ という名前を書き．`42` とか `"Hello, world"` とか値を入れてみよう．円が集合で型，その中の要素 (元) が値で，ふたつを合体させた和集合が合併型で `string | number` である．

ところで `string | number` が表せる値の数が `string`が表せる値の数 + `number`が表せる値の数 になっていることにお気づきだろうか．和集合の濃度 (要素の数) は各集合の濃度の和になっている^[各集合の要素に重複がない場合．今回の場合 `string`かつ`number` の値は存在しないので条件を満たしている．]．`string`がほぼ無限，`number` は 64bit なので $2^{64}$ ぐらいなのでまあほぼ無限なのは変わらないのだが，これを $1$ 型ふたつでやってみたらどうなるだろう？

```ts
type NulOrUnd = null | undefined;
```

はい，ではこの `NulOrUnd` がもつ値の数，つまり$1+1$ は？ ~~みそスープ~~ 当然 $2$ だ．`null` か `undefined` の 2 者択一になる．2 者択一といえば `true` か `false` の `boolean`，つまり`null | undefined` は $2$ 型なのだ．もちろん，上で挙げた `"Regular" | "Visitor"` もばっちり $1$ と $1$ の和なので $2$ 型だ．

```ts
type User = "Regular" | "Visitor";
```

# 「同型」であること

$1$ 型の `undefined` と `null` を相互変換する関数を書いてみよう．

```ts
const tonull = (und: undefined) => null;
const tounde = (nul: null) => undefined;
```

ところでこの関数を 2 個つなげると元の値に戻る。

```ts
tonull(tounde(null)); // => null
tounde(tonull(undefined)); // => undefined
```

:::details パイプライン演算子を使うと
TC39 で ECMAScript 仕様に入れるか検討中のパイプライン演算子を使うと，こんな感じでたくさん関数を連ねて書くことができる．

```ts
undefined |> tonull |> tounde |> tonull |> tounde |> tonull |> tounde; // undefined
null |> tounde |> tonull |> tounde |> tonull |> tounde |> tonull; // null
```

どれだけ重ねても情報のロスなく元々の値に戻っていることがわかる．

パイプライン演算子もっと有名になって入れてほしいの声が増えてくれないかな～～という宣伝でした．
:::

これは数学的に型を集合、関数`tonull`, `tounde`を射として考えて **同型** であるという．`null` と `undefined` がそれぞれ持てる情報量はどちらも 1 つなので同型である．

もちろん `"hello"` と `undefined` と `42` と `[]` も同型，`boolean` と `"Regular" | "Visitor"` も同型．

## いろいろな同型

```ts
type UserType = "Regular" | "Visitor";

const isVisitor = (type: UserType) => type === "Visitor";
const toString = (isVisitor: boolean) => (isVisitor ? "Visitor" : "Regular");

isVisitor(toString(true)); // true
toString(isVisitor("Visitor")); // "Visitor"
```

# マジックナンバーの magic は黒魔術を意味するのだから

さっそくだが実際のソフトウェアにありそうなシチュエーションを提示してみる．ある日，指定した IP アドレスに ping を飛ばす関数を Rust で実装することになった．IP には IPv4 と IPv6 という **2 種類のバージョン** があり，両者では別々の IP アドレスを使用する．IPv4 と IPv6 の両方にひとつの関数で対応したいので，引数の `is_v6` が `true` なら IPv6 を使うようにした．

```rust
fn ping(is_v6: bool, address: &str) {
  if is_v6 {
    ping_v6(address)
  } else {
    ping_v4(address)
  }
}
```

これはあまりよくない例である．なぜなら将来 1024bit のアドレスに対応した Internet Protocol Version 7 とかが爆誕したときに困るのが目に見えている^[まあ IPv6 アドレスは文字通り路傍の石ころに割り当てても余るレベルで用意されてるので，このコードが生きてる間に枯渇することはないだろう．しかしそれは IP アドレスの話なのであって．] からだ．ここに `is_v7` というばかげた変数を用意しよう，おおっと！ `(is_v6_ && is_v7) == true` の IP アドレスが誕生してしまった！

また，IP アドレスの種類がそう簡単に増えないとは言っても，コード上の `true` や `false` が何を意味しているのかひと目でわからないという問題はいまだ残る．

```rust
ping(true, jonathan.ipAddr);
ping(false, joseph.ipAddr);
```

## 数値や文字列でがんばって表現する

真偽値だと将来性がないのでバージョンの文字列，あるいは数値を受け取ることにしたらどうだろう？

```rust
fn ping(ip_version: &str, address: &str) {
  match ip_version {
    "v4" => ping_v4(address),
    "v6" => ping_v6(address),
    _ => panic!(),
  }
}
```

```rust
ping("v6", jonathan.ipAddr);
ping("v4", joseph.ipAddr);
```

将来的な追加が多少容易になったし，関数を使うときにどのバージョンを使っているかもわかりやすくなった．しかしこの場合，`"v4"` と渡す代わりに `"IPv4"` といった不正な値を渡してしまうことがありうる．数値にすれば微妙な表記ゆれ問題はなくなるが，うっかり `3` とか不正な値が渡ってしまいうるのは変わらない．

「v4 か v6」といったようなデータを扱うのに，数値や文字列だと _多くの言語では_ 型が `String` `&str` とか `number` `i32` に潰れてしまう．後でも出てくることだが文字列や数値型は非常に多くの値を含んでいる．JS の `number` なら `42` とか `-3.14159` とか `8192.25323` とか `0` とか `-0` とか `NaN` とか `Infinity` とか…

これでは関数を使うとき，関数のインターフェースを見ただけでは `user_type: &str` に何を渡せばいいのかわからない．ヒアドキュメントで「`user_type`: IPv4 では`"v4"`, IPv6 では`"v6"`を渡します」と書くこともできるが，コンパイラ/LSP サーバはドキュメントを読めないので `"V4"` とか `"IPv6"` と書く人間を止められないし，IDE の補完も受けることができない．

**真偽値は表現できるデータ量が少なすぎる** (現状では十分だがのちのちに増やすことができない) し，**数値や文字列では多すぎる** (不注意で不正な値を渡す可能性を否定できない) と言い換えることもできる．ユーザーの種類が $n$ 種類なら，ユーザーを表す型の値は **_ちょうど_** $n$ 個であったほうがよい，ということだ．

ここで代数的データ型を使えば，後から値を追加するのも簡単になるし，間違った値を渡したときにはコンパイラが止めてくれるし，IDE もしっかり補完を出してくれる．

# 代数的データ型ってなーんだ

代数的データ型がどういうものかというと，プログラマが適当な名前で新しい値 (列挙子) を作り，列挙子全部を含む型を定義できる．さらに列挙子が値を持てる．

:::details 列挙子が値を持てない enum
C や TypeScript に `enum` という構文がある．こいつは ADT とよく似ているが，**列挙子が値をもつことができない**．本記事で話題にしている ADT は列挙子をもつことができる．
:::

以下の例では `Suit` 型の値は `Sword` `Wand` `Coin` `Cup` の 4 つである．

```rust
enum Suits {
  Sword,
  Wand,
  Coin,
  Cup,
}
```

IP アドレスはこう表せる．

```rust
enum IpVersion {
  V4,
  V6,
}
```

こいつを使って `ping` 関数を書き換えてみよう．

```rust
fn ping(ip_version: IpVersion, address: &str) {
  match ip_version {
    V4 => ping_v4(address),
    V6 => ping_v6(address),
  }
}
```

:::details ADT 用語の表記ゆれについて

「代数的データ型」に対応する英語は Algebraic Data Type で，列挙子は構築子 / コンストラクタ(constructor)，バリアント(variant) と呼ばれることが多い気がする．構築子 / コンストラクタは Haskell でよく使われている印象を受ける．Elm, Rust は Variant を使っている．
代数的データ型の定義に使う構文にも話題を広げると，Haskell では `data`, Elm では `type`, Rust では `enum`．Rust は `=` を使わず波括弧を使う構文が特徴的だが手続き型言語にある `enum` との類似性を重視しているのだろうか．
:::

もうちょっと実際的な例として，登録ユーザーと未登録ユーザーをまとめた `User` という型を作る．登録ユーザー `Regular` はユーザー ID の入った無名構造体を持っているが，未登録ユーザー `Visitor` はなにも持っていない．このようにバリアントによって保持するデータの構造をまるっきり変えることも可能である．

```rust
enum User {
  Regular({ id: u32 }),
  Visitor,
}
```

:::details Elm のコード例

`|` 記号を使っているところに関数型プログラミングのエッセンスが見え隠れしている．

```elm
type User
  = Regular { id : int }
  | Visitor
```

:::

こうして定義すれば `User(3042)` といったように登録済みユーザーを表現でき，`User` 型が必要な場面で使うことができる．

# 代数的データ型を分解してみよう

ここでようやく TypeScript での代数的データ型を出してみる．

```ts
type User = { type: "Regular"; id: number } | { type: "Visitor" };
```

代数的データ型を TypeScript で実現するのに必要なのは **(文字列) リテラル型 とオブジェクト型と Union 型** だ．それらの機能について見てみよう．

# 列挙型

最初の例は Rust です。いきなり関数型か微妙なラインですが、少なくとも代数的データ型は関数型のそれだと思います。

IP(Internet Protoundecol) には v4 と v6 の 2 バージョンがあり、IP アドレスにも 2 つバージョンがありますよね。これをコードで表現してみましょう。

```rust
enum IPAddr {
  V4,
  V6,
}
```

`V4`, `V6` という新しい値と、2 つを含む集合 (型) として `IPAddr` を定義しました。1 個で IPv4, IPv6 の両方に ping できる関数はこんな感じで書けそうです。

```rust
fn ping(ip_version: IPAddr, ip_address: String) {
	match(ip_version) {
		IPAddr::V4 => ping4(ip_address),
		IPAddr::V6 => ping6(ip_address),
	}
}
```

この例では世界一有名な (要出典) ADT である Option を定義している．こいつは型引数 `t` をとるジェネリック型で，Haskell と Elm では Maybe と呼ばれている．あまりに重要なのでこの構造は後でもっかい出す．

```rust
enum Option<T> {
  Some<T>,
  None,
}
```
