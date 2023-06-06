// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract AccountContract {
    mapping(address => bool) public isRegistered;
    mapping(address => address) public accountToPolygonAddress;

    function createAccount(address polygonAddress) external {
        require(!isRegistered[msg.sender], "Account already exists");
        require(polygonAddress != address(0), "Invalid Polygon address");

        isRegistered[msg.sender] = true;
        accountToPolygonAddress[msg.sender] = polygonAddress;
    }
}

contract WanCoin is ERC20 {
    constructor() ERC20("WanCoin", "WNC") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }
}

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFTContract is ERC721URIStorage {
    mapping(uint256 => address) public nftOwner;
    uint256 public tokenId;

    constructor() ERC721("DogPhotos", "DOG") {}

    function createNFT(address owner, string memory tokenURI) external returns (uint256) {
        tokenId++;
        _safeMint(owner, tokenId);
        _setTokenURI(tokenId, tokenURI);
        nftOwner[tokenId] = owner;

        return tokenId;
    }
}






contract MarketplaceContract {
    struct Listing {
        address seller;
        uint256 tokenId;
        uint256 price;
    }

    mapping(uint256 => Listing) public listings;
    uint256 public listingCount;

    event ListingCreated(address indexed seller, uint256 indexed tokenId, uint256 price);
    event ListingRemoved(uint256 indexed tokenId);
    event ListingSold(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 price);

    function createListing(uint256 tokenId, uint256 price) external {
        require(IERC721(msg.sender).ownerOf(tokenId) == msg.sender, "You don't own this NFT");
        require(IERC721(msg.sender).getApproved(tokenId) == address(this), "Marketplace not approved for NFT");

        listings[listingCount] = Listing({
            seller: msg.sender,
            tokenId: tokenId,
            price: price
        });

        emit ListingCreated(msg.sender, tokenId, price);
        listingCount++;
    }

    function removeListing(uint256 tokenId) external {
        require(listings[tokenId].seller == msg.sender, "You are not the seller");

        delete listings[tokenId];

        emit ListingRemoved(tokenId);
    }

    function buyNFT(uint256 tokenId) external payable {
        Listing memory listing = listings[tokenId];
        require(listing.seller != address(0), "Invalid listing");
        require(msg.value >= listing.price, "Insufficient funds");

        address payable seller = payable(listing.seller);
        seller.transfer(listing.price);

        IERC721(msg.sender).safeTransferFrom(address(this), msg.sender, tokenId);
        delete listings[tokenId];

        emit ListingSold(listing.seller, msg.sender, tokenId, listing.price);
    }
}
