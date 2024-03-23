//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {LotteryRandom} from "./LotteryRandom.sol";
import {Shard} from "./Shard.sol";
import {Badge} from "./Badge.sol";
import {ERC404} from "./erc404/ERC404.sol";
import "hardhat/console.sol";

contract Lottery is Ownable, ERC404 {
    LotteryRandom public lotteryRandom;
    Shard public shard;
    Badge public badge;

    uint256 public constant SHARD_NUMBER = 12;
    uint256 public constant TARGET_NUMBER = 3;

    uint256 public currentUnopened;
    uint256 public currentShardNumber;

    string public baseURI = "https://lottery.com/";

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address initialOwner_,
        address lotteryRandom_,
        address shard_,
        address badge_
    ) ERC404(name_, symbol_, decimals_) Ownable(initialOwner_) {
        lotteryRandom = LotteryRandom(lotteryRandom_);
        totalSupply = 100 ** decimals_;
        currentShardNumber = SHARD_NUMBER;
        currentUnopened = 0;
        shard = Shard(shard_);
        badge = Badge(badge_);
    }

    function _afterERC721Mint(uint256 id_) internal override {
        currentUnopened = currentUnopened + 1;
    }

    function open(uint256 tokenId) public returns (uint256 requestId) {
        require(ownerOf(tokenId) == _msgSender(), "Not the owner");

        requestId = lotteryRandom.requestRandomWords(tokenId, _msgSender());
        transferFrom(_msgSender(), address(this), tokenId);
        currentUnopened -= 1;
    }

    function claimShard(uint256 reqId) public {
        require(lotteryRandom.getRequestResult(reqId).winning, "Not winning");
        require(currentShardNumber > 0, "No shard left");

        shard.mint(msg.sender);
        lotteryRandom.setWinningResult(reqId, false);

        currentShardNumber -= 1;
    }

    function claim() public {
        require(
            shard.balanceOf(msg.sender) >= TARGET_NUMBER,
            "Not enough shards"
        );

        //TODO burn shard

        badge.mint(msg.sender);

        uint256 pool = erc20BalanceOf(address(this));
        uint256 winnerAmount = (pool / 100) * 80;
        uint256 ownerAmount = (pool / 100) * 10;

        _transferERC20WithERC721(address(this), msg.sender, winnerAmount);
        _transferERC20WithERC721(address(this), owner(), ownerAmount);

        //Start newRound
        _setUnopenedAndShardNumber(minted, SHARD_NUMBER);
    }

    function mintERC20(address to, uint256 value) public payable {
        require(msg.value >= (value / 100), "Not enough ether");
        _mintERC20(to, value);
    }

    function _setUnopenedAndShardNumber(
        uint256 _currentUnopened,
        uint256 _currentShardNumber
    ) internal {
        currentUnopened = _currentUnopened;
        currentShardNumber = _currentShardNumber;
    }

    function withdraw() external onlyOwner {
        erc20TransferFrom(
            address(this),
            owner(),
            erc20BalanceOf(address(this))
        );
    }

    function getCurrentUnopened() public view returns (uint256) {
        return currentUnopened;
    }

    function getCurrentShardNumber() public view returns (uint256) {
        return currentShardNumber;
    }

    function setRandom(address lotteryRandom_) public onlyOwner {
        lotteryRandom = LotteryRandom(lotteryRandom_);
    }

    function setShard(address shard_) public onlyOwner {
        shard = Shard(shard_);
    }

    function setBadge(address badge_) public onlyOwner {
        badge = Badge(badge_);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(id)));
    }
}
