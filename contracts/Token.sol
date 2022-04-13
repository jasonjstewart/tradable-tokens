//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract TokenContract {

    event TokenListed(uint tokenId, uint32 listPrice);
    event TokenUnlisted(uint tokenId);
    event MakeOffer(uint offerId, uint32 offerPrice);
    event RetractOffer(uint offerId, uint32 offerPrice);
    event TokenTransfer(address from, address to, uint32 salePrice);

    struct Token {
        address currentOwner;
        uint32 originalTokenPrice;
        uint32 lastPurchasePrice;
        bool listed;
        uint32 listPrice;
    }

    struct Offer {
        address buyer;
        uint32 offerPrice;
        bool active;
    }

    string public tokenId;
    address private tokenOwner;
    uint public totalSupply;
    uint public circulatingSupply;
    Token[] private tokens;
    Offer[] private offers;
    mapping(address => uint) public addressToTokenCount;
    mapping(address => uint) public addressToOfferCount;
    mapping(address => uint) public addressToOffer;

    // Used to create view functions
    uint public listingsCount;
    uint public offersCount;

    // use this to know how many tokens are for sale from a seller
    // we can then sell multiple tokens at once
    mapping(address => uint) escrowedTokensBalance;

    constructor(string memory _tokenId, address _tokenOwner, uint _totalSupply, uint _initialSupply, uint32 _pricePerShare ) {
        tokenId = _tokenId;
        totalSupply = _totalSupply;
        circulatingSupply = _initialSupply;
        tokenOwner = _tokenOwner;
        
        for(uint i = 1; i < _totalSupply; i++) {
            address _assignee;
            if (i < _initialSupply) {
                _assignee = _tokenOwner;
            } else {
                _assignee = msg.sender;
            }
            tokens.push(Token({
                currentOwner: _assignee,
                originalTokenPrice: _pricePerShare,
                lastPurchasePrice: _pricePerShare,
                listed: false,
                listPrice: 0
            }));
            addressToTokenCount[_assignee]++;
        }
    }

    modifier onlyAdmin() {
        _;
    }

    modifier onlyTokenOwner(uint _tokenId) {
        require(msg.sender == tokens[_tokenId].currentOwner);
        _;
    }

    modifier onlyOfferBuyer(uint _offerId) {
        require(msg.sender == offers[_offerId].buyer);
        _;
    }

    modifier isListed(uint _tokenId){
        require(tokens[_tokenId].listed==true);
        _;
    }

    //modifier to check tokens are available and in smart contract

    
    //modifier the smart contract has enough money to faciliate a trade


    modifier amountSentMoreThanOfferPrice(uint32 _offerPrice){
        require(msg.value > _offerPrice);
        _;
    }

    function getListings() external view returns(Token[] memory) {
        Token[] memory listings = new Token[](listingsCount);
        uint256 count = 0;
        //TODO: is this the best check????
        if (count > listingsCount){
            return listings;
        }
        for (uint256 index = 0; index < tokens.length; index++) {
            if (tokens[index].listed == true){
                listings[count]=tokens[index];
                count++;
            }
        }

        return listings;
    }

    function getOffers() external view returns(Offer[] memory) {
        Offer[] memory activeOffers = new Offer[](offersCount);
        uint256 count = 0;
        if (count > offersCount){
            return activeOffers;
        }
        for (uint256 index = 0; index < tokens.length; index++) {
            if (offers[index].active == true){
                activeOffers[count]=offers[index];
                count++;
            }
        }
        return activeOffers;
    }

    function getAddressTokens() external view returns(Token[] memory) {
        Token[] memory addressTokens = new Token[](addressToTokenCount[msg.sender]);
        uint256 count = 0;
        for (uint256 index = 0; index < tokens.length; index++) {
            if (tokens[index].currentOwner == msg.sender){
                addressTokens[count]=tokens[index];
                count++;
            }
        }

        return addressTokens;
    }

    function getAddressOffers() external view returns(Offer[] memory) {
        // TODO get any offer that are the senders and are active
        Offer[] memory addressOffers = new Offer[](addressToOfferCount[msg.sender]);
        uint256 count = 0;
        for (uint256 index = 0; index < tokens.length; index++) {
            if (offers[index].buyer == msg.sender){
                addressOffers[count]=offers[index];
                count++;
            }
        }

        return addressOffers;
    }

    function getBalance(address addr) public view returns (uint) {
        return addressToTokenCount[addr];
    }

    function getToken(uint _tokenId) public view returns (Token memory) {
        return tokens[_tokenId];
    }

    function listToken(uint _tokenId, uint32 _listPrice) public onlyTokenOwner(_tokenId) {
        depositToken();
        tokens[_tokenId].listPrice = _listPrice;
        tokens[_tokenId].listed = true;
        listingsCount++;
    }


    function depositToken() public {
        escrowedTokensBalance[msg.sender]=escrowedTokensBalance[msg.sender]+1;
        TokenContract(address(this)).transferFrom(msg.sender, address(this), 1);
    }

    function returnToken() public {
        escrowedTokensBalance[msg.sender]=escrowedTokensBalance[msg.sender] - 1;
        TokenContract(address(this)).transferFrom(address(this),msg.sender, 1);
    }

    function updateToken(uint _tokenId, uint32 _listPrice) public onlyTokenOwner(_tokenId) isListed(_tokenId) {
        tokens[_tokenId].listPrice = _listPrice;
    }

    function unlistToken(uint _tokenId) public onlyTokenOwner(_tokenId) isListed(_tokenId){
        returnToken();
        tokens[_tokenId].listed = false;
        listingsCount--;
    }

    function makeOffer(uint32 _offerPrice) public payable amountSentMoreThanOfferPrice(_offerPrice){
        payable(address(this)).transfer(msg.value);
        addressToOffer[msg.sender] = offers.length;
        offers.push(Offer(msg.sender, _offerPrice, true));
        offersCount++;
    }

    // TODO: Could find a way to update this where we add or subtract and change the offerPrice. This is the easiest right now. We will need some frontend logic to 
    // make it easier if we go add/subtract
    function updateOffer(uint32 _offerPrice) public payable  amountSentMoreThanOfferPrice(_offerPrice) { 
        uint offerId = addressToOffer[msg.sender];
        payable(msg.sender).transfer(offers[offerId].offerPrice);
        payable(address(this)).transfer(msg.value);
        offers[offerId].offerPrice = _offerPrice;
    }

    function retractOffer() public { 
        uint offerId = addressToOffer[msg.sender];
        offers[offerId].active = false;
        payable(msg.sender).transfer(offers[offerId].offerPrice);
        offersCount--;
    }

    function buyListing(uint _tokenId) public payable {
        require(getBalance(tokens[_tokenId].currentOwner)>=1, "Seller does not have enough tokens.");
        require(msg.value >= tokens[_tokenId].listPrice, "Insufficient funds sent, please send the correct amount of funds.");
        transferFrom(address(this), msg.sender, 1);
        payable(tokens[_tokenId].currentOwner).transfer(msg.value);
        tokens[_tokenId].listed=false;
        tokens[_tokenId].lastPurchasePrice=tokens[_tokenId].listPrice;
        incrementTokenCount(msg.sender);
        decrementTokenCount(tokens[_tokenId].currentOwner);
        listingsCount--;
        emit TokenTransfer(tokens[_tokenId].currentOwner, msg.sender, tokens[_tokenId].listPrice);
    }


    //TODO: think through how this will work, because there is no listing so is it just any token that the owner holds that isnt listed?
    function acceptOffer(uint _offerId) public payable {
        require(getBalance(msg.sender)>=1, "Seller does not have enough tokens.");
        transferFrom(address(this), offers[_offerId].buyer, 1);
        payable(msg.sender).transfer(msg.value);
        incrementTokenCount(offers[_offerId].buyer);
        decrementTokenCount(msg.sender);
        offersCount--;
        emit TokenTransfer(msg.sender,offers[_offerId].buyer, offers[_offerId].offerPrice);
    }

    function releaseToken(uint _amount) public onlyAdmin {
        // TODO release the tokens to the tokenOwner
    }

    //TODO: see if this incrementing works
    function incrementTokenCount(address tokenAddress) private {
        addressToTokenCount[tokenAddress] = addressToTokenCount[tokenAddress]+1;
    }

    //TODO: see if this decrementing works
    function decrementTokenCount(address tokenAddress) private {
        addressToTokenCount[tokenAddress] = addressToTokenCount[tokenAddress]-1;
    }

    //TODO: this may be best as a private function but deposit relies on it being public
    function transferFrom(address from, address to, uint256 count) public {
        // this code should be able to be pulled in from ERC721 contracts
    }
}