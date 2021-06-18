# https://zenn.dev/aumy

## Nix を使わないセットアップ

`npm i`

## Nix & direnv のセットアップ

Nix channel を追加して、

```
nix-channel --add https://github.com/aumyf/zenn-cli.nix/archive/master.tar.gz zenn-cli
```

Cachix を追加して、

```
cachix use zenn-cli
```

ディレクトリでの direnv 実行を許可する

```
direnv allow .
```

完了したら `zenn` が有効になる。
