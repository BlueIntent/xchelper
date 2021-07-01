# xchelper

[![License](https://img.shields.io/github/license/blueintent/xchelper)](https://github.com/blueintent/xchelper/blob/main/LICENSE)

__xchelper__ is a tool for iOS developers to automate tedious tasks like run, test.

## Installation

| Method    | Command                                                                                           |
|:----------|:--------------------------------------------------------------------------------------------------|
| **curl**  | `sh -c "$(curl -fsSL https://raw.githubusercontent.com/BlueIntent/xchelper/main/scripts/install.sh)"` |
| **wget**  | `sh -c "$(wget -O- https://raw.githubusercontent.com/BlueIntent/xchelper/main/scripts/install.sh)"`   |
``` diff
- brew install xchelper
+ GitHub repository not notable enough (<30 forks, <30 watchers and <75 stars)
```

## Usage

install project dependencies.
```bash 
xchelper install
```

install project dependencies, and open workspace.
```bash 
xchelper run
```

test a scheme from the build root (SYMROOT).
```bash 
xchelper test
```