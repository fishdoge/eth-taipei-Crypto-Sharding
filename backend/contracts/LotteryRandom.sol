//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Lottery} from "./Lottery.sol";

contract LotteryRandom is VRFConsumerBaseV2, Ownable {
    event RequestSent(uint256 requestId, address owner, uint256 tokenId);
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

    uint64 s_subscriptionId;
    VRFCoordinatorV2Interface COORDINATOR;
    bytes32 keyHash;
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    Lottery public lottery;

    constructor(
        address vrfCoordinator,
        uint64 subscriptionId,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) Ownable(msg.sender) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        keyHash = _keyHash;
    }

    modifier onlyLottery() {
        require(
            msg.sender == address(lottery),
            "Only lottery can call this function"
        );
        _;
    }

    function setLottery(address newLottery) public onlyOwner {
        lottery = Lottery(newLottery);
    }

    function requestRandomWords(
        uint256 tokenId,
        address owner
    ) external onlyLottery returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

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

        emit RequestSent(requestId, owner, tokenId);
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

    function setWinningResult(
        uint256 requestId,
        bool winning
    ) external onlyLottery {
        s_requests[requestId].winning = winning;
    }
}
