---
title: npmの「parcel-bundler」は「parcel」に移行する流れ
type: tech
emoji: 📦
topics: [Parcel]
published: false
---

Zero configuration でおなじみ、みんな大好き [Parcel](https://parceljs.org) だけど、`npm i` するパッケージ名は何だろう？`parcel` だっけ？`parcel-bundler` だったかも？[チュートリアルの Installation](https://parceljs.org/getting_started.html) を見ると `npm install -g parcel-bundler` となっている。と思いきや、[次期バージョンである Parcel v2 のドキュメンテーション](https://v2.parceljs.org/getting-started/webapp/) では `npm install -D parcel@next`。

基本的に、Parcel v1 では `parcel-bundler`、v2 では `parcel` と案内されていて、v1 は `parcel` でも入れられるが v2 は `parcel-bundler` では公開されていない。こんなことになっている理由は、**昔は別のパッケージが `parcel` の名前を使ってた** から。

# npm を掘る

https://www.npmjs.com/package/parcel

`parcel` で version をご覧いただこう。一番下に `0.0.1` というバージョンが **8 years ago** に公開されている。Brwoserify→webpack→Parcel というなんとなくな流れで生まれた Parcel が 8 年も前に存在していたはずがない。これはバンドラの Parcel とは別のパッケージ。`curl -O https://registry.npmjs.org/parcel/-/parcel-0.0.1.tgz` でファイルを引っ張ってきて `tar xf parcel-0.0.1.tgz --directory=0.0.1` で解凍し、中の `package/package.json` を見ると、description には「Package management using a file server and path conventions.」と。明らかにおれたちの知ってる Parcel じゃないですね。

で、version の 1 個上が 3 年前の `0.1.0`。そしてその次でいきなり `1.8.0`。ここで `0.1.0` を同じように落として解凍して `package.json` を見ると description には「`DO NOT INSTALL`」の文字が踊っている。`preInstall` のスクリプトには `echo \"You are looking for 'parcel-bundler'\" && exit 1` が仕込まれており、インストールさせまいという固い意思がみえる。author が sheetjs になってるのが気になる。

そしてご想像どおり `1.8.0` は Zero configuration で blazing fast なモジュールバンドラの Parcel。パッケージが移管されてるってことみたい。

# GitHub を掘る

GitHub にそのへんの話が出てないか Issue を探ってみたら「どっち使えばいいんだ」という質問が 2 個見つかった。
https://github.com/parcel-bundler/parcel/issues/2937
https://github.com/parcel-bundler/parcel/issues/1798

# Twitter で探る

そこで Twitter にて `parcel` の URL を検索してみたら答えが 1 発で見つかる。

https://twitter.com/MaartenBicknese/status/965611823251812353

https://twitter.com/parceljs/status/992119459161694208

1 つ目のツイートのリプライとわたしの英語力によれば、bundler のほうを公開する前に `parcel` を譲ってはくれまいか的なことをかけあったらしいが、当時は OK してもらえなかったそう。どうやら `parcel` はこの後に移管されたようだ。さすがに npm の仲裁が入ったとかはわからなかったが、まあ Twitter じゃなくて Discord とかメールでやりとりしたからだろう。

# おわりに

2018 年の `1.8.0` から `parcel` が使えるってことは、おそらく自分が Parcel そのものの存在を知ったときには既に使用可能だったのだと思う。これからは `parcel` を使えばいいんだろうけど、`parcel-bundler` を要求する別のパッケージがあったりした場合がだるそう。詳しく調べてないので意外と大丈夫なのかもしれないが。

ついでにパッケージ (など) の名前とかについての紛争についてのポリシーを貼っておく。

https://www.npmjs.com/policies/disputes
https://docs.npmjs.com/cli/v6/using-npm/disputes

パッケージレジストリの名前が枯渇したりしないか気になっている。`username/package` とかで空間を広げていくのか、メンテされてないパッケージを潰していくのか。というか、今回は古い `parcel` の `0.0.1` の上に積み上げていってるけど、`2.2.0` とか行っちゃってるものに `1.13.0` を重ねたりするのは無理では？そのへんどう扱われるんだろう。
