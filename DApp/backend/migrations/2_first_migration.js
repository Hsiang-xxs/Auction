//var ERC721Interface = artifacts.require("ERC721Interface");
//var ERC721Metadata = artifacts.require("ERC721Metadata");
//var ERC721Enumerable = artifacts.require("ERC721Enumerable");
//var ERC721TokenReceiverInterface = artifacts.require("ERC721TokenReceiverInterface");
var ERC721TokenReceiver = artifacts.require("ERC721TokenReceiver");
var ERC721BasicToken = artifacts.require("ERC721BasicToken");
var ERC721AdvancedToken = artifacts.require("ERC721AdvancedToken");
var TokenRepository = artifacts.require("TokenRepository");
var AuctionRepository = artifacts.require("AuctionRepository");
//var ERC165 = artifacts.require("ERC165");

module.exports = function(deployer) {
    //deployer.deploy(ERC721Interface);
    //deployer.deploy(ERC721Metadata);
    //deployer.deploy(ERC721Enumerable);
    //deployer.deploy(ERC721TokenReceiverInterface);
    deployer.deploy(ERC721TokenReceiver);
    deployer.deploy(ERC721BasicToken);
    deployer.deploy(ERC721AdvancedToken, 'xxs', 'no');
    deployer.deploy(TokenRepository, 'xxs', 'no');
    deployer.deploy(AuctionRepository);
    //deployer.deploy(ERC165);
};
