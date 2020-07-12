var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";

module.exports = {
    networks: {
        development: {
            host: "127.0.0.1", // Localhost (default: none)
            port: 8545, // Standard Ethereum port (default: none)
            network_id: "*", // Any network (default: none)
        },

        rinkeby: {
            provider: () => new HDWalletProvider(mnemonic, `https://rinkeby.infura.io/v3/${infuraKey}`),
            network_id: 4, // Rinkeby's id
            gas: 4500000, // Rinkeby has a lower block limit than mainnet
            gasPrice: 10000000000
        }
    },

    compilers: {
        solc: {
            version: "^0.4.24",
        }
    }
};