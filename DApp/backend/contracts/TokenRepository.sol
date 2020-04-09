pragma solidity >=0.4.17 <0.7.0;

import "./ERC721Token/ERC721AdvancedToken.sol";

/**
 * @title Repository of ERC721 Tokens
 * This contract contains the list of tokens registered by users.
 * This is a demo to show how tokens can be minted and added to the repository.
 */
 contract TokenRepository is ERC721AdvancedToken{
     /**
      * @dev Event is triggered if deed/token is registered
      * @param _by address of the registrar
      * @param _tokenId uint256 represents a specific deed
      */
     event TokenRegistered(address _by, uint256 _tokenId);
     
     /**
      * @dev Created a TokenRepository with a name and symbol
      * @param _name string represents the name of the repository
      * @param _symbol string represents the symbol of the repository
      */
     constructor (string memory _name, string memory _symbol) ERC721AdvancedToken(_name, _symbol) public {} //???
    
     /**
      * @dev Public function to add metadata to a deed
      * @param _tokenId represents a specific deed
      * @param _uri text which describes the characteristics of a given deed
      * @return whether the deed metadata was added to the repository
      */
     function addTokenMetadata(uint256 _tokenId, string memory _uri) public returns(bool) {
         super.setTokenURL(_tokenId, _uri);
         return true;
     } 
    
     /**
      * @dev Public function to register a new token
      * @dev Call the ERC721Token minter
      * @param _tokenId uint256 represents a specific token
      * @param _uri string containing metadata/uri
      */
     function registerToken(uint256 _tokenId, string memory _uri) public returns(bool) {
         super._mint(msg.sender, _tokenId);
         addTokenMetadata(_tokenId, _uri);
         emit TokenRegistered(msg.sender, _tokenId);
     } 
 }
