---
title: "React: useStateをuseReducerでつくる"
emoji: "♻️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [React, TypeScript, JavaScript]
published: false
---

最近 `useState` と `useReducer` について考えることが多いです。ある日ふと `useState` の型定義を見ていたら

https://twitter.com/aumy_f/status/1380757273547395077

ということを思いつきました。というわけで、`useState` を `useReducer` で作っていきます。

# useState の型定義

useState は関数コンポーネント (Function Components, `React.FC`) に **状態 (State)** を持たせるための Hook です。

このように使います。

```tsx:importは省略します
const Counter: React.FC = () => {
  const [count, setCount] = useState(() => 0);
  const increment = useCallback(() => setCount(prev => prev + 1), []);

  return (
    <div>
      <p>{count}</p>
      <button onClick={increment}>incremnet</button>
    </div>
  );
}
```

おおむね

```ts
type UseState = <S>(init?: () => S) => [S, React.Dispatch<SetStateAction<S>>];
```

のような型をしています。その中でも筆者が目をつけたのは `React.Dispatch` です。この型は `useReducer` にも登場します。この型が解決されるとこのような感じになります。

```ts
type SetState<S> = (updater: (prev: S) => S) => void;
```

ここで引数である `updater` は、古いステート `prev: S` を受け取って新しいステートを返す純粋な関数です。`prev => prev + 1` は前のステートを受け取ってそれに 1 加えたものを返し、それが新しいステートになります。

実は「古いステートを受け取って新しいステートを返す」ということは useReducer でもやっています。

# useReducer とは

```tsx

```
