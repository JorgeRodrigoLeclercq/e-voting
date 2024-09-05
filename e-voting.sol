pragma solidity >=0.7.0 <0.9.0;

contract Ballot {

    mapping(address => uint256) public deposits;  // each player's deposit
    mapping(bytes32 => address) public messages;  // each player's blinded message
    mapping(bytes32 => address) public signedMessages;  // each player's signed blinded message
    mapping(bytes32 => bool) public messagesSigned;  
    mapping(uint256 => uint256) public optionCount;  
    mapping(bytes32 => bool) public votes;
    mapping(address => bool) public reentrancy_flags;

    uint256 winner;
    uint256 numberOfVotes;
    bool end;

    address organiser;
    uint256 deployedBlockNumber;
    uint256 duration;
    uint256 options;
    uint256 e;
    uint256 n;

    constructor(uint256 _duration, uint256 _options, uint256 _e, uint256 _n){
        organiser = msg.sender;
        deployedBlockNumber = block.number;
        duration = _duration;
        options = _options;
        e = _e;
        n = _n;
    }

    // Voters deposit their money and communicate their blinded message
    function signUp(bytes32 _message) public payable 
    {   
        require(block.number>=deployedBlockNumber && block.number<deployedBlockNumber + duration, "This function cannot be called in this block");
        require(msg.value == 1 ether, "Deposit must be 1 ETH");
        require(messages[_message] == address(0), "This message has already been sent");

        messages[_message] = msg.sender;
        deposits[msg.sender] += 950000000000000000 wei;
        numberOfVotes += 1;
    }

    // Publish the list of signed messages
    function revealSignedMessage(address _voter, bytes32 _message, bytes32 _signedMessage) public  
    { 
        require(block.number>=deployedBlockNumber && block.number<deployedBlockNumber + duration, "This function cannot be called in this block");
        require(msg.sender == organiser, "Only the organiser can sign messages");
        require(verifyRSASignature(_message, _signedMessage), "This message hasn't been signed");
        require(_voter != address(0), "This is an invalid address");
        require(messages[_message] == _voter, "This voter didn't vote for this");
        require(!messagesSigned[_message], "This message has already been signed");

        signedMessages[_signedMessage] = _voter;  
        messagesSigned[_message] = true;  // a message has been signed
        deposits[_voter] -= 50000000000000000 wei;
        deposits[msg.sender] += 50000000000000000 wei;
    }

    // Increase the count of the selected choice
    function vote(bytes32 _signedHash, uint256 _choice, uint256 _nonce) public  
    {
        require(block.number>=deployedBlockNumber + duration && block.number<deployedBlockNumber + 2*duration, "This function cannot be called in this block");
        require(verifyRSASignature(keccak256(abi.encodePacked(_choice, _nonce)), _signedHash), "This message hasn't been signed");
        require(_choice < options, "That's not a valid option");
        require(!votes[_signedHash], "This vote has already been used");

        optionCount[_choice] += 1;
        votes[_signedHash] = true;  // a vote has been used
    }

    // Announce the winner and finish the poll
    function revealWinner() public returns(uint256)  
    {
        require(block.number>=deployedBlockNumber + 2*duration && block.number<deployedBlockNumber + 3*duration, "This function cannot be called in this block");
        require(!end, "The winner has already been revealed");
        
        // Count the votes
        for (uint256 i = 0; i < options; i++) {
            if (optionCount[i] > optionCount[winner]) {
                winner = i;
            }
        }
        
        deposits[msg.sender] += numberOfVotes*50000000000000000 wei;
        end = true;  // the poll is over

        return winner;
    }

    // Withdraw the corresponding deposit
    function withdraw() public  
    {
        require(block.number>=deployedBlockNumber + 3*duration, "This function cannot be called in this block");
        require(!reentrancy_flags[msg.sender], "REENTRANCY ATTACK DETECTED");

        reentrancy_flags[msg.sender] = true;
        msg.sender.call{ value: deposits[msg.sender] }("");
        deposits[msg.sender] = 0;  
    }

    // Compare messages
    function verifyRSASignature(bytes32 _message, bytes32 _signedMessage) view  private returns(bool)
    {
        uint256 message = uint256(_message);
        uint256 signedMessage = uint256(_signedMessage);

        uint256 result = modExp(signedMessage, e, n);

        return result == message;
    }

    // Follow RSA decryption process
    function modExp(uint256 base, uint256 exponent, uint256 modulus) pure private returns(uint256) 
    {
        if (modulus == 1) return 0;
        uint256 result = 1;
        base = base % modulus;  // limit base to [0, modulus - 1]
        while (exponent > 0) {
            if (exponent % 2 == 1) {  // bit in the exponent is 1
                result = (result * base) % modulus;
            }
            exponent = exponent >> 1;  // divide by 2
            base = (base * base) % modulus;
        }
        return result;
    }
}