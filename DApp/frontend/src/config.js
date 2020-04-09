var DeedRepository = require('./contracts/DeedRepository')
var AuctionRepository = require('./contracts/AuctionRepository')

module.exports = {
    JSONRPC_ENDPOINT: 'http://52.59.238.144:8545',
    JSONRPC_WS_ENDPOINT: 'ws://52.59.238.144:8546', //'ws://52.59.238.144:8546',
    BZZ_ENDPOINT: 'http://52.59.238.144:8500',
    SHH_ENDPOINT: 'ws://52.59.238.144:8546',

    DEEDREPOSITORY_ADDRESS: '0x100525CE9177Ce7214Fff8efE532048B3e125e96',
    AUCTIONREPOSITORY_ADDRESS: '0xe0Ce03b391ed1Bd7db752d8eEabDCd8115647161',

    DEEDREPOSITORY_ABI: DeedRepository.abi,
    AUCTIONREPOSITORY_ABI: AuctionRepository.abi,

    GAS_AMOUNT: 500000,

    //whisper settings
    WHISPER_SHARED_KEY: '0x8bda3abeb454847b515fa9b404cede50b1cc63cfdeddd4999d074284b4c21e15'

}

// web3.eth.sendTransaction({from: web3.eth.accounts[0], to: "0x6f0023D1CFe5A7A56F96e61E0169B775Ac97f90E" , value: web3.toWei(1, 'ether'), gasLimit: 21000, gasPrice: 20000000000})
