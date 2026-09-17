# dalfox

- **Rivets** : web
- **Type** : Go (`go.lock`)
- **Source** : `github.com/hahwul/dalfox/v2`

## Rôle
Scanner de vulnérabilités XSS : détection et exploitation automatisée des failles XSS.

## Usage
```
dalfox url https://exemple.com/?q=test
```

## Exemple
```
dalfox url "https://exemple.com/?page=1&q=FUZZ" --custom-payload XSS
```