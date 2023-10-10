  // SPDX-License-Identifier: MIT
  pragma solidity ^0.8.4;

  import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
  import "@openzeppelin/contracts/utils/Counters.sol";
  import "@openzeppelin/contracts/utils/math/SafeMath.sol";
  import "@openzeppelin/contracts/access/Ownable.sol";
  import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

  struct MarketItem {
          uint256 tokenId;
          address payable creator;
          address payable owner;
          address payable lastSeller;
          string tokenURI;
          uint256 price;
          bool sold; 
    }

  struct Creator {
      uint256 creatorId;
      address creatorAddress;
      string name;
      uint256 ItemCount;
      uint256 totalSells;
  }

  contract NFTMarket is ERC721URIStorage{
    using Counters for Counters.Counter;
    using SafeMath for uint256; 

    Counters.Counter private _tokenIDs;

    Counters.Counter private _creatorIDs;

    error alreadyRegisterd();
    error notRegisterdAsCreator();
    error zeroBalance();
    error incorrectAmount();
    error notForSale();
    error invalidTokenID();
    error notTheOwner();
    

    address private immutable owner;

    mapping(uint256 => Creator) private creators;

    mapping(address => uint256) private balance;

    mapping(uint256 => MarketItem) public idToMarketItem;

    event NFTTransfer(uint256 tokenID, address from, address to, string tokenURI, uint256 price);

    constructor() ERC721("NFTs", "NFT") {
        owner = msg.sender;
    }

    function addCreater(string calldata _name) public { 
      if(_ifAlredyExist(msg.sender) != 0){
        revert alreadyRegisterd();
      }
      _creatorIDs.increment();
      creators[_creatorIDs.current()] = Creator(_creatorIDs.current(), msg.sender, _name, 0, 0);
    } 

    function _ifAlredyExist(address account) internal view returns(uint256){
      uint256 creatorCount = _creatorIDs.current();

      for(uint256 i=0;i<creatorCount;i++){
        if(creators[i+1].creatorAddress  == account){
          return i+1;
        }
      } 
      return 0;
    } 

    function createNFT(string calldata _tokenURI, uint256 _price) public { 
        if(_ifAlredyExist(msg.sender) == 0){
          revert notRegisterdAsCreator();
        }
        _tokenIDs.increment();
        uint256 currentID = _tokenIDs.current(); 
        idToMarketItem[currentID] = MarketItem(currentID, payable(msg.sender), payable(address(this)), payable(msg.sender), _tokenURI, _price, false); 
        creators[_ifAlredyExist(msg.sender)].ItemCount += 1;
    }

    function purchaseNFT(uint256 _tokenID) public payable { 
      if( !(_tokenID > 0 && _tokenID <= _tokenIDs.current())){
        revert invalidTokenID();
      }
      MarketItem storage item = idToMarketItem[_tokenID]; 
      if(item.sold){
        revert notForSale();
      }
 
      if(msg.value != item.price){
        revert incorrectAmount();
      }

      _mint(msg.sender, _tokenID);
      _setTokenURI(_tokenID, item.tokenURI); 
      idToMarketItem[_tokenID].owner = payable(msg.sender);
      idToMarketItem[_tokenID].sold = true; 
      creators[_ifAlredyExist(item.creator)].totalSells += 1;
      balance[item.creator] += item.price;
    } 

    function resellNFT(uint256 _tokenID, uint256 _price) public {  
      if( !(_tokenID > 0 && _tokenID <= _tokenIDs.current())){
        revert invalidTokenID();
      }
      MarketItem storage item = idToMarketItem[_tokenID]; 
      if(ownerOf(_tokenID) != payable(msg.sender)){
        revert notTheOwner();
      }
      idToMarketItem[_tokenID].sold = false;
      idToMarketItem[_tokenID].price = _price;
      idToMarketItem[_tokenID].lastSeller = payable(msg.sender);
      creators[_ifAlredyExist(item.creator)].totalSells += 1;
      _transfer(payable(msg.sender), address(this), _tokenID);
    }

    function rePurchaseNFT(uint256 _tokenID) public payable { 
      if(!(_tokenID > 0 && _tokenID <= _tokenIDs.current())){
        revert invalidTokenID();
      }
      MarketItem storage item = idToMarketItem[_tokenID]; 
      
      if(item.creator == item.lastSeller){
        revert notForSale();
      } 
      if(msg.value != item.price){
        revert incorrectAmount();
      }
      idToMarketItem[_tokenID].sold = true;
      idToMarketItem[_tokenID].owner= payable(msg.sender);
      _transfer(address(this), msg.sender, _tokenID);
      balance[item.creator] += item.price.mul(5).div(100);
      balance[item.lastSeller] += item.price.mul(95).div(100);
      
    }

    function withdrawFunds() public payable returns(bool){
      uint256 _balance =  balance[address(msg.sender)]; 
      if(_balance == 0){
        revert zeroBalance();
      }
      (bool success, ) = msg.sender.call{value: _balance}("");
      if(success == true){
        balance[address(msg.sender)] = 0;
      }
      return success;
    } 

    function getBalance() public view returns(uint256){
      return balance[msg.sender];
    }

    function getAllNFTs() public view returns (MarketItem[] memory) {
      uint256 itemCount = _tokenIDs.current();
      MarketItem[] memory items = new MarketItem[](itemCount);
 
      for (uint256 i = 0; i < itemCount; i++) { 
              items[i] = idToMarketItem[i + 1];   
      } 

      return items;
  }

    function getAllCreators() public view returns (Creator[] memory) { 
        uint256 creatorCount = _creatorIDs.current();
        Creator[] memory allCreators = new Creator[](creatorCount);

        for (uint256 i = 0; i < creatorCount; i++) { 
            allCreators[i] = creators[i + 1];
        }

        return allCreators;
    }
    
  }