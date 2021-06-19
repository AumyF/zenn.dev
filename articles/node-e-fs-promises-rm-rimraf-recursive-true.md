---
title: npm scripts で rimraf を使わずディレクトリを再帰的に削除する
type: tech
topics: [NodeJS, rimraf]
emoji: 🗑️
published: false
---

# 3 行で

0. Node.js >= v14.14.0 であること
1. `rimraf dist` は `` node -e 'fs.rmSync(`dist`, {recursive:true, force:true})' `` で置き換えられる
2. `rimraf dist/*.bundle.js` みたいな glob を含むものは置き換えできない

# 長い説明

npm scripts で不要なキャッシュやビルドの出力ファイルを削除したい場合は [**`rimraf`**](https://www.npmjs.com/package/rimraf) というパッケージを POSIX の `rm -rf` の代わりに使うことが多いと思います。これは [Windows で `npm run` の実行に使われる](https://docs.npmjs.com/cli/v7/commands/npm-run-script#script-shell) コマンドプロンプト (cmd.exe) に `rm` がないのを始めとした環境依存の問題を避けるためです。

とはいえパッケージなしではディレクトリの再帰的削除もできない、というのはちょっと困るので、v12.10.0 で `fs.rmdir` `fs.promises.rmdir` `fs.rmdirSync` に `recursive` オプションが追加され、`fs.rmdirSync('foo/', { recursive: true })` とすることで `rm -rf` や `rimraf` に近いことができるようになりました。ちなみに、glob が使えないこと以外は [rimraf がそのまま使われています](https://github.com/nodejs/node/blob/79c57d0cc55db834177d2f8ce4b4d83109a23dc9/lib/fs.js#L1185)。

しかし、実は POSIX の `rmdir` には再帰的削除の機能がないため、`recursive` を `rmdir` のオプションに追加するとややこしくなるという意見があったようです。大体案として `rmtree` という関数の追加とかが考えられたようです。また、POSIX との整合性で言うと `rm` に相当するのが `fs.unlink` になっていてややこしいといった問題もありました。

そこで、v14.14.0 で POSIX の `rm` に相当する [**`fs.rm`**](https://nodejs.org/api/fs.html#fs_fs_rm_path_options_callback) [**`fs.promises.rm`**](https://nodejs.org/api/fs.html#fs_fspromises_rm_path_options) [**`fs.rmSync`**](https://nodejs.org/api/fs.html#fs_fs_rmsync_path_options) が追加されました。Linux のシェルで `rm -rf` とするように、`fs.rmSync('foo/', { recursive: true, force: true })` とすることでディレクトリを再帰的に削除できます。

ということで、`fs.rmSync` するコードを文字列として [`node --eval`](https://nodejs.org/api/cli.html#cli_e_eval_script) (`node -e`) に渡してディレクトリを削除できます。`node -e` や `node -p` では REPL と同じく `fs` のインポートは不要です。また、`fs.rmSync` にした理由は、`fs.rm` は `,()=>{}` のぶん、`fs.promises.rm` は `.promises` のぶん若干長いためです。

`fs.rm` 系に再帰的削除オプションが追加されたため、`fs.rmdir` 系の `recursive` オプションは [v16.0.0 で deprecated になりました](https://github.com/nodejs/node/pull/37302)。将来的にこのオプションは指定しても無視されることになります。

```
[nix-shell:~/fs]$ node -v
v16.1.0

[nix-shell:~/fs]$ node -e "fs.rmdirSync('bin', {recursive: true})"
(node:11973) [DEP0147] DeprecationWarning: In future versions of Node.js, fs.rmdir(path, { recursive: true }) will be removed. Use fs.rm(path, { recursive: true }) instead
(Use `node --trace-deprecation ...` to show where the warning was created)
```

`fs.rm` が現行 LTS すべてで使えるようになるのは Node.js v12 が EOL になる 2022-04-30 以降です。それか v12 に `fs.rm` がバックポートされるかもしれません。

# 参考リンク

https://shisama.hatenablog.com/entry/2021/04/22/090000#fsrmdir%E3%81%AErecursive%E3%82%AA%E3%83%97%E3%82%B7%E3%83%A7%E3%83%B3%E3%81%8CDeprecated%E3%81%AB%E3%81%AA%E3%82%8A%E3%81%BE%E3%81%97%E3%81%9F

http://var.blog.jp/archives/80110966.html

https://qiita.com/qrusadorz/items/aa6ac6a6d6b3e7d458d5
ここで `fs.rmdir` の `recursive` を知ってドキュメントを見に行ったら deprecated になっててびっくりしたのがこの記事を書いたきっかけです。

https://github.com/nodejs/node/issues/34278
