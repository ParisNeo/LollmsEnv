# LollmsEnv

![Licence GitHub](https://img.shields.io/github/license/ParisNeo/LollmsEnv)
![Étoiles GitHub](https://img.shields.io/github/stars/ParisNeo/LollmsEnv)
![Forks GitHub](https://img.shields.io/github/forks/ParisNeo/LollmsEnv)
![Problèmes GitHub](https://img.shields.io/github/issues/ParisNeo/LollmsEnv)

LollmsEnv est un outil léger et simple pour gérer les environnements et les versions Python. Il fournit une interface facile à utiliser pour installer plusieurs versions de Python, créer et gérer des environnements virtuels, et regrouper des installations Python avec des environnements.

## Table des matières

1. [Fonctionnalités](#fonctionnalités)
2. [Installation](#installation)
3. [Utilisation](#utilisation)
4. [Commandes](#commandes)
5. [Exemples](#exemples)
6. [Licence](#licence)
7. [Remerciements](#remerciements)

## Fonctionnalités

- Installer et gérer plusieurs versions de Python
- Créer et gérer des environnements virtuels
- Créer des regroupements d'installations Python avec des environnements
- Support multiplateforme (Windows et systèmes basés sur Unix)
- Léger et facile à utiliser
- Prend en charge les répertoires d'installation personnalisés

## Installation

### Windows

1. Téléchargez l'installateur :
   [lollmsenv_installer.bat](https://github.com/ParisNeo/LollmsEnv/releases/download/V1.2.5/lollmsenv_installer.bat)

2. Exécutez l'installateur :
   ```
   lollmsenv_installer.bat [options]
   ```

### Systèmes basés sur Unix (Linux, macOS)

1. Téléchargez l'installateur :
   [lollmsenv_installer.sh](https://github.com/ParisNeo/LollmsEnv/releases/download/V1.2.5/lollmsenv_installer.sh)
   ou bien dans la console, tapez:
   ```
   wget https://github.com/ParisNeo/LollmsEnv/releases/download/V1.2.5/lollmsenv_installer.sh
   ```

3. Rendez l'installateur exécutable :
   ```
   chmod +x lollmsenv_installer.sh
   ```

4. Exécutez l'installateur :
   ```
   ./lollmsenv_installer.sh [options]
   ```

### Options d'installation

- `--local` : Installer LollmsEnv localement dans le répertoire actuel.
- `--dir <répertoire>` : Installer LollmsEnv dans le répertoire spécifié.
- `--no-modify-rc` : Ne pas modifier .bashrc ou .zshrc (Unix) ou le PATH système (Windows). Générer un script source à la place.
- `-h, --help` : Afficher le message d'aide et quitter.

## Utilisation

Après l'installation, vous pouvez utiliser la commande `lollmsenv` pour gérer les versions et les environnements Python.

Pour Windows :
```
lollmsenv.bat [commande] [options]
```

Pour les systèmes basés sur Unix :
```
[source] lollmsenv [commande] [options]
```

Si vous n'avez pas accepté d'ajouter lollmsenv à votre Path (`--no-modify-rc`), assurez-vous de commencer par activer l'outil avant utilisation :
Windows
```
chemin/vers/votre/lollmsenv activate
```

Linux
```
source chemin/vers/votre/lollmsenv activate 
```

## Commandes

- `install-python [version] [répertoire_personnalisé]` : Installer une version spécifique de Python
- `create-env [nom] [version-python] [répertoire_personnalisé]` : Créer un nouvel environnement virtuel
- `activate [nom]` : Activer un environnement
- `deactivate` : Désactiver l'environnement actuel
- `install [package]` : Installer un package dans l'environnement actuel
- `list-pythons` : Lister les versions Python installées
- `list-envs` : Lister les environnements virtuels installés
- `list-available-pythons` : Lister les versions Python disponibles pour l'installation
- `create-bundle [nom] [version-python] [nom-env]` : Créer un regroupement avec Python et environnement
- `delete-env [nom]` : Supprimer un environnement virtuel
- `delete-python [version]` : Supprimer une installation Python
- `--help, -h` : Afficher le message d'aide

## Exemples

1. Installer Python 3.9.5 :
   ```
   lollmsenv install-python 3.9.5
   ```

2. Créer un nouvel environnement nommé "monprojet" avec Python 3.9.5 :
   ```
   lollmsenv create-env monprojet 3.9.5
   ```

3. Activer l'environnement "monprojet" :
   Windows :
   ```
   lollmsenv activate monprojet
   ```
   Linux :
   ```
   source lollmsenv activate monprojet
   ```

5. Installer un package dans l'environnement actuel :
   ```
   lollmsenv install numpy
   ```

6. Créer un regroupement avec Python 3.9.5 et un environnement nommé "monregroupement" :
   ```
   lollmsenv create-bundle monregroupement 3.9.5 monenv
   ```

## Licence

Ce projet est open source et disponible sous la [Licence Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0).

## Remerciements

LollmsEnv a été créé par ParisNeo et est hébergé sur GitHub à l'adresse [https://github.com/ParisNeo/LollmsEnv](https://github.com/ParisNeo/LollmsEnv).
