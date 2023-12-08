## Getting Started

Requirements / Steps are performed on MacOS.

### Requirements:

-   **Foundry** [[Official Docs]](https://book.getfoundry.sh/getting-started/installation):

    `curl -L https://foundry.paradigm.xyz | bash`

-   **Rust** [[Official Docs]](https://doc.rust-lang.org/book/ch01-01-installation.html):

    `curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh`

-   **Yarn**[[Official Docs]](https://classic.yarnpkg.com/lang/en/docs/install/#mac-stable):

    `npm install --global yarn`

-   **CMake** [[Official Docs]](https://cmake.org/download/):

    -   [MacOS] Install GUI: [v3.7.0](https://github.com/Kitware/CMake/releases/download/v3.27.0/cmake-3.27.0-macos-universal.dmg)
    -   Add it to the Application folder
    -   Open terminal and run:

        ` sudo "/Applications/CMake.app/Contents/bin/cmake-gui" --install`

### Setup process:

-   Clone the repo with the `--recursive` flag

    ```
    git clone https://github.com/filecoin-project/filecoin-solidity.git --recursive
    ```

-   Run: `cd filecoin-solidity`
-   Install Solc:

    -   MacOS:
        `make install_solc_mac`
    -   Linux:
        `make install_solc_linux`

-   Run: `make`

### Workflow

-   Compiling / testing contracts:

    `forge <build/test>`

-   Running all of the integration tests:

    `make test_integration`

-   Running individual integration tests:
    -   see [Makefile](./Makefile) for a complete list

### Supported networks

The following table contains information about the versions of filecoin network on which the `filecoin-solidity` library has been tested on.

|                                              FVM version                                              |                                                         Builtin actors                                                          |        Pass        |
| :---------------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------------------------------------------------: | :----------------: |
| [fvm@v3.0.0-alpha.21](https://github.com/filecoin-project/ref-fvm/releases/tag/fvm%40v3.0.0-alpha.21) | [builtin_actors@dev/20230206-pre-rc.6](https://github.com/filecoin-project/builtin-actors/releases/tag/dev%2F20230206-pre-rc.6) | :white_check_mark: |
