// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// like Artion

error NftMarketPlace_PriceNotMet(
    address nftAddress,
    uint256 tokenId,
    uint256 price
);
error NftMarketPlace_ItemNotForSale(address nftAddress, uint256 tokenId);
error NftMarketPlace_NotListed(address nftAddress, uint256 tokenId);
error NftMarketPlace_AlreadyListed(address nftAddress, uint256 tokenId);
error NftMarketPlace_NoProceeds();
error NftMarketPlace_NotOwner();
error NftMarketPlace_NotApprovedForMarketplace();
error NftMarketPlace_PriceMustBeAboveZero();

contract NftMarketplace is ReentrancyGuard {
    struct Listing {
        uint256 price;
        address seller;
    }

    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    mapping(address => mapping(uint256 => Listing)) private s_itemsForSale;
    mapping(address => uint256) private s_proceeds;

    modifier notListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_itemsForSale[nftAddress][tokenId];
        if (listing.price > 0) {
            revert NftMarketPlace_AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_itemsForSale[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NftMarketPlace_NotListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NftMarketPlace_NoProceeds();
        }
        _;
    }

    /*
     * @notice Method for listing NFT
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     * @param price sale price for each item
     */

    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        notListed(nftAddress, tokenId)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        if (price <= 0) {
            revert NftMarketPlace_PriceMustBeAboveZero();
        }
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketPlace_NotApprovedForMarketplace();
        }
        s_itemsForSale[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    /* @notice Buy NFT
     * @notice Method for buying listing
     * @notice The owner of an NFT could unapprove the marketplace,
     * which would cause this function to fail
     * Ideally you'd also have a `createOffer` functionality.
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     */

    function buyItem(
        address nftAddress,
        uint256 tokenId
    ) external payable isListed(nftAddress, tokenId) nonReentrant {
        Listing memory listedItem = s_itemsForSale[nftAddress][tokenId];
        if (msg.value < listedItem.price) {
            revert NftMarketPlace_PriceNotMet(
                nftAddress,
                tokenId,
                listedItem.price
            );
        }
        s_proceeds[listedItem.seller] += msg.value;

        delete (s_itemsForSale[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(
            listedItem.seller,
            msg.sender,
            tokenId
        );
        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
    }

    /*
     * @notice Method for cancelling listing
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     */

    function cancelListing(
        address nftAddress,
        uint256 tokenId
    )
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
    {
        delete (s_itemsForSale[nftAddress][tokenId]);
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    /*
     * @notice Method for updating listing
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     * @param newPrice Price in Wei of the item
     */
    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isListed(nftAddress, tokenId)
        nonReentrant
        isOwner(nftAddress, tokenId, msg.sender)
    {
        //We should check the value of `newPrice` and revert if it's below zero (like we also check in `listItem()`)
        if (newPrice <= 0) {
            revert NftMarketPlace_PriceMustBeAboveZero();
        }
        s_itemsForSale[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }

    /*
     * @notice Method for withdrawing proceeds from sales
     */
    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) {
            revert NftMarketPlace_NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed");
    }

    /** @notice  get functions
     *  @notice Method for getting listing
     */
    function getListing(
        address nftAddress,
        uint256 tokenId
    ) external view returns (Listing memory) {
        return s_itemsForSale[nftAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }
}
