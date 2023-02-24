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


## TODO
- Gem追加時に`make bundle`だけだとgem not foundになることがあり、`make build`が必要になることがある問題を解消
- フロントと分離できる作りにしているが、本ボイラープレートとしては不要なので削除