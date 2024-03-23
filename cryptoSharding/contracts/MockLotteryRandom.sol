//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "hardhat/console.sol";
import {Lottery} from "./Lottery.sol";

contract MockLotteryRandom is VRFConsumerBaseV2 {
    event RequestSent(uint256 requestId, uint32 numWords, uint256 tokenId);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        bool winning;
        uint256 tokenId;
        address owner;
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    uint256[] public requestIds;
    uint256 public lastRequestId;

    //TODO this configuration is holesky now
    uint64 s_subscriptionId;
    VRFCoordinatorV2Interface COORDINATOR;
    bytes32 keyHash =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    Lottery lottery;

    constructor(
        address vrfCoordinator,
        uint64 subscriptionId
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    modifier onlyLottery() {
        require(
            msg.sender == address(lottery),
            "Only lottery can call this function"
        );
        _;
    }

    function setLottery(address newLottery) public {
        lottery = Lottery(newLottery);
    }

    function requestRandomWords(
        uint256 tokenId,
        address owner
    ) public returns (uint256 requestId) {
        requestId = block.number;

        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            tokenId: tokenId,
            exists: true,
            fulfilled: false,
            winning: false,
            owner: owner
        });

        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords, tokenId);

        uint256[] memory _randomWords = new uint256[](1);
        _randomWords[0] = requestId + 10;
        fulfillRandomWords(requestId, _randomWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        _setWinningResult(_requestId, _randomWords[0]);

        emit RequestFulfilled(_requestId, _randomWords);
    }

    function _setWinningResult(
        uint256 _requestId,
        uint256 randomWord
    ) internal {
        if (
            (randomWord % lottery.getCurrentUnopened()) <
            lottery.getCurrentShardNumber()
        ) {
            s_requests[_requestId].winning = true;
        }
    }

    function getRequestResult(
        uint256 requestId
    ) public view returns (RequestStatus memory) {
        require(s_requests[requestId].exists, "request not found");
        return s_requests[requestId];
    }

    function setWinningResult(uint256 requestId, bool winning) public {
        s_requests[requestId].winning = winning;
    }
}
