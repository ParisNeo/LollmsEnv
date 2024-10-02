# LollmsEnv

LollmsEnv est un outil léger et simple pour gérer les environnements et versions Python.

## Résumé

LollmsEnv est conçu pour simplifier la gestion des installations Python et des environnements virtuels. Il permet d'installer plusieurs versions de Python, de créer et gérer des environnements virtuels, et de créer des bundles contenant une version spécifique de Python avec un environnement dédié.

## Fonctionnalités principales

- Installation de versions spécifiques de Python
- Création et gestion d'environnements virtuels
- Création de bundles (Python + environnement)
- Gestion des packages dans les environnements
- Listing des versions Python et environnements installés
- Suppression d'environnements et d'installations Python

## Installation

### Windows

Téléchargez le fichier d'installation :
[lollmsenv_installer.bat](https://github.com/ParisNeo/LollmsEnv/releases/download/V1.2.4/lollmsenv_installer.bat)

Exécutez le fichier téléchargé pour installer LollmsEnv.

### Linux/macOS

Téléchargez le script d'installation :
[lollmsenv_installer.sh](https://github.com/ParisNeo/LollmsEnv/releases/download/V1.2.4/lollmsenv_installer.sh)

Rendez le script exécutable et lancez-le :

```bash
chmod +x lollmsenv_installer.sh
./lollmsenv_installer.sh
```

## Utilisation

Après l'installation, vous pouvez utiliser LollmsEnv via la ligne de commande :

```bash
lollmsenv [commande] [options]
```

### Commandes principales

- `install-python [version] [dossier_personnalisé]` : Installe une version spécifique de Python
- `create-env [nom] [version-python] [dossier_personnalisé]` : Crée un nouvel environnement virtuel
- `activate [nom]` : Active un environnement
- `deactivate` : Désactive l'environnement actuel
- `install [package]` : Installe un package dans l'environnement actuel
- `list-pythons` : Liste les versions Python installées
- `list-envs` : Liste les environnements virtuels installés
- `create-bundle [nom] [version-python] [nom-env]` : Crée un bundle avec Python et un environnement
- `delete-env [nom]` : Supprime un environnement virtuel
- `delete-python [version]` : Supprime une installation Python

Pour une liste complète des commandes, utilisez `lollmsenv --help`.

## Exemples d'utilisation

1. Installer Python 3.9.5 :
   ```
   lollmsenv install-python 3.9.5
   ```

2. Créer un environnement virtuel avec Python 3.9.5 :
   ```
   lollmsenv create-env mon_env 3.9.5
   ```

3. Activer l'environnement :
   ```
   lollmsenv activate mon_env
   ```

4. Installer un package dans l'environnement actif :
   ```
   lollmsenv install numpy
   ```

5. Créer un bundle :
   ```
   lollmsenv create-bundle mon_bundle 3.9.5 mon_env
   ```

## Licence

Ce projet est sous licence Apache 2.0. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## Auteur

Développé par ParisNeo.

## Liens

- [Dépôt GitHub](https://github.com/ParisNeo/LollmsEnv)
- [Signaler un problème](https://github.com/ParisNeo/LollmsEnv/issues)

