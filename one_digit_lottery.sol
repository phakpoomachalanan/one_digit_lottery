pragma solidity >=0.7.0 <0.9.0;

contract lottery {
    struct User{
        uint choice;
        address addr;
    }

    bool[5] isChoose = [false];

    address public owner;
    uint private T1;
    uint private T2;

    uint private reward = 0;
    uint private startTime = 0;
    uint private numUser = 0;

    uint private ownerChoice;
    bytes32 private ownerCommit;

    bool isRevealed = false;

    mapping (address => uint) private userNumber;
    mapping (uint => User) private users;

    constructor(uint t1, uint t2) {
        owner = msg.sender;
        T1 = t1;
        T2 = t2;
    }

    function startContract(uint choice, uint salt) public payable {
        require(msg.value == 3 ether, "3 ETH");
        require(msg.sender == owner, "Owner only");

        reward += 3 ether;

        if (startTime == 0) {
            startTime = block.timestamp;
        }

        ownerCommit = keccak256(abi.encodePacked(bytes32(choice), bytes32(salt)));
    }

    function addUser(uint choice) public payable {
        require(msg.value == 1 ether, "1 ETH");
        require(numUser < 5, "Full");
        require(startTime != 0 && block.timestamp - startTime <= T1, "Too late");
        require(isChoose[choice] == false, "Already chosen");

        reward += msg.value;
        numUser++;

        userNumber[msg.sender] = numUser;

        users[numUser].choice = choice;
        users[numUser].addr = msg.sender;

        isChoose[choice] = true;
    }

    function revealChoice(uint choice, uint salt) public {
        require(block.timestamp - startTime >= T1, "Too early");
        require(keccak256(abi.encodePacked(bytes32(choice), bytes32(salt))) == ownerCommit, "Incorrect choice or salt");

        ownerChoice = choice;
    }

    function checkWinner() public payable {
        require(block.timestamp - startTime - T1 <= T2, "Too early");
        require(owner == msg.sender, "Owner");

        bool hasWinner;
        address payable winnerAddr;

        isRevealed = true;

        for (uint i=0; i<5; i++) {
            if (users[i].choice == ownerChoice) {
                hasWinner = true;
                reward -= 3 ether;
                winnerAddr = payable(users[i].addr);
                winnerAddr.transfer(3 ether);
            }
        }

        payable(owner).transfer(reward);
    }

    function withdraw() public payable {
        require(block.timestamp >= startTime + T1 + T2, "Please wait");
        require(isRevealed == false, "Already reveled");

        for(uint i = 0; i < numUser; i++) {
            if (users[i].choice != 5) {
                users[i].choice = 5;
                users[i].addr = address(0);
                reward -= 1 ether;
                payable(users[i].addr).transfer(1 ether);
            }
        }
    }
}