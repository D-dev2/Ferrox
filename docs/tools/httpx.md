# httpx

- **Rivets** : web, api
- **Type** : Go (`go.lock`)
- **Source** : `github.com/projectdiscovery/httpx/cmd/httpx`

## Rôle
Détection rapide de HTTP/HTTPS et collecte d'informations sur des hôtes (statut, titre, technologies).

## Usage
```
httpx -l hôtes.txt -sc -title
```

## Exemple
```
echo https://exemple.com | httpx -sc -title
```