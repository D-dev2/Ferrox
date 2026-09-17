# waybackurls

- **Rivets** : web
- **Type** : Go (`go.lock`)
- **Source** : `github.com/tomnomnom/waybackurls`

## Rôle
Récupère les URLs archivées d'un domaine dans la Wayback Machine.

## Usage
```
echo exemple.com | waybackurls
```

## Exemple
```
echo exemple.com | waybackurls | grep -E '\.php|\.aspx'
```