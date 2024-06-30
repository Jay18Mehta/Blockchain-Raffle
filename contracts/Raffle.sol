// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";  // for keepers
//npm i @chainlink/contracts , will add this in nodemodules


error Raffle__NotEnoughEthEntered();
error Raffle__TransferFailed();
error Raffle__RaffleNotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

contract Raffle is VRFConsumerBaseV2,AutomationCompatibleInterface {  // because we are overriding one of its function
    
    /* Type declarations */
    enum RaffleState { // because while searching for winner no one should enter in lottery
        OPEN,
        CALCULATING
    } // uint256 open=0,CALCULATING=1

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;  //address payable is an address you can send Ether to, while you are not supposed to send Ether to a plain address
    address private s_recentWinner; 
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS =3;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant NUM_WORDS =3;

    //events = >Emit a event when we update a dynamic array or mapping
                // Events are emitted to data-storage outside of smart contract
    //name events with function named reverse.
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    // VRFConsumerBaseV2 is constructor of VRFConsumerBaseV2.sol and it takes _vrfCoordinator as input
    constructor (address _vrfCoordinator,uint256 entranceFee,bytes32 _keyHash,uint64 _subscriptionId,uint32 _callbackGasLimit,uint256 _interval) VRFConsumerBaseV2(_vrfCoordinator){
        i_entranceFee=entranceFee;
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);  // from docs in supported network
        s_raffleState=RaffleState.OPEN; //s_raffleState=RaffleState(0);
        s_lastTimeStamp = block.timestamp;
        i_interval = _interval;
    }

    function enterRaffle() public payable{
        if(msg.value < i_entranceFee){
            revert Raffle__NotEnoughEthEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender)); // type casting payable because msg.sender is an address but we want payable address.
        emit RaffleEnter(msg.sender);
    }


     /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.(atleast one player)
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(bytes memory /*checkData "because we dont use it"*/) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {  // made public so that we can call it from perfromUpkeep.
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    //request a random number
     /*function requestRandomWinner*/
     function performUpkeep(bytes calldata /* performData */) external override{  // will be called by chainlink and not by our contract
        (bool upkeepNeeded, ) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance,s_players.length,uint256(s_raffleState));
        }
         s_raffleState = RaffleState.CALCULATING;
         
         uint256 requestId=i_vrfCoordinator.requestRandomWords(  //from docs
            i_keyHash,  // from docs
            i_subscriptionId, // from subscription manager
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,  // max gas to be spent
            NUM_WORDS);  // number of random numbers

        emit RequestedRaffleWinner(requestId);
    }

    //once we get random number do something with it
    function fulfillRandomWords(uint256 /*requestId "because we dont use it"*/, uint256[] memory randomWords) internal override{  //this function is in VRFConsumerBaseV2.sol and we are overriding it.
        uint256 indexOfWinner = randomWords[0] % s_players.length;  // randomWords[0] because we are only getting one number back.
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        //transfering money
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

     /** Getter Functions */

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
}

