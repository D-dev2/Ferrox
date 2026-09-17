# ffuf

- **Rivets** : web
- **Type** : Go (`go.lock`)
- **Source** : `github.com/ffuf/ffuf/v2`

## Rôle
Fuzzing web : découverte de répertoires, fichiers et paramètres à partir d'une wordlist.

## Usage
```
ffuf -u https://exemple.com/FUZZ -w wordlist.txt
```

## Exemple
```
ffuf -u https://exemple.com/FUZZ -w $HOME/wordlists/common.txt -mc 200
```