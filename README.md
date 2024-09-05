### Introduction

The goal of this code is to implement an electronic voting system in a
blockchain, providing all the usual services that voting system has, such as privacy and
verifiability, plus some others, such as decentralised counting.

### Protocol

This protocol mainly revolves around the concept of blind signatures. Blind signatures allow
us to have signed messages from an entity without the entity knowing the content of it. As
one can imagine, this comes in handy when voting, as voters can get validation for their
votes without revealing what they voted for and in addition, once they have revealed their
vote, their identity is kept secret.
How does this work in the blockchain then? Well, the idea is that every person registered to
vote gets their vote signed by the organiser of the ballot and then, with another account, one
that can’t be tracked back to them, votes. Without the use of blind signatures, if the organiser
saw someone that hasn’t signed up for the ballot voting, they would immediately disqualify
the vote. However, thanks to blind signatures, they can verify that that vote is indeed valid.
Now, we are going to go through a step by step explanation of this procedure, using Alice as
an example of a voter:
 1) The organiser creates a key pair using RSA, publishing e (and n, and from here on,
 we assume that all of the operations are modulo n) and keeping d private.

 2) Once the voting has started, Alice signs up for it, paying the corresponding fee and
 sending a message m, which is equal to h(choice, n1),n2
 e. choice is Alice’s election
 for the poll from the range of options provided and n1 and n2 are nonces from a range
 of 2256. n1 and the hash are to protect Alice’s choice from the rest of the voters and n2
 is to make the choice untraceable back to Alice later by the organiser. After some
 time determined by the organiser, the sign up process is closed.

 3) The organiser signs Alice’s m and publishes it along with the other signed messages
 in the blockchain, linking every signed message, md, to its owner.

 4) At this point, one could think that Alice’s (as well as the other voters’) vote is
 endangered, as anyone could take anyone’s vote and use it, but this is not true! First
 of all, because only Alice knows n2, only she can retrieve h(choice, n1)d, and in
 addition, because only Alice knows choice and n1, only she can later provide a valid
 vote! Furthermore, Alice can not only obtain h(choice, n1)d, but also prove that the
 signing is valid. To obtain h(choice, n1)d, Alice simply needs to separate (h(choice,
 n1),n2
 e)d into h(choice, n1)d,n2
 ed, and since n2
 ed is equal to n2, she just needs to
 separate n2 from h(choice, n1)d. To prove that the signing is valid, Alice simply can
 compute (h(choice, n1),n2
 e)de, and if the signing is valid, then she should get the
 original message m, that is h(choice, n1),n2
 e.

5) Once Alice has her h(choice, n1)d, which is only known to her, she can, with another
 account, provide h(choice, n1)d, choice and n1, which will be corroborated as a valid
 vote and added to the count by the organiser. The rest of voters have to do the same
 in the specified timeslot.

 6) After the voting has taken place, someone calls a function to count the votes and
 return the winner.

 7) Finally, everyone who has acted honestly can retrieve their money

### Code

 `constructor()`: this is the constructor of the contract and its purpose is to initialise some
 previously declared variables, like the organiser, the duration of each epoch and the number
 of options to choose from. In addition, the organiser will publish here its e and n for the RSA
 blind signature protocol. **1631012 gas**.

 ``signUp()``: voters will deposit their money and communicate their blinded message to the
 organiser through this function. As one can see, it maps the message to the sender’s
 address so that people can vote multiple times if they deposit more than 1 ether.
 Furthermore, the voter’s deposit is increased by 0.95 ether. The idea is that the remaining
 0.05 ether will go to the person that calls the revealWinner() function. **93426 gas**.

 ``revealSignedMessage()``: one of the most important functions in the whole code, if not the
 most. This function can only be used by the organiser and its purpose is to publish the list of
 signed messages, which, as we have seen previously, doesn’t leak any information about
 the choice of each participant. The questions now are, what incentive does the organiser
 have? And, how can we ensure that they don’t perform any malicious actions? Let’s take a
 look at every possible scenario:

    a. The organiser is honest. The organiser provides a valid signature for the message
    that the specified address sent, and as a reward, they earn 0.05 ether.

    b. The organiser doesn’t provide a valid signature. The verifyRSASignature() function
    returns false and therefore the organiser doesn’t earn the money.

    c. The organiser provides a valid signature but an invalid address. The require
    statement checks that either the voter parameter is 0 or the message parameter is
    not the one mapped to the voter parameter and therefore the organiser doesn’t earn
    any money.

    d. The organiser tries to call this function multiple times. The organiser could attempt to
    do something like this in order to get more ether, but then
    require(!messagesSigned[_voter], "This message has already been
    signed"); would return false and therefore the organiser doesn’t earn any money.

 All in all, it simply doesn’t make sense for the organiser to tamper the voting process at this
 stage. If they are honest, they win money and if not, they don’t. The only reason by which
 they would tamper the voting process is if they didn’t want the elections to take place or if
 they wanted an specific option to win or an specific option to lose. However, this wouldn’t
 make much sense either as 1, somebody else would run the elections then and 2, because
 the votes are still private, they really don’t know what the outcome is at this point. **1142581 gas**.

``vote()``: similar to revealSignedMessage(), vote() performs various require checkings to
 guarantee that the vote provided is valid. A valid vote means that it has been signed by the
 entity organising the ballot, that the choice is within the provided range and that it hasn’t
 been used yet. **1054232gas**.

 ``revealWinner()``: this function uses a for loop to count the votes for each option and then
 returns the one with the most votes. In the case of draw, the option, represented by the
 lowest number wins. It is usually recommended to avoid using for loops in Solidity, as
 transactions may run out of gas if the limit is undefined, but in this contract the limit, options,
 is well defined in the constructor. Everybody can call this function in case that the organiser
 doesn’t want to, and for doing such, they will receive the money left from the voters’ deposit.
 **606567 gas**.

 ``withdraw()``: final function that allows everybody to get their money back. In case of the
 voters, they will get it from the account they voted with. Each voter has their address
 mapped to a reentrancy flag so as to prevent them from performing a DAO-like attack. After
 withdrawing their corresponding amount, their deposit is set to 0. **109021 gas**.

 ``verifyRSASignature()``: prepares the parameters for modExp() and ultimately indicates
 whether the “signed message” is actually a signed version of “message” or not. **702755 gas**.

 ``modExp()``: key function in the program as it allows everybody to verify the signatures in the
 messages that they have sent. Because we are using RSA, to retrieve the original message
 from the signed message, we have to perform modular exponentiation, using the signed
 message as the base. If everyone has been honest, then messagede mod n should be equal
 to message. **503947 gas**.

### Services and Conclusion

We are going to finish this report by doing a wrap-up of the services provided by this implementation of an e-voting system and discussing possible attacks.

- Anyone on the Ethereum network can sign up in the protocol by depositing 1 ether.
   One may sign up several times and thus pay a larger overall deposit. *True*. ``signUp()``
   allows any user to vote how many times they want to by depositing 1 ether.

- At the end of the protocol, everyone can get their deposits back. The returned value
   may be a bit smaller than the original deposit, e.g. 0.9 ether, if you need to pay for
   something in your protocol. *True*. ``withdrawal()`` allows people to get the money they
   deserve back. Throughout the code, there are instances where some money is
   deducted from them, so as to incentivize other participants to perform certain actions
   such as signing or revealing.

- Each deposit of 1 ether entitles the depositor to one vote. *True*. ``signUp()`` allows any
   user to vote, and assigns one vote to each ether they deposit, as they can only vote
   when they sign up, and they can only sign up if they put 1 ether.

- After a particular deadline 𝑡1, the contract stops accepting deposits and instead only
   accepts votes by those who have already deposited money. *True*. ``signUp()`` and
   ``signMessage()`` functions cannot be called after a certain block number.
   ``require(block.number>=deployedBlockNumber && block.number<deployedBlockNumber + duration, "This function cannot be called in this block");``

- No one can vote twice for the same deposit. *True*. 

- After a later deadline 𝑡2, the contract stops accepting votes. *True*. ``vote()`` function
   cannot be called after a certain block number.
   ``require(block.number>=deployedBlockNumber + duration && block.number<deployedBlockNumber + 2*duration, "This function cannot be called in this block");``

- After an even later deadline 𝑡3, everyone with access to the blockchain should be
   able to figure out which option from the set {1, 2, ... , 𝑘} received the maximum
   number of votes. If there is a tie, you can break it arbitrarily as you wish. *True*.
   ``revealWinner()`` function cannot be called after a certain block number.
   ``require(block.number>=deployedBlockNumber + 2*duration && block.number<deployedBlockNumber + 3*duration, "This function cannot be called in this block");``

- No one should be able to know another person’s vote. *True*. This has been explained
   already. Blind signatures, n2 and the use of another account makes voters
   untraceable.
   
- If Alice has voted for 𝑖 ∈ {1, 2, ... , 𝑘} and she wants to prove this to Bob, she should
   be able to do so. You can assume that Bob has access to the blockchain.*True*.
   Assuming that Bob doesn’t know the address from which Alice voted and that he
   doesn’t trust her, It is fairly simple for Alice to prove to Bob that she voted for k. In
   order to do so, Alice needs to ask Bob for its ethereum address. Once she has it, she
   can make a transaction to Bob of 0 eth (plus transaction fees). Bob can now look at
   the address of the correspondent sender (Alice) and check that she voted for k.
   Because the recipient is Bob, it couldn’t occur that Alice is reusing another person’s
   proof. In case Bob didn’t want to reveal his address to Alice, he could just choose a
   random address and wait till the transaction was published in the ledger.
