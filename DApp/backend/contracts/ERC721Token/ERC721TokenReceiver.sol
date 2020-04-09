pragma solidity >=0.4.20 <0.7.0;

import "./ERC721TokenReceiverInterface.sol";

contract ERC721TokenReceiver is ERC721TokenReceiverInterface {
    /**
     * @dev Magic value to be returned upon successful reception of an NFT
     *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
     *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
     */
  
  function onERC721Received(address _from, uint256 _tokenId, bytes memory _data) public returns(uint) {
      return 0xf0b9e5ba;
  }
}
