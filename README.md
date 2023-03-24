# README

## 起動方法
### 初回起動
```
make init
make dbinit
make up
```

### 2回目以降
```
make up
```

## 開発環境アクセス
http://localhost:3010


## tailwindを使った開発
buildをする必要があるので、`make up`とは別のterminalタブで`make dev`を実行しておくことでerbの保存時に必要なtailwindのスタイルが利用可能となる。（buildしないとスタイルが適用されない）


## TODO
- Gem追加時に`make bundle`だけだとgem not foundになることがあり、`make build`が必要になることがある問題を解消
- フロントと分離できる作りにしているが、本ボイラープレートとしては不要なので削除