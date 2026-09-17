# gau

- **Rivets** : web
- **Type** : Go (`go.lock`)
- **Source** : `github.com/lc/gau/v2/cmd/gau`

## Rôle
Gathers URLs : collecte d'URLs historiques d'un domaine depuis de nombreuses sources (Wayback Machine, Common Crawl, etc.).

## Usage
```
echo exemple.com | gau
```

## Exemple
```
echo exemple.com | gau --subs | sort -u > urls.txt
```