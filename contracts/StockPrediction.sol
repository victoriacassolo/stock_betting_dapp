// SDPX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StockPrediction {
    address public owner;
    uint256 public predictionStartTime;
    uint256 public predictionEndTime;
    int public currentPrice; // Allows for negative numbers using int
    mapping (address => uint) public bets;
    address[] public bettors;
    mapping(address => uint256) public betAmounts;

    uint public lastCheckedTime;
    bool public isBettingActive;
    address public lastWinner;

    struct Bet {
        address bettor;
        int amount;
    }

    struct BetInfo {
        address bettor;
        int amount;
        uint256 betAmount;
    }

    constructor() {
        owner = msg.sender;
        predictionEndTime = block.timestamp + 5 minutes;
        isBettingActive = false;
    }

    function getAllBets() public view returns (BetInfo[] memory) {
        BetInfo[] memory allBets = new BetInfo[](bettors.length);
        for(uint256 i = 0; i < bettors.length; i++) {
            allBets[i].bettor = bettors[i];
            allBets[i].amount = bets[bettors[i]];
            allBets[i].betAmount = betAmounts[bettors[i]];
        }

        return allBets;
    }

    function startPrediction(int _currentPrice) public {
        require(msg.sender == owner, 'Only owner can start prediction');
        currentPrice = _currentPrice;
        predictionStartTime = block.timestamp;
        predictionEndTime = block.timestamp + 5 minutes;
        isBettingActive = true;
    }

    function enterBet(int _prediction) public payable {
        require(block.timestamp < predictionEndTime, 'Prediction has ended');
        require(msg.value >= 0.0001, 'Minimum bet amount is 0.0001 ETH');
        bets[msg.sender] = _prediction;
        bettors.push(msg.sender);
        betAmounts[msg.sender] = msg.value;
    }

    // Finalize Prediction
    function finalizePrediction(int _currentPrice) public {
        require(block.timestamp >= predictionEndTime, 'Prediction has not ended');
        require(isBettingActive, 'Prediction is not active');
        
        int closestPrediction = bets[bettors[0]];
        uint closestDistance = abs(currentPrice, closestPrediction);
        address payable winner = payable(bettors[0]);

        for(uint i = 1; i < bettors.length; i++) {
            int prediction = bets[bettors[i]];
            uint distance = abs(currentPrice, prediction);
            if(distance < closestDistance) {
                closestPrediction = prediction;
                closestDistance = distance;
                winner = payable(bettors[i]);
            }
        }

        uint pool = address(this).balance;
        require(pool > 0, 'Pool is empty');
        require(winner != address(0), 'No winner found');
        winner.transfer(pool);
        lastWinner = winner;

        // Reset
        predictionStartTime = 0;
        predictionEndTime = 0;
        currentPrice = 0;
        isBettingActive = false;

        for(uint i = 0; i < bettors.length; i++) {
            bets[bettors[i]] = 0;
        }

        bettors = new address[](0);
    }

    // Helper Functions
    function resetLastWinner() public {
        require(msg.sender == owner, 'Only owner can reset last winner');
        lastWinner = address(0);
    }

    function isPredictionOver() public view returns (bool) {
        if(block.timestamp >= predictionEndTime) {
            return true;
        }
        return false;
    }

    function getPoolAmount() public view returns (uint) {
        return address(this).balance;
    }

    function abs(int x, int y) internal pure returns (uint) {
        return x >= y ? uint(x-y) : uint(y-x);
    }
}